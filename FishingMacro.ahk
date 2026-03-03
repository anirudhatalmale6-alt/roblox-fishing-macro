; ============================================================
;  ROBLOX FISHING MINIGAME MACRO  v1.0
; ============================================================
;  A client-side AHK helper that mimics normal player inputs.
;  No exploits, memory edits, or injection — only mouse clicks.
;
;  HOTKEYS:
;    F1  = Toggle macro ON / OFF
;    F2  = Cycle variant  (1 → 2 → 3 → 1)
;    F3  = Cycle difficulty (Easy → Med → Hard → Impossible)
;    F4  = Calibrate game area (click two corners)
;    F5  = Cast rod (left-click once)
;    F6  = Color picker — shows color under cursor
;    F12 = Emergency exit
;
;  VARIANTS:
;    1 = Multi-circle (blue UI) — click every circle ASAP
;    2 = Single circle, random pos (purple UI) — time the ring
;    3 = Single circle, fixed center (purple UI) — time the ring
; ============================================================

#Requires AutoHotkey v1.1
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SendMode Input

; ==========================
;  USER-EDITABLE SETTINGS
; ==========================

; --- Current mode ---
global Running   := false
global Variant   := 1          ; 1, 2, or 3
global Difficulty := 2         ; 1=Easy 2=Medium 3=Hard 4=Impossible

; --- Game area (screen coords) ---
; Default for 1920x1080 — recalibrate with F4 for your setup.
global GX1 := 110
global GY1 := 30
global GX2 := 1810
global GY2 := 640

; --- Variant 1: circle colors to hunt ---
; These are approximate RGB values for the colored inner circles.
; Increase *Var values if circles aren't being detected.
global V1_Yellow    := 0xE8E800
global V1_YellowVar := 55
global V1_Green     := 0x30D830
global V1_GreenVar  := 55
global V1_Orange    := 0xE89830
global V1_OrangeVar := 55

; --- Variants 2 & 3: white inner circle ---
global V23_White    := 0xD8D8D8
global V23_WhiteVar := 45

; --- Ring detection ---
; "GapThreshold" = max pixels of background between inner circle
; edge and the ring outline before we consider it "close enough".
; Lower = more precise timing, higher = clicks earlier.
; Tune per difficulty:  Easy needs less precision, Impossible needs more.
global GapThreshold := [12, 8, 5, 3]   ; Easy, Med, Hard, Impossible

; Ring outline darkness — the outer ring is near-black.
global RingMinBrightness := 80   ; 0-255; a pixel is "ring" if R,G,B < this

; --- Humanization ---
; Small random variations so inputs look natural.
global HumanDelayMin   := 15    ; ms before click
global HumanDelayMax   := 55
global ClickJitter     := 4     ; random pixel offset on clicks
global PostClickPause  := 180   ; ms cooldown after a click (avoid doubles)

; ==========================
;  INTERNAL STATE
; ==========================
global DiffNames := ["Easy", "Medium", "Hard", "Impossible"]
global LastClickTick := 0

; ==========================
;  STATUS TOOLTIP
; ==========================
ShowStatus() {
    dn := DiffNames[Difficulty]
    st := Running ? "ON" : "OFF"
    ToolTip, % "Fishing Macro [" st "]`n"
        . "Variant: " Variant "  |  " dn "`n"
        . "Area: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n"
        . "F1=Toggle F2=Var F3=Diff F4=Cal F5=Cast F6=Color"
    SetTimer, HideTip, -4000
}
HideTip:
    ToolTip
return

; ==========================
;  HOTKEYS
; ==========================

; --- F1: Toggle macro ---
F1::
    Running := !Running
    if (Running) {
        ShowStatus()
        SetTimer, MainLoop, 10
    } else {
        SetTimer, MainLoop, Off
        ShowStatus()
    }
return

; --- F2: Cycle variant ---
F2::
    Variant := Mod(Variant, 3) + 1
    ShowStatus()
return

; --- F3: Cycle difficulty ---
F3::
    Difficulty := Mod(Difficulty, 4) + 1
    ShowStatus()
return

; --- F4: Calibrate game area ---
F4::
    Running := false
    SetTimer, MainLoop, Off
    ToolTip, Click the TOP-LEFT corner of the minigame UI...
    KeyWait, LButton, D
    MouseGetPos, GX1, GY1
    KeyWait, LButton
    Sleep, 200
    ToolTip, Now click the BOTTOM-RIGHT corner...
    KeyWait, LButton, D
    MouseGetPos, GX2, GY2
    KeyWait, LButton
    ShowStatus()
return

; --- F5: Cast rod ---
F5::
    Click
    Sleep, 500
return

; --- F6: Color picker ---
F6::
    MouseGetPos, mx, my
    PixelGetColor, col, mx, my, RGB
    hex := Format("0x{:06X}", col)
    r := (col >> 16) & 0xFF
    g := (col >> 8)  & 0xFF
    b := col & 0xFF
    ToolTip, % "Color at (" mx "," my "): " hex " | R=" r " G=" g " B=" b
    SetTimer, HideTip, -5000
