; ============================================================
;  ROBLOX FISHING MINIGAME MACRO  v4.0  —  PRECISION UPDATE
; ============================================================
;
;  CHANGES IN v4:
;    - Auto-excludes left menu & bottom toolbar from scan area
;    - Blob confirmation: verifies a found pixel is part of a
;      real circle (not a UI button or stray pixel) before clicking
;    - Casts by clicking in the game center, not at cursor
;    - Saturation scan is smarter: excludes brown/tan UI colors
;    - Less aggressive: won't spam-click on false positives
;
;  Press F1 and walk away.  The macro handles everything.
;
;  HOTKEYS:
;    F1  = Start / Stop
;    F4  = Calibrate game area (click two corners)
;    F6  = Color picker (checks pixel under cursor)
;    F7  = Decrease gap threshold (ring: more precise)
;    F8  = Increase gap threshold (ring: more forgiving)
;    F9  = Pause / Resume (keeps state, stops mouse movement)
;    F12 = Emergency exit
;
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

global Running := false
global Paused  := false

; --- Raw game area (set with F4) ---
; This is the FULL area including menus.  The script auto-
; shrinks it to exclude the left menu and bottom toolbar.
global RawX1 := 110
global RawY1 := 30
global RawX2 := 1810
global RawY2 := 640

; --- UI exclusion margins (pixels) ---
; Shrink the scan area inward to skip UI elements.
; Left margin: skips Challenges/Storage/Shop menu
; Bottom margin: skips inventory toolbar
; Top margin: skips difficulty text area
; Adjust these if your UI is different.
global MarginLeft   := 130
global MarginRight  := 20
global MarginTop    := 90
global MarginBottom := 80

; --- Effective scan area (computed from raw + margins) ---
global GX1 := 0
global GY1 := 0
global GX2 := 0
global GY2 := 0

; --- Strategy A: circle color palette ---
global CircleColors := []

; --- Strategy B: white inner circle (Variants 2 & 3) ---
global V23_White    := 0xD8D8D8
global V23_WhiteVar := 45

; --- Ring gap threshold ---
global GapThresh := 7
global RingMinBrightness := 80

; --- Blob confirmation ---
; How many nearby pixels must also be colorful to confirm
; that the found pixel is a real circle (not a stray pixel).
; Checks 8 points around the found pixel at this distance.
global BlobCheckDist  := 8    ; pixels from found point
global BlobMinMatches := 4    ; out of 8 must match

; --- Saturation scan (catches unlisted colors) ---
global SatScanStep      := 22
global MinSaturation    := 100   ; raised to reduce false hits
global MinBrightness    := 130
global WaterBlueMargin  := 50
; Also skip brown/tan pixels (UI buttons):
global BrownMaxSat      := 70    ; low-sat warm colors = UI

; --- Automation timing ---
global CastClickDelay   := 300
global WaitForGameMax   := 8000
global RoundEndTimeout  := 2500
global RecastDelay      := 1500

; --- Humanization ---
global HumanDelayMin    := 15
global HumanDelayMax    := 55
global ClickJitter      := 4
global PostClickPause   := 200   ; slightly longer to reduce spam

; ==========================
;  INITIALIZE
; ==========================
InitColors() {
    CircleColors := []
    CircleColors.Push({c: 0xE8E800, v: 50})   ; Yellow
    CircleColors.Push({c: 0x30D830, v: 50})   ; Green
    CircleColors.Push({c: 0xE89830, v: 50})   ; Orange
    CircleColors.Push({c: 0xE840A0, v: 50})   ; Pink
    CircleColors.Push({c: 0x9040E0, v: 50})   ; Purple
    CircleColors.Push({c: 0xE83030, v: 50})   ; Red
    CircleColors.Push({c: 0x4090F0, v: 30})   ; Light Blue (tight)
    CircleColors.Push({c: 0x3050D0, v: 30})   ; Deep Blue (tight)
    CircleColors.Push({c: 0x30E8D0, v: 35})   ; Cyan/Teal
}
InitColors()
UpdateScanArea()

UpdateScanArea() {
    GX1 := RawX1 + MarginLeft
    GY1 := RawY1 + MarginTop
    GX2 := RawX2 - MarginRight
    GY2 := RawY2 - MarginBottom
}

