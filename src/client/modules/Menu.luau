--[[ GUGU-GAGA · Menú principal
	Ventana con pestañas (Emotes, Jugador, Troll, Team, Mundo, Ajustes),
	burbuja GG flotante, panel de vuelo (tecla L) y atajos de teclado. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Config = require(root:WaitForChild("Config"))
local Net = root:WaitForChild("Remotes"):WaitForChild("Net")
local UI = require(script.Parent.UI)
local Emotes = require(script.Parent.Emotes)
local Movement = require(script.Parent.Movement)
local Icons = require(script.Parent.Icons)
local T = UI.T

local lp = Players.LocalPlayer

local Menu = { open = false, morphs = {} }

local TABS = {
	{ key = "emotes", icon = "💃", label = "Emotes" },
	{ key = "player", icon = "⚡", label = "Jugador" },
	{ key = "troll", icon = "🤪", label = "Troll" },
	{ key = "team", icon = "👶", label = "Team" },
	{ key = "world", icon = "🌍", label = "Mundo" },
	{ key = "settings", icon = "⚙️", label = "Ajustes" },
}

local RESERVED = {
	W = true, A = true, S = true, D = true, Space = true, Slash = true, Tab = true,
	Backquote = true, LeftShift = true, RightShift = true, LeftControl = true, Return = true, Q = true,
}
RESERVED[Config.MenuKey.Name] = true
RESERVED[Config.FlyKey.Name] = true

local CAT_COLOR = { baile = T.Pink, reaccion = T.Cyan, pose = T.Yellow, custom = T.Green }
local CAT_NAME = { baile = "Baile", reaccion = "Reacción", pose = "Pose", custom = "Mi ID" }
local DIGITS = { Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9" }

local function keyShort(k)
	if DIGITS[k] then
		return DIGITS[k]
	end
	local kp = string.match(k, "^Keypad(.+)$")
	if kp then
		return "N" .. (DIGITS[kp] or string.sub(kp, 1, 1))
	end
	if #k > 4 then
		return string.sub(k, 1, 4)
	end
	return k
end

local gui, win, winScale, bubble, flyPanel
local userScale = 1
local pages, tabButtons, ticks = {}, {}, {}
local currentTab
local flyOpen = false

local function baseScale()
	local v = workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(v.X / 720, v.Y / 500), 0.5, 1.2) * userScale
end

local function scrollList(parent, pos, size)
	local sf = UI.new("ScrollingFrame", {
		Position = pos or UDim2.new(),
		Size = size or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	UI.list(sf, 6)
	UI.new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), Parent = sf })
	return sf
end

local function section(parent, text, order)
	return UI.label({ text = text, font = Enum.Font.GothamBlack, textSize = 12, color = T.Pink, size = UDim2.new(1, 0, 0, 22), order = order, parent = parent })
end

local function clearRows(list)
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function avatarIcon(userId, size, parent, pos)
	local img = UI.new("ImageLabel", {
		Image = UI.headshot(userId),
		BackgroundColor3 = T.Panel2,
		Position = pos or UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	}, { UI.corner(UDim.new(1, 0)) })
	return img
end

---------------------------------------------------------------- pestaña EMOTES

local function buildEmotes(page)
	local filter, query = "all", ""
	local cards = {}
	local capture
	local chips = {}

	local search = UI.new("TextBox", {
		Size = UDim2.new(1, -156, 0, 32),
		BackgroundColor3 = T.Panel,
		Text = "",
		PlaceholderText = "🔍  Buscar emote…",
		PlaceholderColor3 = T.Muted,
		TextColor3 = T.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = page,
	}, { UI.corner(8), UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	UI.stroke(T.Cyan, 1, 0.7, search)

	local chipBar = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = page,
	})
	UI.list(chipBar, 6, true)

	local grid = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 1, -160),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = page,
	})
	UI.new("UIGridLayout", {
		CellSize = UDim2.new(0.333, -6, 0, 56),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	UI.new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), Parent = grid })
	local empty = UI.label({
		text = "",
		textSize = 14,
		color = T.Muted,
		wrap = true,
		alignX = Enum.TextXAlignment.Center,
		pos = UDim2.fromOffset(0, 110),
		size = UDim2.new(1, 0, 0, 40),
		parent = page,
	})

	local function refreshCard(c)
		local id = c.e.id
		local isFav = Emotes.fav[id] == true
		c.fav.Text = isFav and "★" or "☆"
		c.fav.TextColor3 = isFav and T.Yellow or T.Muted
		if capture and capture.c == c then
			c.bind.Text = "…"
			c.bind.TextColor3 = T.Pink
		else
			local k = Emotes.keyOf(id)
			c.bind.Text = k and keyShort(k) or "KEY"
			c.bind.TextColor3 = k and T.Cyan or T.Muted
		end
		local playing = Emotes.current ~= nil and Emotes.current.id == id
		c.stroke.Color = playing and T.Pink or (CAT_COLOR[c.e.cat] or T.Cyan)
		c.stroke.Thickness = playing and 2.5 or 1.2
		c.stroke.Transparency = playing and 0 or 0.7
		c.play.Visible = playing
		UI.setBase(c.card, playing and Color3.fromRGB(72, 30, 86) or T.Panel2)
	end
	local function refreshAll()
		for _, c in cards do
			refreshCard(c)
		end
	end

	local function refreshGrid()
		local q = string.lower(query)
		local shown = 0
		for _, c in cards do
			local e = c.e
			local okCat = filter == "all" or (filter == "fav" and Emotes.fav[e.id] == true) or (filter == "top" and e.top == true) or e.cat == filter
			local okQ = q == "" or string.find(string.lower(e.name), q, 1, true) ~= nil
			c.card.Visible = okCat and okQ
			if c.card.Visible then
				shown += 1
			end
		end
		empty.Visible = shown == 0
		if filter == "fav" then
			empty.Text = "Aún no tienes favoritos. Toca ☆ en un emote."
		elseif filter == "custom" then
			empty.Text = "Agrega tus propias animaciones con «+ ID»."
		else
			empty.Text = "No hay emotes con ese nombre."
		end
	end

	local function refreshChips()
		for k, chip in chips do
			UI.setBase(chip, k == filter and Color3.fromRGB(110, 34, 110) or T.Panel2)
			chip.TextColor3 = k == filter and T.Text or T.Muted
		end
	end

	for i, cat in Config.Categories do
		local chip = UI.button({
			text = cat.label,
			size = UDim2.fromOffset(0, 26),
			textSize = 12,
			order = i,
			radius = 13,
			parent = chipBar,
			callback = function()
				filter = cat.key
				refreshChips()
				refreshGrid()
				grid.CanvasPosition = Vector2.zero
			end,
		})
		chip.AutomaticSize = Enum.AutomaticSize.X
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = chip })
		chips[cat.key] = chip
	end

	local function stopCapture()
		local c = capture and capture.c
		capture = nil
		task.defer(function()
			Emotes.capturing = false
		end)
		if c then
			refreshCard(c)
		end
	end

	local function makeCard(e, order)
		local card = UI.new("TextButton", {
			Name = "E" .. e.id,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.Panel2,
			LayoutOrder = order,
			Parent = grid,
		}, { UI.corner(10) })
		UI.hover(card)
		local stroke = UI.stroke(CAT_COLOR[e.cat] or T.Cyan, 1.2, 0.7, card)
		UI.new("Frame", {
			Size = UDim2.new(0, 4, 1, -14),
			Position = UDim2.fromOffset(6, 7),
			BackgroundColor3 = CAT_COLOR[e.cat] or T.Cyan,
			BorderSizePixel = 0,
			Parent = card,
		}, { UI.corner(2) })
		UI.label({ text = e.name, font = Enum.Font.GothamBold, textSize = 14, pos = UDim2.fromOffset(16, 5), size = UDim2.new(1, -36, 0, 22), truncate = true, parent = card })
		UI.label({
			text = (e.top and "🔥 " or "") .. (CAT_NAME[e.cat] or ""),
			textSize = 11,
			color = T.Muted,
			pos = UDim2.fromOffset(16, 29),
			size = UDim2.new(1, e.cat == "custom" and -110 or -86, 0, 18),
			truncate = true,
			parent = card,
		})
		local play = UI.label({
			text = "▶",
			font = Enum.Font.GothamBlack,
			textSize = 12,
			color = T.Pink,
			alignX = Enum.TextXAlignment.Center,
			anchor = Vector2.new(1, 0),
			pos = UDim2.new(1, -6, 0, 8),
			size = UDim2.fromOffset(16, 16),
			parent = card,
		})
		local fav = UI.button({ text = "☆", size = UDim2.fromOffset(26, 22), pos = UDim2.new(1, -64, 1, -27), textSize = 15, stroke = false, color = T.Panel, parent = card })
		local bind = UI.button({ text = "KEY", size = UDim2.fromOffset(32, 22), pos = UDim2.new(1, -36, 1, -27), textSize = 10, stroke = false, color = T.Panel, parent = card })
		local c = { e = e, card = card, stroke = stroke, fav = fav, bind = bind, play = play }
		card.Activated:Connect(function()
			UI.sound("click", 0.35)
			Emotes.toggle(e.id)
		end)
		fav.Activated:Connect(function()
			UI.sound("click", 0.35)
			Emotes.toggleFav(e.id)
			if filter == "fav" then
				refreshGrid()
			end
		end)
		bind.Activated:Connect(function()
			UI.sound("click", 0.35)
			if capture and capture.c == c then
				stopCapture()
				return
			end
			if capture then
				stopCapture()
			end
			capture = { c = c }
			Emotes.capturing = true
			refreshCard(c)
			UI.toast("🎹 Presiona una tecla para <b>" .. e.name .. "</b><br/>Backspace = quitar · toca KEY otra vez = cancelar", "info")
		end)
		if e.cat == "custom" then
			UI.button({
				text = "🗑",
				size = UDim2.fromOffset(26, 22),
				pos = UDim2.new(1, -94, 1, -27),
				textSize = 12,
				stroke = false,
				color = T.Panel,
				parent = card,
				callback = function()
					Emotes.removeCustom(e.id)
					UI.toast("Emote quitado", "info")
				end,
			})
		end
		table.insert(cards, c)
		refreshCard(c)
	end

	local function buildCards()
		for _, c in cards do
			c.card:Destroy()
		end
		table.clear(cards)
		for i, e in Emotes.all() do
			makeCard(e, i)
		end
		refreshGrid()
	end

	-- teclas para emotes
	UserInputService.InputBegan:Connect(function(input)
		if not capture or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local key = input.KeyCode
		local e = capture.c.e
		if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
			Emotes.bindKey(nil, e.id)
			UI.toast("Tecla quitada de " .. e.name, "info")
		elseif RESERVED[key.Name] or key == Enum.KeyCode.Escape or key == Enum.KeyCode.Unknown then
			UI.toast("La tecla " .. key.Name .. " está reservada, elige otra", "warn")
			return
		else
			Emotes.bindKey(key.Name, e.id)
			UI.toast("✅ <b>" .. keyShort(key.Name) .. "</b> → " .. e.name, "ok")
		end
		stopCapture()
		refreshAll()
	end)

	-- botones de arriba
	local popup
	UI.button({ text = "+ ID", size = UDim2.fromOffset(70, 32), pos = UDim2.new(1, -150, 0, 0), parent = page, callback = function()
		popup.Visible = not popup.Visible
	end })
	UI.button({
		text = "■ PARAR",
		size = UDim2.fromOffset(76, 32),
		pos = UDim2.new(1, -76, 0, 0),
		color = Color3.fromRGB(90, 28, 52),
		strokeColor = T.Red,
		parent = page,
		callback = function()
			Emotes.stop()
		end,
	})

	-- barra de abajo: velocidad, BPM, repetir, auto-parar
	local bar = UI.new("Frame", {
		Position = UDim2.new(0, 0, 1, -84),
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.1,
		Parent = page,
	}, { UI.corner(10) })
	local bpmBox
	local speed = UI.slider({
		parent = bar,
		text = "⚡ Velocidad del emote",
		min = 0.1,
		max = 3,
		step = 0.05,
		default = Emotes.speed,
		bgT = 1,
		size = UDim2.new(0.6, 0, 0, 54),
		fmt = function(v)
			return string.format("%.2fx", v)
		end,
		callback = function(v)
			Emotes.setSpeed(v)
			if bpmBox then
				bpmBox.Text = tostring(math.floor(v * 120 + 0.5))
			end
		end,
	})
	for i, v in { 0.5, 1, 1.5, 2 } do
		UI.button({
			text = tostring(v) .. "x",
			size = UDim2.fromOffset(44, 20),
			pos = UDim2.fromOffset(14 + (i - 1) * 50, 57),
			textSize = 11,
			radius = 10,
			parent = bar,
			callback = function()
				speed.set(v, true)
			end,
		})
	end
	UI.label({ text = "BPM", font = Enum.Font.GothamBlack, textSize = 12, color = T.Muted, pos = UDim2.new(0.6, 6, 0, 8), size = UDim2.fromOffset(34, 24), parent = bar })
	bpmBox = UI.new("TextBox", {
		Position = UDim2.new(0.6, 42, 0, 8),
		Size = UDim2.fromOffset(56, 24),
		BackgroundColor3 = T.Bg,
		Text = tostring(math.floor(Emotes.speed * 120 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = T.Cyan,
		ClearTextOnFocus = true,
		Parent = bar,
	}, { UI.corner(6) })
	bpmBox.FocusLost:Connect(function()
		local n = tonumber(string.match(bpmBox.Text, "%d+"))
		if n and n > 0 then
			speed.set(math.clamp(n / 120, 0.1, 3), true)
		end
		bpmBox.Text = tostring(math.floor(Emotes.speed * 120 + 0.5))
	end)
	local syncLabel = UI.label({
		text = "",
		font = Enum.Font.GothamBold,
		textSize = 11,
		color = T.Pink,
		pos = UDim2.new(0.6, 104, 0, 8),
		size = UDim2.new(0.4, -110, 0, 24),
		truncate = true,
		parent = bar,
	})
	local loopBtn, moveBtn
	local function refreshBar()
		UI.setBase(loopBtn, Emotes.loop and Color3.fromRGB(90, 30, 100) or T.Panel2)
		loopBtn.TextColor3 = Emotes.loop and T.Text or T.Muted
		UI.setBase(moveBtn, Emotes.stopOnMove and Color3.fromRGB(90, 30, 100) or T.Panel2)
		moveBtn.TextColor3 = Emotes.stopOnMove and T.Text or T.Muted
		local leader = Emotes.following()
		syncLabel.Text = leader and ("🔗 SYNC: " .. leader.DisplayName) or ""
	end
	loopBtn = UI.button({
		text = "🔁 Repetir",
		size = UDim2.new(0.2, -9, 0, 28),
		pos = UDim2.new(0.6, 6, 0, 46),
		textSize = 12,
		parent = bar,
		callback = function()
			Emotes.setLoop(not Emotes.loop)
			refreshBar()
		end,
	})
	moveBtn = UI.button({
		text = "🚶 Auto-parar",
		size = UDim2.new(0.2, -9, 0, 28),
		pos = UDim2.new(0.8, 3, 0, 46),
		textSize = 12,
		parent = bar,
		callback = function()
			Emotes.stopOnMove = not Emotes.stopOnMove
			Emotes.setSetting("stopOnMove", Emotes.stopOnMove)
			refreshBar()
			UI.toast(Emotes.stopOnMove and "El emote se para al caminar" or "El emote sigue aunque camines 🕺", "info")
		end,
	})

	-- ventanita para agregar animaciones por ID
	popup = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(330, 210),
		BackgroundColor3 = T.Bg,
		Visible = false,
		ZIndex = 20,
		Parent = page,
	}, { UI.corner(14) })
	UI.stroke(T.Pink, 2, 0, popup)
	UI.label({ text = "🧩 Agregar emote por ID", font = Enum.Font.FredokaOne, textSize = 20, pos = UDim2.fromOffset(16, 10), size = UDim2.new(1, -32, 0, 26), parent = popup })
	local function input(y, placeholder)
		return UI.new("TextBox", {
			Position = UDim2.fromOffset(16, y),
			Size = UDim2.new(1, -32, 0, 32),
			BackgroundColor3 = T.Panel,
			Text = "",
			PlaceholderText = placeholder,
			PlaceholderColor3 = T.Muted,
			TextColor3 = T.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = popup,
		}, { UI.corner(8), UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
	end
	local nameBox = input(44, "Nombre (opcional)")
	local idBox = input(82, "ID de la animación (solo números)")
	UI.label({
		text = "Funcionan las animaciones oficiales de Roblox y las que subas tú (o tu grupo).",
		textSize = 11,
		color = T.Muted,
		wrap = true,
		pos = UDim2.fromOffset(16, 118),
		size = UDim2.new(1, -32, 0, 30),
		parent = popup,
	})
	local function parsedId()
		return tonumber(string.match(idBox.Text, "%d+"))
	end
	UI.button({ text = "▶ Probar", size = UDim2.fromOffset(90, 34), pos = UDim2.fromOffset(16, 160), textSize = 13, parent = popup, callback = function()
		local id = parsedId()
		if id then
			Emotes.play(id)
		else
			UI.toast("Escribe un ID válido", "error")
		end
	end })
	UI.button({
		text = "Guardar",
		size = UDim2.fromOffset(110, 34),
		pos = UDim2.fromOffset(112, 160),
		textSize = 14,
		color = Color3.new(1, 1, 1),
		gradient = UI.Hot,
		stroke = false,
		parent = popup,
		callback = function()
			local id = parsedId()
			if not id then
				UI.toast("Escribe un ID válido", "error")
				return
			end
			local name = nameBox.Text ~= "" and string.sub(nameBox.Text, 1, 28) or ("Emote " .. id)
			Emotes.addCustom(id, name)
			nameBox.Text, idBox.Text = "", ""
			popup.Visible = false
			filter = "custom"
			refreshChips()
			UI.toast("🧩 Guardado en MIS IDs: " .. name, "ok")
		end,
	})
	UI.button({ text = "Cerrar", size = UDim2.fromOffset(84, 34), pos = UDim2.fromOffset(230, 160), textSize = 13, parent = popup, callback = function()
		popup.Visible = false
	end })

	search:GetPropertyChangedSignal("Text"):Connect(function()
		query = search.Text
		refreshGrid()
	end)
	Emotes.onChange(function(what)
		if what == "custom" then
			buildCards()
		elseif what == "sync" then
			refreshBar()
		else
			refreshAll()
		end
	end)

	buildCards()
	refreshChips()
	refreshBar()
end

---------------------------------------------------------------- pestaña JUGADOR

local function buildPlayer(page)
	local sf = scrollList(page)
	local o = 0
	local function n()
		o += 1
		return o
	end
	section(sf, "MOVIMIENTO", n())
	local walkT = UI.toggle({ parent = sf, order = n(), text = "🏃  Velocidad (WalkSpeed)", default = Movement.walkOn, callback = function(v)
		Movement.set("walkOn", v)
	end })
	UI.slider({ parent = sf, order = n(), text = "Velocidad al caminar", min = 16, max = 300, step = 1, default = Movement.walk, callback = function(v)
		Movement.set("walk", v)
		if not Movement.walkOn then
			Movement.set("walkOn", true)
		end
	end })
	local jumpT = UI.toggle({ parent = sf, order = n(), text = "🦘  Súper salto", default = Movement.jumpOn, callback = function(v)
		Movement.set("jumpOn", v)
	end })
	UI.slider({ parent = sf, order = n(), text = "Fuerza del salto", min = 50, max = 800, step = 5, default = Movement.jump, callback = function(v)
		Movement.set("jump", v)
		if not Movement.jumpOn then
			Movement.set("jumpOn", true)
		end
	end })
	local infT = UI.toggle({ parent = sf, order = n(), text = "♾️  Saltos infinitos", default = Movement.infJump, callback = function(v)
		Movement.set("infJump", v)
	end })

	section(sf, "VUELO  (tecla L)", n())
	local flyT = UI.toggle({ parent = sf, order = n(), text = "✈️  Volar", default = Movement.flying, callback = function(v)
		Movement.setFly(v)
	end })
	local flyS = UI.slider({ parent = sf, order = n(), text = "Velocidad de vuelo", min = 10, max = 600, step = 5, default = Movement.flySpeed, callback = function(v)
		Movement.set("flySpeed", v)
	end })

	section(sf, "EXTRAS", n())
	local noclipT = UI.toggle({ parent = sf, order = n(), text = "👻  Atravesar paredes", default = Movement.noclip, callback = function(v)
		Movement.set("noclip", v)
	end })
	local gravT = UI.toggle({ parent = sf, order = n(), text = "🌙  Gravedad lunar", default = Movement.lowGrav, callback = function(v)
		Movement.set("lowGrav", v)
	end })
	local tpT = UI.toggle({ parent = sf, order = n(), text = "🖱️  Ctrl + Click = teletransporte", default = Movement.clickTp, callback = function(v)
		Movement.set("clickTp", v)
	end })
	local spinT = UI.toggle({ parent = sf, order = n(), text = "🌀  Trompo", default = Movement.spin, callback = function(v)
		Movement.setSpin(v)
	end })
	UI.slider({ parent = sf, order = n(), text = "Velocidad del trompo", min = 5, max = 80, step = 1, default = Movement.spinSpeed, callback = function(v)
		Movement.set("spinSpeed", v)
	end })
	UI.button({ text = "💀  Reiniciar personaje", size = UDim2.new(1, 0, 0, 38), order = n(), color = Color3.fromRGB(80, 26, 48), strokeColor = T.Red, parent = sf, callback = function()
		Movement.reset()
	end })

	Movement.onChange(function()
		walkT.set(Movement.walkOn, true)
		jumpT.set(Movement.jumpOn, true)
		infT.set(Movement.infJump, true)
		flyT.set(Movement.flying, true)
		flyS.set(Movement.flySpeed, false)
		noclipT.set(Movement.noclip, true)
		gravT.set(Movement.lowGrav, true)
		tpT.set(Movement.clickTp, true)
		spinT.set(Movement.spin, true)
	end)
end

---------------------------------------------------------------- pestaña TROLL

local morphCards = {}

local function refreshMorphs()
	for key, c in morphCards do
		local on = Menu.morphs[key] == true
		c.stroke.Color = on and T.Pink or T.Cyan
		c.stroke.Transparency = on and 0 or 0.75
		c.stroke.Thickness = on and 2.5 or 1.2
		UI.setBase(c.btn, on and Color3.fromRGB(86, 30, 96) or T.Panel2)
		c.label.TextColor3 = on and T.Text or T.Muted
	end
end

function Menu.setMorphs(set)
	Menu.morphs = set or {}
	refreshMorphs()
end

local function buildTroll(page)
	UI.label({
		text = "🤪 Estos efectos los ven <b>TODOS</b> los jugadores. ¡Combínalos!",
		textSize = 13,
		wrap = true,
		size = UDim2.new(1, 0, 0, 30),
		parent = page,
	})
	local grid = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -86),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Pink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = page,
	})
	UI.new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 72), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	UI.new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), Parent = grid })
	for i, m in Config.Morphs do
		local btn = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = T.Panel2, LayoutOrder = i, Parent = grid }, { UI.corner(12) })
		UI.hover(btn)
		local stroke = UI.stroke(T.Cyan, 1.2, 0.75, btn)
		UI.label({ text = m.icon, textSize = 28, alignX = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 6), size = UDim2.new(1, 0, 0, 34), parent = btn })
		local label = UI.label({
			text = m.label,
			font = Enum.Font.GothamBold,
			textSize = 12,
			color = T.Muted,
			alignX = Enum.TextXAlignment.Center,
			pos = UDim2.new(0, 4, 1, -26),
			size = UDim2.new(1, -8, 0, 20),
			truncate = true,
			parent = btn,
		})
		btn.Activated:Connect(function()
			UI.sound("click", 0.4)
			local v = not Menu.morphs[m.key]
			Menu.morphs[m.key] = v or nil
			if v and Config.Exclusive[m.key] then
				for _, k in Config.Exclusive[m.key] do
					Menu.morphs[k] = nil
				end
			end
			refreshMorphs()
			Net:FireServer("Morph", m.key, v)
		end)
		morphCards[m.key] = { btn = btn, stroke = stroke, label = label }
	end
	local row = UI.new("Frame", { Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = page })
	UI.list(row, 6, true)
	UI.button({ text = "💥 Ragdoll", size = UDim2.new(0.25, -5, 1, 0), order = 1, textSize = 13, parent = row, callback = function()
		Net:FireServer("Ragdoll")
	end })
	UI.button({ text = "🌀 Trompo", size = UDim2.new(0.25, -5, 1, 0), order = 2, textSize = 13, parent = row, callback = function()
		Movement.setSpin(not Movement.spin)
	end })
	UI.button({ text = "♻️ Normal", size = UDim2.new(0.25, -5, 1, 0), order = 3, textSize = 13, parent = row, callback = function()
		Menu.setMorphs({})
		Net:FireServer("Morph", "__clear")
		UI.toast("Cuerpo normal otra vez", "ok")
	end })
	UI.button({ text = "💀 Reset", size = UDim2.new(0.25, -5, 1, 0), order = 4, textSize = 13, color = Color3.fromRGB(80, 26, 48), strokeColor = T.Red, parent = row, callback = function()
		Movement.reset()
	end })
	refreshMorphs()
