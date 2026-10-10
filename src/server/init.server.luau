--[[ GUGU-GAGA · Servidor
	Valida la contraseña, pone la etiqueta TEAM gugu-gaga, reparte el estado
	de los emotes para sincronizarlos, aplica los trolleos al cuerpo (los ven
	todos) y crea la base gigante para caminar lejos. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- La contraseña vive en el módulo hijo Secret: solo existe en el servidor y no se sube a GitHub.
local PASSWORD
do
	local secret = script:FindFirstChild("Secret")
	local ok, value = pcall(function()
		return require(secret)
	end)
	if ok and type(value) == "table" and type(value.Password) == "string" and value.Password ~= "" then
		PASSWORD = value.Password
	else
		warn("[GuguGaga] Falta ServerScriptService.GuguGagaServer.Secret (ModuleScript que devuelve { Password = \"...\" }). Nadie podrá activar el menú.")
	end
end

local root = ReplicatedStorage:WaitForChild("GuguGaga")
local Config = require(root:WaitForChild("Config"))

local remotes = root:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = root

local function getRemote(className, name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotes
	end
	return r
end
local AuthFn = getRemote("RemoteFunction", "Auth")
local Net = getRemote("RemoteEvent", "Net")

local store
pcall(function()
	store = DataStoreService:GetDataStore("GuguGaga_v1")
end)

local authed, attempts, saved, cooldown = {}, {}, {}, {}
local emoteState, leaders, morphs = {}, {}, {}
local snapshots = setmetatable({}, { __mode = "k" })
local ragdolls, rides, floatHeads, rainbows = {}, {}, {}, {}

local function rateOk(player, key, gap)
	local c = cooldown[player]
	if not c then
		c = {}
		cooldown[player] = c
	end
	local now = os.clock()
	if c[key] and now - c[key] < gap then
		return false
	end
	c[key] = now
	return true
end

local function notify(player, text, kind)
	Net:FireClient(player, "Notify", text, kind)
end

---------------------------------------------------------------- datos guardados

local function sanitize(d)
	local out = { fav = {}, binds = {}, custom = {}, settings = {} }
	if type(d) ~= "table" then
		return out
	end
	if type(d.fav) == "table" then
		for _, v in d.fav do
			if type(v) == "number" and #out.fav < 200 then
				table.insert(out.fav, v)
			end
		end
	end
	if type(d.binds) == "table" then
		local n = 0
		for k, v in d.binds do
			if type(k) == "string" and type(v) == "number" and n < 40 then
				out.binds[k] = v
				n += 1
			end
		end
	end
	if type(d.custom) == "table" then
		for _, c in d.custom do
			if type(c) == "table" and type(c.id) == "number" and type(c.name) == "string" and #out.custom < 60 then
				table.insert(out.custom, { id = c.id, name = string.sub(c.name, 1, 28) })
			end
		end
	end
	if type(d.settings) == "table" then
		for k, v in d.settings do
			if type(k) == "string" and (type(v) == "number" or type(v) == "boolean") then
				out.settings[k] = v
			end
		end
	end
	return out
end

local function loadData(player)
	local data
	if store then
		local ok, res = pcall(function()
			return store:GetAsync("u" .. player.UserId)
		end)
		if ok then
			data = res
		end
	end
	return sanitize(data)
end

local function saveData(player)
	if not store or not saved[player] then
		return
	end
	local data = saved[player]
	pcall(function()
		store:SetAsync("u" .. player.UserId, data)
	end)
end

---------------------------------------------------------------- base gigante

local function buildMegaBase()
	if workspace:FindFirstChild("GuguGagaMegaBase") then
		return
	end
	local base = workspace:FindFirstChild("Baseplate")
	if base and not base:IsA("BasePart") then
		base = nil
	end
	local TILE, RADIUS = 2048, 3 -- 7x7 losas = 14 336 studs de lado
	local folder = Instance.new("Folder")
	folder.Name = "GuguGagaMegaBase"
	local topY = base and (base.Position.Y + base.Size.Y / 2) or 0
	local cx, cz = base and base.Position.X or 0, base and base.Position.Z or 0
	local reuseBase = base and base.Size.X == TILE and base.Size.Z == TILE
	for x = -RADIUS, RADIUS do
		for z = -RADIUS, RADIUS do
			if not (reuseBase and x == 0 and z == 0) then
				local tile
				if base then
					tile = base:Clone()
					tile.Size = Vector3.new(TILE, base.Size.Y, TILE)
				else
					tile = Instance.new("Part")
					tile.Size = Vector3.new(TILE, 16, TILE)
					tile.Material = Enum.Material.Grass
					tile.Color = Color3.fromRGB(86, 171, 92)
				end
				tile.Name = "Tile"
				tile.Anchored = true
				tile.Locked = true
				tile.CFrame = CFrame.new(cx + x * TILE, topY - tile.Size.Y / 2, cz + z * TILE)
				tile.Parent = folder
			end
		end
	end
	folder.Parent = workspace
end

---------------------------------------------------------------- etiqueta TEAM

local function addTag(player, char)
	local head = char:WaitForChild("Head", 10)
	if not head or not head:IsA("BasePart") then
		return
	end
	local old = head:FindFirstChild("GGTag")
	if old then
		old:Destroy()
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "GGTag"
	bb.Size = UDim2.fromOffset(240, 58)
	bb.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 160
	bb.LightInfluence = 0

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 34)
	title.Font = Enum.Font.FredokaOne
	title.Text = "👶 " .. Config.TeamTag .. " 👶"
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(30, 0, 50)
	stroke.Parent = title
	local shine = Instance.new("UIGradient")
	shine.Name = "Shine"
	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Config.Theme.Cyan),
		ColorSequenceKeypoint.new(0.5, Config.Theme.Pink),
		ColorSequenceKeypoint.new(1, Config.Theme.Purple),
	})
	shine.Parent = title

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(0, 34)
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Font = Enum.Font.GothamBold
	sub.Text = "@" .. player.Name
	sub.TextSize = 14
	sub.TextColor3 = Color3.fromRGB(230, 225, 255)
	sub.TextStrokeTransparency = 0.4
	sub.Parent = bb

	CollectionService:AddTag(bb, "GGTag")
	bb.Parent = head