; ==========================
;  INTERNAL STATE
; ==========================
global MacroState     := "IDLE"
global LastClickTick  := 0
global LastFoundTick  := 0
global StateStartTick := 0
global DetectedMode   := ""

; ==========================
;  STATUS TOOLTIP
; ==========================
ShowStatus() {
    st := Running ? (Paused ? "PAUSED" : "RUNNING") : "STOPPED"
    ToolTip, % "Fishing Macro [" st "]`n"
        . "State: " MacroState "  |  Mode: " DetectedMode "`n"
        . "Gap: " GapThresh "px`n"
        . "Scan: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n"
        . "F1=On/Off F4=Cal F7/8=Gap F9=Pause F12=Exit"
    SetTimer, HideTip, -4000
}
HideTip:
    ToolTip
return

; ==========================
;  HOTKEYS
; ==========================

F1::
    Running := !Running
    Paused := false
    if (Running) {
        MacroState := "CASTING"
        StateStartTick := A_TickCount
        DetectedMode := ""
        ShowStatus()
        SetTimer, AutoLoop, 15
    } else {
        MacroState := "IDLE"
        SetTimer, AutoLoop, Off
        ShowStatus()
    }
return

F4::
    Running := false
    Paused := false
    MacroState := "IDLE"
    SetTimer, AutoLoop, Off
    ToolTip, Click the TOP-LEFT corner of the FULL game area...
    KeyWait, LButton, D
    MouseGetPos, RawX1, RawY1
    KeyWait, LButton
    Sleep, 200
    ToolTip, Now click the BOTTOM-RIGHT corner...
    KeyWait, LButton, D
    MouseGetPos, RawX2, RawY2
    KeyWait, LButton
    UpdateScanArea()
    ToolTip, % "Raw area: (" RawX1 "," RawY1 ")-(" RawX2 "," RawY2 ")`n"
        . "Scan area (after margins): (" GX1 "," GY1 ")-(" GX2 "," GY2 ")"
    SetTimer, HideTip, -5000
return

F6::
    MouseGetPos, mx, my
    PixelGetColor, col, mx, my, RGB
    hex := Format("0x{:06X}", col)
    r := (col >> 16) & 0xFF
    g := (col >> 8)  & 0xFF
    b := col & 0xFF
    maxC := Max(r, Max(g, b))
    minC := Min(r, Min(g, b))
    sat := maxC - minC
    ToolTip, % "(" mx "," my "): " hex "`nR=" r " G=" g " B=" b " Sat=" sat
    SetTimer, HideTip, -6000
return

F7::
    GapThresh := Max(1, GapThresh - 1)
    ToolTip, % "Gap: " GapThresh "px (more precise)"
    SetTimer, HideTip, -2000
return

F8::
    GapThresh := Min(25, GapThresh + 1)
    ToolTip, % "Gap: " GapThresh "px (more forgiving)"
    SetTimer, HideTip, -2000
return

F9::
    if (Running) {
        Paused := !Paused
        ShowStatus()
    }
return

F12::
    ExitApp
return

; ==========================
;  MAIN AUTO-LOOP
; ==========================
AutoLoop:
    if (!Running || Paused)
        return

    if (MacroState = "CASTING")
        DoCasting()
    else if (MacroState = "WAITING")
        DoWaiting()
    else if (MacroState = "PLAYING")
        DoPlaying()
    else if (MacroState = "COOLDOWN")
        DoCooldown()
return

; --------------------------------------------------
;  CASTING — click in the CENTER of the game area
; --------------------------------------------------
DoCasting() {
    Random, d, 200, 500
    Sleep, d

    ; Click in the center of the raw game area (where the water is)
    castX := (RawX1 + RawX2) // 2
    castY := (RawY1 + RawY2) // 2
    Random, ox, -10, 10
    Random, oy, -10, 10
    Click, % (castX + ox) . " " . (castY + oy)
    Sleep, CastClickDelay

    MacroState := "WAITING"
    StateStartTick := A_TickCount
    DetectedMode := ""
    ToolTip, % "Cast! Waiting for minigame..."
    SetTimer, HideTip, -3000
}

; --------------------------------------------------
;  WAITING — scan for circles to appear
; --------------------------------------------------
DoWaiting() {
    elapsed := A_TickCount - StateStartTick
    if (elapsed > WaitForGameMax) {
        MacroState := "CASTING"
        StateStartTick := A_TickCount
        return
    }

    if (TryFindAndClick()) {
        MacroState := "PLAYING"
        LastFoundTick := A_TickCount
        StateStartTick := A_TickCount
        ShowStatus()
    }
}

