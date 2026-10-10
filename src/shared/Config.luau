--[[ GUGU-GAGA · Configuración compartida (cliente y servidor)
	Lista de emotes, trolleos, colores y teclas. La contraseña NO está aquí:
	vive solo en el servidor (ServerScriptService.GuguGagaServer). ]]

local Config = {}

Config.Title = "GUGU-GAGA"
Config.Version = "v1.0"
Config.TeamTag = "TEAM gugu-gaga"
Config.MenuKey = Enum.KeyCode.G
Config.FlyKey = Enum.KeyCode.L

-- emotes que usa la intro
Config.IntroWave = 10714359093 -- Hola
Config.IntroEmote = 10714355069 -- Revelación de superhéroe

Config.Theme = {
	Bg = Color3.fromRGB(13, 12, 24),
	Panel = Color3.fromRGB(24, 22, 42),
	Panel2 = Color3.fromRGB(36, 33, 62),
	Cyan = Color3.fromRGB(0, 229, 255),
	Pink = Color3.fromRGB(255, 70, 200),
	Purple = Color3.fromRGB(150, 90, 255),
	Yellow = Color3.fromRGB(255, 214, 80),
	Green = Color3.fromRGB(80, 255, 160),
	Red = Color3.fromRGB(255, 80, 105),
	Text = Color3.fromRGB(242, 240, 255),
	Muted = Color3.fromRGB(150, 146, 190),
}

-- Animaciones oficiales de Roblox (se pueden usar en cualquier juego).
-- cat: baile | reaccion | pose · top = sale en la pestaña 🔥 TOP
local E = {}
local function add(cat, name, id, top)
	table.insert(E, { name = name, id = id, cat = cat, top = top == true })
end

add("baile", "Hips Poppin'", 10714364213, true)
add("baile", "Movimiento de cadera", 10713981723, true)
add("baile", "Take Me Under", 10714345459, true)
add("baile", "Bouncy Twirl", 14352343065, true)
add("baile", "Baile infantil", 10713983178, true)
add("baile", "Old Town Road", 10714391240, true)
add("baile", "Panini", 10714394082, true)
add("baile", "Floss", 10714340543, true)
add("baile", "Break Dance", 10714003221, true)
add("baile", "Robot", 10714392151, true)
add("baile", "HOLIDAY", 10714365721)
add("baile", "Country Line", 5915712534)
add("baile", "Saturday", 10714382522)
add("baile", "It Ain't My Fault", 10714374267)
add("baile", "Heart Skip", 11309255148)
add("baile", "Rise Above", 12992262118)
add("baile", "Dolphin Dance", 10714068222)
add("baile", "Hype Dance", 10714369624, true)
add("baile", "Mono", 10714388352)
add("baile", "Zombi", 10714089137)
add("baile", "Pirueta", 10714293450)
add("baile", "Baile aéreo", 10713957138)
add("baile", "Top Rock", 10714336041)
add("baile", "Pies sofisticados", 10714076981)
add("baile", "Ídolo", 10714372526)
add("baile", "Cha Cha Cha", 10714018192)
add("baile", "Marcando el compás", 10714380563)
add("baile", "¡A rockear!", 10714403700)
add("baile", "Shuffle", 10714371274)
add("baile", "Caminata flexible", 15505459811)
add("baile", "Line Dance", 10714383856)
add("baile", "Baile torpe", 10714069471)
add("baile", "Brisa fluida", 10714342957)
add("baile", "Saltos de tijera", 10714375667)
add("baile", "Salto de conejo", 10714004791)
add("baile", "Guitarra rock", 10714393929)
add("baile", "Solo de batería", 10714074218)
add("baile", "Guitarra invisible", 10713959108)
add("baile", "Baile 1", 507771019)
add("baile", "Baile 2", 507776043)
add("baile", "Baile 3", 507777268)

