; ============================================================
;  ROBLOX FISHING MINIGAME MACRO  v3.0  —  FULLY AUTOMATIC
; ============================================================
;
;  Press F1 and walk away.  The macro will:
;    1. Cast the rod (left-click)
;    2. Wait for the minigame to start
;    3. Auto-detect variant and click circles
;    4. When the round ends, wait and recast
;    5. Repeat forever until you press F1 again
;
;  Works with ALL circle colors and ALL 3 variants.
;
;  HOTKEYS:
;    F1  = Start / Stop full-auto loop
;    F4  = Calibrate game area (click two corners)
;    F6  = Color picker (debug tool)
;    F7  = Decrease gap threshold (ring timing: more precise)
;    F8  = Increase gap threshold (ring timing: more forgiving)
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
; Recalibrate with F4 for your setup.
global GX1 := 110
global GY1 := 30
global GX2 := 1810
global GY2 := 640

; --- Strategy A: colored circle palette ---
; All known circle colors.  Add more if new ones appear.
; Use F6 to check colors on your screen.
global CircleColors := []

; --- Strategy B: white inner circle (Variants 2 & 3) ---
global V23_White    := 0xD8D8D8
global V23_WhiteVar := 45

; --- Ring gap threshold ---
; How close the ring must be before clicking (pixels).
; Adjust live with F7/F8.  Default 7 works across difficulties.
global GapThresh := 7

; Ring outline: pixel is "ring" if R,G,B all below this.
global RingMinBrightness := 80

; --- Saturation scan (fallback for unknown colors) ---
; If no known color matches, grid-scan for any vivid pixel.
; MinSaturation: how vivid a pixel must be (max-min of RGB).
; MinBrightness: how bright the brightest channel must be.
global SatScanStep      := 20    ; grid spacing in pixels
global MinSaturation    := 90    ; color vividness threshold
global MinBrightness    := 130   ; brightness threshold
; Exclude water-blue pixels: skip if Blue is dominant by this margin
global WaterBlueMargin  := 50

; --- Automation timing ---
global CastClickDelay   := 300   ; ms to hold before releasing cast
global WaitForGameMax   := 8000  ; ms to wait for minigame after cast
global RoundEndTimeout  := 2500  ; ms with no circles = round over
global RecastDelay      := 1500  ; ms pause between rounds

; --- Humanization ---
global HumanDelayMin    := 15
global HumanDelayMax    := 55
global ClickJitter      := 4
global PostClickPause   := 170

; ==========================
;  INITIALIZE COLORS
; ==========================
InitColors() {
    CircleColors := []
    ; Yellow
    CircleColors.Push({c: 0xE8E800, v: 55})
    ; Green
    CircleColors.Push({c: 0x30D830, v: 55})
    ; Orange
    CircleColors.Push({c: 0xE89830, v: 55})
    ; Pink / Magenta
    CircleColors.Push({c: 0xE840A0, v: 55})
    ; Purple
    CircleColors.Push({c: 0x9040E0, v: 55})
    ; Red
    CircleColors.Push({c: 0xE83030, v: 55})
    ; Light blue (tighter variation to avoid matching water)
    CircleColors.Push({c: 0x4090F0, v: 35})
    ; Deep blue
    CircleColors.Push({c: 0x3050D0, v: 35})
    ; Cyan / Teal circle (distinct from water by saturation)
    CircleColors.Push({c: 0x30E8D0, v: 40})
}
InitColors()

; ==========================
;  INTERNAL STATE
; ==========================
global MacroState     := "IDLE"   ; IDLE, CASTING, WAITING, PLAYING, COOLDOWN
global LastClickTick  := 0
global LastFoundTick  := 0        ; last time we found a circle
global StateStartTick := 0
global DetectedMode   := ""

; ==========================
;  STATUS TOOLTIP
; ==========================
ShowStatus() {
    st := Running ? "RUNNING" : "STOPPED"
    ToolTip, % "Fishing Macro [" st "]  Auto-Loop`n"
        . "State: " MacroState "  |  Mode: " DetectedMode "`n"
        . "Gap: " GapThresh "px  |  Area: (" GX1 "," GY1 ")-(" GX2 "," GY2 ")`n"
        . "F1=Start/Stop  F4=Calibrate  F7/F8=Gap  F12=Exit"
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
        MacroState := "CASTING"
        StateStartTick := A_TickCount
        DetectedMode := ""
        ShowStatus()
        SetTimer, AutoLoop, 10
    } else {
        MacroState := "IDLE"
        SetTimer, AutoLoop, Off
        ShowStatus()
    }
return

F4::
    Running := false
    MacroState := "IDLE"
    SetTimer, AutoLoop, Off
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

F6::
    MouseGetPos, mx, my
    PixelGetColor, col, mx, my, RGB
    hex := Format("0x{:06X}", col)
    r := (col >> 16) & 0xFF
    g := (col >> 8)  & 0xFF
    b := col & 0xFF
    sat := Max(r, Max(g, b)) - Min(r, Min(g, b))
    ToolTip, % "(" mx "," my "): " hex " R=" r " G=" g " B=" b " Sat=" sat
    SetTimer, HideTip, -5000
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

F12::
    ExitApp
return