end

---------------------------------------------------------------- trolleos (cuerpo)

local BODY = {
	"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local LIMBS = table.move(BODY, 2, #BODY, 1, {})
local ARMS = { "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm" }
local LEGS = { "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" }
local TORSO = { "UpperTorso", "LowerTorso" }

local MORPH_KEYS = {}
for _, m in Config.Morphs do
	MORPH_KEYS[m.key] = true
end

local function factors(set)
	local f = {}
	local function mul(names, v)
		for _, n in names do
			f[n] = (f[n] or Vector3.one) * v
		end
	end
	if set.LongArms then mul(ARMS, Vector3.new(1, 2.8, 1)) end
	if set.LongLegs then mul(LEGS, Vector3.new(1, 2.4, 1)) end
	if set.BigHead then mul({ "Head" }, Vector3.one * 2.6) end
	if set.TinyHead then mul({ "Head" }, Vector3.one * 0.4) end
	if set.Flat then mul(LIMBS, Vector3.new(1, 1, 0.12)) end
	if set.Chubby then
		mul(TORSO, Vector3.new(2.1, 1, 2.3))
		mul(ARMS, Vector3.new(1.5, 1, 1.5))
		mul(LEGS, Vector3.new(1.5, 1, 1.5))
	end
	if set.Noodle then mul(LIMBS, Vector3.new(0.45, 1.5, 0.45)) end
	if set.Giant then mul(BODY, Vector3.one * 3) end
	if set.Tiny then mul(BODY, Vector3.one * 0.4) end
	return f
end

-- Roblox tiene dos tipos de rig: el clásico (Motor6D) y el nuevo (AnimationConstraint,
-- que sigue a sus Attachments). Esto los trata igual.
local function isJoint(d)
	return d:IsA("Motor6D") or d:IsA("AnimationConstraint")
end

local function jointInfo(j)
	if j:IsA("Motor6D") then
		if j.Part0 and j.Part1 then
			return j.Part0, j.Part1, j.C0, j.C1
		end
		return nil
	end
	local a0, a1 = j.Attachment0, j.Attachment1
	if a0 and a1 and a0.Parent and a1.Parent then
		return a0.Parent, a1.Parent, a0.CFrame, a1.CFrame
	end
	return nil
end

local function jointAttachments(j)
	if j:IsA("Motor6D") then
		if j.Part0 and j.Part1 then
			return j.Part0:FindFirstChild(j.Name .. "RigAttachment"), j.Part1:FindFirstChild(j.Name .. "RigAttachment")
		end
		return nil
	end
	return j.Attachment0, j.Attachment1
end

-- posición de cada parte en reposo, relativa al HumanoidRootPart
local function legReach(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	local cfs = { [hrp] = CFrame.identity }
	local joints = {}
	for _, d in char:GetDescendants() do
		if isJoint(d) then
			local p0, p1, c0, c1 = jointInfo(d)
			if p0 then
				table.insert(joints, { p0, p1, c0, c1 })
			end
		end
	end
	for _ = 1, 20 do
		local changed = false
		for _, j in joints do
			local p0, p1, c0, c1 = j[1], j[2], j[3], j[4]
			local a, b = cfs[p0], cfs[p1]
			if a and not b then
				cfs[p1] = a * c0 * c1:Inverse()
				changed = true
			elseif b and not a then
				cfs[p0] = b * c1 * c0:Inverse()
				changed = true
			end
		end
		if not changed then
			break
		end
	end
	local minY = math.huge
	for part, cf in cfs do
		if string.find(part.Name, "Leg") or string.find(part.Name, "Foot") then
			minY = math.min(minY, cf.Position.Y - part.Size.Y / 2)
		end
	end
	if minY == math.huge then
		return nil
	end
	return -minY - hrp.Size.Y / 2
end

local function isFileMesh(m)
	return m:IsA("SpecialMesh") and m.MeshType == Enum.MeshType.FileMesh
end

local function takeSnapshot(char, hum)
	local s = { parts = {}, atts = {}, meshes = {}, trans = {}, decals = {}, acc = {} }
	for _, name in BODY do
		local p = char:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			s.parts[p] = p.Size
			s.trans[p] = p.Transparency
			for _, c in p:GetChildren() do
				if c:IsA("Attachment") then
					s.atts[c] = c.Position
				elseif isFileMesh(c) then
					s.meshes[c] = c.Scale
				elseif c:IsA("Decal") then
					s.decals[c] = c.Transparency
				end
			end
		end
	end
	for _, acc in char:GetChildren() do
		local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then
			local info = { handle = h, size = h.Size, trans = h.Transparency, atts = {}, layered = h:FindFirstChildOfClass("WrapLayer") ~= nil }
			local mesh = h:FindFirstChildOfClass("SpecialMesh")
			if mesh and isFileMesh(mesh) then
				info.mesh, info.meshScale = mesh, mesh.Scale
			end
			local weld = h:FindFirstChild("AccessoryWeld")
			if weld and weld:IsA("Weld") then
				info.weld = weld
				info.body = weld.Part0 == h and weld.Part1 or weld.Part0
			end
			-- rig nuevo: el accesorio va con un RigidConstraint que sigue a los Attachments solo
			local rigid = h:FindFirstChildWhichIsA("RigidConstraint")
			if rigid and rigid.Attachment0 and rigid.Attachment1 then
				local a0, a1 = rigid.Attachment0, rigid.Attachment1
				info.body = a0.Parent == h and a1.Parent or a0.Parent
			end
			for _, a in h:GetChildren() do
				if a:IsA("Attachment") then
					info.atts[a] = a.Position
					local bodyAtt = info.body and info.body:FindFirstChild(a.Name)
					if bodyAtt and bodyAtt:IsA("Attachment") then
						info.handleAtt, info.bodyAtt = a, bodyAtt
					end
				end
			end
			table.insert(s.acc, info)
		end
	end
	local head = char:FindFirstChild("Head")
	local neck = head and head:FindFirstChild("Neck")
	if neck and neck:IsA("AnimationConstraint") then
		s.neck, s.neckA0 = neck, neck.Attachment0
	end
	s.hip = hum.HipHeight
	s.reach = legReach(char)
	return s
end

local function applyMorphs(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or ragdolls[player] then
		return
	end
	local set = morphs[player] or {}
	if hum.RigType ~= Enum.HumanoidRigType.R15 then
		if next(set) then
			notify(player, "Los trolleos de cuerpo necesitan avatar R15", "error")
		end
		morphs[player] = {}
		Net:FireClient(player, "Morphs", {})
		return
	end
	local s = snapshots[char]
	if not s then
		-- con el autoescalado activo, BuildRigFromAttachments devuelve las partes a su tamaño original
		hum.AutomaticScalingEnabled = false
		s = takeSnapshot(char, hum)
		snapshots[char] = s
	end

	-- 1) volver a la forma original
	for _, d in char:GetDescendants() do
		if d.Name == "GGNeckAtt" then
			d:Destroy()
		end
	end
	if s.neck and s.neckA0 then
		s.neck.Attachment0 = s.neckA0
	end
	for p, v in s.parts do p.Size = v end
	for a, v in s.atts do a.Position = v end
	for m, v in s.meshes do m.Scale = v end
	for p, v in s.trans do p.Transparency = v end
	for d, v in s.decals do d.Transparency = v end
	for _, info in s.acc do
		info.handle.Transparency = info.trans
		if not info.layered then
			info.handle.Size = info.size
			if info.mesh then info.mesh.Scale = info.meshScale end
			for a, v in info.atts do a.Position = v end
		end
	end

	-- 2) deformar
	local f = factors(set)
	for p, size in s.parts do
		local k = f[p.Name]
		if k then
			p.Size = size * k
			for _, c in p:GetChildren() do
				if s.atts[c] then
					c.Position = s.atts[c] * k
				elseif s.meshes[c] then
					c.Scale = s.meshes[c] * k
				end
			end
		end
	end
	for _, info in s.acc do
		local k = info.body and f[info.body.Name]
		if k and not info.layered then
			info.handle.Size = info.size * k
			if info.mesh then info.mesh.Scale = info.meshScale * k end
			for a, v in info.atts do a.Position = v * k end
		end
	end

	-- 3) reconstruir articulaciones y altura de cadera
	hum:BuildRigFromAttachments()
	for _, info in s.acc do
		local w = info.weld
		if w and w.Parent and info.handleAtt and info.bodyAtt then
			if w.Part0 == info.handle then
				w.C0, w.C1 = info.handleAtt.CFrame, info.bodyAtt.CFrame
			else
				w.C0, w.C1 = info.bodyAtt.CFrame, info.handleAtt.CFrame
			end
		end
	end
	local reach = legReach(char)
	if reach and s.reach then
		hum.HipHeight = math.max(0.2, s.hip + (reach - s.reach))
	else
		hum.HipHeight = s.hip
	end

	-- 4) transparencias
	local head = char:FindFirstChild("Head")
	if set.Ghost then
		for p, v in s.trans do
			if p.Name ~= "HumanoidRootPart" then p.Transparency = math.max(v, 0.75) end
		end
		for d in s.decals do d.Transparency = 0.75 end
		for _, info in s.acc do info.handle.Transparency = math.max(info.trans, 0.75) end
	end
	if set.Headless and head then
		head.Transparency = 1
		for d in s.decals do
			if d.Parent == head then d.Transparency = 1 end
		end
		for _, info in s.acc do
			if info.body == head then info.handle.Transparency = 1 end
		end
	end

	-- 5) cuello: cabeza en la mano o flotando
	floatHeads[player] = nil
	local neck = head and head:FindFirstChild("Neck")
	hum.RequiresNeck = not (set.HeadInHand or set.FloatHead)
	local hand = char:FindFirstChild("RightHand")
	if neck and neck:IsA("Motor6D") then
		if set.HeadInHand and hand then
			neck.Part0 = hand
			neck.C0 = CFrame.new(0, -(hand.Size.Y / 2 + head.Size.Y * 0.45), -0.3)
			neck.C1 = CFrame.new()
		elseif set.FloatHead then
			floatHeads[player] = { neck = neck, base = neck.C0, lift = head.Size.Y * 1.5 + 1 }
		end
	elseif neck and neck:IsA("AnimationConstraint") and neck.Attachment1 and s.neckA0 then
		-- rig nuevo: se mueve el punto de enganche del cuello con un Attachment propio
		local a1 = neck.Attachment1
		if set.HeadInHand and hand then
			local a = Instance.new("Attachment")
			a.Name = "GGNeckAtt"
			a.CFrame = CFrame.new(0, -(hand.Size.Y / 2 + head.Size.Y * 0.45), -0.3) * a1.CFrame
			a.Parent = hand
			neck.Attachment0 = a
		elseif set.FloatHead then
			local a = Instance.new("Attachment")
			a.Name = "GGNeckAtt"
			a.CFrame = s.neckA0.CFrame
			a.Parent = s.neckA0.Parent
			neck.Attachment0 = a
			floatHeads[player] = { att = a, base = s.neckA0.CFrame, lift = head.Size.Y * 1.5 + 1 }
		end
	end

	-- 6) arcoíris
	local hl = char:FindFirstChild("GGRainbow")
	if set.Rainbow then
		if not hl then
			hl = Instance.new("Highlight")
			hl.Name = "GGRainbow"
			hl.FillTransparency = 0.35
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = char
		end
		rainbows[player] = hl
	else
		if hl then hl:Destroy() end
		rainbows[player] = nil
	end

	local tag = head and head:FindFirstChild("GGTag")
	if tag then
		tag.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 2, 0)
	end
	Net:FireClient(player, "Morphs", set)
