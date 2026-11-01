# CLAUDE.md — Fork personal de Caelestia Shell

Guía de contexto para trabajar en este repo. Léela entera antes de tocar código: resume la
arquitectura, los comandos de uso diario, las trampas ya descubiertas y todo lo que se cambió
respecto a upstream.

## Contexto del usuario

- Responde **en español**. El usuario (Iago) usa este fork en su laptop personal.
- Sistema: CachyOS (Arch), kernel CachyOS, GPU AMD, zona horaria `America/Montevideo`.
- Hyprland **0.56** con configuración en **Lua** (`~/.config/hypr/*.lua`), no en `hyprland.conf`.
- Shell interactiva: fish. Las herramientas de Claude ejecutan zsh: cuidado con globs que no
  matchean (`zz_*` sin resultados da error) y usa comillas en `--include='*.qml'`.
- Gestor de archivos: Thunar (`thunar.desktop` es el predeterminado para carpetas). Tema de
  iconos: Papirus-Dark. Terminal: foot. Lanzador de menús: rofi/fuzzel.
- Se probó **Loaf** (gestor de archivos en Rust + Qt) como reemplazo de Thunar y el usuario lo
  descartó porque no le funcionaron varias cosas: se quitó todo. No reintroducir sin que lo pida.
- Prefiere que se le pregunte antes de tocar cosas fuera del repo (config de Hyprland, `sudo`).
  Cualquier comando con `sudo` lo ejecuta él: dale el comando en un bloque `bash`.

## Repositorio

- Ruta: `~/.config/quickshell/caelestia` (quickshell lo encuentra como config `caelestia`).
- Rama de trabajo: **`mis-cambios`**. `main` sigue a upstream.
- Remotos: `origin` = `git@github.com:IagoMaSp/shell.git` (fork), `upstream` =
  `https://github.com/caelestia-dots/shell.git`.
- No hagas commits ni push salvo que el usuario lo pida.
- `~/.config/quickshell/custom-shell` es un symlink a `~/dev/custom-shell`, otro proyecto aparte
  (se ejecuta con `qs -p ~/dev/custom-shell`). No forma parte de este repo.

## Comandos frecuentes

```bash
# Reiniciar la shell (NO recarga sola al guardar archivos)
qs kill -c caelestia; caelestia shell -d

# Logs de la instancia en ejecución (filtrando ruido conocido)
qs log -c caelestia | grep -E "WARN|ERROR" | grep -v "notifications\|textinput\|\.face"

# Recompilar el plugin C++ (tarda ~30 s). Necesario solo si cambias plugin/
cmake --build build

# Verificar convenciones QML (orden de secciones e imports). Debe dar "No violations found."
python3 scripts/qml-lint-conventions.py
python3 scripts/qml-lint-conventions.py --fix --file ruta/al/archivo.qml   # --fix solo arregla imports

# IPC: listar targets/funciones y llamarlas
qs -c caelestia ipc show
qs -c caelestia ipc call notch open media      # toggle/open <página>/close/pages
qs -c caelestia ipc call keybinds toggle

# Disparar un atajo global de la shell como lo haría Hyprland (sintaxis Lua obligatoria)
hyprctl dispatch 'hl.dsp.global("caelestia:keybinds")'

# Hyprland
hyprctl reload && hyprctl configerrors
hyprctl binds -j            # atajos cargados (con descripción)

# Esquema de colores
caelestia scheme set -n hollowknight -f vessel -m dark
caelestia scheme set -n dynamic        # volver a colores del fondo de pantalla
```

### El plugin compilado y `QML_IMPORT_PATH`

El paquete AUR `caelestia-shell` **ya no está instalado** (se quitó el 2026-10-27: su versión
2.5.0 sacó `M3Shapes` a `qt6-m3shapes-git`, que chocaba con la 2.2.0 y bloqueaba `paru -Syu`). No
reinstalarlo. Del sistema solo se usan:
- `qt6-m3shapes-git` (módulo QML `M3Shapes`, en `/usr/lib/qt6/qml/M3Shapes`).
- `caelestia-cli` (comando `caelestia`, esquemas).
- Sus antiguas dependencias (`quickshell-git`, fuentes, `libcava`, `libqalculate`, `aubio`...),
  marcadas como explícitas.

El plugin C++ (`Caelestia.*`) está compilado en `build/qml` y **no está instalado** en el sistema
(no ejecutes `sudo cmake --install`). Se usa mediante:

```lua
-- ~/.config/hypr/hyprland/env.lua
hl.env("QML_IMPORT_PATH", "/home/iago/.config/quickshell/caelestia/build/qml")
```

Hyprland lanza la shell al iniciar sesión con `caelestia shell -d` (`hyprland/execs.lua`), que
ejecuta `qs -c caelestia -n -d` heredando esa variable. Las terminales abiertas desde Hyprland
también la tienen. Si un `qs` falla con `module "Caelestia.I18n" is not installed`, falta la
variable: lanza con `QML_IMPORT_PATH=$PWD/build/qml qs -c caelestia -n -d`.
Si se borra `build/`, la shell no arranca hasta volver a compilar. Tras un `paru -Syu` que suba
Qt de versión (p. ej. 6.12 → 6.13), recompila con `cmake --build build` y reinicia la shell.

### Probar cambios sin tocar la shell del usuario

Patrón usado con éxito: crear un `zz_*.qml` temporal en la raíz del repo (para que resuelvan los
imports `qs.*`), lanzarlo como instancia separada y borrarlo después.