; ==========================
;  MAIN AUTO-LOOP
; ==========================
; State machine:
;   CASTING  → click to cast rod
;   WAITING  → scan for circles (minigame starting)
;   PLAYING  → click circles as they appear
;   COOLDOWN → round over, pause before recasting
AutoLoop:
    if (!Running)
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
;  STATE: CASTING — click to cast the rod
; --------------------------------------------------
DoCasting() {
    ; Add human-like delay before casting
    Random, d, 200, 500
    Sleep, d
    Click
    Sleep, CastClickDelay

    ; Move to WAITING state
    MacroState := "WAITING"
    StateStartTick := A_TickCount
    DetectedMode := ""
    ToolTip, % "Fishing Macro [RUNNING]`nCast! Waiting for minigame..."
    SetTimer, HideTip, -3000
}

; --------------------------------------------------
;  STATE: WAITING — look for the minigame to appear
; --------------------------------------------------
DoWaiting() {
    ; Check if we've been waiting too long (no minigame appeared)
    elapsed := A_TickCount - StateStartTick
    if (elapsed > WaitForGameMax) {
        ; Timeout — try casting again
        MacroState := "CASTING"
        StateStartTick := A_TickCount
        return
    }

    ; Try to find any circle
    if (TryFindAndClick()) {
        ; Found something — minigame is active!
        MacroState := "PLAYING"
        LastFoundTick := A_TickCount
        StateStartTick := A_TickCount
        ShowStatus()
    }
}

; --------------------------------------------------
;  STATE: PLAYING — actively clicking circles
; --------------------------------------------------
DoPlaying() {
    ; Cooldown guard
    elapsed := A_TickCount - LastClickTick
    if (elapsed < PostClickPause)
        return

    ; Try to find and click a circle
    if (TryFindAndClick()) {
        LastFoundTick := A_TickCount
    }

    ; Check if round is over (no circles for a while)
    sinceLastFound := A_TickCount - LastFoundTick
    if (sinceLastFound > RoundEndTimeout) {
        ; Round seems over
        MacroState := "COOLDOWN"
        StateStartTick := A_TickCount
        ToolTip, % "Fishing Macro [RUNNING]`nRound over! Recasting soon..."
        SetTimer, HideTip, -2000
    }
}

; --------------------------------------------------
;  STATE: COOLDOWN — pause before next cast
; --------------------------------------------------
DoCooldown() {
    elapsed := A_TickCount - StateStartTick
    if (elapsed > RecastDelay) {
        ; Add random extra wait for human-like behavior
        Random, extra, 200, 800
        Sleep, extra
        MacroState := "CASTING"
        StateStartTick := A_TickCount
    }
}

; ==========================
;  CIRCLE DETECTION ENGINE
; ==========================
; Tries all detection strategies.  Returns true if a circle
; was found and clicked.

TryFindAndClick() {
    ; --- Strategy A: search for known circle colors ---
    for i, entry in CircleColors {
        PixelSearch, fx, fy, GX1, GY1, GX2, GY2, entry.c, entry.v, Fast RGB
        if (ErrorLevel = 0) {
            DetectedMode := "multi-circle"
            HumanClick(fx, fy)
            return true
        }
    }

    ; --- Strategy A fallback: saturation grid scan ---
    ; Catches ANY vivid color we didn't list above.
    if (SaturationScan(fx, fy)) {
        DetectedMode := "multi-circle (sat)"
        HumanClick(fx, fy)
        return true
    }

    ; --- Strategy B: white circle + ring timing ---
    if (TryRingTiming()) {
        return true
    }

    return false
}

; ==========================
;  SATURATION GRID SCAN
; ==========================
; Scans the game area on a grid looking for any pixel with
; high color saturation (vivid color = circle, not background).
; Skips water-blue pixels.  Returns true if found.
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

            ; Must be vivid and reasonably bright
            if (sat > MinSaturation && maxC > MinBrightness) {
                ; Skip water-blue: blue is dominant by a large margin
                if (b > r + WaterBlueMargin && b > g + WaterBlueMargin) {
                    ; Looks like water — skip
                } else {
                    outX := x
                    outY := y
                    return true
                }
            }
            x += SatScanStep
        }
        y += SatScanStep
    }
    return false
}

; ==========================
;  STRATEGY B — Ring timing
; ==========================
TryRingTiming() {
    ; Find white inner circle
    PixelSearch, cx, cy, GX1, GY1, GX2, GY2, V23_White, V23_WhiteVar, Fast RGB
    if (ErrorLevel != 0)
        return false

    ; Confirm it's a real circle (not stray white pixel)
    if (!ConfirmCircle(cx, cy))
        return false

    ; Measure gap in 4 directions, take smallest
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

; ==========================
;  CIRCLE CONFIRMATION
; ==========================
ConfirmCircle(cx, cy) {
    offsets := [{x: 4, y: 0}, {x: -4, y: 0}, {x: 0, y: 4}, {x: 0, y: -4}]
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
    return (brightCount >= 3)
}

; ==========================
;  GAP MEASUREMENT
; ==========================
MeasureGapDir(cx, cy, dx, dy) {
    x := cx
    y := cy

    ; Skip through white inner circle
    Loop, 120 {
        x += dx
        y += dy
        if (x < GX1 || x > GX2 || y < GY1 || y > GY2)
            return -1
        PixelGetColor, col, x, y, RGB
        if (!IsBright(col, 140))
            break
    }

    ; Count background pixels until dark ring
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