end

---------------------------------------------------------------- pestaña TEAM

local function buildTeam(page)
	local status = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = T.Panel, Parent = page }, { UI.corner(12) })
	UI.stroke(T.Pink, 1.5, 0.3, status)
	local statusText = UI.label({ text = "", font = Enum.Font.GothamBold, textSize = 14, wrap = true, pos = UDim2.fromOffset(14, 0), size = UDim2.new(1, -150, 1, 0), parent = status })
	local leave = UI.button({
		text = "Dejar SYNC",
		size = UDim2.fromOffset(118, 34),
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -12, 0.5, 0),
		color = Color3.fromRGB(90, 28, 58),
		strokeColor = T.Red,
		parent = status,
		callback = function()
			Emotes.unsync()
		end,
	})
	UI.label({
		text = "💡 Haz <b>click</b> sobre un miembro del TEAM en el mapa (o en SYNC aquí). Cuando él ponga un emote, tú lo harás al mismo tiempo exacto.",
		textSize = 12,
		color = T.Muted,
		wrap = true,
		pos = UDim2.fromOffset(2, 62),
		size = UDim2.new(1, -4, 0, 34),
		parent = page,
	})
	local list = scrollList(page, UDim2.fromOffset(0, 100), UDim2.new(1, 0, 1, -100))

	local dirty = true
	local function row(p, order)
		local isMe = p == lp
		local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.1, LayoutOrder = order, Parent = list }, { UI.corner(10) })
		local img = avatarIcon(p.UserId, 40, r)
		local ring = UI.stroke(Color3.new(1, 1, 1), 2, 0, img)
		UI.new("UIGradient", { Color = UI.Rainbow, Parent = ring })
		UI.label({ text = p.DisplayName .. (isMe and "  <font color='#ff46c8'>(tú)</font>" or ""), font = Enum.Font.GothamBold, textSize = 14, pos = UDim2.fromOffset(54, 6), size = UDim2.new(1, -190, 0, 20), truncate = true, parent = r })
		local st = Emotes.states[p]
		local info = st and ("💃 " .. Emotes.nameOf(st.id) .. string.format(" · %.2fx", st.speed)) or "🧍 quieto"
		if Emotes.leaders[p] then
			info ..= "  ·  🔗 " .. Emotes.leaders[p].DisplayName
		end
		UI.label({ text = info, textSize = 11, color = T.Muted, pos = UDim2.fromOffset(54, 27), size = UDim2.new(1, -190, 0, 18), truncate = true, parent = r })
		if not isMe then
			local following = Emotes.leaders[lp] == p
			UI.button({
				text = following and "✔ SYNC" or "🔗 SYNC",
				size = UDim2.fromOffset(80, 30),
				anchor = Vector2.new(1, 0.5),
				pos = UDim2.new(1, -58, 0.5, 0),
				color = following and Color3.fromRGB(96, 30, 104) or T.Panel2,
				strokeColor = T.Pink,
				textSize = 12,
				parent = r,
				callback = function()
					Icons.toggleSync(p)
				end,
			})
			UI.button({ text = "TP", size = UDim2.fromOffset(44, 30), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -8, 0.5, 0), textSize = 12, parent = r, callback = function()
				if Movement.teleportTo(p) then
					UI.toast("✨ Teleport a <b>" .. p.DisplayName .. "</b>", "ok")
				end
			end })
		end
	end
	local function rebuild()
		dirty = false
		clearRows(list)
		local members = {}
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("GuguGaga") == true then
				table.insert(members, p)
			end
		end
		table.sort(members, function(a, b)
			if a == lp then
				return true
			elseif b == lp then
				return false
			end
			return a.DisplayName < b.DisplayName
		end)
		for i, p in members do
			row(p, i)
		end
		if #members <= 1 then
			UI.label({
				text = "Nadie más del TEAM está en este servidor todavía.\nCuando un amigo ponga la contraseña aparecerá aquí 👶",
				textSize = 13,
				color = T.Muted,
				wrap = true,
				alignX = Enum.TextXAlignment.Center,
				size = UDim2.new(1, 0, 0, 50),
				order = 99,
				parent = list,
			})
		end
		local leader = Emotes.leaders[lp]
		statusText.Text = leader and ("🔗 Sincronizado con <b>" .. leader.DisplayName .. "</b> ✨") or "🔗 No estás sincronizado con nadie"
		leave.Visible = leader ~= nil
	end
	local function markDirty()
		dirty = true
	end
	Emotes.onChange(function(what)
		if what == "sync" or what == "states" then
			dirty = true
		end
	end)
	local function watch(p)
		p:GetAttributeChangedSignal("GuguGaga"):Connect(markDirty)
	end
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(function(p)
		watch(p)
		dirty = true
	end)
	Players.PlayerRemoving:Connect(markDirty)
	table.insert(ticks, function()
		if dirty and page.Visible then
			rebuild()
		end
	end)
