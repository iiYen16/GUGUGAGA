--[[ GUGU-GAGA · Intro
	1) Pantalla de contraseña con tu avatar R15 en vivo, estilo selector de
	   modelos de GMod: la cámara va del cuerpo a tu cara y puedes girarlo.
	2) Cinemática al activar: barras de cine, vuelo de cámara alrededor, primer
	   plano de tu cara, explosión de brillo (la ven todos) y título gigante. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent.Parent
local Config = require(root:WaitForChild("Config"))
local Net = root:WaitForChild("Remotes"):WaitForChild("Net")
local UI = require(script.Parent.UI)
local Emotes = require(script.Parent.Emotes)
local T = UI.T

local lp = Players.LocalPlayer
local Intro = {}

-- al arrancar la pantalla mide 1x1 un instante: esperar a que tenga tamaño real
local function waitViewport()
	while workspace.CurrentCamera.ViewportSize.X < 200 do
		task.wait()
	end
end

local function fitValue(w, h, max)
	local v = workspace.CurrentCamera.ViewportSize
	return math.min(v.X / w, v.Y / h, max or 1.15)
end

local function fit(scale, w, h, max)
	local function update()
		if workspace.CurrentCamera.ViewportSize.X >= 200 then
			scale.Scale = fitValue(w, h, max)
		end
	end
	update()
	return workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
end

---------------------------------------------------------------- copia del avatar

-- radio de la cabeza contando gorros y pelo, para que el primer plano no quede dentro del sombrero
local function headRadius(model)
	local head = model:FindFirstChild("Head")
	if not head then
		return 1
	end
	local r = head.Size.Magnitude / 2
	for _, acc in model:GetChildren() do
		local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
		local w = h and h:FindFirstChild("AccessoryWeld")
		local rigid = h and h:FindFirstChildWhichIsA("RigidConstraint")
		local onHead = (w and w:IsA("Weld") and (w.Part0 == head or w.Part1 == head))
			or (rigid and ((rigid.Attachment0 and rigid.Attachment0.Parent == head) or (rigid.Attachment1 and rigid.Attachment1.Parent == head)))
		if onHead then
			r = math.max(r, (h.Position - head.Position).Magnitude + h.Size.Magnitude * 0.3)
		end
	end
	return math.min(r, 4)
end

local function cloneAvatar()
	local char = lp.Character or lp.CharacterAdded:Wait()
	char:WaitForChild("HumanoidRootPart", 10)
	char:WaitForChild("Head", 10)
	local t0 = os.clock()
	while not lp:HasAppearanceLoaded() and os.clock() - t0 < 6 do
		task.wait(0.1)
	end
	task.wait(0.2)
	local idleId
	local animate = char:FindFirstChild("Animate")
	local idle = animate and animate:FindFirstChild("idle")
	local a = idle and idle:FindFirstChildWhichIsA("Animation")
	if a then
		idleId = a.AnimationId
	end
	local prev = char.Archivable
	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = prev
	if not clone then
		return nil
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("ForceField") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = true
	end
	clone:PivotTo(CFrame.new())
	return clone, idleId
end

---------------------------------------------------------------- pantalla de contraseña