```bash
cat > zz_test.qml <<'EOF'
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.notch.pages.calendar

ShellRoot {
    FloatingWindow {
        title: "Dash test"
        implicitWidth: 760
        implicitHeight: 440
        color: Colours.tPalette.m3surface
        contentItem.Config.screen: screen?.name ?? ""
        contentItem.Tokens.screen: screen?.name ?? ""
        Week { anchors.fill: parent; anchors.margins: 20 }
    }
}
EOF
QML_IMPORT_PATH=$PWD/build/qml timeout 14 qs -p $PWD/zz_test.qml > log.txt 2>&1 &
sleep 7
G=$(hyprctl clients -j | python3 -c "import json,sys
for c in json.load(sys.stdin):
    if c['title']=='Dash test': print('%d,%d %dx%d'%(c['at'][0],c['at'][1],c['size'][0],c['size'][1]))")
grim -g "$G" captura.png      # captura SOLO esa ventana
rm -f zz_test.qml
```

- **Nunca hagas `grim` de la pantalla completa**: captura lo que el usuario tenga abierto.
  Captura solo la geometría de la ventana de prueba.
- Para aislar datos (p. ej. un calendario khal de prueba), lanza con `XDG_CONFIG_HOME=<dir>`
  apuntando a una config falsa. Ojo: entonces la shell no ve el tema de iconos ni `shell.json`.
- Ventanas con fondo opaco (`color: Colours.palette.m3surface`) para no capturar lo de detrás.
- Los archivos temporales van al scratchpad de la sesión, no a `/tmp` ni al repo.

## Arquitectura

QML (Quickshell) + plugin C++ propio (módulos QML `Caelestia.*`).

```
shell.qml            Punto de entrada: ShellRoot que instancia módulos y daemons
modules/             Funcionalidades visibles (cada carpeta = módulo qs.modules.<nombre>)
  drawers/           Ventana principal por pantalla que aloja los paneles deslizables
  bar/               Barra (componentes + popouts)
  notch/             [fork] Isla superior (reemplaza al dashboard y al OSD): ver sección Notch
  calendar/          [fork] Ventana flotante de eventos del día + importador .ics
  keybinds/          [fork] Menú de atajos de teclado (Super + F1)
  launcher/ sidebar/ utilities/ notifications/ session/ lock/ background/
  areapicker/ windowinfo/ nexus/ (ajustes)
services/            Singletons de datos (qs.services): Audio, Colours, Weather, Players...
  Events.qml         [fork] Eventos de calendario vía khal
components/          Componentes reutilizables (qs.components, .controls, .containers...)
utils/               Utilidades (Paths, Icons, Strings...) y scripts JS (fzf, fuzzysort)
daemons/             Lógica en segundo plano (Shortcuts, IdleMonitors, BatteryMonitor...)
assets/              Recursos y scripts de runtime (import-ics.py, schemes/, pam.d...)
scripts/             Herramientas de desarrollo (linter QML, traducciones, generador de esquema)
plugin/src/Caelestia/ Plugin C++: Config (config + tokens), I18n, Services, Components...
build/               Salida de CMake; build/qml es el plugin que usa la shell
```

### Conceptos clave

- **Singletons**: cualquier `.qml` con `pragma Singleton` dentro de una carpeta-módulo queda
  disponible por nombre al importar ese módulo (`import qs.services` → `Events`, `Colours`...).
  No hace falta `qmldir`.
- **Módulos nuevos**: crear `modules/<nombre>/` e instanciar en `shell.qml` (importar
  `qs.modules.<nombre>`).
- **Config de usuario** (`Config.*`, `GlobalConfig.*`): `~/.config/caelestia/shell.json`,
  definida en C++ (`plugin/src/Caelestia/Config/*config.hpp`). La shell avisa
  `Unknown option` si hay claves obsoletas.
- **Tokens** (`Tokens.*`): tamaños, espaciados, fuentes, curvas y duraciones de animación.
  Defaults en `plugin/src/Caelestia/Config/tokens.hpp`; overrides en
  `~/.config/caelestia/shell-tokens.json`. Ventanas propias deben fijar
  `contentItem.Config.screen` y `contentItem.Tokens.screen`.
- **Colores**: `Colours.palette.m3*` (Material 3) y `Colours.tPalette` (con transparencia).
  [fork] Tema fijo Hollow Knight: `Colours` ya NO lee `scheme.json`; carga
  `assets/schemes/hollowknight/<flavour>/dark.txt` según `Hallownest.flavour` (vessel,
  lifeblood, infection, greenpath), guardado en `~/.local/state/caelestia/hallownest.json`.
  Se cambia con `qs -c caelestia ipc call hallownest flavour <nombre>` o en Settings del notch;
  `Hallownest.setFlavour` también ejecuta `caelestia scheme set -n hollowknight -f <flavour>`
  para que GTK/Qt/terminal sigan el tema. El selector de esquemas de Nexus, `>scheme` del
  launcher y el modo claro solo afectan a las otras apps (la shell los ignora).
- **Animaciones**: `Anim { type: Anim.DefaultSpatial }` / `CAnim` para colores. Los tipos se
  mapean a curvas y duraciones de los tokens.
- **Atajos globales**: `CustomShortcut { name: "x" }` registra `caelestia:x`; en Hyprland se
  enlaza con `hl.dsp.global("caelestia:x")`.
- **IPC**: `IpcHandler { target: "x"; function f(): void {...} }` → `qs -c caelestia ipc call x f`.
- **Procesos externos**: `Process { command: [...]; stdout: StdioCollector { onStreamFinished: ... } }`.
  No cambies `command` mientras corre: encola y relanza en `onExited`.
