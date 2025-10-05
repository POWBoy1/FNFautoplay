#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

; --- Globals ---
global MyGUI
global engineDropdown, scrollDropdown, middleDropdown
global leftEdit, downEdit, upEdit, rightEdit
global settingsFile, settings

; --- Settings File ---
settingsFile := A_ScriptDir "\settings.ini"

; --- Mappings (numbers <-> labels) ---
engineMap := Map(1, "Friday Night Funkin'", 2, "Psych Engine", 3, "Kade Engine", 4, "Custom")
scrollMap := Map(1, "Downscroll", 2, "Upscroll")
middleMap := Map(1, "No", 2, "Yes")

; --- Load Settings from INI (numbers only for Engine/Scroll/Middle) ---
if FileExist(settingsFile) {
    settings := {}
    settings.Engine := Integer(IniRead(settingsFile, "Settings", "Engine", "1"))
    settings.Scroll := Integer(IniRead(settingsFile, "Settings", "Scroll", "1"))
    settings.MiddleScroll := Integer(IniRead(settingsFile, "Settings", "MiddleScroll", "1"))
    settings.Keys := {}
    settings.Keys.Left  := IniRead(settingsFile, "Keys", "Left", "A")
    settings.Keys.Down  := IniRead(settingsFile, "Keys", "Down", "S")
    settings.Keys.Up    := IniRead(settingsFile, "Keys", "Up", "W")
    settings.Keys.Right := IniRead(settingsFile, "Keys", "Right", "D")
} else {
    settings := { Engine: 1, Scroll: 1, MiddleScroll: 1, Keys: { Left: "A", Down: "S", Up: "W", Right: "D" } }
}

; --- Create GUI ---
MyGUI := Gui("+AlwaysOnTop +ToolWindow", "Friday Night Funkin Auto Player")
try MyGUI.SetFont("s9", "Segoe UI")

; --- General Settings ---
MyGUI.Add("GroupBox", "x8 y8 w424 h100", "General Settings")

; Engine
engines := []
for , val in engineMap
    engines.Push(val)
MyGUI.Add("Text", "x20 y22", "Engine:")
engineDropdown := MyGUI.Add("DropDownList", "x120 y20 w260", engines)
engineDropdown.Choose(settings.Engine)

; Scroll
scrolls := []
for , val in scrollMap
    scrolls.Push(val)
MyGUI.Add("Text", "x20 y52", "Scroll:")
scrollDropdown := MyGUI.Add("DropDownList", "x120 y50 w260", scrolls)
scrollDropdown.Choose(settings.Scroll)

; Middle Scroll
middles := []
for , val in middleMap
    middles.Push(val)
MyGUI.Add("Text", "x20 y82", "Middle Scroll:")
middleDropdown := MyGUI.Add("DropDownList", "x120 y80 w260", middles)
middleDropdown.Choose(settings.MiddleScroll)

; --- Keybinds ---
MyGUI.Add("GroupBox", "x8 y116 w424 h110", "Keybinds")
MyGUI.Add("Text", "x20 y126", "Left:")
leftEdit := MyGUI.Add("Edit", "x100 y124 w120", settings.Keys.Left)
MyGUI.Add("Text", "x240 y126", "Down:")
downEdit := MyGUI.Add("Edit", "x290 y124 w120", settings.Keys.Down)
MyGUI.Add("Text", "x20 y156", "Up:")
upEdit := MyGUI.Add("Edit", "x100 y154 w120", settings.Keys.Up)
MyGUI.Add("Text", "x240 y156", "Right:")
rightEdit := MyGUI.Add("Edit", "x290 y154 w120", settings.Keys.Right)

; --- Buttons ---
saveBtn   := MyGUI.Add("Button", "x80 y235 w120 h30", "Save")
setKeysBtn:= MyGUI.Add("Button", "x210 y235 w100 h30", "Set Keys")
launchBtn := MyGUI.Add("Button", "x330 y235 w90 h30", "Launch")