end

---------------------------------------------------------------- pestaña MUNDO

local function buildWorld(page)
	local chipRow = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = page })
	UI.list(chipRow, 6, true)
	local function chip(text, order, get, set)
		local b = UI.button({ text = text, size = UDim2.new(0.25, -5, 1, 0), textSize = 12, order = order, parent = chipRow })
		local function refresh()
			local on = get()
			UI.setBase(b, on and Color3.fromRGB(96, 30, 104) or T.Panel2)
			b.TextColor3 = on and T.Text or T.Muted
		end
		b.Activated:Connect(function()
			UI.sound("click", 0.35)
			set(not get())
			refresh()
		end)
		refresh()
	end
	chip("👥 Amigos", 1, function()
		return Icons.friends
	end, function(v)
		Icons.friends = v
		Emotes.setSetting("icFriends", v)
	end)
	chip("👶 Team", 2, function()
		return Icons.team
	end, function(v)
		Icons.team = v
		Emotes.setSetting("icTeam", v)
	end)
	chip("🌐 Todos", 3, function()
		return Icons.all
	end, function(v)
		Icons.all = v
		Emotes.setSetting("icAll", v)
	end)
	chip("💞 Rayos", 4, function()
		return Icons.beams
	end, function(v)
		Icons.beams = v
		Emotes.setSetting("beams", v)
		Icons.refreshBeams()
	end)

	local actRow = UI.new("Frame", { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = page })
	UI.list(actRow, 6, true)
	UI.button({ text = "🏠 Ir al spawn", size = UDim2.new(0.333, -4, 1, 0), order = 1, textSize = 12, parent = actRow, callback = function()
		local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		local pos = spawn and spawn.Position or Vector3.new(0, 0, 0)
		Movement.teleport(CFrame.new(pos + Vector3.new(0, 5, 0)))
	end })
	UI.button({ text = "👤 Mi avatar", size = UDim2.new(0.333, -4, 1, 0), order = 2, textSize = 12, parent = actRow, callback = function()
		Net:FireServer("CopyAvatar", lp.UserId)
		UI.toast("Volviendo a tu avatar…", "info")
	end })
	UI.button({ text = "🛑 Bajarme / parar", size = UDim2.new(0.333, -4, 1, 0), order = 3, textSize = 12, parent = actRow, callback = function()
		Movement.setOrbit(nil)
		Net:FireServer("Ride", nil)
	end })
	UI.label({
		text = "TP = ir  ·  🌀 orbitar  ·  🎩 subirte a su cabeza  ·  👕 copiar su avatar",
		textSize = 11,
		color = T.Muted,
		pos = UDim2.fromOffset(2, 72),
		size = UDim2.new(1, -4, 0, 18),
		parent = page,
	})
	local list = scrollList(page, UDim2.fromOffset(0, 94), UDim2.new(1, 0, 1, -94))

	local dirty = true
	local function smallBtn(text, x, parent, cb)
		return UI.button({ text = text, size = UDim2.fromOffset(x == -8 and 42 or 34, 30), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, x, 0.5, 0), textSize = 13, parent = parent, callback = cb })
	end
	local function row(p, order)
		local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.1, LayoutOrder = order, Parent = list }, { UI.corner(10) })
		avatarIcon(p.UserId, 38, r)
		local badges = {}
		if Icons.isFriend(p) then
			table.insert(badges, "⭐ amigo")
		end
		if Icons.isTeam(p) then
			table.insert(badges, "👶 TEAM")
		end
		UI.label({ text = p.DisplayName, font = Enum.Font.GothamBold, textSize = 14, pos = UDim2.fromOffset(52, 6), size = UDim2.new(1, -220, 0, 20), truncate = true, parent = r })
		UI.label({ text = #badges > 0 and table.concat(badges, "  ") or ("@" .. p.Name), textSize = 11, color = T.Muted, pos = UDim2.fromOffset(52, 26), size = UDim2.new(1, -220, 0, 18), truncate = true, parent = r })
		smallBtn("TP", -8, r, function()
			if Movement.teleportTo(p) then
				UI.toast("✨ Teleport a <b>" .. p.DisplayName .. "</b>", "ok")
			end
		end)
		smallBtn("🌀", -56, r, function()
			Movement.setOrbit(p)
			UI.toast(Movement.orbit and ("🌀 Orbitando a " .. p.DisplayName) or "Órbita parada", "info")
		end)
		smallBtn("🎩", -96, r, function()
			Net:FireServer("Ride", p)
		end)
		smallBtn("👕", -136, r, function()
			Net:FireServer("CopyAvatar", p.UserId)
			UI.toast("👕 Copiando el avatar de " .. p.DisplayName .. "…", "info")
		end)
	end
	local function rebuild()
		dirty = false
		clearRows(list)
		local others = {}
		for _, p in Players:GetPlayers() do
			if p ~= lp then
				table.insert(others, p)
			end
		end
		table.sort(others, function(a, b)
			return a.DisplayName < b.DisplayName
		end)
		for i, p in others do
			row(p, i)
		end
		if #others == 0 then
			UI.label({
				text = "Estás solo en el servidor. ¡Invita a tus amigos! 😄",
				textSize = 13,
				color = T.Muted,
				alignX = Enum.TextXAlignment.Center,
				size = UDim2.new(1, 0, 0, 40),
				parent = list,
			})
		end
	end
	local function markDirty()
		dirty = true
	end
	Players.PlayerAdded:Connect(markDirty)
	Players.PlayerRemoving:Connect(markDirty)
	local acc = 0
	table.insert(ticks, function()
		acc += 1
		if acc >= 8 then -- refresca insignias de amigo de vez en cuando
			acc = 0
			dirty = true
		end
		if dirty and page.Visible then
			rebuild()
		end
	end)
end

---------------------------------------------------------------- pestaña AJUSTES

local function buildSettings(page)
	local sf = scrollList(page)
	section(sf, "MENÚ", 1)
	UI.slider({
		parent = sf,
		order = 2,
		text = "Tamaño del menú",
		min = 0.6,
		max = 1.4,
		step = 0.05,
		default = userScale,
		fmt = function(v)
			return string.format("%d%%", math.floor(v * 100 + 0.5))
		end,
		callback = function(v)
			userScale = v
			Emotes.setSetting("uiScale", v)
			if Menu.open then
				winScale.Scale = baseScale()
			end
		end,
	})
	UI.toggle({ parent = sf, order = 3, text = "🔊  Sonidos del menú", default = UI.soundsOn, callback = function(v)
		UI.soundsOn = v
		Emotes.setSetting("sounds", v)
	end })
	UI.toggle({ parent = sf, order = 4, text = "🫧  Burbuja GG flotante", default = bubble.Visible, callback = function(v)
		bubble.Visible = v
		Emotes.setSetting("bubble", v)
	end })
	section(sf, "ATAJOS", 5)
	local keys = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, BackgroundTransparency = 0.15, LayoutOrder = 6, Parent = sf }, { UI.corner(10) })
	UI.pad(12, keys)
	local k = UI.label({
		text = table.concat({
			"<b>" .. Config.MenuKey.Name .. "</b>  —  abrir / cerrar el menú",
			"<b>" .. Config.FlyKey.Name .. "</b>  —  panel de vuelo",
			"<b>Espacio / Ctrl</b>  —  subir / bajar volando",
			"<b>Ctrl + Click</b>  —  teletransporte",
			"<b>Click en un miembro</b>  —  SYNC de emotes",
			"<b>KEY en cada emote</b>  —  asignarle una tecla",
		}, "\n"),
		textSize = 13,
		wrap = true,
		size = UDim2.new(1, 0, 0, 0),
		parent = keys,
	})
	k.AutomaticSize = Enum.AutomaticSize.Y
	k.LineHeight = 1.3
	section(sf, "ACERCA DE", 7)
	UI.label({
		text = Config.Title .. " " .. Config.Version .. "  ·  hecho con 💖 para el " .. Config.TeamTag,
		textSize = 12,
		color = T.Muted,
		size = UDim2.new(1, 0, 0, 20),
		order = 8,
		parent = sf,
	})