- **Ventanas**: `StyledWindow` (layer-shell; `WlrLayershell.layer`/`keyboardFocus`) para
  overlays; `FloatingWindow` para ventanas normales (Hyprland las hace flotar por la regla de
  clase `org.quickshell`). Envolver en `LazyLoader` para crearlas bajo demanda.
- **Notificaciones internas**: `Toaster.toast(titulo, texto, icono)`.
- **Scripts de runtime**: ponerlos en `assets/` y referenciarlos con
  `Quickshell.shellPath("assets/x.py")`.

### Librería Hallownest (`components/hallownest/`, `import qs.components.hallownest`)

Componentes propios con la paleta fija `Hallownest` (`services/Hallownest.qml`: colores,
`serif` = Cinzel, `mono`, flavour). Úsalos en vez de los controles M3 de `components/controls`
al rediseñar módulos.

| Componente | Para qué |
|---|---|
| `HkButton` | Píldora: `icon`, `text`, `filled`, `tinted` + `accent`, `disabled`, `iconAfter` |
| `HkField` | Campo de texto en píldora (`leadingIcon`) |
| `HkSwitch` | Interruptor con rombo (`checked`, señal `toggled(checked)`) |
| `HkStepper` | − valor + (`value`, `from`, `to`, `stepSize`, `suffix`, señal `moved`) |
| `HkSlider` | Barra fina con punta de Aguijón (`value`, `colour`, señal `moved`) |
| `HkCheck` | Círculo de color que se rellena con check |
| `HkSelect` | Desplegable (`options` strings u objetos `{text}`, `currentIndex`, `activated`) |
| `HkCard` | Tarjeta oscura con borde; `ornate` añade filigrana |
| `HkRow` | Fila de ajustes (`text`, `subtext`, `icon`, `first`/`last` redondean el grupo; hijos a la derecha) |
| `HkSection` / `HkTitle` | Cabecera de sección / título en Cinzel |
| `Filigree` | Ornamento de esquinas inferiores (`radius`, `inset`) |
| `CharmNotches` | Muescas de amuleto con flechas (`notches`, `current`, `selected`, `stepped`) |
| `IslandShape` | Forma pegada al borde superior con fillets (`w`, `h`, `radius`, `leftFillet`, `rightFillet`) |
| `SoulVessel` / `SoulParticles` | Orbe con líquido / partículas de Alma |
| `HkSelection` | Resaltado de lista con punteros ornamentados (`radius`, `inset`, `colour`) |
| `HkToggle` | Botón de icono con estado (`icon`, `checked`, `isToggle`, `accent`) |
| `HkRadio` | Opción con rombo que se rellena (`checked`, `text`, `accent`, señal `clicked`) |
| `HealthMask` | Máscara de vida: dibujo del usuario (`assets/hallownest/health-mask.svg`, recortado de `~/Pictures/InkScape/healthMask.svg`: PNG incrustado + calco vectorial); `filled`, `colour` (tinte), `glow` |
| `Mask` | Máscara de vida (silueta del Caballero con ojos): `filled`, `colour`, `glow`, `size` |

Etapa 3 (rediseño por módulos), hecho hasta ahora:
- Barra: workspaces como máscaras de vida del juego (`HealthMask`, forma de huevo con punta y
  ojos ovalados; en `Workspace.qml`, `shapeComponent`: activa blanca con brillo, ocupada acero,
  vacía apagada). El usuario rechazó las cabezas del Caballero ahí; indicador activo = píldora tenue con borde. Batería =
  mini `SoulVessel` (`ornate: false`; Lifeblood cargando, rojo ≤20 %). Apagado dentro de un
  rombo rojo Grimm.
- Popouts de la barra: cabeceras en Cinzel acero; dispositivos de audio con `HkRadio` (rombo),
  volumen con `HkSlider` Lifeblood, interruptores `HkSwitch`, "Open settings" como `HkButton`
  teñido; reescanear redes y selector de perfil de energía con píldoras tenues. `TrayMenu`,
  `ActiveWindow` y `WirelessPassword` solo heredan la paleta.
- Launcher: la selección es `HkSelection` (fondo tenue + punteros en rombo a los lados que
  laten, como en los menús del juego); los ítems dejan 16 px extra a cada lado para ellos. Nombre
  en blanco Alma, descripción gris, favoritas = rombo dorado. `SearchBar` (compartida con Nexus
  y el menú de atajos): fondo `card`, borde acero que pasa a Alma con foco. Estado vacío con
  título en Cinzel.
- Utilidades: toggles rápidos con `HkToggle` (tarjeta con icono y rombo bajo el icono cuando
  está activo), "Keep awake" con `HkSwitch`, tarjetas con borde acero, cabecera en Cinzel.
- Toasts de la shell (`utilities/toasts/ToastItem.qml`): fondo Vacío, icono en rombo y borde del
  color del tipo (info Alma, éxito Unn, aviso Oro, error Grimm), título en Cinzel.
- Dock de notificaciones del sidebar: cabecera y contador en Cinzel, grupos como tarjetas con
  borde, botón de limpiar `HkButton`; sin notificaciones muestra una `Mask` apagada y "All up to
  date!" en Cinzel (ya no usa `Config.paths.noNotifsPic`).
- Notificaciones emergentes (`notifications/Notification.qml`): fondo Vacío con borde acero;
  críticas con tinte y borde rojo Grimm. Título en Cinzel (rojo si es crítica), icono de app sobre
  círculo tenue, acciones como `HkButton` en un `RowLayout`. Las del dock usan la misma paleta.
- Menú de sesión (`session/Content.qml`): `SessionButton` propio (tarjeta 80 px con icono y
  etiqueta en Cinzel; enfocado o con hover se ilumina en su color: Logout Alma, Shutdown Grimm,
  Hibernate Lifeblood, Reboot Oro) y rombo indicador a la izquierda del enfocado. El hover da el
  foco; teclado (flechas, Tab, vim) igual que antes.