add("reaccion", "Hola", 10714359093)
add("reaccion", "Saludo de salto", 10714378156)
add("reaccion", "Saludo militar", 10714389988)
add("reaccion", "Aplauso", 10713966026)
add("reaccion", "Celebrando", 10714016223)
add("reaccion", "Salto de felicidad", 5895324424)
add("reaccion", "Estadio", 10714356920)
add("reaccion", "Ja ja", 10714350889)
add("reaccion", "Risa", 507770818)
add("reaccion", "Feliz", 10714352626)
add("reaccion", "Triste", 10714392876)
add("reaccion", "Aburrido", 10713992055)
add("reaccion", "Dormir", 10714360343, true)
add("reaccion", "Tímido", 10714369325)
add("reaccion", "Furtivo", 10714358528)
add("reaccion", "Acobardarse", 4940563117)
add("reaccion", "Vértigo", 10714066964)
add("reaccion", "De acuerdo", 10713954623)
add("reaccion", "No de acuerdo", 10714065135)
add("reaccion", "Encoger hombros", 10714374484)
add("reaccion", "Inclinación", 10714338461)
add("reaccion", "Apuntar", 10714395441)
add("reaccion", "Llamar", 10713984554)
add("reaccion", "¡Fuera!", 10714345862)
add("reaccion", "Más alto", 10714385204)
add("reaccion", "Educado", 10714061912)
add("reaccion", "Pescando", 10714101749)

add("pose", "Superhéroe", 10714355069, true)
add("pose", "Divino", 10714347256)
add("pose", "Aterrizaje de héroe", 10714360164)
add("pose", "Guerrero", 12507083048)
add("pose", "Patada escorpión", 13694096724)
add("pose", "Culturista", 10713990381)
add("pose", "El mejor", 10714349037)
add("pose", "Heisman", 10714357129)
add("pose", "A la moda", 10714091938)
add("pose", "Árbol", 10714330764)
add("pose", "Bengala", 10214311282)
add("pose", "Y", 10714164866)
add("pose", "T", 10714347453)

Config.Emotes = E

Config.Categories = {
	{ key = "all", label = "TODOS" },
	{ key = "fav", label = "⭐ FAVS" },
	{ key = "top", label = "🔥 TOP" },
	{ key = "baile", label = "💃 BAILES" },
	{ key = "reaccion", label = "😄 REACCIONES" },
	{ key = "pose", label = "🦸 POSES" },
	{ key = "custom", label = "🧩 MIS IDs" },
}

-- Trolleos: los aplica el servidor, así que los ven TODOS los jugadores
Config.Morphs = {
	{ key = "LongArms", label = "Brazos largos", icon = "💪" },
	{ key = "LongLegs", label = "Piernas largas", icon = "🦒" },
	{ key = "BigHead", label = "Cabezón", icon = "🎃" },
	{ key = "TinyHead", label = "Cabeza mini", icon = "🥜" },
	{ key = "Headless", label = "Sin cabeza", icon = "🙈" },
	{ key = "FloatHead", label = "Cabeza flotante", icon = "🎈" },
	{ key = "HeadInHand", label = "Cabeza en mano", icon = "🤲" },
	{ key = "Flat", label = "Aplastado", icon = "📄" },
	{ key = "Chubby", label = "Gordito", icon = "🍔" },
	{ key = "Noodle", label = "Fideo", icon = "🍜" },
	{ key = "Giant", label = "Gigante", icon = "🗿" },
	{ key = "Tiny", label = "Enano", icon = "🐜" },
	{ key = "Ghost", label = "Fantasma", icon = "👻" },
	{ key = "Rainbow", label = "Arcoíris", icon = "🌈" },
}

-- activar uno apaga los que chocan con él
Config.Exclusive = {
	Giant = { "Tiny" },
	Tiny = { "Giant" },
	BigHead = { "TinyHead" },
	TinyHead = { "BigHead" },
	HeadInHand = { "FloatHead" },
	FloatHead = { "HeadInHand" },
	Flat = { "Chubby" },
	Chubby = { "Flat", "Noodle" },
	Noodle = { "Chubby" },
}

return Config
