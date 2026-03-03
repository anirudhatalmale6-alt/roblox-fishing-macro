; ============================================================
;  ROBLOX FISHING MINIGAME MACRO  v5.0  —  UI EXCLUSION FIX
; ============================================================
;
;  v5 FIXES:
;    - Brown UI buttons (R173 G140 B95) now properly excluded
;    - White text ("Challenges" etc.) no longer triggers ring
;      mode — white blob check now requires 20px radius
;    - Cast position fixed to (994, 735) — configurable with F5
;    - Wait time increased to 20 sec for bait to be ready
;    - Added explicit warm-color (brown/tan/beige) filter
;
;  Press F1 and walk away.  The macro handles everything.
;
;  HOTKEYS:
;    F1  = Start / Stop
;    F4  = Calibrate game area (click two corners)
;    F5  = Set cast point (click where to cast the rod)
;    F6  = Color picker (checks pixel under cursor)
;    F7  = Decrease gap threshold (ring: more precise)
;    F8  = Increase gap threshold (ring: more forgiving)
;    F9  = Pause / Resume
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
global RawX1 := 110
global RawY1 := 30
global RawX2 := 1810
global RawY2 := 640

; --- Cast point (set with F5) ---
; Where the script clicks to cast the rod.
; Default: (994, 735) as recommended.
global CastX := 994
global CastY := 735

; --- UI exclusion margins (pixels) ---
global MarginLeft   := 150    ; increased to fully skip side menu
global MarginRight  := 20
global MarginTop    := 100    ; skip difficulty text
global MarginBottom := 80

; --- Effective scan area (auto-computed) ---
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
global BlobCheckDist  := 10    ; pixels from found point
global BlobMinMatches := 4     ; out of 8 must match

; --- White circle size check ---
; The real minigame circle is large (40-80px diameter).
; UI text characters are small (~12px).  We check at 20px
; distance to distinguish circles from text.
global WhiteCheckDist := 20

; --- Saturation scan ---
global SatScanStep      := 22
global MinSaturation    := 100
global MinBrightness    := 130
global WaterBlueMargin  := 50

; --- Automation timing ---
global CastClickDelay   := 300
global WaitForGameMax   := 20000   ; 20 sec — bait takes 5-15s
global RoundEndTimeout  := 2500
global RecastDelay      := 1500

; --- Humanization ---
global HumanDelayMin    := 15
global HumanDelayMax    := 55
global ClickJitter      := 4
global PostClickPause   := 200

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
        . "Gap: " GapThresh "px  |  Cast: (" CastX "," CastY ")`n"
        . "Scan: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n"
        . "F1=On/Off F4=Area F5=Cast F7/8=Gap F9=Pause"
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
    ToolTip, Click the TOP-LEFT corner of the game area...
    KeyWait, LButton, D
    MouseGetPos, RawX1, RawY1
    KeyWait, LButton
    Sleep, 200
    ToolTip, Now click the BOTTOM-RIGHT corner...
    KeyWait, LButton, D
    MouseGetPos, RawX2, RawY2
    KeyWait, LButton
    UpdateScanArea()
    ToolTip, % "Scan area: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n(margins auto-exclude menus)"
    SetTimer, HideTip, -5000
return