## Convenciones de código

- Orden dentro de cada objeto QML: `id`, propiedades, señales, funciones, bindings, hijos,
  `component`s, con una línea en blanco entre secciones. Imports ordenados (`qs.services` antes
  que `qs.modules.*`). Verificar con `scripts/qml-lint-conventions.py`.
- `pragma ComponentBehavior: Bound` y `required property` en delegados; referenciar por `id`
  (`root.x`, `card.modelData`).
- Textos de UI con `Tr.tr("English text")` / `Tr.trCtx(...)`: la UI de la shell está en inglés
  (`LANG=en_US`). Los datos del usuario (descripciones de atajos, eventos) van en español.
- Fechas visibles: `Qt.locale().toString(date, "d MMMM yyyy")` (sale en español como el
  calendario). `Qt.formatDate` usa otra locale y mezcla idiomas.
- Indentación de 4 espacios (`.editorconfig`); JSON/YAML/nix con 2.
- Comentarios escasos y en inglés, como el resto del código.

### Trampas conocidas (ya costaron tiempo)

- **Tokens inexistentes**: `Tokens.spacing` y `Tokens.padding` NO tienen `normal`. Válidos:
  `extraSmall, small, medium, large, largeIncreased, extraLarge, extraLargeIncreased,
  extraExtraLarge`. Un token inexistente da `Unable to assign [undefined]`.
- **JS de Qt (V4)**: no hay `String.matchAll` ni `Array.flatMap`. Usa `exec` en bucle y
  `reduce/concat`.
- **`list<var>`**: las propiedades y parámetros `list<var>` no tienen todos los métodos de array.
  Usa `property var` / parámetros `var` para arrays JS.
- **Crash de Qt**: `maximumLineCount` con `NaN` (p. ej. dividir por `fontInfo.pixelSize` antes
  del layout) tumba quickshell con SIGSEGV en `QTextLine`. Usa valores enteros seguros.
- **`.arg()` encadenado**: `.arg("%1").arg(x)` vuelve a sustituir el `%1` insertado.
- **`hyprctl dispatch`** en Hyprland Lua requiere sintaxis Lua:
  `hyprctl dispatch 'hl.dsp.exec_cmd("...")'`.
- **Bug del plugin**: si `shell-tokens.json` contiene `appearance.curves`, la shell reescribe el
  archivo dejando las curvas en `null`. Las curvas se cambian en `tokens.hpp` + recompilar; en el
  JSON solo poner duraciones (enteros funcionan).
- **Dos instancias**: lanzar `qs -p .` con la shell ya corriendo duplica la barra y da
  `Could not register notification server`. Usa `qs kill -c caelestia` antes o `-n`.
- **Iconos rotos** (cuadrados negro/magenta) en el `FileDialog` propio de la shell: no encuentra
  el tema de iconos de Qt. Por eso el importador usa zenity (selector GTK).
- `Failed to open VDPAU backend libvdpau_nvidia.so` es inofensivo (GPU AMD).

## Cambios del fork respecto a upstream

### Eliminado
- GIF de `kurukuru` en el menú de sesión (`modules/session/Content.qml`) y `bongocat` del
  dashboard. Los assets `.gif` siguen en `assets/` sin uso.
- **Dashboard** (`modules/dashboard/`) y **OSD lateral** (`modules/osd/` ya no se instancia):
  sustituidos por el notch. Sus restos se quitaron de `modules/drawers/` (`Panels`, `Regions`,
  `Interactions`, `ContentWindow`). `ScreenState.dashboard/osd/dashboardTab/dashboardKeyboard`
  ya no existen. La entrada "Dashboard" de Nexus sigue pero no hace nada.
- Página Water del notch: se descartó por decisión del usuario. No reintroducir sin que lo pida.
- Sincronización con Google Calendar (vdirsyncer): se implementó y se quitó por decisión del
  usuario. No reintroducir sin que lo pida.
- Apuntes automáticos de clases (grabación con `pw-record`, whisper.cpp y resumen con
  `claude -p`; servicio `Lectures`, tarjeta de utilidades, píldora de barra, atajo
  `Super + Shift + R`): se quitó porque consumía demasiado de la cuenta de Claude. No
  reintroducir sin que lo pida.

### Calendario y eventos (khal)
- Backend: **khal** (`~/.config/khal/config`, calendario `private` en
  `~/.local/share/khal/calendars/private`). Formatos de fecha `%d/%m/%Y`, hora `%H:%M`.
- `services/Events.qml`:
  - Deriva los formatos Qt de `khal printformats`.
  - Lista con `khal list` usando separadores de control (`\x1d` día, `\x1e` registro,
    `\x1f` campo), porque la salida `--json` de khal no indica el día de los eventos multi-día.
  - `loadRange(key, start, end)` / `loadMonth(y, m, key)`: cada vista pide su rango
    (`calendar`, `week`, `window`) y se carga la unión.
  - `add()` usa `khal new` con `--repeat weekly --until`. **khal corta el `UNTIL` a las 00:00
    del día dado**, así que se suma 1 día para que la fecha límite sea inclusiva.
  - `remove(uid)` borra el `.ics` vía script Python (`khal.settings.get_config`); borra todas
    las repeticiones.
  - `importFile(path)` ejecuta `assets/import-ics.py`.
  - Recarga cada 15 min.
