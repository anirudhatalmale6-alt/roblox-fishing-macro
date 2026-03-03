; ============================================================
;  ROBLOX FISHING MINIGAME MACRO  v2.0  —  AUTO-DETECT
; ============================================================
;
;  Automatically detects which variant is active and handles
;  all 4 difficulty levels with no manual switching.
;
;  HOW IT WORKS:
;    Every scan cycle the macro tries TWO detection strategies:
;
;    Strategy A — "Multi-circle" (Variant 1):
;      Scan for brightly colored circles (yellow/green/orange).
;      If any are found → click immediately.
;
;    Strategy B — "Ring-timing" (Variants 2 & 3):
;      Scan for a white/gray inner circle anywhere in the game
;      area.  Measure the pixel-gap between the inner circle
;      edge and the dark shrinking ring.  Click when the gap
;      is small enough.
;
;    Whichever strategy finds a target first, it acts.
;    Works for ALL variants and ALL difficulties automatically.
;
;  HOTKEYS:
;    F1  = Toggle macro ON / OFF
;    F4  = Calibrate game area (click two corners)
;    F5  = Cast rod (single left-click)
;    F6  = Color picker (hover + press to see pixel color)
;    F7  = Decrease gap threshold (more precise, clicks later)
;    F8  = Increase gap threshold (more forgiving, clicks earlier)
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

; --- Game area (screen coordinates) ---
; Recalibrate with F4 for your screen resolution.
; Should cover the minigame UI only (not Roblox menus/toolbar).
global GX1 := 110
global GY1 := 30
global GX2 := 1810
global GY2 := 640

; --- STRATEGY A: colored circle colors (Variant 1) ---
; The bright circles that appear on the blue/cyan water.
; Use F6 to check actual colors on your screen, then adjust.
global V1_Yellow    := 0xE8E800
global V1_YellowVar := 55
global V1_Green     := 0x30D830
global V1_GreenVar  := 55
global V1_Orange    := 0xE89830
global V1_OrangeVar := 55

; --- STRATEGY B: white inner circle (Variants 2 & 3) ---
global V23_White    := 0xD8D8D8
global V23_WhiteVar := 45

; --- Gap threshold (ring timing) ---
; How close the ring must be before we click (in pixels).
; LOWER = more precise timing (better score, but riskier).
; HIGHER = clicks earlier (safer, may lose some precision).
; Default 7 works well across Easy → Impossible.
; Fine-tune with F7 (decrease) / F8 (increase) while playing.
global GapThresh := 7

; --- Ring outline detection ---
; The shrinking ring is near-black.  A pixel is considered
; "ring" if its R, G, AND B channels are all below this value.
global RingMinBrightness := 80

; --- Humanization ---
global HumanDelayMin   := 15    ; ms random delay before click
global HumanDelayMax   := 55
global ClickJitter     := 4     ; random pixel offset
global PostClickPause  := 170   ; ms cooldown after a click

; ==========================
;  INTERNAL STATE
; ==========================
global LastClickTick := 0
global DetectedMode  := ""      ; "multi" or "ring" — display only

