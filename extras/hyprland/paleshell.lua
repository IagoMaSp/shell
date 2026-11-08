-- PaleShell for Hyprland (Lua config). Load it from hyprland.lua with:
--   package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/quickshell/paleshell/extras/hyprland/?.lua"
--   require("paleshell")
-- Descriptions ("Section|Text") show up in the shell's keybinds menu (SUPER + F3).

local home = os.getenv("HOME")
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

-- The C++ plugin is built into build/qml and not installed system-wide
hl.env("QML_IMPORT_PATH", config .. "/quickshell/paleshell/build/qml")

hl.on("hyprland.start", function()
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("qs -c paleshell -n -d")
end)

local locked = { locked = true }
local release = { release = true }

local function bind(keys, action, flags, description)
	if type(keys) ~= "table" then
		keys = { keys }
	end
	for _, key in ipairs(keys) do
		local opts = { description = description }
		for k, v in pairs(flags or {}) do
			opts[k] = v
		end
		hl.bind(key, action, opts)
	end
end

local function shell(name)
	return hl.dsp.global("paleshell:" .. name)
end

-- Shell
bind("SUPER + SUPER_L", shell("launcher"), release, "Shell|Open the app launcher")
bind({ "SUPER + Escape", "XF86PowerOff" }, shell("session"), nil, "Shell|Power menu")
bind("SUPER + SHIFT + N", shell("sidebar"), nil, "Shell|Show sidebar")
bind("SUPER + K", shell("showall"), nil, "Shell|Show all panels")
bind("SUPER + L", shell("lock"), nil, "Shell|Lock screen")
bind("SUPER + F3", shell("keybinds"), nil, "Shell|Keybinds")
bind("SUPER + F1", shell("dock"), nil, "Shell|Switch between island and dock")
bind("F1", shell("notch"), nil, "Shell|Open / close the notch")
bind("SUPER + F8", shell("mascot"), nil, "Shell|Pick a mascot animation")
bind({ "SUPER + TAB", "F2" }, shell("overview"), nil, "Workspaces|Workspace overview")
bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("qs kill -c paleshell; sleep .1; qs -c paleshell -n -d"), release,
	"Shell|Restart the shell")

-- Screenshots
bind("Print", shell("screenshotFull"), locked, "Screenshots|Full screen")
bind("SUPER + SHIFT + S", shell("screenshotFreeze"), nil, "Screenshots|Region (frozen screen)")
bind("F9", shell("screenshot"), nil, "Screenshots|Region")
bind("SUPER + F9", shell("ocr"), nil, "Screenshots|Copy text from the screen (OCR)")

-- System and media
bind({ "XF86MonBrightnessUp", "SUPER + Insert" }, shell("brightnessUp"), locked, "System|Brightness up")
bind({ "XF86MonBrightnessDown", "SUPER + F12" }, shell("brightnessDown"), locked, "System|Brightness down")
bind({ "XF86AudioPlay", "XF86AudioPause", "F10" }, shell("mediaToggle"), locked, "Media|Play / pause")
bind({ "XF86AudioNext", "SUPER + F10" }, shell("mediaNext"), locked, "Media|Next track")
bind({ "XF86AudioPrev", "SUPER + SHIFT + F10" }, shell("mediaPrev"), locked, "Media|Previous track")
bind("XF86AudioStop", shell("mediaStop"), locked, "Media|Stop")

-- Utilities
bind({ "SUPER + V", "F3" }, hl.dsp.exec_cmd("qs -c paleshell ipc call notch open clipboard"), nil,
	"Utilities|Clipboard history")
bind({ "SUPER + Period", "F8" }, shell("emoji"), nil, "Utilities|Emoji picker")
bind("CTRL + SUPER + C", shell("clearNotifs"), locked, "Utilities|Clear notifications")