- `assets/import-ics.py`:
  - Recorta basura tras `END:VCALENDAR`.
  - Reemplaza TZIDs estilo Windows (`(UTC-03:00) Montevideo`, con reglas DST obsoletas que
    adelantaban todo 1 hora) por la zona IANA y elimina ese VTIMEZONE.
  - Importa con `khal import --batch` (si se reimporta, actualiza por UID) y borra los restos
    `<uid>.ics<8 chars>` que khal 0.14 deja al actualizar.
  - Probado con el horario de la Universidad de Montevideo (`~/Downloads/2026_sem2_*.ics`).
- `modules/calendar/`:
  - `EventsWindow` (singleton; ventana flotante del día).
  - `DayEvents` (lista de eventos + formulario: todo el día, semanal + "hasta", lugar, notas).
  - `ScheduleImporter` (singleton; zenity `--file-selection` con fallback al `FileDialog`).
- `modules/notch/pages/calendar/MonthGrid.qml` (antes `dash/Calendar.qml`): puntos de color en
  días con eventos; clic en un día abre `EventsWindow`. Mes en `ScreenState.calendarDate`.
- `modules/notch/pages/calendar/Week.qml`: vista semanal (lunes a domingo según la locale):
  - Rejilla de horas, 8–20 por defecto; se amplía si hay eventos fuera de ese rango.
  - Bloques por evento, con carriles para los que se solapan.
  - Franja de eventos de todo el día.
  - Línea de la hora actual.
  - Navegación por semanas y botón de importar `.ics`.
- `modules/notch/pages/Calendar.qml`: mes a la izquierda, semana a la derecha.
- Fuera del repo: `~/.local/bin/caelestia-add-event` (rofi + `khal new`, atajo
  `Super + Ctrl + E`).
- **Editar eventos**: lápiz en cada tarjeta de `DayEvents` → el mismo `EventForm` con `event`
  precargado, en el lugar de la tarjeta. `Events.update(uid, data)` ejecuta
  `assets/edit-event.py`, que modifica el `.ics` en su sitio con `icalendar` (conserva UID,
  zona horaria, `BYDAY`, alarmas, excepciones; sube `SEQUENCE`). En series los cambios aplican
  a todas las repeticiones y se mantiene el día de inicio; `COUNT` se conserva salvo que se
  toque "Until"; `UNTIL` inclusivo (23:59:59 local en UTC). Reimportar el `.ics` de la facultad
  pisa las ediciones de esos eventos (mismo UID).
- Ideas pendientes: borrar de una vez todo lo importado de un archivo.

### Notch (isla superior, estilo Nusa)
- `modules/notch/`: `Notch.qml` (una `NotchWindow` por pantalla + `IpcHandler` `notch`:
  `toggle`, `open <página>`, `close`, `pages`), `NotchWindow.qml`, `Collapsed.qml` (reloj +
  cuenta del pomodoro + indicador de música), `PageDots.qml`, `NotchPages.qml` (lista de
  páginas), `NotchPage.qml` (base), `mascot/Knight.qml`, `pages/`.
- Ventana layer-shell anclada arriba, tamaño fijo, `mask` = solo la píldora (+ píldora de
  letras). Forma: `Shape` pegada al borde superior con esquinas cóncavas (`fillet`) y solo las de
  abajo redondeadas. Escala con `NotchSettings.scale` (transform del contenido).
- Estados de la píldora colapsada, por prioridad: alerta To-Do (`alertShown`, no se expande al
  hover para poder pulsar los botones) > OSD (`osdShown`) > mascota (`mascotShown`) > reloj.
  `minimal` = línea fina. Se expande con hover (80 ms de entrada, 250 ms de salida), con
  `ScreenState.notch` (atajo `caelestia:notch`, fija abierto hasta `Esc`/clic fuera), al
  arrastrar algo encima y mientras se arrastra desde el Shelf. Oculta en pantalla completa.
- Navegación: cabecera arriba (título de página en Cinzel a la izquierda, muescas de amuleto
  en rombo al centro con flechas < >, fecha + hora a la derecha), rueda, flechas del teclado.
  El usuario prefiere la navegación arriba (no abajo como Nusa).
- Estilo Hollow Knight con colores **fijos** (no siguen el esquema): `services/Hallownest.qml`
  (Negro Vacío, Acero de Aguijón, Alma, Lifeblood, Infección, colores de amuletos; `serif` =
  Cinzel cargada con `FontLoader` desde `assets/fonts/cinzel/`, OFL). Fondo `void_`, borde
  acero al 15 %, sombra amplia que pasa a brillo Lifeblood con música o pomodoro activos,
  filigrana en las esquinas inferiores al expandir (`component Filigree`).
- Rediseño estilo Nusa + Hollow Knight hecho en 4 fases (A contenedor/cabecera, B colapsado +
  caras, C Media + isla de letras, D productividad + alertas). Water sigue descartado.
  Iconos del clima (`pages/weather/WeatherIcon.qml`) dibujados con `Shape` en un lienzo de
  48 unidades (trazo fino Alma + brillo): orbe con rayos, luna creciente con estrellas en
  rombo, nube oscura con contorno, gotas Lifeblood, copos en rombo Cristal, rayo que destella,
  niebla y viento ondulantes. Un solo `t` en bucle mueve todo; `ambient` (icono principal)
  anima siempre y los del pronóstico solo con hover. Los iconos sin dibujo caen al glifo.
  Todas las páginas usan la paleta fija `Hallownest` (no `Colours`). Settings usa filas propias
  (`SettingRow`, interruptor con rombo, contador −/+) en vez de los de Nexus.
- Pomodoro: `SoulVessel` que se vacía (naranja Infección en foco, Lifeblood en descanso), hora
  grande en Cinzel, botones reset/play/selector de modo/saltar.