return

; --- F12: Emergency exit ---
F12::
    ExitApp
return

; ==========================
;  MAIN LOOP (runs on timer)
; ==========================
MainLoop:
    if (!Running)
        return

    ; Cooldown guard — skip if we just clicked
    elapsed := A_TickCount - LastClickTick
    if (elapsed < PostClickPause)
        return

    if (Variant = 1)
        V1_MultiCircle()
    else if (Variant = 2)
        V2_SingleRandom()
    else
        V3_SingleCenter()
return

; ==========================
;  VARIANT 1 — Multi-circle
; ==========================
; Scan the game area for brightly colored circles and click them.
; Searches yellow first (most common), then green, then orange.
V1_MultiCircle() {
    ; Yellow
    PixelSearch, fx, fy, GX1, GY1, GX2, GY2, V1_Yellow, V1_YellowVar, Fast RGB
    if (ErrorLevel = 0) {
        HumanClick(fx, fy)
        return
    }
    ; Green
    PixelSearch, fx, fy, GX1, GY1, GX2, GY2, V1_Green, V1_GreenVar, Fast RGB
    if (ErrorLevel = 0) {
        HumanClick(fx, fy)
        return
    }
    ; Orange
    PixelSearch, fx, fy, GX1, GY1, GX2, GY2, V1_Orange, V1_OrangeVar, Fast RGB
    if (ErrorLevel = 0) {
        HumanClick(fx, fy)
        return
    }
}

; ==========================
;  VARIANT 2 — Single circle, random position
; ==========================
; Find the white inner circle, scan outward to measure gap to ring.
; Click when gap is small enough (ring is close).
V2_SingleRandom() {
    ; Find white inner circle
    PixelSearch, cx, cy, GX1, GY1, GX2, GY2, V23_White, V23_WhiteVar, Fast RGB
    if (ErrorLevel != 0)
        return   ; No circle visible yet

    ; Measure gap: walk rightward from center past white area, count
    ; background pixels until we hit the dark ring outline.
    gap := MeasureGap(cx, cy)
    if (gap >= 0 && gap <= GapThreshold[Difficulty]) {
        HumanClick(cx, cy)
    }
}

; ==========================
;  VARIANT 3 — Single circle, fixed center
; ==========================
; The circle always appears at the center of the game UI.
V3_SingleCenter() {
    cx := (GX1 + GX2) // 2
    cy := (GY1 + GY2) // 2

    ; Verify white circle is present at center
    PixelGetColor, col, cx, cy, RGB
    if (!IsBright(col, 170))
        return   ; No circle at center

    gap := MeasureGap(cx, cy)
    if (gap >= 0 && gap <= GapThreshold[Difficulty]) {
        HumanClick(cx, cy)
    }
}

; ==========================
;  GAP MEASUREMENT
; ==========================
; From the detected circle center, walk RIGHT until we leave the
; white inner circle, then count background pixels until we hit
; the dark ring outline.  Returns gap size (pixels), or -1 if
; no ring found within 200 px.
MeasureGap(cx, cy) {
    x := cx

    ; Step 1 — skip through white inner circle
    Loop, 150 {
        x++
        if (x >= GX2)
            return -1
        PixelGetColor, col, x, cy, RGB
        if (!IsBright(col, 150))
            break   ; Left the white area
    }

    ; Step 2 — count background pixels until dark ring
    gapPx := 0
    Loop, 200 {
        x++
        if (x >= GX2)
            return -1
        PixelGetColor, col, x, cy, RGB
        if (IsDarkRing(col)) {
            return gapPx   ; Found the ring
        }
        gapPx++
    }
    return -1   ; Ring not found
}

; ==========================
;  HELPER FUNCTIONS
; ==========================

; Click with small human-like jitter and delay.
HumanClick(x, y) {
    Random, ox, -ClickJitter, ClickJitter
    Random, oy, -ClickJitter, ClickJitter
    Random, d,  HumanDelayMin, HumanDelayMax
    Sleep, d
    Click, % (x + ox) . " " . (y + oy)
    LastClickTick := A_TickCount
}

; Is this pixel "bright" (i.e. part of the white inner circle)?
; threshold: each R,G,B channel must be above this value.
IsBright(color, threshold) {
    r := (color >> 16) & 0xFF
    g := (color >> 8)  & 0xFF
    b := color & 0xFF
    return (r > threshold && g > threshold && b > threshold)
}

; Is this pixel dark enough to be the ring outline?
IsDarkRing(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8)  & 0xFF
    b := color & 0xFF
    return (r < RingMinBrightness && g < RingMinBrightness && b < RingMinBrightness)
}

; ==========================
;  STARTUP
; ==========================
ShowStatus()
return