; --------------------------------------------------
;  PLAYING — click circles
; --------------------------------------------------
DoPlaying() {
    elapsed := A_TickCount - LastClickTick
    if (elapsed < PostClickPause)
        return

    if (TryFindAndClick()) {
        LastFoundTick := A_TickCount
    }

    sinceLastFound := A_TickCount - LastFoundTick
    if (sinceLastFound > RoundEndTimeout) {
        MacroState := "COOLDOWN"
        StateStartTick := A_TickCount
        ToolTip, % "Round over! Recasting soon..."
        SetTimer, HideTip, -2000
    }
}

; --------------------------------------------------
;  COOLDOWN — pause before recasting
; --------------------------------------------------
DoCooldown() {
    elapsed := A_TickCount - StateStartTick
    if (elapsed > RecastDelay) {
        Random, extra, 300, 900
        Sleep, extra
        MacroState := "CASTING"
        StateStartTick := A_TickCount
    }
}

; ==========================
;  CIRCLE DETECTION ENGINE
; ==========================
TryFindAndClick() {
    ; --- Strategy A: known colors + blob confirmation ---
    for i, entry in CircleColors {
        PixelSearch, fx, fy, GX1, GY1, GX2, GY2, entry.c, entry.v, Fast RGB
        if (ErrorLevel = 0) {
            ; CONFIRM it's a real circle, not a stray pixel or UI
            if (ConfirmColorBlob(fx, fy, entry.c, entry.v)) {
                DetectedMode := "multi-circle"
                HumanClick(fx, fy)
                return true
            }
        }
    }

    ; --- Strategy A fallback: saturation grid scan ---
    if (SaturationScan(fx, fy)) {
        DetectedMode := "multi-circle (sat)"
        HumanClick(fx, fy)
        return true
    }

    ; --- Strategy B: ring timing ---
    if (TryRingTiming()) {
        return true
    }

    return false
}

; ==========================
;  BLOB CONFIRMATION (Strategy A)
; ==========================
; Checks 8 points around the found pixel at BlobCheckDist.
; At least BlobMinMatches must also be colorful (high sat)
; to confirm this is a real circle and not noise/UI.
ConfirmColorBlob(fx, fy, targetColor, variation) {
    d := BlobCheckDist
    offsets := [ {x: d, y: 0}, {x: -d, y: 0}, {x: 0, y: d}, {x: 0, y: -d}
               , {x: d, y: d}, {x: -d, y: -d}, {x: d, y: -d}, {x: -d, y: d} ]
    matches := 0

    for i, o in offsets {
        px := fx + o.x
        py := fy + o.y
        if (px < GX1 || px > GX2 || py < GY1 || py > GY2)
            continue
        PixelGetColor, col, px, py, RGB
        r := (col >> 16) & 0xFF
        g := (col >> 8)  & 0xFF
        b := col & 0xFF
        maxC := Max(r, Max(g, b))
        minC := Min(r, Min(g, b))
        sat  := maxC - minC
        ; Neighbor must be vivid (part of a colored circle)
        if (sat > 60 && maxC > 100)
            matches++
    }
    return (matches >= BlobMinMatches)
}

; ==========================
;  SATURATION GRID SCAN
; ==========================
SaturationScan(ByRef outX, ByRef outY) {
    y := GY1
    while (y <= GY2) {
        x := GX1
        while (x <= GX2) {
            PixelGetColor, col, x, y, RGB
            r := (col >> 16) & 0xFF
            g := (col >> 8)  & 0xFF
            b := col & 0xFF

            maxC := Max(r, Max(g, b))
            minC := Min(r, Min(g, b))
            sat  := maxC - minC

            if (sat > MinSaturation && maxC > MinBrightness) {
                ; Skip water-blue (blue dominant by large margin)
                if (b > r + WaterBlueMargin && b > g + WaterBlueMargin)
                    goto SatNext

                ; Skip brown/tan (warm, low-to-medium sat = UI buttons)
                if (r > g && r > b && sat < BrownMaxSat)
                    goto SatNext

                ; Skip gray/desaturated
                if (sat < 50)
                    goto SatNext

                ; Confirm it's a blob, not a stray pixel
                if (ConfirmSatBlob(x, y)) {
                    outX := x
                    outY := y
                    return true
                }
            }
            SatNext:
            x += SatScanStep
        }
        y += SatScanStep
    }
    return false
}