- To-Do: dos columnas (tarjeta con `X/Y` en Cinzel, barra, Add task, Clear done + lista de
  píldoras con círculo de color). Colores = amuletos (`grimm`, `gold`, `unn`, `crystal`, `steel`).
- Shelf: dos columnas (contador grande + Remove/Clear, tarjetas `card` con miniatura/icono,
  nombre y tamaño). `Shelf` guarda `size` (`du -sb`) junto al MIME; `sizeStr()` lo formatea.
- Alertas ricas (`richOsd`, 64 px): Bluetooth (círculo Lifeblood con `headphones` si el
  `icon` del dispositivo es de audio, nombre y "Connected · 70%") y cargador ("Soul Restoring",
  porcentaje en Cinzel y pila dibujada). Al enchufar: destello radial blanco (`benchFlash`).
  El resto de avisos usa la vista simple con la paleta.
- Forma: `IslandShape.qml` (fondo `void_`, borde acero, `leftFillet`/`rightFillet` separados).
  La usan el notch y la isla de letras.
- Media (estilo Nusa): carátula 56 px, título/artista, volumen al pasar el ratón, `NailSlider`
  (barra fina con punta de Aguijón y guarda, también para volumen), píldora "Lyrics" y
  controles con play redondo blanco.
- Isla de letras (sustituye a la píldora bajo el notch): segunda `IslandShape` a 10 px a la
  derecha (el fillet de los lados enfrentados baja a 4 px para que la brecha llegue limpia al
  borde superior). Cerrado: línea actual (`islandShown` = letras activas + reproduciendo +
  hay letras); clic abre Media. Abierto en Media: 4 líneas centradas (`StrictlyEnforceRange`),
  actual en blanco negrita con niebla radial (`highlight`), el resto al 35 %; clic = seek.
- Para probar Media sin tocar el bus del usuario: `dbus-run-session` con el MPRIS falso y una
  copia temporal `ZzNotchWindow.qml` con `hasFullscreen: false` si hay una ventana a pantalla
  completa (si no, el notch está oculto y no se expande).
- Colapsado (`Collapsed.qml`): hora en JetBrains Mono, pomodoro naranja Infección (foco) /
  Lifeblood (descanso) y `MiniEqualizer` (4 barras reales de Cava vía `ServiceRef` solo mientras
  suena, con brillo y `SoulParticles` subiendo). `mascot/SoulParticles.qml` es reutilizable.
- **Trampa**: Quickshell solo empaqueta los QML alcanzables estáticamente. Las páginas se
  declaran como `Component { Pages.X {...} }` en `NotchWindow` (`pageComponents`); un `Loader`
  con `source:` por URL no encuentra los componentes de subcarpetas. Tras mover un archivo con
  `mv` (mtime viejo) puede hacer falta `touch`.
- Servicios (`services/`), estado en `~/.local/state/caelestia/notch/`:
  - `NotchSettings`: `config.json`; página **Settings** del notch, cambios en caliente.
  - `NotchMedia`: reproductor activo, letras (singleton C++ `Lyrics`, backend lrclib) y refresco
    de posición por contador `positionUsers` (solo con página Media o píldora de letras).
  - `NotchOsd`: avisos efímeros (volumen, mic, brillo, Caps Lock, layout, cargador, Wi-Fi,
    Bluetooth), con toggle cada uno. Ignora eventos los primeros 3 s. Si el aviso del cargador
    está activo, `BatteryMonitor` no muestra su toast.
  - `Shelf`: `shelf.json`, solo rutas `file://` y textos; MIME con `file --mime-type`. Arrastrar
    fuera = copia y quita del shelf; soltar sobre el propio notch cancela.
  - `Pomodoro`: `pomodoro.json`; sonido `pw-play complete.oga`; aviso por `NotchOsd`.
  - `Todos`: `todos.json`; hora límite `HH:MM` (si ya pasó, mañana); `Timer` single-shot a la
    próxima; alerta *Time's up!* con Snooze (`snoozeMinutes`), sonido `alarm-clock-elapsed.oga`.
    Las tareas hechas de días anteriores se borran al cargar.
- Mascota (`mascot/Knight.qml`): formas tomadas de `~/Downloads/hollow.svg` (dibujo del usuario
  en Inkscape; trazados `PathSvg` en coordenadas del SVG). Ojos = hueco: borde gris + elipse negra,
  tapados por un anillo color cabeza (relleno par-impar) para que el negro no se salga del borde.
  Expresiones `open`/`happy` (^)/`dizzy` (espirales que giran). Respira con squash & stretch,
  parpadea, acciones aleatorias (mirar a los lados, inclinar, saltito, feliz, mareado), bosteza al
  dormirse, se balancea con música. Es más alta que la píldora: los cuernos asoman sobre el borde.
- Aparece por inactividad (`IdleMonitor`, `mascotDelay`/`dozeDelay`) y en visitas aleatorias
  (`mascotRandom`, cada 1–3 min durante 12–30 s, se despide con un saltito). `ipc call notch
  mascot` fuerza una visita. Ojos siguen al ratón (`mascotTracking`) solo mientras se mueve
  (`cursorMoving`, 2 s): `j/cursorpos` por el socket de Hyprland (`Socket` de Quickshell, sin
  procesos) cada 60 ms con la mascota visible. Quieto, mira a los lados al azar (`idleX/idleY`).