end

---------------------------------------------------------------- ragdoll

local function setRagdoll(player, on)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if on then
		if ragdolls[player] or hum.Health <= 0 then
			return
		end
		local data = { sockets = {}, motors = {}, collide = {}, requiresNeck = hum.RequiresNeck }
		for _, m in char:GetDescendants() do
			if isJoint(m) and m.Name ~= "Root" then
				local a0, a1 = jointAttachments(m)
				if a0 and a1 then
					local bs = Instance.new("BallSocketConstraint")
					bs.Name = "GGRagdoll"
					bs.Attachment0, bs.Attachment1 = a0, a1
					bs.LimitsEnabled = true
					bs.UpperAngle = 75
					bs.TwistLimitsEnabled = true
					bs.TwistLowerAngle, bs.TwistUpperAngle = -50, 50
					bs.Parent = m.Part1
					table.insert(data.sockets, bs)
					m.Enabled = false
					table.insert(data.motors, m)
				end
			end
		end
		for _, p in char:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				data.collide[p] = p.CanCollide
				p.CanCollide = true
			end
		end
		hum.RequiresNeck = false
		ragdolls[player] = data
		Net:FireClient(player, "Ragdoll", true)
		task.delay(5, function()
			if ragdolls[player] == data then
				setRagdoll(player, false)
			end
		end)
	else
		local data = ragdolls[player]
		if not data then
			return
		end
		ragdolls[player] = nil
		for _, bs in data.sockets do bs:Destroy() end
		for _, m in data.motors do m.Enabled = true end
		for p, v in data.collide do p.CanCollide = v end
		hum.RequiresNeck = data.requiresNeck
		Net:FireClient(player, "Ragdoll", false)
	end
