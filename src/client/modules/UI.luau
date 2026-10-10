--[[ GUGU-GAGA · UI
	Piezas visuales reutilizables: botones, interruptores, deslizadores,
	avisos, sonidos, arrastre y degradados animados. ]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.Parent:WaitForChild("Config"))
local T = Config.Theme

local UI = {}
UI.T = T
UI.soundsOn = true

UI.Rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, T.Cyan),
	ColorSequenceKeypoint.new(0.5, T.Pink),
	ColorSequenceKeypoint.new(1, T.Purple),
})
UI.Hot = ColorSequence.new(T.Pink, T.Purple)
UI.kindColor = { info = T.Cyan, ok = T.Green, error = T.Red, team = T.Pink, warn = T.Yellow }

function UI.new(className, props, children)
	local inst = Instance.new(className)
	local parent
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(r)
	return UI.new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 10) })
end

function UI.stroke(color, thickness, transparency, parent)
	return UI.new("UIStroke", {
		Color = color or T.Cyan,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.pad(px, parent)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.list(parent, padding, horizontal)
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

function UI.tween(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function UI.headshot(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
end

-- degradados que giran o brillan solos
local animated = {}
function UI.spin(gradient, speed)
	table.insert(animated, { g = gradient, mode = "spin", s = speed or 90 })
	return gradient
end
function UI.shine(gradient, speed)
	table.insert(animated, { g = gradient, mode = "shine", s = speed or 0.5 })
	return gradient
end
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for i = #animated, 1, -1 do
		local a = animated[i]
		if not a.g.Parent then
			table.remove(animated, i)
		elseif a.mode == "spin" then
			a.g.Rotation = (a.g.Rotation + a.s * dt) % 360
		else
			a.g.Offset = Vector2.new(math.sin(t * a.s * math.pi) * 0.5, 0)
		end
	end
end)

---------------------------------------------------------------- sonidos

-- efectos gratis de la Creator Store
local SOUNDS = {
	click = "rbxassetid://88442833509532",
	ping = "rbxassetid://136655923047274",
	whoosh = "rbxassetid://140334012603496",
	boom = "rbxassetid://9125484526",
	error = "rbxassetid://134343807114403",
}
function UI.sound(name, volume, pitch)
	if not UI.soundsOn or not SOUNDS[name] then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = SOUNDS[name]
	s.Volume = volume or 0.5
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	task.delay(4, function()
		s:Destroy()
	end)
end

---------------------------------------------------------------- piezas

function UI.label(o)
	return UI.new("TextLabel", {
		Name = o.name or "Label",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.new(1, 0, 0, 20),
		Position = o.pos or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		Text = o.text or "",
		RichText = true,
		Font = o.font or Enum.Font.GothamMedium,
		TextSize = o.textSize or 14,
		TextColor3 = o.color or T.Text,
		TextXAlignment = o.alignX or Enum.TextXAlignment.Left,
		TextYAlignment = o.alignY or Enum.TextYAlignment.Center,
		TextWrapped = o.wrap == true,
		TextTruncate = o.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		LayoutOrder = o.order or 0,
		ZIndex = o.z or 1,
		Parent = o.parent,
	})
end

-- hover y "apretón" para cualquier botón; el color base vive en el atributo Base
function UI.hover(b)
	b:SetAttribute("Base", b.BackgroundColor3)
	local sc = b:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		UI.tween(b, 0.15, { BackgroundColor3 = b:GetAttribute("Base"):Lerp(Color3.new(1, 1, 1), 0.14) })
	end)
	b.MouseLeave:Connect(function()
		UI.tween(b, 0.2, { BackgroundColor3 = b:GetAttribute("Base") })
		UI.tween(sc, 0.15, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		UI.tween(sc, 0.08, { Scale = 0.93 })
	end)
	b.MouseButton1Up:Connect(function()
		UI.tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- cambia el texto de un botón, tenga o no degradado
function UI.setText(b, text)
	if b:FindFirstChild("Text") then
		b:SetAttribute("Label", text)
	else
		b.Text = text
	end
end

function UI.setBase(b, color)
	b:SetAttribute("Base", color)
	UI.tween(b, 0.2, { BackgroundColor3 = color })
end

function UI.button(o)
	local b = UI.new("TextButton", {
		Name = o.name or "Button",
		Size = o.size or UDim2.fromOffset(120, 32),
		Position = o.pos or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		BackgroundColor3 = o.color or T.Panel2,
		BackgroundTransparency = o.bgT or 0,
		AutoButtonColor = false,
		Text = o.text or "",
		RichText = true,
		Font = o.font or Enum.Font.GothamBold,
		TextSize = o.textSize or 14,
		TextColor3 = o.textColor or T.Text,
		TextWrapped = o.wrap == true,
		LayoutOrder = o.order or 0,
		ZIndex = o.z or 1,
		Parent = o.parent,
	}, { UI.corner(o.radius or 8) })
	if o.stroke ~= false then
		UI.stroke(o.strokeColor or T.Cyan, 1.2, o.strokeT or 0.6, b)
	end
	if o.gradient then
		-- el degradado pintaría también el texto: el texto va en una etiqueta encima
		UI.new("UIGradient", { Color = o.gradient, Parent = b })
		local label = UI.new("TextLabel", {
			Name = "Text",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = b.Text,
			RichText = true,
			Font = b.Font,
			TextSize = b.TextSize,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = b.ZIndex,
			Parent = b,
		})
		UI.new("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(60, 0, 70), Transparency = 0.3, Parent = label })
		b.Text = ""
		b:GetAttributeChangedSignal("Label"):Connect(function()
			label.Text = b:GetAttribute("Label")
		end)
	end
	UI.hover(b)
	if o.callback then
		b.Activated:Connect(function()
			UI.sound("click", 0.4)
			o.callback(b)
		end)
	end
	return b
end

-- fila con interruptor: devuelve { value, set(v, silent), row }
function UI.toggle(o)
	local row = UI.new("Frame", {
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, o.height or 42),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.15,
		LayoutOrder = o.order or 0,
		Parent = o.parent,
	}, { UI.corner(10) })
	UI.label({ text = o.text, font = Enum.Font.GothamBold, textSize = 14, pos = UDim2.fromOffset(12, 0), size = UDim2.new(1, -80, 1, 0), parent = row })
	local sw = UI.new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(48, 24),
		BackgroundColor3 = T.Panel2,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, { UI.corner(UDim.new(1, 0)) })
	local knob = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = T.Muted,
		Parent = sw,
	}, { UI.corner(UDim.new(1, 0)) })
	local obj = { value = false, row = row }
	function obj.set(v, silent)
		obj.value = v == true
		UI.tween(knob, 0.2, {
			Position = obj.value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = obj.value and Color3.new(1, 1, 1) or T.Muted,
		})
		UI.tween(sw, 0.2, { BackgroundColor3 = obj.value and T.Pink or T.Panel2 })
		if not silent and o.callback then
			o.callback(obj.value)
		end
	end
	sw.Activated:Connect(function()
		UI.sound("click", 0.3)
		obj.set(not obj.value)
	end)
	obj.set(o.default == true, true)
	return obj
end

-- deslizador con caja de valor: devuelve { value, set(v, fire), row }
function UI.slider(o)
	local fmt = o.fmt or function(v)
		return tostring(v)
	end
	local row = UI.new("Frame", {
		Name = "Slider",
		Size = o.size or UDim2.new(1, 0, 0, 54),
		Position = o.pos or UDim2.new(),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = o.bgT or 0.15,
		LayoutOrder = o.order or 0,
		Parent = o.parent,
	}, { UI.corner(10) })
	UI.label({ text = o.text, font = Enum.Font.GothamBold, textSize = 13, color = T.Muted, pos = UDim2.fromOffset(12, 4), size = UDim2.new(1, -90, 0, 20), parent = row })
	local box = UI.new("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 4),
		Size = UDim2.fromOffset(64, 22),
		BackgroundColor3 = T.Bg,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = T.Cyan,
		ClearTextOnFocus = true,
		Parent = row,
	}, { UI.corner(6) })
	local track = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.new(0, 14, 1, -18),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = T.Bg,
		Parent = row,
	}, { UI.corner(UDim.new(1, 0)) })
	local fill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track }, {
		UI.corner(UDim.new(1, 0)),
		UI.new("UIGradient", { Color = ColorSequence.new(T.Cyan, T.Pink) }),
	})
	local knob = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	}, { UI.corner(UDim.new(1, 0)) })
	UI.stroke(T.Pink, 2, 0, knob)
	-- zona de toque más grande que la barra
	local hit = UI.new("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0),
		Size = UDim2.new(1, 16, 0, 26),
		Parent = track,
	})

	local obj = { value = o.default, row = row }
	function obj.set(v, fire)
		v = math.clamp(v, o.min, o.max)
		if o.step then
			v = math.floor(v / o.step + 0.5) * o.step
		end
		obj.value = v
		local a = (v - o.min) / (o.max - o.min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		box.Text = fmt(v)
		if fire and o.callback then
			o.callback(v)
		end
	end
	local dragging = false
	local function fromX(x)
		local a = (x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)
		obj.set(o.min + math.clamp(a, 0, 1) * (o.max - o.min), true)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	box.FocusLost:Connect(function()
		local n = tonumber((string.gsub(box.Text, "[^%d%.%-]", "")))
		if n then
			obj.set(n, true)
		else
			obj.set(obj.value, false)
		end
	end)
	obj.set(o.default, false)
	return obj
end

-- ventana arrastrable; devuelve una función que dice si el último toque fue arrastre
function UI.draggable(handle, target)
	local dragging, moved, startPos, startInput = false, 0, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, 0
			startInput, startPos = input.Position, target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			moved = math.max(moved, d.Magnitude)
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	return function()
		return moved > 6
	end
end

---------------------------------------------------------------- avisos

local toastHolder
local toastOrder = 0

function UI.attach(gui)
	toastHolder = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 70),
		Size = UDim2.fromOffset(300, 500),
		ZIndex = 90,
		Parent = gui,
	})
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastHolder,
	})
end

function UI.toast(text, kind)
	if not toastHolder then
		return
	end
	local color = UI.kindColor[kind or "info"] or T.Cyan
	toastOrder -= 1
	local slot = UI.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(290, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = toastOrder,
		ZIndex = 90,
		Parent = toastHolder,
	})
	local body = UI.new("Frame", {
		BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.06,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(330, 0),
		ZIndex = 90,
		Parent = slot,
	}, { UI.corner(10) })
	UI.stroke(color, 1.5, 0.2, body)
	UI.new("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.new(0, 4, 1, -14),
		Position = UDim2.fromOffset(7, 7),
		ZIndex = 91,
		Parent = body,
	}, { UI.corner(2) })
	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(20, 0),
		Text = text,
		RichText = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 91,
		Parent = body,
	}, { UI.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }) })
	UI.tween(body, 0.45, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	UI.sound("ping", 0.25)
	task.delay(3.6, function()
		UI.tween(body, 0.3, { Position = UDim2.fromOffset(330, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.wait(0.32)
		slot:Destroy()
	end)
end

return UI