end

---------------------------------------------------------------- ventana

local function selectTab(key)
	if currentTab == key then
		return
	end
	for k, b in tabButtons do
		local on = k == key
		UI.setBase(b.btn, on and Color3.fromRGB(70, 28, 92) or T.Panel)
		UI.tween(b.bar, 0.25, { Size = UDim2.fromOffset(4, on and 24 or 0) }, Enum.EasingStyle.Back)
		b.label.TextColor3 = on and T.Text or T.Muted
	end
	local oldKey = currentTab
	if oldKey then
		local old = pages[oldKey]
		UI.tween(old, 0.15, { GroupTransparency = 1 })
		task.delay(0.15, function()
			if currentTab ~= oldKey then
				old.Visible = false
			end
		end)
	end
	currentTab = key
	local pg = pages[key]
	pg.Visible = true
	pg.GroupTransparency = 1
	pg.Position = UDim2.fromOffset(0, 16)
	UI.tween(pg, 0.3, { GroupTransparency = 0, Position = UDim2.new() })
	for _, tick in ticks do
		tick()
	end
end

local function buildWindow()
	win = UI.new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(660, 440),
		BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { UI.corner(16) })
	winScale = UI.new("UIScale", { Parent = win })
	local border = UI.stroke(Color3.new(1, 1, 1), 2.5, 0, win)
	UI.spin(UI.new("UIGradient", { Color = UI.Rainbow, Parent = border }), 70)
	UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 140),
		BackgroundColor3 = T.Purple,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = win,
	}, {
		UI.corner(16),
		UI.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1) }),
	})

	-- cabecera
	local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = win })
	local avatar = avatarIcon(lp.UserId, 40, header, UDim2.fromOffset(14, 9))
	UI.spin(UI.new("UIGradient", { Color = UI.Rainbow, Parent = UI.stroke(Color3.new(1, 1, 1), 2.5, 0, avatar) }), 200)
	local title = UI.label({ text = Config.Title, font = Enum.Font.FredokaOne, textSize = 30, pos = UDim2.fromOffset(64, 4), size = UDim2.fromOffset(240, 34), parent = header })
	UI.shine(UI.new("UIGradient", { Color = UI.Rainbow, Parent = title }), 0.4)
	UI.new("UIStroke", { Thickness = 2, Color = Color3.fromRGB(25, 0, 45), Parent = title })
	UI.label({
		text = "👶 " .. Config.TeamTag .. "  ·  " .. Config.Version .. "  ·  hola, " .. lp.DisplayName,
		textSize = 12,
		color = T.Muted,
		pos = UDim2.fromOffset(65, 36),
		size = UDim2.new(1, -130, 0, 16),
		truncate = true,
		parent = header,
	})
	UI.button({
		text = "X",
		font = Enum.Font.GothamBlack,
		textSize = 16,
		size = UDim2.fromOffset(34, 34),
		anchor = Vector2.new(1, 0),
		pos = UDim2.new(1, -12, 0, 12),
		color = Color3.fromRGB(90, 28, 52),
		strokeColor = T.Red,
		parent = header,
		callback = function()
			Menu.show(false)
		end,
	})
	UI.draggable(header, win)
	UI.new("Frame", { Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = win }, {
		UI.new("UIGradient", { Color = UI.Rainbow }),
	})

	-- barra lateral
	local side = UI.new("Frame", {
		Position = UDim2.fromOffset(12, 68),
		Size = UDim2.new(0, 126, 1, -80),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.25,
		Parent = win,
	}, { UI.corner(12) })
	UI.pad(6, side)
	UI.list(side, 5)
	for i, tab in TABS do
		local btn = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.Panel, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = side }, { UI.corner(9) })
		UI.hover(btn)
		local bar = UI.new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(4, 0), BackgroundColor3 = T.Pink, BorderSizePixel = 0, Parent = btn }, { UI.corner(2) })
		UI.label({ text = tab.icon, textSize = 18, alignX = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 0), size = UDim2.new(0, 28, 1, 0), parent = btn })
		local label = UI.label({ text = tab.label, font = Enum.Font.GothamBold, textSize = 14, color = T.Muted, pos = UDim2.fromOffset(38, 0), size = UDim2.new(1, -40, 1, 0), parent = btn })
		btn.Activated:Connect(function()
			UI.sound("click", 0.35)
			selectTab(tab.key)
		end)
		tabButtons[tab.key] = { btn = btn, bar = bar, label = label }
	end

	local content = UI.new("Frame", {
		Position = UDim2.fromOffset(148, 68),
		Size = UDim2.new(1, -160, 1, -80),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = win,
	})
	for _, tab in TABS do
		pages[tab.key] = UI.new("CanvasGroup", { Name = tab.key, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content })
	end
