--[[ GUGU-GAGA · Cliente
	Pide la contraseña y, si es correcta, lanza la cinemática, el menú, los
	iconos de amigos y la sincronización de emotes del TEAM gugu-gaga. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
-- espera una pieza del sistema; si no aparece, lo dice claro en Output en vez de quedarse esperando
local function need(parent, name, hint)
	local inst = parent:WaitForChild(name, 20)
	if not inst then
		error(string.format("[GuguGaga] No aparece %s.%s — %s. El menú no puede arrancar.", parent:GetFullName(), name, hint), 0)
	end
	return inst
end

local root = need(ReplicatedStorage, "GuguGaga", "falta la carpeta del sistema: vuelve a instalarlo")
local remotes = need(root, "Remotes", "la crea ServerScriptService.GuguGagaServer: revisa que exista, esté activado y no tenga errores en Output")
local AuthFn = need(remotes, "Auth", "la crea ServerScriptService.GuguGagaServer")
local Net = need(remotes, "Net", "la crea ServerScriptService.GuguGagaServer")
local mods = need(root, "Client", "faltan los módulos del cliente: vuelve a instalarlo")
local Config = require(need(root, "Config", "falta el módulo de configuración: vuelve a instalarlo"))

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

if Config.Debug then
	print("[GuguGaga] Cliente listo")
end