function Intro.lock(gui, invoke)
	waitViewport()
	local finished = Instance.new("BindableEvent")
	local result
	local conns = {}

	local overlay = UI.new("Frame", {
		Name = "GGLock",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	}, {
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(45, 12, 70), Color3.fromRGB(4, 4, 12)),
			Rotation = 90,
		}),
	})
	UI.tween(overlay, 0.8, { BackgroundTransparency = 0.04 })

	-- haz de escaneo que baja por la pantalla
	local scan = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 160),
		Position = UDim2.new(0, 0, 0, -160),
		BackgroundColor3 = T.Cyan,
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = overlay,
	}, {
		UI.new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.9),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local TweenService = game:GetService("TweenService")
	TweenService:Create(scan, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Position = UDim2.new(0, 0, 1, 0),
	}):Play()

	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(920, 520),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = overlay,
	})
	local holderScale = UI.new("UIScale", { Parent = holder })
	table.insert(conns, fit(holderScale, 980, 580))

	------------------------------------------------ tarjeta del avatar
	local card = UI.new("Frame", {
		Size = UDim2.fromOffset(380, 520),
		BackgroundColor3 = T.Bg,
		ZIndex = 51,
		Parent = holder,
	}, { UI.corner(20) })
	local cardStroke = UI.stroke(Color3.new(1, 1, 1), 3, 0, card)
	UI.spin(UI.new("UIGradient", { Color = UI.Rainbow, Parent = cardStroke }), 120)

	local vpBack = UI.new("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 1, -104),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 52,
		ClipsDescendants = true,
		Parent = card,
	}, {
		UI.corner(14),
		UI.new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(80, 34, 130), Color3.fromRGB(8, 50, 80)),
			Rotation = 90,
		}),
	})
	local vp = UI.new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(160, 150, 200),
		LightColor = Color3.fromRGB(255, 240, 255),
		LightDirection = Vector3.new(-0.5, -1, -0.8),
		ZIndex = 53,
		Parent = vpBack,
	})
	-- decoración tipo selector de GMod
	UI.label({ text = "PLAYER MODEL", font = Enum.Font.GothamBlack, textSize = 12, color = T.Cyan, pos = UDim2.fromOffset(12, 8), size = UDim2.fromOffset(200, 16), z = 54, parent = vpBack })
	local chip = UI.label({
		text = "R15",
		font = Enum.Font.GothamBlack,
		textSize = 12,
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(1, 0),
		pos = UDim2.new(1, -10, 0, 8),
		size = UDim2.fromOffset(44, 20),
		z = 54,
		parent = vpBack,
	})
	chip.BackgroundTransparency = 0
	chip.BackgroundColor3 = T.Pink
	UI.corner(UDim.new(1, 0)).Parent = chip
	UI.label({
		text = "🔄 arrastra para girar",
		textSize = 11,
		color = T.Muted,
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 1),
		pos = UDim2.new(0.5, 0, 1, -6),
		size = UDim2.fromOffset(200, 16),
		z = 54,
		parent = vpBack,
	})

	UI.label({
		text = lp.DisplayName,
		font = Enum.Font.FredokaOne,
		textSize = 30,
		pos = UDim2.new(0, 18, 1, -86),
		size = UDim2.new(1, -36, 0, 36),
		truncate = true,
		z = 52,
		parent = card,
	})
	UI.label({
		text = "@" .. lp.Name .. "  ·  ID " .. lp.UserId,
		textSize = 13,
		color = T.Muted,
		pos = UDim2.new(0, 18, 1, -48),
		size = UDim2.new(1, -36, 0, 20),
		truncate = true,
		z = 52,
		parent = card,
	})

	-- avatar vivo dentro del visor
	local world = UI.new("WorldModel", { Parent = vp })
	local cam = UI.new("Camera", { FieldOfView = 30, Parent = vp })
	vp.CurrentCamera = cam
	local clone
	local faceDist = 3.6
	task.spawn(function()
		local c, idleId = cloneAvatar()
		if not c or not overlay.Parent then
			return
		end
		clone = c
		clone.Parent = world
		faceDist = math.max(3.6, headRadius(clone) * 3.2)
		local hum = clone:FindFirstChildOfClass("Humanoid")
		local animator = hum and (hum:FindFirstChildOfClass("Animator") or UI.new("Animator", { Parent = hum }))
		if not animator then
			return
		end
		local function load(id)
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, tr = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			return ok and tr or nil
		end
		local idle = idleId and load(idleId)
		if idle then
			idle.Looped = true
			idle:Play()
		end
		local wave = load("rbxassetid://" .. Config.IntroWave)
		if wave then
			wave.Priority = Enum.AnimationPriority.Action
			task.delay(1, function()
				if overlay.Parent then
					wave:Play()
				end
			end)
		end
	end)

	local yaw, dragging, lastX = 0, false, 0
	local t0 = os.clock()
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, lastX = true, input.Position.X
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			yaw += (input.Position.X - lastX) * 0.012
			lastX = input.Position.X
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(conns, RunService.RenderStepped:Connect(function()
		if not clone or not clone.Parent then
			return
		end
		local head = clone:FindFirstChild("Head")
		local hrp = clone:FindFirstChild("HumanoidRootPart")
		if not head or not hrp then
			return
		end
		local t = os.clock() - t0
		-- del cuerpo entero a la cara, como en GMod
		local z = math.clamp((t - 0.6) / 2.4, 0, 1)
		z = z * z * (3 - 2 * z)
		local focus = (hrp.Position + Vector3.new(0, 0.4, 0)):Lerp(head.Position - Vector3.new(0, head.Size.Y * 0.1, 0), z)
		local dist = 12 + (faceDist - 12) * z
		local ang = yaw + math.sin(t * 0.6) * 0.22
		local pos = focus + Vector3.new(math.sin(ang) * dist, 0.6 - 0.45 * z, -math.cos(ang) * dist)
		cam.CFrame = CFrame.lookAt(pos, focus)
	end))

	------------------------------------------------ lado derecho
	local right = UI.new("Frame", {
		Position = UDim2.fromOffset(410, 0),
		Size = UDim2.new(0, 510, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = holder,
	})
	UI.label({ text = "🔒  A C C E S O   P R I V A D O", font = Enum.Font.GothamBlack, textSize = 14, color = T.Pink, pos = UDim2.fromOffset(4, 30), size = UDim2.new(1, 0, 0, 20), z = 52, parent = right })
	local title = UI.label({
		text = Config.Title,
		font = Enum.Font.FredokaOne,
		textSize = 92,
		color = Color3.new(1, 1, 1),
		pos = UDim2.fromOffset(0, 52),
		size = UDim2.new(1, 0, 0, 100),
		z = 52,
		parent = right,
	})
	UI.shine(UI.new("UIGradient", { Color = UI.Rainbow, Parent = title }), 0.35)
	UI.new("UIStroke", { Thickness = 4, Color = Color3.fromRGB(25, 0, 45), Parent = title })
	UI.label({ text = "CHEAT MENU  ·  " .. Config.TeamTag .. "  ·  " .. Config.Version, font = Enum.Font.GothamBold, textSize = 15, color = T.Muted, pos = UDim2.fromOffset(4, 152), size = UDim2.new(1, 0, 0, 20), z = 52, parent = right })

	local hello = UI.label({
		text = "",
		font = Enum.Font.GothamMedium,
		textSize = 18,
		wrap = true,
		alignY = Enum.TextYAlignment.Top,
		pos = UDim2.fromOffset(4, 196),
		size = UDim2.new(1, -20, 0, 56),
		z = 52,
		parent = right,
	})
	local helloText = "Hola, " .. lp.DisplayName .. " 👶  Escribe la contraseña para activar tu menú."
	task.spawn(function()
		task.wait(0.5)
		for i = 1, utf8.len(helloText) or #helloText do
			if not overlay.Parent then
				return
			end
			local last = utf8.offset(helloText, i + 1)
			hello.Text = last and string.sub(helloText, 1, last - 1) or helloText
			task.wait(0.025)
		end
	end)

	local field = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 270),
		Size = UDim2.new(1, -20, 0, 60),
		BackgroundColor3 = T.Panel,
		ClipsDescendants = true,
		ZIndex = 52,
		Parent = right,
	}, { UI.corner(14) })
	local fieldStroke = UI.stroke(T.Cyan, 2, 0.5, field)
	UI.label({ text = "🔑", textSize = 24, alignX = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(8, 0), size = UDim2.new(0, 40, 1, 0), z = 53, parent = field })
	local box = UI.new("TextBox", {
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = T.Text,
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 54,
		Parent = field,
	})
	local mask = UI.label({
		text = "Contraseña…",
		font = Enum.Font.GothamBold,
		textSize = 22,
		color = T.Muted,
		pos = UDim2.fromOffset(54, 0),
		size = UDim2.new(1, -110, 1, 0),
		z = 53,
		parent = field,
	})
	mask.TextTruncate = Enum.TextTruncate.AtEnd
	local masked = true
	local function refreshMask()
		local txt = box.Text
		if txt == "" then
			mask.Text = box:IsFocused() and "|" or "Contraseña…"
			mask.TextColor3 = T.Muted
		else
			local shown = masked and string.rep("●", utf8.len(txt) or #txt) or txt
			mask.Text = shown .. (box:IsFocused() and "|" or "")
			mask.TextColor3 = T.Text
		end
	end
	box:GetPropertyChangedSignal("Text"):Connect(refreshMask)
	box.Focused:Connect(function()
		UI.tween(fieldStroke, 0.2, { Transparency = 0, Color = T.Pink })
		refreshMask()
	end)
	UI.button({
		text = "👁",
		textSize = 20,
		size = UDim2.fromOffset(44, 44),
		anchor = Vector2.new(1, 0.5),
		pos = UDim2.new(1, -8, 0.5, 0),
		color = T.Panel2,
		stroke = false,
		z = 54,
		parent = field,
		callback = function()
			masked = not masked
			refreshMask()
		end,
	})

	local status = UI.label({ text = "", font = Enum.Font.GothamBold, textSize = 15, color = T.Red, pos = UDim2.fromOffset(4, 338), size = UDim2.new(1, -20, 0, 22), z = 52, parent = right })

	local enter = UI.button({
		text = "ACTIVAR  ⚡",
		font = Enum.Font.FredokaOne,
		textSize = 28,
		size = UDim2.new(1, -20, 0, 60),
		pos = UDim2.fromOffset(0, 370),
		color = Color3.new(1, 1, 1),
		gradient = UI.Hot,
		stroke = false,
		radius = 14,
		z = 52,
		parent = right,
	})
	UI.label({
		text = "Enter para confirmar  ·  la contraseña la revisa el servidor",
		textSize = 12,
		color = T.Muted,
		pos = UDim2.fromOffset(4, 440),
		size = UDim2.new(1, -20, 0, 18),
		z = 52,
		parent = right,
	})

	local busy = false
	local function shake()
		for _, x in { 16, -14, 10, -7, 4, 0 } do
			holder.Position = UDim2.new(0.5, x, 0.5, 0)
			task.wait(0.045)
		end
	end
	local function submit()
		if busy then
			return
		end
		busy = true
		status.TextColor3 = T.Cyan
		status.Text = "Verificando…"
		local ok, res = pcall(invoke, box.Text)
		if ok and type(res) == "table" and res.ok then
			result = res
			status.TextColor3 = T.Green
			status.Text = "✔ ACCESO CONCEDIDO"
			UI.setText(enter, "✔ ACTIVADO")
			UI.tween(fieldStroke, 0.2, { Color = T.Green, Transparency = 0 })
			UI.sound("ping", 0.7, 1.2)
			task.wait(0.7)
			UI.tween(holderScale, 0.35, { Scale = holderScale.Scale * 0.6 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			UI.tween(overlay, 0.45, { BackgroundTransparency = 1 })
			task.wait(0.4)
			finished:Fire()
		else
			busy = false
			status.TextColor3 = T.Red
			status.Text = (ok and type(res) == "table" and res.msg) or "No se pudo conectar con el servidor"
			UI.tween(fieldStroke, 0.2, { Color = T.Red, Transparency = 0 })
			UI.sound("error", 0.5)
			shake()
		end
	end
	enter.Activated:Connect(submit)
	box.FocusLost:Connect(function(enterPressed)
		refreshMask()
		UI.tween(fieldStroke, 0.2, { Transparency = 0.5, Color = T.Cyan })
		if enterPressed then
			task.spawn(submit)
		end
	end)

	-- entrada animada
	local target = fitValue(980, 580)
	holderScale.Scale = target * 0.7
	UI.tween(holderScale, 0.7, { Scale = target }, Enum.EasingStyle.Back)
	card.Position = UDim2.fromOffset(-120, 0)
	UI.tween(card, 0.8, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
	UI.sound("whoosh", 0.5)
	if not UserInputService.TouchEnabled then
		task.delay(0.9, function()
			if overlay.Parent then
				box:CaptureFocus()
			end
		end)
	end

	finished.Event:Wait()
	for _, c in conns do
		c:Disconnect()
	end
	overlay:Destroy()
	return result
end

---------------------------------------------------------------- cinemática

local function ease(a)
	if a < 0.5 then
		return 4 * a * a * a
	end
	return 1 - (-2 * a + 2) ^ 3 / 2
end

function Intro.cinematic(gui)
	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and head and hum) then
		return
	end
	local cam = workspace.CurrentCamera
	local controls
	pcall(function()
		controls = require(lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 3)):GetControls()
	end)
	if controls then
		controls:Disable()
	end
	local oldFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable

	local layer = UI.new("Frame", { Name = "GGCine", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 70, Parent = gui })
	local top = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), ZIndex = 71, Parent = layer })
	local bottom = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 71,
		Parent = layer,
	})
	UI.tween(top, 0.6, { Size = UDim2.new(1, 0, 0.11, 0) })
	UI.tween(bottom, 0.6, { Size = UDim2.new(1, 0, 0.11, 0) })
	local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 79, Parent = layer })

	-- títulos
	local titles = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1000, 300),
		BackgroundTransparency = 1,
		ZIndex = 75,
		Parent = layer,
	})
	local titlesFit = UI.new("UIScale", { Parent = titles })
	local fitConn = fit(titlesFit, 1050, 500, 1)
	local big = UI.label({
		text = Config.Title,
		font = Enum.Font.FredokaOne,
		textSize = 130,
		color = Color3.new(1, 1, 1),
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		pos = UDim2.fromScale(0.5, 0.38),
		size = UDim2.fromOffset(1000, 150),
		z = 76,
		parent = titles,
	})
	big.TextTransparency = 1
	UI.shine(UI.new("UIGradient", { Color = UI.Rainbow, Parent = big }), 0.6)
	local bigStroke = UI.new("UIStroke", { Thickness = 5, Color = Color3.fromRGB(25, 0, 45), Transparency = 1, Parent = big })
	local bigScale = UI.new("UIScale", { Scale = 2.6, Parent = big })
	local sub = UI.label({
		text = "⚡ MENÚ ACTIVADO ⚡",
		font = Enum.Font.GothamBlack,
		textSize = 30,
		color = T.Pink,
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		pos = UDim2.fromScale(0.5, 0.7),
		size = UDim2.fromOffset(900, 40),
		z = 76,
		parent = titles,
	})
	sub.TextTransparency = 1
	sub.TextStrokeTransparency = 1
	local welcome = UI.label({
		text = "",
		font = Enum.Font.GothamBold,
		textSize = 22,
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0.5, 0.5),
		pos = UDim2.fromScale(0.5, 0.86),
		size = UDim2.fromOffset(900, 30),
		z = 76,
		parent = titles,
	})
	welcome.TextStrokeTransparency = 0.4

	local base = hrp.CFrame
	local function orbit(angleDeg, dist, height, focus)
		local dir = (base * CFrame.Angles(0, math.rad(angleDeg), 0)).LookVector
		return CFrame.lookAt(focus + dir * dist + Vector3.new(0, height, 0), focus)
	end
	local function bodyFocus()
		return hrp.Position + Vector3.new(0, 1.2, 0)
	end
	local function headFocus()
		return head.Position - Vector3.new(0, head.Size.Y * 0.1, 0)
	end
	local face = math.max(3.3, headRadius(char) * 2.9)
	local function shot(dur, a0, a1, d0, d1, h0, h1, f0, f1, focusFn, shakeAmt)
		local start = os.clock()
		while head.Parent and hrp.Parent do
			local a = math.clamp((os.clock() - start) / dur, 0, 1)
			local e = ease(a)
			local cf = orbit(a0 + (a1 - a0) * e, d0 + (d1 - d0) * e, h0 + (h1 - h0) * e, focusFn())
			if shakeAmt then
				local k = shakeAmt * (1 - a)
				cf *= CFrame.Angles((math.random() - 0.5) * k, (math.random() - 0.5) * k, (math.random() - 0.5) * k * 0.5)
			end
			cam.CFrame = cf
			cam.FieldOfView = f0 + (f1 - f0) * e
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end

	pcall(Emotes.play, Config.IntroEmote)
	UI.sound("whoosh", 0.7)
	shot(2.3, 150, 35, 30, 15, 18, 5, 70, 55, bodyFocus)
	UI.sound("whoosh", 0.7, 1.25)
	shot(1.3, 35, 0, 10, face, 2, 0.15, 55, 34, headFocus)

	-- impacto
	Net:FireServer("Burst")
	UI.sound("boom", 1, 0.6)
	flash.BackgroundTransparency = 0
	UI.tween(flash, 0.9, { BackgroundTransparency = 1 })
	UI.tween(bigScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	UI.tween(big, 0.3, { TextTransparency = 0 })
	UI.tween(bigStroke, 0.3, { Transparency = 0 })
	task.delay(0.35, function()
		UI.tween(sub, 0.4, { TextTransparency = 0, TextStrokeTransparency = 0.3 })
		local msg = "Bienvenido al " .. Config.TeamTag .. ", " .. lp.DisplayName .. " 👶"
		for i = 1, utf8.len(msg) or #msg do
			local last = utf8.offset(msg, i + 1)
			welcome.Text = last and string.sub(msg, 1, last - 1) or msg
			task.wait(0.022)
		end
	end)
	shot(1.9, 0, -14, face, face * 0.85, 0.15, 0.1, 34, 30, headFocus, 0.05)

	-- regreso a la cámara normal
	UI.sound("whoosh", 0.6, 0.9)
	UI.tween(big, 0.6, { TextTransparency = 1 })
	UI.tween(bigStroke, 0.6, { Transparency = 1 })
	UI.tween(sub, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
	UI.tween(welcome, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
	shot(1.2, -14, -180, face * 0.85, 12, 0.1, 3, 30, oldFov, bodyFocus)

	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum
	cam.FieldOfView = oldFov
	if controls then
		controls:Enable()
	end
	UI.tween(top, 0.5, { Size = UDim2.new(1, 0, 0, 0) })
	UI.tween(bottom, 0.5, { Size = UDim2.new(1, 0, 0, 0) })
	task.delay(0.6, function()
		fitConn:Disconnect()
		layer:Destroy()
	end)
end

return Intro
