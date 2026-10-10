--[[ GUGU-GAGA · Instalador / actualizador para Roblox Studio

	Se ejecuta en la BARRA DE COMANDOS de Studio (View → Command Bar), en modo edición:

	loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/iiYen16/GUGUGAGA/main/install.lua", true))()

	Descarga el código de GitHub y crea o actualiza cada script en su servicio.
	No toca la contraseña (ServerScriptService.GuguGagaServer.Secret) ni nada más del place.
	Antes de cambiar un script guarda la versión anterior en ServerStorage.GuguGagaRespaldos. ]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local BASE = "https://raw.githubusercontent.com/iiYen16/GUGUGAGA/main/"

-- archivo del repo → dónde va en Studio
local FILES = {
	{ file = "src/shared/Config.luau", path = { "ReplicatedStorage", "GuguGaga" }, name = "Config", class = "ModuleScript" },
	{ file = "src/client/modules/UI.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "UI", class = "ModuleScript" },
	{ file = "src/client/modules/Emotes.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "Emotes", class = "ModuleScript" },
	{ file = "src/client/modules/Movement.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "Movement", class = "ModuleScript" },
	{ file = "src/client/modules/Icons.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "Icons", class = "ModuleScript" },
	{ file = "src/client/modules/Intro.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "Intro", class = "ModuleScript" },
	{ file = "src/client/modules/Menu.luau", path = { "ReplicatedStorage", "GuguGaga", "Client" }, name = "Menu", class = "ModuleScript" },
	{ file = "src/server/init.server.luau", path = { "ServerScriptService" }, name = "GuguGagaServer", class = "Script" },
	{ file = "src/client/GuguGagaClient.client.luau", path = { "StarterPlayer", "StarterPlayerScripts" }, name = "GuguGagaClient", class = "LocalScript" },
}

local function say(text)
	print("[GuguGaga] " .. text)
end

if not RunService:IsStudio() or RunService:IsRunning() then
	warn("[GuguGaga] El instalador solo funciona en Roblox Studio, en modo edición (sin Play).")
	return
end

-- 1) descargar todo antes de tocar nada: si algo falla, el place queda como estaba
local sources = {}
for _, item in FILES do
	local ok, res = pcall(function()
		return HttpService:GetAsync(BASE .. item.file, true)
	end)
	if not ok or type(res) ~= "string" or #res == 0 then
		warn("[GuguGaga] No se pudo descargar " .. item.file .. ": " .. tostring(res))
		warn("[GuguGaga] Revisa Game Settings → Security → Allow HTTP Requests y que el repositorio sea público. No se cambió nada.")
		return
	end
	sources[item] = (string.gsub(res, "\r\n", "\n"))
end

local function find(item)
	local parent = game:GetService(item.path[1])
	for i = 2, #item.path do
		parent = parent and parent:FindFirstChild(item.path[i])
	end
	return parent and parent:FindFirstChild(item.name)
end

local function ensureParent(item)
	local parent = game:GetService(item.path[1])
	for i = 2, #item.path do
		local child = parent:FindFirstChild(item.path[i])
		if not child then
			child = Instance.new("Folder")
			child.Name = item.path[i]
			child.Parent = parent
		end
		parent = child
	end
	return parent
end

-- 2) comprobar que nada del mismo nombre es de otro tipo
for _, item in FILES do
	local existing = find(item)
	if existing and existing.ClassName ~= item.class then
		warn(string.format("[GuguGaga] %s ya existe pero es %s y debería ser %s. No se cambió nada.", existing:GetFullName(), existing.ClassName, item.class))
		return
	end
end

local recording = ChangeHistoryService:TryBeginRecording("GuguGaga: instalar desde GitHub")

-- 3) respaldo de lo que va a cambiar
local backup
for _, item in FILES do
	local existing = find(item)
	if existing and existing.Source ~= sources[item] then
		if not backup then
			local holder = ServerStorage:FindFirstChild("GuguGagaRespaldos")
			if not holder then
				holder = Instance.new("Folder")
				holder.Name = "GuguGagaRespaldos"
				holder.Parent = ServerStorage
			end
			backup = Instance.new("Folder")
			backup.Name = os.date("%Y-%m-%d %H.%M.%S")
			backup.Parent = holder
		end
		-- se guarda como ModuleScript para que la copia nunca se ejecute; la contraseña no se copia
		local copy = Instance.new("ModuleScript")
		copy.Name = item.name .. " (" .. item.class .. ")"
		copy.Source = existing.Source
		copy.Parent = backup
	end
end

-- 4) crear o actualizar
local created, updated, same = {}, {}, {}
for _, item in FILES do
	local existing = find(item)
	if not existing then
		local inst = Instance.new(item.class)
		inst.Name = item.name
		inst.Source = sources[item]
		inst.Parent = ensureParent(item)
		table.insert(created, item.name)
	elseif existing.Source ~= sources[item] then
		existing.Source = sources[item]
		table.insert(updated, item.name)
	else
		table.insert(same, item.name)
	end
end

-- un Script o LocalScript desactivado no arranca al jugar: se activa y se avisa
local enabled = {}
for _, item in FILES do
	local inst = find(item)
	if inst and inst:IsA("BaseScript") and inst.Disabled then
		inst.Disabled = false
		table.insert(enabled, item.name)
	end
end

-- 5) la contraseña: nunca viene de GitHub
local server = game:GetService("ServerScriptService"):FindFirstChild("GuguGagaServer")
local needsPassword = false
if server and not server:FindFirstChild("Secret") then
	local secret = Instance.new("ModuleScript")
	secret.Name = "Secret"
	secret.Source = '-- GUGU-GAGA · Secreto del servidor. Escribe tu contraseña entre las comillas.\n-- Este módulo solo existe en el servidor: los clientes no pueden leerlo.\nreturn {\n\tPassword = "",\n}\n'
	secret.Parent = server
	needsPassword = true
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

say(string.format("Listo. Nuevos: %d · Actualizados: %d · Sin cambios: %d", #created, #updated, #same))
if #created > 0 then
	say("Nuevos: " .. table.concat(created, ", "))
end
if #updated > 0 then
	say("Actualizados: " .. table.concat(updated, ", "))
end
if #enabled > 0 then
	warn("[GuguGaga] Estaban desactivados y los activé (si no, el sistema no arranca): " .. table.concat(enabled, ", "))
end
if backup then
	say("Versión anterior guardada en " .. backup:GetFullName())
end
if needsPassword then
	warn("[GuguGaga] Falta la contraseña: abre ServerScriptService.GuguGagaServer.Secret y escríbela en Password. Sin ella nadie puede activar el menú.")
end