; Footer
MyGUI.Add("Text", "x10 y210 w420", "Settings file: " settingsFile)
statusLbl := MyGUI.Add("Text", "x20 y255 w400", "")

; Events
saveBtn.OnEvent("Click", SaveSettings)
setKeysBtn.OnEvent("Click", SetKeybinds)
launchBtn.OnEvent("Click", LaunchBot)
MyGUI.OnEvent("Close", GuiClose)

; Hotkeys
Hotkey("F5", LaunchBot)
Hotkey("F7", GuiClose)

; Show GUI
MyGUI.Show()
return

; --- Functions ---
SaveSettings(*) {
    global engineDropdown, scrollDropdown, middleDropdown
    global leftEdit, downEdit, upEdit, rightEdit
    global settingsFile, engineMap, scrollMap, middleMap

    newSettings := {
        Engine: engineDropdown.Value,
        Scroll: scrollDropdown.Value,
        MiddleScroll: middleDropdown.Value,
        Keys: {
            Left: leftEdit.Value,
            Down: downEdit.Value,
            Up: upEdit.Value,
            Right: rightEdit.Value
        }
    }

    IniWrite(newSettings.Engine, settingsFile, "Settings", "Engine")
    IniWrite(newSettings.Scroll, settingsFile, "Settings", "Scroll")
    IniWrite(newSettings.MiddleScroll, settingsFile, "Settings", "MiddleScroll")
    IniWrite(newSettings.Keys.Left, settingsFile, "Keys", "Left")
    IniWrite(newSettings.Keys.Down, settingsFile, "Keys", "Down")
    IniWrite(newSettings.Keys.Up, settingsFile, "Keys", "Up")
    IniWrite(newSettings.Keys.Right, settingsFile, "Keys", "Right")

    MsgBox("Settings saved to settings.ini!")
}

LaunchBot(*) {
    script := A_ScriptDir "\FNF_Bot.ahk"
    ahk64 := A_ScriptDir "\AutoHotkey64.exe"
    ahk32 := A_ScriptDir "\AutoHotkey32.exe"
    if FileExist(ahk64)
        Run(Format('"{1}" "{2}"', ahk64, script))
    else if FileExist(ahk32)
        Run(Format('"{1}" "{2}"', ahk32, script))
    else
        Run(Format('"{1}"', script))
}

GuiClose(*) {
    ExitApp
}

SetKeybinds(*) {
    global statusLbl, leftEdit, downEdit, upEdit, rightEdit
    lanes := ["Left", "Down", "Up", "Right"]
    assigned := {}
    results := {}

    for _, lane in lanes {
        while true {
            statusLbl.Text := Format("Press the key for {1} (timeout 60s)...", lane)
            key := WaitForKeyPress(60000)
            if (key = "") {
                MsgBox(Format("Key capture timed out for {1}. Please try again.", lane))
                statusLbl.Text := ""
                return
            }

            key := StrUpper(key)

            if assigned.HasProp(key) {
                MsgBox("The key '" key "' is already assigned to " assigned.%key% ". Press a different key.")
                continue
            }

            assigned.%key% := lane
            results.%lane% := key
            break
        }
    }

    leftEdit.Value  := results.Left
    downEdit.Value  := results.Down
    upEdit.Value    := results.Up
    rightEdit.Value := results.Right

    statusLbl.Text := "Keybinds set successfully."
    ToolTip "Keybinds successfully set!", 0, 0
    Sleep 1000
    ToolTip
    statusLbl.Text := ""
}

WaitForKeyPress(timeout := 60000) {
    ih := InputHook("L1 T" timeout)
    ih.KeyOpt("{All}", "E")
    ih.Start()
    ih.Wait()
    ih.Stop()
    key := ih.EndKey
    if (key = "" || key = "EndKey" || key = "Timeout")
        return ""
    if (StrLen(key) = 1)
        return key
    return key
}
