#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

; ------------------- Load settings -------------------
iniPath := A_ScriptDir "\settings.ini"
settings := {}
keys := {}

if FileExist(iniPath) {
    engNum    := IniRead(iniPath, "Settings", "Engine", 1)
    scrollNum := IniRead(iniPath, "Settings", "Scroll", 2)
    midNum    := IniRead(iniPath, "Settings", "MiddleScroll", 0)

    ; Engine mapping
    switch engNum {
        case 1: settings.Engine := "Friday Night Funkin'"
        case 2: settings.Engine := "Psych Engine"
        case 3: settings.Engine := "Kade Engine"
        case 4: settings.Engine := "Custom"
        default: settings.Engine := "Friday Night Funkin'"
    }

    ; Scroll mapping
    settings.Scroll := (scrollNum = 1) ? "Upscroll" : "Downscroll"

    ; Middle scroll mapping
    settings.MiddleScroll := (midNum = 1) ? "Yes" : "No"

    ; Keys
    keys.Left  := IniRead(iniPath, "Keys", "Left", "A")
    keys.Down  := IniRead(iniPath, "Keys", "Down", "S")
    keys.Up    := IniRead(iniPath, "Keys", "Up", "W")
    keys.Right := IniRead(iniPath, "Keys", "Right", "D")
} else {
    ; Defaults
    settings.Engine := "Friday Night Funkin'"
    settings.Scroll := "Downscroll"
    settings.MiddleScroll := "No"
    keys := { Left: "A", Down: "S", Up: "W", Right: "D" }
}

winTitle := settings.Engine
reactionMS := 10

; ------------------- Hitline Y -------------------
if settings.MiddleScroll = "Yes"
    hitY := 540   ; middle of 1080p
else if settings.Scroll = "Upscroll"
    hitY := 400   ; near top
else
    hitY := 800   ; near bottom

; ------------------- Note positions -------------------
notePos := { left:{x:400,y:hitY}, down:{x:600,y:hitY}, up:{x:800,y:hitY}, right:{x:1000,y:hitY} }

; ------------------- Lane configs -------------------
laneConfig := {
    left:  { mode: "pixelsearch" },
    down:  { mode: "pixelsearch" },
    up:    { mode: "pixelsearch" },
    right: { mode: "pixelsearch" }
}

; Unified note colors (RGB)
noteColors := { 
    left: 0xC24B99, 
    down: 0x00FFFF, 
    up: 0x12FA05, 
    right: 0xF9393F 
}

; ------------------- Activate window -------------------
if WinExist(winTitle)
    WinActivate()
else {
    MsgBox("FNF window not found!")
    ExitApp
}

Esc::ExitApp

; Force window to 1080p
WinWaitActive(winTitle, 3)
WinMove(winTitle, 0, 0, 1920, 1080)
Sleep 200

; Get window position
winX := 0, winY := 0, winW := 0, winH := 0
WinGetPos(&winX, &winY, &winW, &winH, winTitle)

; Adjust absolute note positions
notePos := { 
    left:  {x: winX + 400, y: winY + hitY}, 
    down:  {x: winX + 600, y: winY + hitY}, 
    up:    {x: winX + 800, y: winY + hitY}, 
    right: {x: winX + 1000, y: winY + hitY} 
}

; ------------------- Main loop -------------------
Loop {
    ; Search area based on scroll
    if settings.Scroll = "Downscroll" {
        searchTop := hitY - 80
        searchBottom := hitY - 5
    } else { ; Upscroll or Middle
        searchTop := hitY + 5
        searchBottom := hitY + 80
    }

    xRadius := 150
    stepSize := 6
    tolerance := 10

    ; Check lanes
    for lane, color in noteColors {
        if FindColorInRect(color, notePos[lane].x - xRadius, searchTop, notePos[lane].x + xRadius, searchBottom, stepSize, tolerance)
            SendKeyTap(keys[lane])
    }

    Sleep reactionMS
}

; ------------------- Functions -------------------

FindColorInRect(expectedColor, x1, y1, x2, y2, stepSize := 6, tolerance := 10) {
    try {
        x1 := Floor(x1), y1 := Floor(y1), x2 := Floor(x2), y2 := Floor(y2)
        x := x1
        while (x <= x2) {
            y := y1
            while (y <= y2) {
                c := PixelGetColor(x, y, "RGB")
                rDiff := Abs((c >> 16 & 0xFF) - (expectedColor >> 16 & 0xFF))
                gDiff := Abs((c >> 8 & 0xFF) - (expectedColor >> 8 & 0xFF))
                bDiff := Abs((c & 0xFF) - (expectedColor & 0xFF))
                if (rDiff + gDiff + bDiff) <= tolerance
                    return true
                y += stepSize
            }
            x += stepSize
        }
        return false
    } catch {
        return false
    }
}

SendKeyTap(key) {
    try {
        Send("{" key " down}")
        Sleep 28
        Send("{" key " up}")
    } catch {
        Send(key)
    }
}