F5::
    Running := false
    Paused := false
    MacroState := "IDLE"
    SetTimer, AutoLoop, Off
    ToolTip, Click where you want to CAST the rod...
    KeyWait, LButton, D
    MouseGetPos, CastX, CastY
    KeyWait, LButton
    ToolTip, % "Cast point set: (" CastX "," CastY ")"
    SetTimer, HideTip, -3000
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
    warm := IsWarmBrown(r, g, b)
    wt := warm ? " [BROWN-excluded]" : ""
    ToolTip, % "(" mx "," my "): " hex "`nR=" r " G=" g " B=" b " Sat=" sat wt
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
;  CASTING — click at the set cast point
; --------------------------------------------------
DoCasting() {
    Random, d, 200, 500
    Sleep, d

    ; Click at the configured cast point with small jitter
    Random, ox, -8, 8
    Random, oy, -8, 8
    Click, % (CastX + ox) . " " . (CastY + oy)
    Sleep, CastClickDelay

    MacroState := "WAITING"
    StateStartTick := A_TickCount
    DetectedMode := ""
    ToolTip, % "Cast! Waiting for minigame (up to 20s)..."
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
    ; --- Strategy A: known colors + blob confirm ---
    for i, entry in CircleColors {
        PixelSearch, fx, fy, GX1, GY1, GX2, GY2, entry.c, entry.v, Fast RGB
        if (ErrorLevel = 0) {
            ; Check it's not a brown/tan UI element
            PixelGetColor, checkCol, fx, fy, RGB
            cr := (checkCol >> 16) & 0xFF
            cg := (checkCol >> 8)  & 0xFF
            cb := checkCol & 0xFF
            if (IsWarmBrown(cr, cg, cb))
                continue

            if (ConfirmColorBlob(fx, fy)) {
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
;  WARM BROWN / TAN FILTER
; ==========================
; Returns true if the color looks like a UI button (brown/tan/beige).
; The Challenges menu buttons are around R=173 G=140 B=95.
; This catches any warm, desaturated color in that family.
IsWarmBrown(r, g, b) {
    ; Must be warm: R > G > B
    if (r <= g || g <= b)
        return false
    ; Must be in the right brightness range (not too dark, not too bright)
    if (r < 100 || r > 220)
        return false
    ; Must be low-to-medium saturation (UI buttons, not vivid game circles)
    sat := r - b   ; for warm colors, R-B is a good saturation proxy
    if (sat > 120)
        return false   ; too saturated = probably a real game circle
    ; Check the warm ratio: R/B should be moderate (not extreme)
    if (r > 0 && b > 0) {
        ratio := r / b
        if (ratio > 1.2 && ratio < 3.0 && sat < 110)
            return true
    }
    return false
}

; ==========================
;  BLOB CONFIRMATION (Strategy A)
; ==========================
; Verifies the found pixel is part of a large colored area
; (real circle), not a small UI element or stray pixel.
ConfirmColorBlob(fx, fy) {
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

        ; Skip if this neighbor is a brown UI pixel
        if (IsWarmBrown(r, g, b))
            continue

        maxC := Max(r, Max(g, b))
        minC := Min(r, Min(g, b))
        sat  := maxC - minC
        if (sat > 50 && maxC > 100)
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

            ; Skip warm brown / tan immediately
            if (IsWarmBrown(r, g, b))
                goto SatNext

            maxC := Max(r, Max(g, b))
            minC := Min(r, Min(g, b))
            sat  := maxC - minC

            if (sat > MinSaturation && maxC > MinBrightness) {
                ; Skip water-blue
                if (b > r + WaterBlueMargin && b > g + WaterBlueMargin)
                    goto SatNext

                ; Confirm blob
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

ConfirmSatBlob(fx, fy) {
    d := 8
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
        if (IsWarmBrown(r, g, b))
            continue
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

    ; STRICT white circle check: must be bright at 20px distance
    ; in all directions.  Real circles are 40-80px diameter.
    ; UI text characters are only ~12px tall, so they fail this.
    if (!ConfirmLargeWhiteBlob(cx, cy))
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

; Large white blob check — the found pixel must be surrounded
; by bright pixels at WhiteCheckDist (20px) in all 4 directions.
; This eliminates small UI text as false positives.
ConfirmLargeWhiteBlob(cx, cy) {
    d := WhiteCheckDist
    offsets := [{x: d, y: 0}, {x: -d, y: 0}, {x: 0, y: d}, {x: 0, y: -d}
              , {x: d, y: d}, {x: -d, y: -d}, {x: d, y: -d}, {x: -d, y: d}]
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
    ; At least 6 of 8 directions must be bright at 20px distance
    return (bright >= 6)
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