end

---------------------------------------------------------------- montarse en la cabeza de alguien

local function stopRide(player)
	local r = rides[player]
	if not r then
		return
	end
	rides[player] = nil
	if r.weld then r.weld:Destroy() end
	for p, v in r.massless do
		if p.Parent then
			p.Massless = v
			p.CanCollide = r.collide[p]
		end
	end
	Net:FireClient(player, "Ride", false)
end

local function startRide(player, target)
	stopRide(player)
	local char, tchar = player.Character, target.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = tchar and tchar:FindFirstChild("Head")
	if not (hrp and hum and head) then
		return
	end
	local r = { massless = {}, collide = {} }
	for _, p in char:GetDescendants() do
		if p:IsA("BasePart") then
			r.massless[p], r.collide[p] = p.Massless, p.CanCollide
			p.Massless = true
			p.CanCollide = false
		end
	end
	local w = Instance.new("Weld")
	w.Name = "GGRide"
	w.Part0, w.Part1 = head, hrp
	w.C0 = CFrame.new(0, head.Size.Y / 2 + hrp.Size.Y * 0.8, 0)
	w.Parent = hrp
	r.weld = w
	rides[player] = r
	Net:FireClient(player, "Ride", true)
end

---------------------------------------------------------------- copiar avatar

local function applyAvatar(player, userId)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	if not ok or not desc then
		notify(player, "No se pudo cargar ese avatar", "error")
		return
	end
	stopRide(player)
	setRagdoll(player, false)
	morphs[player] = {}
	applyMorphs(player)
	snapshots[char] = nil
	hum.AutomaticScalingEnabled = true -- para que el avatar nuevo traiga sus proporciones
	local applied = pcall(function()
		hum:ApplyDescription(desc)
	end)
	snapshots[char] = nil
	if authed[player] then
		task.spawn(addTag, player, char)
	end
	Net:FireClient(player, "Morphs", {})
	if not applied then
		notify(player, "Roblox no dejó aplicar ese avatar", "error")
	end