; ==========================
;  STATUS TOOLTIP
; ==========================
ShowStatus() {
    st := Running ? "ON" : "OFF"
    dm := (DetectedMode = "") ? "waiting" : DetectedMode
    ToolTip, % "Fishing Macro [" st "] — Auto-Detect`n"
        . "Mode: " dm "  |  Gap: " GapThresh "px`n"
        . "Area: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n"
        . "F1=Toggle  F4=Calibrate  F5=Cast`n"
        . "F7=Gap-  F8=Gap+  F6=Color  F12=Exit"
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
    if (Running) {
        DetectedMode := ""
        ShowStatus()
        SetTimer, MainLoop, 10
    } else {
        SetTimer, MainLoop, Off
        ShowStatus()
    }
return

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

F5::
    Click
    Sleep, 500
return

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

F7::
    GapThresh := Max(1, GapThresh - 1)
    ToolTip, % "Gap threshold: " GapThresh "px  (more precise)"
    SetTimer, HideTip, -2000
return

F8::
    GapThresh := Min(25, GapThresh + 1)
    ToolTip, % "Gap threshold: " GapThresh "px  (more forgiving)"
    SetTimer, HideTip, -2000
return

F12::
    ExitApp
return

; ==========================
;  MAIN LOOP
; ==========================
; Runs every ~10ms.  Tries Strategy A first (colored circles),
; then falls back to Strategy B (white circle + ring timing).
; This way it auto-handles whichever variant the game throws.
MainLoop:
    if (!Running)
        return

    ; Cooldown guard
    elapsed := A_TickCount - LastClickTick
    if (elapsed < PostClickPause)
        return

    ; --------------------------------------------------
    ; STRATEGY A — Multi-circle (Variant 1)
    ; Look for brightly colored circles and click them.
    ; --------------------------------------------------
    if (TryColoredCircle(V1_Yellow, V1_YellowVar))
        return
    if (TryColoredCircle(V1_Green, V1_GreenVar))
        return
    if (TryColoredCircle(V1_Orange, V1_OrangeVar))
        return

    ; --------------------------------------------------
    ; STRATEGY B — Ring-timing (Variants 2 & 3)
    ; Find white inner circle, measure gap to ring, click
    ; when the ring is close enough.
    ; --------------------------------------------------
    TryRingTiming()
return

; ==========================
;  STRATEGY A — Find colored circle & click
; ==========================
TryColoredCircle(color, variation) {
    PixelSearch, fx, fy, GX1, GY1, GX2, GY2, color, variation, Fast RGB
    if (ErrorLevel != 0)
        return false

    DetectedMode := "multi-circle"
    HumanClick(fx, fy)
    return true
}

; ==========================
;  STRATEGY B — White circle + ring gap
; ==========================
TryRingTiming() {
    ; Find white inner circle anywhere in game area
    PixelSearch, cx, cy, GX1, GY1, GX2, GY2, V23_White, V23_WhiteVar, Fast RGB
    if (ErrorLevel != 0)
        return   ; No white circle visible

    ; Verify it's a real circle by checking a few nearby pixels
    ; are also bright (not a single stray white pixel).
    if (!ConfirmCircle(cx, cy))
        return

    ; Measure gap from inner circle edge to the dark ring.
    ; We scan in multiple directions and take the smallest gap
    ; for more reliable detection.
    gapR := MeasureGapDir(cx, cy, 1, 0)    ; right
    gapL := MeasureGapDir(cx, cy, -1, 0)   ; left
    gapD := MeasureGapDir(cx, cy, 0, 1)    ; down
    gapU := MeasureGapDir(cx, cy, 0, -1)   ; up

    ; Find the smallest valid gap from any direction
    bestGap := 9999
    if (gapR >= 0 && gapR < bestGap)
        bestGap := gapR
    if (gapL >= 0 && gapL < bestGap)
        bestGap := gapL
    if (gapD >= 0 && gapD < bestGap)
        bestGap := gapD
    if (gapU >= 0 && gapU < bestGap)
        bestGap := gapU

    ; Click if the ring is close enough
    if (bestGap <= GapThresh) {
        DetectedMode := "ring-timing"
        HumanClick(cx, cy)
    }
}

; ==========================
;  CIRCLE CONFIRMATION
; ==========================
; Make sure the found white pixel is part of an actual circle,
; not a stray bright pixel from the UI or background.
; Checks that a small area around the pixel is also bright.
ConfirmCircle(cx, cy) {
    offsets := [{x: 3, y: 0}, {x: -3, y: 0}, {x: 0, y: 3}, {x: 0, y: -3}]
    brightCount := 0
    for i, o in offsets {
        px := cx + o.x
        py := cy + o.y
        if (px < GX1 || px > GX2 || py < GY1 || py > GY2)
            continue
        PixelGetColor, col, px, py, RGB
        if (IsBright(col, 150))
            brightCount++
    }
    return (brightCount >= 3)  ; At least 3 of 4 neighbors are bright
}

; ==========================
;  GAP MEASUREMENT (directional)
; ==========================
; Walk from (cx,cy) in direction (dx,dy).
; Step 1: skip through bright (white) inner circle pixels.
; Step 2: count non-bright, non-dark pixels (the gap/background).
; Step 3: when we hit a dark pixel (ring), return the gap size.
; Returns -1 if no ring found within range.
MeasureGapDir(cx, cy, dx, dy) {
    x := cx
    y := cy

    ; Step 1 — walk through the white inner circle
    Loop, 120 {
        x += dx
        y += dy
        if (x < GX1 || x > GX2 || y < GY1 || y > GY2)
            return -1
        PixelGetColor, col, x, y, RGB
        if (!IsBright(col, 140))
            break
    }

    ; Step 2 — count background pixels until dark ring
    gapPx := 0
    Loop, 150 {
        x += dx
        y += dy
        if (x < GX1 || x > GX2 || y < GY1 || y > GY2)
            return -1
        PixelGetColor, col, x, y, RGB
        if (IsDarkRing(col))
            return gapPx   ; Ring found
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

; ==========================
;  STARTUP
; ==========================
ShowStatus()
return