- Colores de la mascota fijos (cabeza `#daebeb`, borde `#4d4d4d` del SVG) y mezclados con
  `soulness` (Alma: blanca brillante con partículas) y `voidness` (Vacío: negra con ojos
  blancos). Dormido = ojos cerrados en arco (`closed` cuando `lid` < 0.5) y tres "z" en Cinzel.
  Aburrido (`stare`) = párpado gris (`lidShade`). Enfadado = `sadTilt` negativo + símbolo de ira
  rojo (`anger`). Nervioso (`shocked`) = pupilas pequeñas, gotas de sudor y líneas de temblor;
  también al despertarlo de golpe mientras duerme. Reacciones: cargador y fin de foco → `soul`,
  fin de descanso y Snooze de un To-Do → `angry`, Wi-Fi perdido → `shocked`; `void` aparece
  al azar.
- Caras extra de `~/Downloads/HollowGuide.svg`: decepcionado (`droop`: párpado plano por `clip`),
  llorando (`sadTilt` + `tears` + `stream`/`drip`), infectado (expresión `infected`, ojos naranjas
  que laten). Acciones aleatorias nuevas: `sigh`, `stare`.
- Reacciones: `services/Mascot.qml` deja una reacción pendiente (`pending`, caduca a 60 s) y la
  `NotchWindow` de la pantalla enfocada la reproduce (`knight.react`) cuando puede mostrar la
  mascota, después del OSD. Disparadores: avisos de `NotchOsd` (cargador, Wi-Fi, Bluetooth,
  pomodoro), batería ≤15 % (llora) y ≤5 % (infectado), cambio de canción (cada 3 min como
  máximo) y todas las tareas hechas. Toggle `mascotReactions`. Prueba:
  `qs -c caelestia ipc call notch react <happy|vibe|sad|cry|infected>`.
- `NotchOsd` pone siempre `utilities.toasts.capsLockChanged = false`: Caps Lock solo se avisa en
  el notch (toggle `osdCapsLock`).
- Batería baja: `BatteryMonitor` usa los `warnLevels` de `shell.json` y, con `osdBattery`, llama a
  `NotchOsd.showBattery(title, message, icon, value, critical)` en vez del toast (también el
  aviso de hibernación). Vista rica en el notch (título, mensaje naranja, pila roja) 6 s, 9 s si
  es crítica.
- Para probar sin tocar los datos del usuario: `XDG_STATE_HOME=<scratch>` (copiar
  `scheme.json` dentro) y un `zz_*.qml` que cree `NotchWindow` y capture
  `win.contentItem.children[0].grabToImage(...)`. Para probar Media sin reproductor: un servicio
  MPRIS falso con `gi.repository.Gio`.

### Menú de atajos (Super + F1)
- `modules/keybinds/Keybinds.qml`:
  - Overlay en la pantalla enfocada.
  - `CustomShortcut` `caelestia:keybinds`.
  - `IpcHandler` `keybinds.toggle`.
- `KeybindsContent.qml`:
  - Lee `hyprctl binds -j` y muestra solo los binds con descripción, agrupados por sección.
  - Buscador que ignora tildes.
  - Colapsa `Super + 1…0` y las flechas.
  - `Esc`/clic fuera para cerrar.
- Las descripciones viven en `~/.config/hypr/hyprland/keybinds.lua`: `create_bind(keys, action,
  flags, "Sección|Descripción")` (4.º argumento; usar `nil` como `flags` si no hay). Un atajo sin
  descripción no aparece en el menú. Hyprland 0.56 acepta `description` en las opciones de
  `hl.bind`. Backup: `keybinds.lua.bak-descripciones`.

### Página AI del notch
- `modules/notch/pages/Ai.qml` (página **AI**, icono `smart_toy`). Selector de proveedor: **Claude Code** (`claude`) y **Antigravity** (`agy`,
  en `~/.local/bin`; sin app de escritorio instalada).
  - Botones Terminal, App (solo si existe `claude-desktop`/`antigravity`) y Continue.
  - Chips de carpeta (home + cwd de sesiones recientes, sin worktrees) y "Other..." con zenity.
  - Campo de prompt (`claude "<texto>"` / `agy -i "<texto>"`).
  - Sesiones recientes; clic → `claude --resume <id>` / `agy --conversation <id>` en su cwd.
- `services/AiAgents.qml`: proveedores, detección de binarios/versiones y lanzadores. El
  proveedor elegido se guarda en `~/.local/state/caelestia/ai-provider`.
- `assets/ai-sessions.py <claude|antigravity>`: Claude lee `~/.claude/projects/*/*.jsonl` (solo
  cabeza y cola: pesan decenas de MB); Antigravity lee
  `~/.gemini/antigravity-cli/conversation_summaries.db` (sqlite).
- **Trampa**: `Quickshell.execDetached({command, workingDirectory})` falla aquí
  (`Could not convert argument 0 ... ProcessContext`) y no lanza nada. Para el cwd se usa
  `sh -c 'cd "$1" && shift && exec "$@"'`.
- Teclado: la ventana del notch es `OnDemand` mientras está expandida; al enfocar el campo de
  prompt se fija abierto (`ScreenState.notch = true`).
- Para capturar pruebas sin tocar la pantalla del usuario: `item.grabToImage(r =>
  r.saveToFile(...))` desde el `zz_*.qml`, en vez de `grim`.

### Calculadora directa en el launcher
- `modules/launcher/AppList.qml`: `isMath(text)` detecta cuentas sin `>calc ` (operadores entre
  números, `10 km to mi`, `15% of 200`, `5!`, `√2`, `sqrt(16)`, o texto que empieza con `=`) y
  pasa al estado `calc`. `calcExpression` es la expresión (con o sin prefijo).
- `items/CalcItem.qml` usa `list.calcExpression` y evalúa también al crearse. `Content.qml`:
  Enter en estado `calc` copia el resultado.