end

---------------------------------------------------------------- efecto de activación (lo ven todos)

local function burst(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Config.Theme.Cyan),
		ColorSequenceKeypoint.new(0.5, Config.Theme.Pink),
		ColorSequenceKeypoint.new(1, Config.Theme.Purple),
	})
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Speed = NumberRange.new(18, 36)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 3
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(90)
	Debris:AddItem(att, 3)

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Config.Theme.Pink
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(0.4, 2, 2)
	ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.1
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quint), {
		Size = Vector3.new(0.2, 70, 70),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 1)
end

---------------------------------------------------------------- contraseña

local function snapshotState()
	local em, ld = {}, {}
	for p, st in emoteState do
		table.insert(em, { p, st })
	end
	for p, l in leaders do
		table.insert(ld, { p, l })
	end
	return { emotes = em, leaders = ld }
end

AuthFn.OnServerInvoke = function(player, pass)
	if authed[player] then
		return { ok = true, data = saved[player], state = snapshotState() }
	end
	local a = attempts[player]
	if not a then
		a = { n = 0, lock = 0 }
		attempts[player] = a
	end
	if os.clock() < a.lock then
		return { ok = false, msg = string.format("Demasiados intentos. Espera %d s", math.ceil(a.lock - os.clock())) }
	end
	if type(pass) ~= "string" then
		return { ok = false, msg = "Contraseña incorrecta" }
	end
	pass = string.gsub(pass, "^%s+", "")
	pass = string.gsub(pass, "%s+$", "")
	if not PASSWORD or pass ~= PASSWORD then
		a.n += 1
		if a.n >= 5 then
			a.n = 0
			a.lock = os.clock() + 15
		end
		return { ok = false, msg = "❌ Contraseña incorrecta" }
	end
	authed[player] = true
	saved[player] = loadData(player)
	player:SetAttribute("GuguGaga", true)
	if player.Character then
		task.spawn(addTag, player, player.Character)
	end
	for _, other in Players:GetPlayers() do
		if other ~= player and authed[other] then
			notify(other, "👶 " .. player.DisplayName .. " entró al TEAM gugu-gaga", "team")
		end
	end
	return { ok = true, data = saved[player], state = snapshotState() }