end

function Menu.show(on)
	Menu.open = on
	if on then
		win.Visible = true
		winScale.Scale = baseScale() * 0.6
		win.Rotation = -6
		UI.tween(winScale, 0.45, { Scale = baseScale() }, Enum.EasingStyle.Back)
		UI.tween(win, 0.45, { Rotation = 0 }, Enum.EasingStyle.Back)
		UI.sound("whoosh", 0.35, 1.3)
		for _, tick in ticks do
			tick()
		end
	else
		local tw = UI.tween(winScale, 0.25, { Scale = baseScale() * 0.6 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		UI.tween(win, 0.25, { Rotation = 4 })
		tw.Completed:Connect(function()
			if not Menu.open then
				win.Visible = false
			end
		end)
	end
end

function Menu.toggle()
	Menu.show(not Menu.open)
end

---------------------------------------------------------------- burbuja GG

local function buildBubble()
	bubble = UI.new("TextButton", {
		Name = "Bubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 50, 0.42, 0),
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = T.Bg,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 40,
		Parent = gui,
	}, { UI.corner(UDim.new(1, 0)) })
	local ring = UI.stroke(Color3.new(1, 1, 1), 3, 0, bubble)
	UI.spin(UI.new("UIGradient", { Color = UI.Rainbow, Parent = ring }), 180)
	local txt = UI.label({ text = "GG", font = Enum.Font.FredokaOne, textSize = 26, alignX = Enum.TextXAlignment.Center, size = UDim2.fromScale(1, 1), parent = bubble })
	UI.shine(UI.new("UIGradient", { Color = UI.Rainbow, Parent = txt }), 0.5)
	local pulse = UI.new("UIScale", { Parent = bubble })
	TweenService:Create(pulse, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 }):Play()
	local wasDrag = UI.draggable(bubble, bubble)
	bubble.Activated:Connect(function()
		if wasDrag() then
			return
		end
		UI.sound("click", 0.4)
		Menu.toggle()
	end)
end

---------------------------------------------------------------- panel de vuelo (L)

function Menu.toggleFly(on)
	if on == nil then
		on = not flyOpen
	end
	flyOpen = on
	if on then
		flyPanel.Visible = true
		flyPanel.Position = UDim2.new(1, 320, 0.5, 0)
		UI.tween(flyPanel, 0.45, { Position = UDim2.new(1, -16, 0.5, 0) }, Enum.EasingStyle.Back)
		UI.sound("whoosh", 0.35, 1.4)
	else
		local tw = UI.tween(flyPanel, 0.3, { Position = UDim2.new(1, 320, 0.5, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tw.Completed:Connect(function()
			if not flyOpen then
				flyPanel.Visible = false
			end
		end)
	end
end

local function buildFly()
	local touch = UserInputService.TouchEnabled
	flyPanel = UI.new("Frame", {
		Name = "Fly",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 320, 0.5, 0),
		Size = UDim2.fromOffset(270, touch and 250 or 204),
		BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 30,
		Parent = gui,
	}, { UI.corner(16) })
	local sc = UI.new("UIScale", { Parent = flyPanel })
	local function fitFly()
		local v = workspace.CurrentCamera.ViewportSize
		sc.Scale = math.clamp(math.min(v.X / 900, v.Y / 560), 0.6, 1)
	end
	fitFly()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitFly)
	UI.spin(UI.new("UIGradient", { Color = UI.Rainbow, Parent = UI.stroke(Color3.new(1, 1, 1), 2.5, 0, flyPanel) }), 90)
	UI.label({ text = "✈️ VUELO", font = Enum.Font.FredokaOne, textSize = 24, pos = UDim2.fromOffset(14, 8), size = UDim2.fromOffset(160, 30), parent = flyPanel })
	UI.label({ text = "tecla " .. Config.FlyKey.Name, textSize = 11, color = T.Muted, pos = UDim2.fromOffset(130, 14), size = UDim2.fromOffset(80, 20), parent = flyPanel })
	UI.button({ text = "X", font = Enum.Font.GothamBlack, textSize = 14, size = UDim2.fromOffset(30, 30), anchor = Vector2.new(1, 0), pos = UDim2.new(1, -10, 0, 10), parent = flyPanel, callback = function()
		Menu.toggleFly(false)
	end })
	local body = UI.new("Frame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 1, -56), BackgroundTransparency = 1, Parent = flyPanel })
	UI.list(body, 6)
	local flyT = UI.toggle({ parent = body, order = 1, text = "Volar", default = Movement.flying, callback = function(v)
		Movement.setFly(v)
	end })
	local flyS = UI.slider({ parent = body, order = 2, text = "Velocidad de vuelo", min = 10, max = 600, step = 5, default = Movement.flySpeed, callback = function(v)
		Movement.set("flySpeed", v)
	end })
	UI.label({ text = touch and "Usa ▲ ▼ para subir y bajar" or "Espacio ⬆   ·   Ctrl / Q ⬇", textSize = 12, color = T.Muted, alignX = Enum.TextXAlignment.Center, size = UDim2.new(1, 0, 0, 18), order = 3, parent = body })
	if touch then
		local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = 4, Parent = body })
		UI.list(row, 8, true)
		local function holdBtn(text, order, key)
			local b = UI.button({ text = text, size = UDim2.new(0.5, -4, 1, 0), textSize = 20, order = order, parent = row })
			b.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					Movement[key] = true
				end
			end)
			b.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					Movement[key] = false
				end
			end)
		end
		holdBtn("▲", 1, "up")
		holdBtn("▼", 2, "down")
	end
	Movement.onChange(function()
		flyT.set(Movement.flying, true)
		flyS.set(Movement.flySpeed, false)
	end)