- Casos que NO deben disparar: `7-zip`, `2048`, `3 in 1 printer`.

### Búsqueda web en el launcher
- `AppList.qml`: estado `web` si el texto no coincide con ninguna app (y no es cuenta ni empieza
  por `@`), o con el comando `>web <texto>`. `webQuery` es el texto sin prefijo.
- `items/WebItem.qml`: "Search …" / "Open …" (si parece URL: `dominio.tld`, `http(s)://`,
  `localhost`). `Content.qml`: Enter en estado `web` lo abre; **Shift+Enter** busca en la web
  aunque haya apps que coincidan.
- `services/WebSearch.qml`: `zen-browser --new-tab <url>` (abre pestaña en la instancia abierta o
  arranca el navegador; Hyprland lo enfoca por `focus_on_activate`). Buscador: Google.
- La acción "Web search" se añade desde `services/Actions.qml` (no está en los defaults C++).
- Búsqueda por sitio: `@yt gatos`, `@reddit …` o `@<nombre sin espacios> …` usan los motores
  de búsqueda propios de Zen. `assets/zen-engines.py` los lee del `search.json.mozlz4` del
  perfil por defecto (descompresor LZ4 propio, sin dependencias) y `WebSearch.siteSearch()` los
  matchea; se recargan al entrar en estado `web`. Los filtros de una letra (`@i`, `@c`...) del
  buscador de apps siguen funcionando porque solo se activa con un alias conocido.

### Tema Hollow Knight
- Esquema en `assets/schemes/hollowknight/<flavour>/dark.txt`, generado por
  `scripts/gen-hollowknight-scheme.py`: editar colores ahí y regenerar.
  - Base: negro vacío `#0b0b0e`, superficies carbón, texto hueso `#e9e6df`.
  - Flavours: `vessel` (blanco/gris), `lifeblood` (celeste), `infection` (naranja),
    `greenpath` (verde).
  - Solo modo oscuro.
- La CLI solo lee esquemas de `/usr/lib/python3.14/site-packages/caelestia/data/schemes/`.
  Instalación (la hace el usuario, una vez):
  `sudo ln -s ~/.config/quickshell/caelestia/assets/schemes/hollowknight
  /usr/lib/python3.14/site-packages/caelestia/data/schemes/hollowknight`. Si cambia la versión
  de Python, hay que rehacer el enlace. Ahí también hay restos de un intento viejo
  (`my-themes/`).
- Animaciones estilo "dash" sin rebote: curvas `expressive*` en `tokens.hpp` (comentadas como
  Hollow Knight) y duraciones en `~/.config/caelestia/shell-tokens.json`.
- Se probaron efectos propios (disolución en "tinta del Vacío" al abrir paneles con un shader y
  pulso celeste en notificaciones) y el usuario los descartó: no reintroducir sin que lo pida.

### Pantalla de bloqueo: almas y juegos
- `modules/lock/Fetch.qml`: la fila de colores de terminal se cambió por las 7 almas de
  Undertale (pixel art, Determinación roja en el centro).
- `PixelArt.qml`: dibuja pixel art a partir de filas de strings (`#` = celda llena) con un `Shape`.
- Sin notificaciones, `NotifDock` muestra `Arcade.qml`: selector (abajo a la derecha) entre
  `DinoGame`, `TetrisGame`, `PacmanGame` y `MinesweeperGame`. El último juego elegido se guarda en
  `~/.local/state/caelestia/lock-game`; récords en `dino-hi`, `tetris-hi`, `pacman-hi` y
  `minesweeper-best` (misma carpeta).
- Teclado: el foco siempre vuelve al campo de contraseña. `PasswordInput` intercepta las flechas
  (la contraseña no las usa) y emite `LockSurface.gameKey(key, pressed, isRepeat)`. La barra
  espaciadora no se usa porque puede ser parte de la contraseña.
- Cada juego expone `keyPressed(key, isRepeat)` / `keyReleased(key)` y solo corre (FrameAnimation
  o Timer) mientras está visible.

### Configuración migrada
- `~/.config/caelestia/shell.json`: `bar.status` → `bar.statusIcons` (lista con `id`/`enabled`),
  `services.useTwelveHourClock` → `services.clockFormat: "TwentyFourHour"`. Backup en
  `shell.json.bak`.

## Archivos relevantes fuera del repo

| Archivo | Para qué |
|---|---|
| `~/.config/hypr/hyprland.lua` | Carga los módulos de `hyprland/` (`env`, `execs`, `keybinds`...) |
| `~/.config/hypr/hyprland/env.lua` | `QML_IMPORT_PATH` del plugin compilado |
| `~/.config/hypr/hyprland/execs.lua` | Autoarranque (`caelestia shell -d`) |
| `~/.config/hypr/hyprland/keybinds.lua` | Atajos + descripciones del menú |
| `~/.config/hypr/variables.lua` | Teclas por defecto (`kb*`), apps (`terminal`, `browser`...) |
| `~/.config/hypr/hyprland/rules.lua` | Reglas de ventana (quickshell/zenity flotan) |
| `~/.config/caelestia/shell.json` | Config de la shell |
| `~/.config/caelestia/shell-tokens.json` | Overrides de tokens (solo duraciones) |
| `~/.local/state/caelestia/scheme.json` | Esquema de colores activo (lo escribe la CLI) |
| `~/.config/khal/config` | Config de khal |
| `/usr/lib/python3.14/site-packages/caelestia/` | CLI de caelestia (esquemas, `shell.py`) |

En Hyprland, `MOD5` es AltGr (modmask 128); Super es 64, Ctrl 4, Alt 8, Shift 1.
