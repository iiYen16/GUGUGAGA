--[[ GUGU-GAGA · Cliente
	Pide la contraseña y, si es correcta, lanza la cinemática, el menú, los
	iconos de amigos y la sincronización de emotes del TEAM gugu-gaga. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local root = ReplicatedStorage:WaitForChild("GuguGaga")
local remotes = root:WaitForChild("Remotes")
local AuthFn = remotes:WaitForChild("Auth")
local Net = remotes:WaitForChild("Net")
local mods = root:WaitForChild("Client")

local UI = require(mods:WaitForChild("UI"))
local Emotes = require(mods:WaitForChild("Emotes"))
local Movement = require(mods:WaitForChild("Movement"))
local Icons = require(mods:WaitForChild("Icons"))
local Intro = require(mods:WaitForChild("Intro"))
local Menu = require(mods:WaitForChild("Menu"))

local gui = UI.new("ScreenGui", {
	Name = "GuguGagaUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 60,
	Parent = lp:WaitForChild("PlayerGui"),
})
UI.attach(gui)

-- brillo animado en las etiquetas TEAM gugu-gaga (las ven todos)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, bb in CollectionService:GetTagged("GGTag") do
		local title = bb:FindFirstChild("Title")
		local shine = title and title:FindFirstChild("Shine")
		if shine then
			shine.Offset = Vector2.new(math.sin(t * 1.6) * 0.6, 0)
		end
	end
end)

Net.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Notify" then
		UI.toast(a, b)
	end
end)

if not lp.Character then
	lp.CharacterAdded:Wait()
end

local result = Intro.lock(gui, function(pass)
	return AuthFn:InvokeServer(pass)
end)

Emotes.init(result)
Movement.init()
Icons.init(gui)
Intro.cinematic(gui)
Menu.build(gui)