end

---------------------------------------------------------------- arranque

function Menu.build(g)
	gui = g
	local s = Emotes.settings
	if type(s.uiScale) == "number" then
		userScale = math.clamp(s.uiScale, 0.6, 1.4)
	end
	if type(s.sounds) == "boolean" then
		UI.soundsOn = s.sounds
	end
	if type(s.icFriends) == "boolean" then Icons.friends = s.icFriends end
	if type(s.icTeam) == "boolean" then Icons.team = s.icTeam end
	if type(s.icAll) == "boolean" then Icons.all = s.icAll end
	if type(s.beams) == "boolean" then Icons.beams = s.beams end

	buildBubble()
	bubble.Visible = s.bubble ~= false
	buildFly()
	buildWindow()
	buildEmotes(pages.emotes)
	buildPlayer(pages.player)
	buildTroll(pages.troll)
	buildTeam(pages.team)
	buildWorld(pages.world)
	buildSettings(pages.settings)
	selectTab("emotes")

	Net.OnClientEvent:Connect(function(kind, a)
		if kind == "Morphs" then
			Menu.setMorphs(a)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or Emotes.capturing then
			return
		end
		if input.KeyCode == Config.MenuKey then
			Menu.toggle()
		elseif input.KeyCode == Config.FlyKey then
			Menu.toggleFly()
		end
	end)

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if Menu.open then
			winScale.Scale = baseScale()
		end
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.4 then
			acc = 0
			if Menu.open then
				for _, tick in ticks do
					tick()
				end
			end
		end
	end)

	Menu.show(true)
	UI.toast("👶 <b>" .. Config.Title .. "</b> listo · " .. Config.MenuKey.Name .. " = menú · " .. Config.FlyKey.Name .. " = vuelo", "team")
end

return Menu