end

---------------------------------------------------------------- acciones del cliente

local function rootOf(p)
	local seen = {}
	while leaders[p] and not seen[p] do
		seen[p] = true
		p = leaders[p]
	end
	return p
end

local function isMember(p)
	return typeof(p) == "Instance" and p:IsA("Player") and p.Parent == Players and authed[p] == true
end

local handlers = {}

function handlers.Emote(player, id, speed, start, loop)
	if not rateOk(player, "emote", 0.05) then
		return
	end
	if id == nil then
		emoteState[player] = nil
	else
		if type(id) ~= "number" or id <= 0 or id ~= id or id > 1e15 then
			return
		end
		speed = type(speed) == "number" and speed == speed and math.clamp(speed, 0.05, 5) or 1
		local now = workspace:GetServerTimeNow()
		if type(start) ~= "number" or start ~= start or start > now + 5 or start < now - 1e5 then
			start = now
		end
		emoteState[player] = { id = math.floor(id), speed = speed, start = start, loop = loop ~= false }
	end
	Net:FireAllClients("Emote", player, emoteState[player])
end

function handlers.Sync(player, target)
	if not rateOk(player, "sync", 0.3) then
		return
	end
	if target ~= nil then
		if not isMember(target) or target == player then
			return
		end
		if rootOf(target) == player then
			notify(player, target.DisplayName .. " ya está sincronizado contigo 💞", "info")
			return
		end
		leaders[player] = target
		notify(target, "🔗 " .. player.DisplayName .. " se sincronizó contigo", "team")
	else
		leaders[player] = nil
	end
	Net:FireAllClients("Sync", player, leaders[player])
end

