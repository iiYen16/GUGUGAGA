--[[ GUGU-GAGA · Iconos y SYNC
	Cara redonda flotando sobre tus amigos (y el TEAM) donde estén: click para
	teletransportarte. Click sobre un miembro del TEAM para sincronizar emotes,
	y rayos de colores entre los que están sincronizados. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local root = script.Parent.Parent
local Net = root:WaitForChild("Remotes"):WaitForChild("Net")
local UI = require(script.Parent.UI)
local Emotes = require(script.Parent.Emotes)
local Movement = require(script.Parent.Movement)
local T = UI.T

local lp = Players.LocalPlayer

local Icons = { friends = true, team = true, all = false, beams = true, minDist = 30 }

local entries, friendCache = {}, {}
local playerGui

function Icons.isTeam(p)
	return p:GetAttribute("GuguGaga") == true
end

function Icons.isFriend(p)
	if p == lp then
		return false
	end
	if friendCache[p] == nil then
		friendCache[p] = false
		task.spawn(function()
			local ok, r = pcall(function()
				return lp:IsFriendsWith(p.UserId)
			end)
			friendCache[p] = ok and r == true
		end)
	end
	return friendCache[p]
end

function Icons.toggleSync(p)
	if Emotes.leaders[lp] == p then
		Emotes.unsync()
		UI.toast("Dejaste de sincronizarte con " .. p.DisplayName, "info")
	else
		Net:FireServer("Sync", p)
		UI.toast("🔗 Sincronizado con <b>" .. p.DisplayName .. "</b> ✨", "team")
	end
end

---------------------------------------------------------------- iconos flotantes

local function makeEntry(p)
	local bb = UI.new("BillboardGui", {
		Name = "GGIcon_" .. p.Name,
		Size = UDim2.fromOffset(64, 82),
		AlwaysOnTop = true,
		Active = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
		StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
		Enabled = false,
		Parent = playerGui,
	})
	local btn = UI.new("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(40, 38, 60),
		Image = UI.headshot(p.UserId),
		AutoButtonColor = false,
		Parent = bb,
	}, { UI.corner(UDim.new(1, 0)) })
	local ring = UI.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, Parent = btn })
	local ringGrad = UI.new("UIGradient", { Color = UI.Rainbow, Enabled = false, Parent = ring })
	UI.spin(ringGrad, 160)
	local sc = UI.new("UIScale", { Parent = btn })
	local name = UI.label({
		text = p.DisplayName,
		font = Enum.Font.GothamBold,
		textSize = 12,
		alignX = Enum.TextXAlignment.Center,
		pos = UDim2.fromOffset(-30, 60),
		size = UDim2.new(1, 60, 0, 16),
		parent = bb,
	})
	name.TextStrokeTransparency = 0.3
	local dist = UI.label({
		text = "",
		font = Enum.Font.GothamBold,
		textSize = 10,
		color = T.Cyan,
		alignX = Enum.TextXAlignment.Center,
		pos = UDim2.fromOffset(-30, 74),
		size = UDim2.new(1, 60, 0, 12),
		parent = bb,
	})
	dist.TextStrokeTransparency = 0.3
	btn.MouseEnter:Connect(function()
		UI.tween(sc, 0.2, { Scale = 1.18 }, Enum.EasingStyle.Back)
	end)
	btn.MouseLeave:Connect(function()
		UI.tween(sc, 0.2, { Scale = 1 })
	end)
	btn.Activated:Connect(function()
		if Movement.teleportTo(p) then
			UI.sound("whoosh", 0.5)
			UI.toast("✨ Teleport a <b>" .. p.DisplayName .. "</b>", "ok")
		end
	end)
	entries[p] = { bb = bb, ring = ring, grad = ringGrad, dist = dist }
end

local function removeEntry(p)
	local e = entries[p]
	if e then
		e.bb:Destroy()
		entries[p] = nil
	end
	friendCache[p] = nil
end

local function updateIcons()
	local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	for p, e in entries do
		local head = p.Character and p.Character:FindFirstChild("Head")
		local team, friend = Icons.isTeam(p), Icons.isFriend(p)
		local want = Icons.all or (Icons.friends and friend) or (Icons.team and team)
		local d = (head and myHrp) and (head.Position - myHrp.Position).Magnitude or 0
		e.bb.Adornee = head
		e.bb.Enabled = want and head ~= nil and d > Icons.minDist
		e.grad.Enabled = team
		e.ring.Color = team and Color3.new(1, 1, 1) or (friend and T.Yellow or Color3.new(1, 1, 1))
		e.dist.Text = string.format("%d m", math.floor(d / 3.57))
	end
