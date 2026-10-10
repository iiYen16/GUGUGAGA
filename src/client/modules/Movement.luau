--[[ GUGU-GAGA · Movimiento
	Velocidad, súper salto, saltos infinitos, vuelo, atravesar paredes,
	gravedad lunar, trompo, orbitar a alguien, teletransporte y Ctrl+Click. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent.Parent
local Net = root:WaitForChild("Remotes"):WaitForChild("Net")
local Emotes = require(script.Parent.Emotes)

local lp = Players.LocalPlayer

local M = {
	walkOn = false,
	walk = 60,
	jumpOn = false,
	jump = 160,
	infJump = false,
	noclip = false,
	flying = false,
	flySpeed = 90,
	lowGrav = false,
	clickTp = true,
	spin = false,
	spinSpeed = 25,
	orbit = nil,
	riding = false,
	up = false,
	down = false,
}

local SAVED = { "walkOn", "walk", "jumpOn", "jump", "infJump", "flySpeed", "clickTp", "spinSpeed" }

local char, hum, hrp
local defaults = { walk = 16, useJP = false, jp = 50, jh = 7.2 }
local defaultGravity = workspace.Gravity
local noclipRestore = {}
local fly = {}
local spinParts = {}

local listeners = {}
function M.onChange(fn)
	table.insert(listeners, fn)
end
local function changed()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function M.apply()
	if not hum then
		return
	end
	hum.WalkSpeed = M.walkOn and M.walk or defaults.walk
	if M.jumpOn then
		hum.UseJumpPower = true
		hum.JumpPower = M.jump
	else
		hum.UseJumpPower = defaults.useJP
		hum.JumpPower = defaults.jp
		hum.JumpHeight = defaults.jh
	end
	workspace.Gravity = M.lowGrav and 45 or defaultGravity
end

function M.set(key, value)
	M[key] = value
	if table.find(SAVED, key) then
		Emotes.setSetting("mv_" .. key, value)
	end
	if key == "noclip" and not value then
		for part, v in noclipRestore do
			if part.Parent then
				part.CanCollide = v
			end
		end
		table.clear(noclipRestore)
	end
	if key == "spinSpeed" and spinParts.av then
		spinParts.av.AngularVelocity = Vector3.new(0, value, 0)
	end
	M.apply()
	changed()
end

---------------------------------------------------------------- vuelo

function M.setFly(on)
	on = on == true
	if on == M.flying then
		return
	end
	if on and (not hrp or not hum or M.riding) then
		return
	end
	M.flying = on
	Emotes.flying = on
	for _, inst in fly do
		inst:Destroy()
	end
	table.clear(fly)
	if on then
		if M.spin then
			M.setSpin(false)
		end
		M.orbit = nil
		local att = Instance.new("Attachment")
		att.Name = "GGFly"
		att.Parent = hrp
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VectorVelocity = Vector3.zero
		lv.Parent = hrp
		local ao = Instance.new("AlignOrientation")
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = att
		ao.MaxTorque = math.huge
		ao.Responsiveness = 30
		ao.CFrame = hrp.CFrame.Rotation
		ao.Parent = hrp
		fly.att, fly.lv, fly.ao = att, lv, ao
		hum.AutoRotate = false
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	elseif hum then
		hum.AutoRotate = true
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	changed()
end

---------------------------------------------------------------- trompo

function M.setSpin(on)
	on = on == true
	for _, inst in spinParts do
		inst:Destroy()
	end
	table.clear(spinParts)
	M.spin = on
	if on and hrp and hum then
		if M.flying then
			M.setFly(false)
		end
		local att = Instance.new("Attachment")
		att.Name = "GGSpin"
		att.Parent = hrp
		local av = Instance.new("AngularVelocity")
		av.Attachment0 = att
		av.MaxTorque = math.huge
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.AngularVelocity = Vector3.new(0, M.spinSpeed, 0)
		av.Parent = hrp
		spinParts.att, spinParts.av = att, av
		hum.AutoRotate = false
	elseif hum and not M.flying then
		hum.AutoRotate = true
	end
	changed()
end

---------------------------------------------------------------- teletransporte

function M.teleport(cf)
	if not char or not hrp then
		return
	end
	if M.riding then
		Net:FireServer("Ride", nil)
	end
	M.orbit = nil
	char:PivotTo(cf)
	hrp.AssemblyLinearVelocity = Vector3.zero
	changed()
end

function M.teleportTo(player)
	local t = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not t then
		return false
	end
	local pos = (t.CFrame * CFrame.new(0, 0, 4)).Position
	M.teleport(CFrame.lookAt(pos, Vector3.new(t.Position.X, pos.Y, t.Position.Z)))
	return true
end

function M.setOrbit(player)
	if M.orbit == player then
		player = nil
	end
	if player and M.flying then
		M.setFly(false)
	end
	if player and M.spin then
		M.setSpin(false)
	end
	M.orbit = player
	changed()
end

function M.reset()
	Net:FireServer("Reset")
end

---------------------------------------------------------------- personaje

local function bind(c)
	char = c
	hum = c:WaitForChild("Humanoid", 10)
	hrp = c:WaitForChild("HumanoidRootPart", 10)
	M.flying, M.spin, M.orbit, M.riding = false, false, nil, false
	Emotes.flying = false
	table.clear(fly)
	table.clear(spinParts)
	table.clear(noclipRestore)
	if not hum then
		return
	end
	defaults = {
		walk = hum.WalkSpeed > 0 and hum.WalkSpeed < 40 and hum.WalkSpeed or 16,
		useJP = hum.UseJumpPower,
		jp = hum.JumpPower,
		jh = hum.JumpHeight,
	}
	M.apply()
	hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if M.walkOn and hum.WalkSpeed ~= M.walk and hum.WalkSpeed > 0 then
			hum.WalkSpeed = M.walk
		end
	end)
	hum:GetPropertyChangedSignal("Sit"):Connect(function()
		if M.riding and not hum.Sit then
			M.riding = false
			Net:FireServer("Ride", nil)
			changed()
		end
	end)
	changed()
end

function M.init()
	local s = Emotes.settings
	for _, key in SAVED do
		local v = s["mv_" .. key]
		if v ~= nil and type(v) == type(M[key]) then
			M[key] = v
		end
	end

	if lp.Character then
		task.spawn(bind, lp.Character)
	end
	lp.CharacterAdded:Connect(bind)

	Net.OnClientEvent:Connect(function(kind, a)
		if kind == "Ragdoll" and hum then
			if a then
				M.setFly(false)
				M.setSpin(false)
				M.orbit = nil
				hum:ChangeState(Enum.HumanoidStateType.Physics)
			else
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		elseif kind == "Ride" and hum then
			M.riding = a == true
			if a then
				M.setFly(false)
				M.setSpin(false)
				M.orbit = nil
				hum.Sit = true
			else
				hum.Sit = false
			end
			changed()
		end
	end)

	-- saltos infinitos
	local lastJump = 0
	UserInputService.JumpRequest:Connect(function()
		if M.infJump and hum and not M.flying and not M.riding then
			local now = os.clock()
			if now - lastJump > 0.15 then
				lastJump = now
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end)

	-- Ctrl + Click = teletransporte
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not M.clickTp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			return
		end
		if not hrp or not hum then
			return
		end
		local pos = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
		if hit then
			local target = hit.Position + Vector3.new(0, hum.HipHeight + hrp.Size.Y / 2 + 0.5, 0)
			M.teleport(CFrame.new(target) * hrp.CFrame.Rotation)
		end
	end)

	-- atravesar paredes
	RunService.Stepped:Connect(function()
		if M.noclip and char then
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") and p.CanCollide then
					if noclipRestore[p] == nil then
						noclipRestore[p] = true
					end
					p.CanCollide = false
				end
			end
		end
	end)

	-- vuelo y órbita
	local orbitAngle = 0
	RunService.RenderStepped:Connect(function(dt)
		if M.flying and fly.lv and hrp and hum then
			local cam = workspace.CurrentCamera.CFrame
			local look, right = cam.LookVector, cam.RightVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			flatLook = flatLook.Magnitude > 0.01 and flatLook.Unit or Vector3.new(0, 0, -1)
			local flatRight = Vector3.new(right.X, 0, right.Z)
			flatRight = flatRight.Magnitude > 0.01 and flatRight.Unit or Vector3.new(1, 0, 0)
			local md = hum.MoveDirection
			local f, r = md:Dot(flatLook), md:Dot(flatRight)
			local dir = look * f + right * r
			local typing = UserInputService:GetFocusedTextBox() ~= nil
			local v = 0
			if M.up or (not typing and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
				v += 1
			end
			if M.down or (not typing and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q))) then
				v -= 1
			end
			dir += Vector3.new(0, v, 0)
			if dir.Magnitude > 1 then
				dir = dir.Unit
			end
			fly.lv.VectorVelocity = fly.lv.VectorVelocity:Lerp(dir * M.flySpeed, math.min(1, dt * 8))
			fly.ao.CFrame = CFrame.lookAt(Vector3.zero, flatLook) * CFrame.Angles(-f * 0.35, 0, -r * 0.3)
		end
		if M.orbit and hrp then
			local t = M.orbit.Character and M.orbit.Character:FindFirstChild("HumanoidRootPart")
			if not t or not M.orbit.Parent then
				M.orbit = nil
				changed()
			else
				orbitAngle += dt * 3
				local pos = t.Position + Vector3.new(math.cos(orbitAngle) * 7, 1.5, math.sin(orbitAngle) * 7)
				hrp.CFrame = CFrame.lookAt(pos, Vector3.new(t.Position.X, pos.Y, t.Position.Z))
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

return M
