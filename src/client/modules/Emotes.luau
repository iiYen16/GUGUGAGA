--[[ GUGU-GAGA · Emotes
	Reproduce los emotes en tu personaje (se ven para todos), controla la
	velocidad, las teclas asignadas, favoritos y la sincronización: cuando
	sigues a alguien del TEAM, tu emote va al mismo tiempo exacto que el suyo
	usando el reloj del servidor. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent.Parent
local Config = require(root:WaitForChild("Config"))
local Net = root:WaitForChild("Remotes"):WaitForChild("Net")

local lp = Players.LocalPlayer

local Emotes = {
	speed = 1,
	loop = true,
	stopOnMove = true,
	flying = false,
	capturing = false,
	current = nil, -- { id, track, start, speed, loop }
	states = {}, -- [Player] = { id, speed, start, loop }
	leaders = {}, -- [Player] = Player al que sigue
	fav = {}, -- [id] = true
	binds = {}, -- [KeyCode.Name] = id
	custom = {}, -- { {id, name} }
	settings = {},
}

local byId = {}
for _, e in Config.Emotes do
	byId[e.id] = e
end

local listeners = {}
function Emotes.onChange(fn)
	table.insert(listeners, fn)
end
local function changed(what)
	for _, fn in listeners do
		task.spawn(fn, what)
	end
end

function Emotes.nameOf(id)
	if byId[id] then
		return byId[id].name
	end
	for _, c in Emotes.custom do
		if c.id == id then
			return c.name
		end
	end
	return "Emote " .. tostring(id)
end

function Emotes.all()
	local list = table.clone(Config.Emotes)
	for _, c in Emotes.custom do
		table.insert(list, { id = c.id, name = c.name, cat = "custom" })
	end
	return list
end

---------------------------------------------------------------- guardar

local savePending = false
function Emotes.save()
	if savePending then
		return
	end
	savePending = true
	task.delay(7, function()
		savePending = false
		local fav = {}
		for id in Emotes.fav do
			table.insert(fav, id)
		end
		Net:FireServer("Save", { fav = fav, binds = Emotes.binds, custom = Emotes.custom, settings = Emotes.settings })
	end)
end

function Emotes.setSetting(key, value)
	Emotes.settings[key] = value
	Emotes.save()
end

---------------------------------------------------------------- envío al servidor

-- El servidor ignora los envíos de emote que llegan a menos de 0.05 s del anterior.
-- Aquí se espacian y siempre sale el más reciente, para que no se pierda el último
-- (por ejemplo al soltar el deslizador de velocidad o al parar justo después de empezar).
local SEND_GAP = 0.1
local lastSend, pendingSend = 0, nil
local function sendEmote(...)
	local args = table.pack(...)
	local wait = SEND_GAP - (os.clock() - lastSend)
	if wait <= 0 and not pendingSend then
		lastSend = os.clock()
		Net:FireServer("Emote", table.unpack(args, 1, args.n))
		return
	end
	local queued = pendingSend ~= nil
	pendingSend = args
	if not queued then
		task.delay(math.max(wait, 0), function()
			local latest = pendingSend
			pendingSend = nil
			lastSend = os.clock()
			Net:FireServer("Emote", table.unpack(latest, 1, latest.n))
		end)
	end
end

---------------------------------------------------------------- pistas de animación

local humanoid, animator
local tracks = {}

local function phaseOf(track, start, speed, loop)
	local len = track.Length
	if len <= 0 then
		return 0
	end
	local ph = (workspace:GetServerTimeNow() - start) * speed
	if loop then
		return ph % len
	end
	return math.clamp(ph, 0, len - 0.03)
end

function Emotes.following()
	local p, seen = lp, {}
	while Emotes.leaders[p] and not seen[p] do
		seen[p] = true
		p = Emotes.leaders[p]
	end
	if p ~= lp then
		return p
	end
	return nil
end

local function getTrack(id)
	local tr = tracks[id]
	if tr then
		return tr
	end
	if not animator then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	local ok, res = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not res then
		return nil
	end
	res.Priority = Enum.AnimationPriority.Action4
	res.Stopped:Connect(function()
		local cur = Emotes.current
		if cur and cur.track == res then
			-- terminó sola (emote sin repetición)
			Emotes.current = nil
			if not Emotes.following() then
				sendEmote(nil)
			end
			changed("current")
		end
	end)
	tracks[id] = res
	return res
end

local function playTrack(id, speed, start, loop)
	local tr = getTrack(id)
	if not tr then
		return false
	end
	local cur = Emotes.current
	if cur and cur.track ~= tr then
		Emotes.current = nil
		cur.track:Stop(0.2)
	end
	tr.Looped = loop
	if tr.IsPlaying then
		tr:AdjustSpeed(speed)
	else
		tr:Play(0.2, 1, speed)
	end
	local entry = { id = id, track = tr, start = start, speed = speed, loop = loop }
	Emotes.current = entry
	-- poner la animación en el punto exacto (importa para sincronizar)
	task.spawn(function()
		local t0 = os.clock()
		while tr.Length <= 0 and os.clock() - t0 < 4 do
			task.wait()
		end
		if Emotes.current == entry and tr.Length > 0 then
			tr.TimePosition = phaseOf(tr, entry.start, entry.speed, entry.loop)
		end
	end)
	changed("current")
	return true
end

local function halt()
	local cur = Emotes.current
	Emotes.current = nil
	if cur then
		cur.track:Stop(0.25)
		changed("current")
	end
end

---------------------------------------------------------------- API

function Emotes.unsync()
	if Emotes.leaders[lp] then
		Emotes.leaders[lp] = nil
		Net:FireServer("Sync", nil)
		changed("sync")
	end
end

function Emotes.play(id)
	Emotes.unsync()
	local start = workspace:GetServerTimeNow()
	if playTrack(id, Emotes.speed, start, Emotes.loop) then
		sendEmote(id, Emotes.speed, start, Emotes.loop)
	end
end

function Emotes.stop()
	Emotes.unsync()
	halt()
	sendEmote(nil)
end

function Emotes.toggle(id)
	if Emotes.current and Emotes.current.id == id and not Emotes.following() then
		Emotes.stop()
	else
		Emotes.play(id)
	end
end

function Emotes.setSpeed(s)
	Emotes.speed = s
	Emotes.settings.speed = s
	Emotes.save()
	local cur = Emotes.current
	if cur and not Emotes.following() then
		-- conservar el punto de la animación al cambiar la velocidad
		local now = workspace:GetServerTimeNow()
		local phase = (now - cur.start) * cur.speed
		cur.speed = s
		cur.start = now - phase / s
		cur.track:AdjustSpeed(s)
		sendEmote(cur.id, s, cur.start, cur.loop)
	end
end

function Emotes.setLoop(v)
	Emotes.loop = v
	Emotes.settings.loop = v
	Emotes.save()
	local cur = Emotes.current
	if cur and not Emotes.following() then
		cur.loop = v
		cur.track.Looped = v
		sendEmote(cur.id, cur.speed, cur.start, v)
	end
end

function Emotes.toggleFav(id)
	Emotes.fav[id] = not Emotes.fav[id] or nil
	Emotes.save()
	changed("fav")
end

function Emotes.bindKey(keyName, id)
	for k, v in Emotes.binds do
		if v == id then
			Emotes.binds[k] = nil
		end
	end
	if keyName then
		Emotes.binds[keyName] = id
	end
	Emotes.save()
	changed("binds")
end

function Emotes.keyOf(id)
	for k, v in Emotes.binds do
		if v == id then
			return k
		end
	end
	return nil
end

function Emotes.addCustom(id, name)
	for _, c in Emotes.custom do
		if c.id == id then
			c.name = name
			Emotes.save()
			changed("custom")
			return
		end
	end
	table.insert(Emotes.custom, { id = id, name = name })
	Emotes.save()
	changed("custom")
end

function Emotes.removeCustom(id)
	for i, c in Emotes.custom do
		if c.id == id then
			table.remove(Emotes.custom, i)
			break
		end
	end
	Emotes.fav[id] = nil
	Emotes.bindKey(nil, id)
	changed("custom")
end

-- seguir al líder: tu emote = su emote, misma velocidad y mismo punto
local function moving()
	return humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1 and not Emotes.flying
end

function Emotes.applySync()
	local leader = Emotes.following()
	if not leader then
		return
	end
	local st = Emotes.states[leader]
	local cur = Emotes.current
	if st then
		if Emotes.stopOnMove and moving() then
			return
		end
		if not cur or cur.id ~= st.id or cur.start ~= st.start or cur.speed ~= st.speed or cur.loop ~= st.loop then
			playTrack(st.id, st.speed, st.start, st.loop)
		end
	elseif cur then
		halt()
	end
end

---------------------------------------------------------------- arranque

local function bindCharacter(char)
	tracks = {}
	Emotes.current = nil
	humanoid = char:WaitForChild("Humanoid", 10)
	animator = humanoid and humanoid:WaitForChild("Animator", 10)
	changed("current")
	task.delay(1, Emotes.applySync)
end

function Emotes.init(result)
	local data = result and result.data or {}
	for _, id in data.fav or {} do
		Emotes.fav[id] = true
	end
	Emotes.binds = data.binds or {}
	Emotes.custom = data.custom or {}
	Emotes.settings = data.settings or {}
	local s = Emotes.settings
	if type(s.speed) == "number" then Emotes.speed = math.clamp(s.speed, 0.1, 3) end
	if type(s.loop) == "boolean" then Emotes.loop = s.loop end
	if type(s.stopOnMove) == "boolean" then Emotes.stopOnMove = s.stopOnMove end

	local state = result and result.state or {}
	for _, pair in state.emotes or {} do
		if pair[1] then Emotes.states[pair[1]] = pair[2] end
	end
	for _, pair in state.leaders or {} do
		if pair[1] then Emotes.leaders[pair[1]] = pair[2] end
	end

	Net.OnClientEvent:Connect(function(kind, a, b)
		if kind == "Emote" then
			Emotes.states[a] = b
			if a ~= lp then
				Emotes.applySync()
			end
			changed("states")
		elseif kind == "Sync" then
			local before = Emotes.following()
			Emotes.leaders[a] = b
			local after = Emotes.following()
			if before and not after then
				halt()
			end
			Emotes.applySync()
			changed("sync")
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		Emotes.states[p] = nil
		Emotes.leaders[p] = nil
		for q, l in Emotes.leaders do
			if l == p then
				Emotes.leaders[q] = nil
			end
		end
		changed("sync")
	end)

	if lp.Character then
		task.spawn(bindCharacter, lp.Character)
	end
	lp.CharacterAdded:Connect(bindCharacter)

	-- teclas asignadas a emotes
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or Emotes.capturing or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local id = Emotes.binds[input.KeyCode.Name]
		if id then
			Emotes.toggle(id)
		end
	end)

	-- parar al caminar y corregir desfases mientras sigues a alguien
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		if not humanoid then
			return
		end
		local cur = Emotes.current
		if cur and Emotes.stopOnMove and moving() then
			if Emotes.following() then
				halt()
			else
				Emotes.stop()
			end
			return
		end
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		if Emotes.following() then
			if not cur then
				Emotes.applySync()
			elseif cur.track.IsPlaying and cur.track.Length > 0 then
				local want = phaseOf(cur.track, cur.start, cur.speed, cur.loop)
				local diff = math.abs(cur.track.TimePosition - want)
				if diff > 0.08 and diff < cur.track.Length - 0.08 then
					cur.track.TimePosition = want
				end
			end
		end
	end)
end

return Emotes