end

---------------------------------------------------------------- rayos de sync

local beamFolder
local beams = {}

local function beamAtt(p)
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	local a = hrp:FindFirstChild("GGBeamAtt")
	if not a then
		a = Instance.new("Attachment")
		a.Name = "GGBeamAtt"
		a.Position = Vector3.new(0, 0.6, 0)
		a.Parent = hrp
	end
	return a
end

function Icons.refreshBeams()
	for _, b in beams do
		b:Destroy()
	end
	table.clear(beams)
	if not Icons.beams or not beamFolder then
		return
	end
	for p, leader in Emotes.leaders do
		if p.Parent and leader and leader.Parent then
			local a0, a1 = beamAtt(p), beamAtt(leader)
			if a0 and a1 then
				table.insert(beams, UI.new("Beam", {
					Attachment0 = a0,
					Attachment1 = a1,
					Color = ColorSequence.new(T.Pink, T.Cyan),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.2),
						NumberSequenceKeypoint.new(0.5, 0.55),
						NumberSequenceKeypoint.new(1, 0.2),
					}),
					Width0 = 0.3,
					Width1 = 0.3,
					LightEmission = 1,
					FaceCamera = true,
					CurveSize0 = 3,
					CurveSize1 = -3,
					Segments = 24,
					Parent = beamFolder,
				}))
			end
		end
	end
end

---------------------------------------------------------------- click sobre miembros

local function memberAt(viewportPos)
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(viewportPos.X, viewportPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { lp.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if not hit then
		return nil
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	local p = model and Players:GetPlayerFromCharacter(model)
	if p and p ~= lp and Icons.isTeam(p) then
		return p
	end
	return nil
end

function Icons.init(gui)
	playerGui = lp:WaitForChild("PlayerGui")
	beamFolder = Instance.new("Folder")
	beamFolder.Name = "GuguGagaBeams"
	beamFolder.Parent = workspace

	for _, p in Players:GetPlayers() do
		if p ~= lp then
			makeEntry(p)
		end
	end
	Players.PlayerAdded:Connect(makeEntry)
	Players.PlayerRemoving:Connect(removeEntry)

	Emotes.onChange(function(what)
		if what == "sync" then
			Icons.refreshBeams()
		end
	end)

	-- resaltado + pista al pasar el ratón por un miembro del TEAM
	local hl = UI.new("Highlight", {
		FillTransparency = 1,
		OutlineColor = T.Pink,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Enabled = false,
		Parent = beamFolder,
	})
	local tip = UI.new("BillboardGui", {
		Name = "GGSyncTip",
		Size = UDim2.fromOffset(170, 28),
		AlwaysOnTop = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
		StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0),
		Enabled = false,
		Parent = playerGui,
	})
	local tipLabel = UI.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.15,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = T.Text,
		Text = "",
		Parent = tip,
	}, { UI.corner(UDim.new(1, 0)) })
	UI.stroke(T.Pink, 1.5, 0, tipLabel)

	local hovered
	local hoverAcc = 0
	RunService.RenderStepped:Connect(function(dt)
		hoverAcc += dt
		if hoverAcc < 0.08 then
			return
		end
		hoverAcc = 0
		local p = nil
		if UserInputService.MouseEnabled and not UserInputService:GetFocusedTextBox() then
			p = memberAt(UserInputService:GetMouseLocation())
		end
		if p ~= hovered then
			hovered = p
			hl.Adornee = p and p.Character or nil
			hl.Enabled = p ~= nil
			tip.Adornee = p and p.Character and p.Character:FindFirstChild("Head") or nil
			tip.Enabled = p ~= nil
		end
		if p then
			tipLabel.Text = Emotes.leaders[lp] == p and "🖱 Click = dejar SYNC" or "🖱 Click = SYNC 🔗"
		end
	end)

	-- toque corto sobre un miembro = sincronizar (así no choca con mover la cámara)
	local pressPos, pressTime
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressPos, pressTime = input.Position, os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not pressTime then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local quick = os.clock() - pressTime < 0.35 and (input.Position - pressPos).Magnitude < 10
		pressTime = nil
		if not quick or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			return
		end
		local pos
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pos = UserInputService:GetMouseLocation()
		else
			pos = Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
		end
		local p = memberAt(pos)
		if p then
			Icons.toggleSync(p)
		end
	end)

	local acc, beamAcc = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		beamAcc += dt
		if acc >= 0.25 then
			acc = 0
			updateIcons()
		end
		if beamAcc >= 2 then
			beamAcc = 0
			Icons.refreshBeams()
		end
	end)
	Icons.refreshBeams()
end

return Icons
