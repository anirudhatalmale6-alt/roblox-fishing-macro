==============================================================
  ROBLOX FISHING MINIGAME MACRO — Setup & Customization Guide
==============================================================

WHAT THIS DOES
--------------
A client-side AutoHotkey macro that automates the fishing
minigame by detecting circles on screen and clicking them
with human-like timing.  Supports all 3 minigame variants
and all 4 difficulty levels.

No exploits, no memory editing, no injection — only simulated
mouse clicks, exactly like a human player would do.


REQUIREMENTS
------------
1. AutoHotkey v1.1+  (free, download from https://www.autohotkey.com)
   - During install, pick "AutoHotkey v1.1" (not v2).
2. Windows 10 or 11.
3. Roblox running in WINDOWED or BORDERLESS-WINDOWED mode
   (full-screen exclusive may block AHK pixel reads).


QUICK START
-----------
1. Install AutoHotkey v1.1 if you haven't already.
2. Double-click  FishingMacro.ahk  — a tooltip appears in the
   top-left showing current settings.
3. Open Roblox and load into the fishing game.
4. Press F4 to calibrate the game area:
     - Click the TOP-LEFT corner of the minigame UI
     - Click the BOTTOM-RIGHT corner of the minigame UI
   This tells the macro where to look for circles.
5. Press F2 to select the right variant (1, 2, or 3).
6. Press F3 to select the right difficulty.
7. Equip the Super Rod, press F5 to cast.
8. Press F1 to start the macro — it will detect and click
   circles automatically until you press F1 again to stop.


HOTKEY REFERENCE
----------------
  F1   Toggle macro ON / OFF
  F2   Cycle variant:  1 → 2 → 3 → 1
  F3   Cycle difficulty:  Easy → Medium → Hard → Impossible
  F4   Calibrate game area (click two corners)
  F5   Cast rod (single left-click)
  F6   Color picker — hover over any pixel and press F6 to
       see its exact color value (useful for tuning)
  F12  Emergency exit — kills the script immediately


VARIANT DETAILS
---------------
Variant 1 — Multi-Circle (blue UI)
  Multiple colored circles (yellow, green, orange) appear at
  random positions.  The macro scans the game area for these
  colors and clicks them as fast as possible.  Aim: 10/10.

Variant 2 — Single Circle, Random Position (purple UI)
  One circle at a time appears at a random spot.  An outer
  ring shrinks toward the white inner circle.  The macro
  detects the gap between the inner circle and the ring,
  and clicks when the ring is close enough.

Variant 3 — Single Circle, Fixed Center (purple UI)
  Same as Variant 2, but the circle always appears at the
  center of the UI — slightly easier for the macro since
  it knows exactly where to look.


CUSTOMIZATION
-------------

>> Changing hotkeys:
   Open FishingMacro.ahk in a text editor.  Find lines like:
       F1::
   Change "F1" to your preferred key (e.g., "^F1" for Ctrl+F1,
   "!F1" for Alt+F1, "Numpad1" for numpad key 1).
   Save the file and reload (right-click tray icon → Reload).

>> Adjusting circle detection colors (Variant 1):
   If circles aren't being detected, use F6 to check what
   color the circles actually are on YOUR screen, then update
   V1_Yellow, V1_Green, V1_Orange values near the top of the
   script.  Increase the *Var values (e.g., from 55 to 70)
   to allow more color tolerance.

>> Adjusting ring timing (Variants 2 & 3):
   The key setting is  GapThreshold  — an array of 4 values
   for [Easy, Medium, Hard, Impossible].

   Current defaults:  [12, 8, 5, 3]

   - HIGHER number = clicks earlier (less precise, safer)
   - LOWER number  = clicks later  (more precise, riskier)

   If the macro clicks too early, decrease the value.
   If it clicks too late (misses), increase the value.

>> Adjusting humanization:
   HumanDelayMin / HumanDelayMax — random delay (ms) before
   each click.  Default: 15-55ms.

   ClickJitter — random pixel offset so clicks aren't always
   at the exact same spot.  Default: 4 pixels.

   PostClickPause — cooldown after each click to prevent
   double-clicking the same circle.  Default: 180ms.
   Decrease if circles appear faster than this.

>> Ring detection sensitivity:
   RingMinBrightness controls what counts as "dark ring".
   Default: 80.  If the macro mistakes background for ring,
   lower this value.  If it can't find the ring, raise it.


TROUBLESHOOTING
---------------
Problem: Macro doesn't detect any circles.
  → Recalibrate with F4.  Make sure the area covers the full
    minigame UI but not the Roblox taskbar or menus.
  → Use F6 to check actual circle colors and update settings.
  → Try increasing color variation values (*Var settings).
  → Make sure Roblox is in windowed mode, not fullscreen.

Problem: Clicks happen but don't register in game.
  → Run FishingMacro.ahk as Administrator (right-click →
    Run as administrator).  Roblox may block normal-privilege
    input injection.
  → Try switching SendMode from "Input" to "Event" in the
    script (change the line near the top).

Problem: Variant 2/3 clicks too early or too late.
  → Adjust the GapThreshold values.  Use small increments
    (change by 1-2 at a time).
  → Lower PostClickPause if circles come faster than 180ms.

Problem: Macro detects background as a circle.
  → Increase the brightness threshold in IsBright() function
    (change 170 to 200).
  → Narrow the game area with F4 to exclude non-game pixels.

Problem: Script won't start / AHK error.
  → Make sure you have AutoHotkey v1.1 installed (not v2).
  → Right-click the .ahk file → Open With → AutoHotkey.


NOTES
-----
- The macro only sends standard mouse clicks — the same input
  Windows generates when you physically click your mouse.
- All timing includes small random variations to appear natural.
- The script does NOT read game memory, inject code, or modify
  any Roblox files.
- Press F12 at any time to immediately kill the macro.
- If the game updates and changes circle colors or UI layout,
  use F6 to get the new colors and update the script settings.


==============================================================
  Version 1.0 — Built for the Roblox fishing rod minigame
==============================================================