; Confirm saturation blob: check 4 neighbors are also vivid
ConfirmSatBlob(fx, fy) {
    d := 6
    offsets := [{x: d, y: 0}, {x: -d, y: 0}, {x: 0, y: d}, {x: 0, y: -d}]
    matches := 0
    for i, o in offsets {
        px := fx + o.x
        py := fy + o.y
        if (px < GX1 || px > GX2 || py < GY1 || py > GY2)
            continue
        PixelGetColor, col, px, py, RGB
        r := (col >> 16) & 0xFF
        g := (col >> 8)  & 0xFF
        b := col & 0xFF
        maxC := Max(r, Max(g, b))
        minC := Min(r, Min(g, b))
        if (maxC - minC > 70)
            matches++
    }
    return (matches >= 3)
}

; ==========================
;  STRATEGY B — Ring timing
; ==========================
TryRingTiming() {
    PixelSearch, cx, cy, GX1, GY1, GX2, GY2, V23_White, V23_WhiteVar, Fast RGB
    if (ErrorLevel != 0)
        return false

    if (!ConfirmWhiteBlob(cx, cy))
        return false

    gapR := MeasureGapDir(cx, cy, 1, 0)
    gapL := MeasureGapDir(cx, cy, -1, 0)
    gapD := MeasureGapDir(cx, cy, 0, 1)
    gapU := MeasureGapDir(cx, cy, 0, -1)

    bestGap := 9999
    if (gapR >= 0 && gapR < bestGap)
        bestGap := gapR
    if (gapL >= 0 && gapL < bestGap)
        bestGap := gapL
    if (gapD >= 0 && gapD < bestGap)
        bestGap := gapD
    if (gapU >= 0 && gapU < bestGap)
        bestGap := gapU

    if (bestGap <= GapThresh) {
        DetectedMode := "ring-timing"
        HumanClick(cx, cy)
        return true
    }
    return false
}

; Confirm white blob (not stray white pixel from UI text etc.)
ConfirmWhiteBlob(cx, cy) {
    offsets := [{x: 5, y: 0}, {x: -5, y: 0}, {x: 0, y: 5}, {x: 0, y: -5}]
    bright := 0
    for i, o in offsets {
        px := cx + o.x
        py := cy + o.y
        if (px < GX1 || px > GX2 || py < GY1 || py > GY2)
            continue
        PixelGetColor, col, px, py, RGB
        if (IsBright(col, 150))
            bright++
    }
    return (bright >= 3)
}

; ==========================
;  GAP MEASUREMENT
; ==========================
MeasureGapDir(cx, cy, dx, dy) {
    x := cx
    y := cy

    Loop, 120 {
        x += dx
        y += dy
        if (x < GX1 || x > GX2 || y < GY1 || y > GY2)
            return -1
        PixelGetColor, col, x, y, RGB
        if (!IsBright(col, 140))
            break
    }

    gapPx := 0
    Loop, 150 {
        x += dx
        y += dy
        if (x < GX1 || x > GX2 || y < GY1 || y > GY2)
            return -1
        PixelGetColor, col, x, y, RGB
        if (IsDarkRing(col))
            return gapPx
        gapPx++
    }
    return -1
}

; ==========================
;  HELPER FUNCTIONS
; ==========================

HumanClick(x, y) {
    Random, ox, -ClickJitter, ClickJitter
    Random, oy, -ClickJitter, ClickJitter
    Random, d,  HumanDelayMin, HumanDelayMax
    Sleep, d
    Click, % (x + ox) . " " . (y + oy)
    LastClickTick := A_TickCount
}

IsBright(color, threshold) {
    r := (color >> 16) & 0xFF
    g := (color >> 8)  & 0xFF
    b := color & 0xFF
    return (r > threshold && g > threshold && b > threshold)
}

IsDarkRing(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8)  & 0xFF
    b := color & 0xFF
    return (r < RingMinBrightness && g < RingMinBrightness && b < RingMinBrightness)
}

Max(a, b) {
    return (a > b) ? a : b
}

Min(a, b) {
    return (a < b) ? a : b
}

; ==========================
;  STARTUP
; ==========================
ShowStatus()
return
