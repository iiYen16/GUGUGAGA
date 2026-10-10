# GUGU-GAGA

Menú con contraseña para tu propio juego de Roblox: intro con tu avatar, cinemática, emotes con sincronización entre miembros, movimiento, trolleos de cuerpo y lista de jugadores.

Este repositorio es la fuente del código. Se instala en Roblox Studio con una línea; el juego publicado usa lo que hay en el place, no GitHub.

## Dónde va cada cosa

| Archivo del repo | Objeto en Roblox Studio | Tipo |
| --- | --- | --- |
| `src/server/init.server.luau` | `ServerScriptService.GuguGagaServer` | Script |
| (solo en Studio, no se sube) | `ServerScriptService.GuguGagaServer.Secret` | ModuleScript |
| `src/shared/Config.luau` | `ReplicatedStorage.GuguGaga.Config` | ModuleScript |
| `src/client/modules/UI.luau` | `ReplicatedStorage.GuguGaga.Client.UI` | ModuleScript |
| `src/client/modules/Emotes.luau` | `ReplicatedStorage.GuguGaga.Client.Emotes` | ModuleScript |
| `src/client/modules/Movement.luau` | `ReplicatedStorage.GuguGaga.Client.Movement` | ModuleScript |
| `src/client/modules/Icons.luau` | `ReplicatedStorage.GuguGaga.Client.Icons` | ModuleScript |
| `src/client/modules/Intro.luau` | `ReplicatedStorage.GuguGaga.Client.Intro` | ModuleScript |
| `src/client/modules/Menu.luau` | `ReplicatedStorage.GuguGaga.Client.Menu` | ModuleScript |
| `src/client/GuguGagaClient.client.luau` | `StarterPlayer.StarterPlayerScripts.GuguGagaClient` | LocalScript |

El servidor crea al arrancar `ReplicatedStorage.GuguGaga.Remotes` (`Auth`, RemoteFunction, y `Net`, RemoteEvent) y `Workspace.GuguGagaMegaBase`. El cliente crea `PlayerGui.GuguGagaUI`. Ninguno de los tres se guarda en el place ni en el repo.

## Orden de arranque

1. `GuguGagaServer` carga `Secret` y `Config`, crea los Remotes y la base gigante.
2. `GuguGagaClient` espera los Remotes, carga los módulos (UI, Emotes, Movement, Icons, Intro, Menu) y crea `GuguGagaUI`.
3. `Intro.lock` pide la contraseña; el servidor la valida en `Auth`.
4. Con acceso: `Emotes.init`, `Movement.init`, `Icons.init`, `Intro.cinematic`, `Menu.build`.

Dependencias entre módulos (sin ciclos): `UI → Config` · `Emotes → Config` · `Movement → Emotes` · `Icons → UI, Emotes, Movement` · `Intro → Config, UI, Emotes` · `Menu → Config, UI, Emotes, Movement, Icons`.

## La contraseña

Vive solo en Studio, en `ServerScriptService.GuguGagaServer.Secret`. No está en este repositorio y el instalador no la toca. Si el módulo falta o la contraseña está vacía, el servidor avisa en la consola y rechaza todos los intentos.

`src/server/Secret.luau` es una copia local opcional y está en `.gitignore`; `Secret.example.luau` muestra el formato.

## Instalar o actualizar en Roblox Studio

1. Abre tu place en Studio, sin Play.
2. Game Settings → Security → activa «Allow HTTP Requests».
3. View → Command Bar, pega esta línea y pulsa Enter:

```lua
loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/iiYen16/GUGUGAGA/main/install.lua", true))()
```

4. Mira la ventana Output: dice qué scripts creó o actualizó.
5. La primera vez en un place nuevo: abre `ServerScriptService.GuguGagaServer.Secret` y escribe tu contraseña.
6. Prueba con Play. Cuando esté bien: File → Publish to Roblox.

El instalador ([install.lua](install.lua)) solo corre en Studio en modo edición. Descarga todo antes de tocar nada, guarda la versión anterior de cada script que cambia en `ServerStorage.GuguGagaRespaldos` y nunca toca `Secret`. Se deshace con Ctrl+Z.

GitHub tarda hasta unos 5 minutos en servir la versión nueva de un archivo después de un push.

## Subir cambios a GitHub

```bash
git add -A
```

```bash
git commit -m "describe el cambio"
```

```bash
git push
```

## Por qué el juego no descarga el código al jugar

La línea de arriba solo sirve en la barra de comandos de Studio. Dentro del juego no se usa porque:

- `game:HttpGet` no existe en Roblox; es una función de programas externos (executors).
- `loadstring` no existe en LocalScripts, y casi todo este sistema es código de cliente.
- En el servidor haría falta activar `LoadStringEnabled`, y quien controle el repo controlaría el servidor del juego.

El flujo es: cambiar el código → `git push` → línea del instalador en Studio → probar → publicar.

## Respaldo

`backup/GuguGagaInstalador.original.rbxm` es el instalador original (no se sube: lleva la contraseña dentro). En el place también está en `ServerStorage.GuguGagaInstalador`, desactivado.