function handlers.Morph(player, key, value)
	if not rateOk(player, "morph", 0.2) then
		return
	end
	local set = morphs[player] or {}
	morphs[player] = set
	if key == "__clear" then
		table.clear(set)
	elseif type(key) == "string" and MORPH_KEYS[key] then
		set[key] = value and true or nil
		if value and Config.Exclusive[key] then
			for _, k in Config.Exclusive[key] do
				set[k] = nil
			end
		end
	else
		return
	end
	if ragdolls[player] then
		notify(player, "Espera a que termine el ragdoll", "warn")
		Net:FireClient(player, "Morphs", set)
		return
	end
	applyMorphs(player)
end

function handlers.Ragdoll(player)
	if rateOk(player, "ragdoll", 1) then
		stopRide(player)
		setRagdoll(player, not ragdolls[player])
	end
end

function handlers.Ride(player, target)
	if not rateOk(player, "ride", 0.5) then
		return
	end
	if target == nil then
		stopRide(player)
	elseif typeof(target) == "Instance" and target:IsA("Player") and target ~= player and target.Parent == Players then
		if rides[target] and rides[target].weld and rides[target].weld.Part0 and rides[target].weld.Part0:IsDescendantOf(player.Character) then
			notify(player, "No pueden montarse uno encima del otro 😂", "warn")
			return
		end
		setRagdoll(player, false)
		startRide(player, target)
	end
end

function handlers.CopyAvatar(player, userId)
	if not rateOk(player, "avatar", 4) then
		notify(player, "Espera unos segundos para cambiar de avatar", "warn")
		return
	end
	if typeof(userId) == "Instance" and userId:IsA("Player") then
		userId = userId.UserId
	end
	if type(userId) ~= "number" or userId <= 0 then
		userId = player.UserId
	end
	applyAvatar(player, userId)
end

function handlers.Reset(player)
	if rateOk(player, "reset", 3) then
		player:LoadCharacter()
	end
end

function handlers.Burst(player)
	if rateOk(player, "burst", 8) then
		burst(player)
	end
end

function handlers.Save(player, data)
	if rateOk(player, "save", 6) then
		saved[player] = sanitize(data)
		task.spawn(saveData, player)
	end
end

Net.OnServerEvent:Connect(function(player, kind, ...)
	if not authed[player] then
		return
	end
	local fn = type(kind) == "string" and handlers[kind]
	if fn then
		fn(player, ...)
	end
end)

---------------------------------------------------------------- jugadores

local function onCharacter(player, char)
	morphs[player] = {}
	ragdolls[player] = nil
	rides[player] = nil
	floatHeads[player] = nil
	rainbows[player] = nil
	if emoteState[player] then
		emoteState[player] = nil
		Net:FireAllClients("Emote", player, nil)
	end
	if authed[player] then
		addTag(player, char)
	end
end

local function onPlayer(player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	stopRide(player)
	for p, l in leaders do
		if l == player then
			leaders[p] = nil
			Net:FireAllClients("Sync", p, nil)
		end
	end
	for _, t in { authed, attempts, saved, cooldown, emoteState, leaders, morphs, ragdolls, rides, floatHeads, rainbows } do
		t[player] = nil
	end
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		saveData(p)
	end
end)

-- cabezas flotantes, arcoíris y jinetes cuyo "caballo" desapareció
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 20 then
		return
	end
	acc = 0
	local t = os.clock()
	for player, fh in floatHeads do
		local target = fh.neck or fh.att
		if target.Parent then
			local cf = fh.base * CFrame.new(0, fh.lift + math.sin(t * 2.2) * 0.35, 0) * CFrame.Angles(0, t * 2, 0)
			if fh.neck then
				fh.neck.C0 = cf
			else
				fh.att.CFrame = cf
			end
		else
			floatHeads[player] = nil
		end
	end
	for player, hl in rainbows do
		if hl.Parent then
			hl.FillColor = Color3.fromHSV((t * 0.25) % 1, 0.85, 1)
			hl.OutlineColor = Color3.fromHSV((t * 0.25 + 0.5) % 1, 0.6, 1)
		else
			rainbows[player] = nil
		end
	end
	for player, r in rides do
		if not r.weld.Parent or not r.weld.Part0 or not r.weld.Part0:IsDescendantOf(workspace) then
			stopRide(player)
		end
	end
end)

buildMegaBase()
