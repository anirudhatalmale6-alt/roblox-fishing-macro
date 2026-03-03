==============================================================
  ROBLOX FISHING MINIGAME MACRO v2.0 — AUTO-DETECT
==============================================================

WHAT'S NEW IN v2
----------------
- Fully automatic variant detection — no need to press F2/F3!
- The script figures out which minigame variant is active and
  handles it automatically, including all 4 difficulties.


HOW IT WORKS
------------
Every scan cycle (~100 times/sec) the macro runs two strategies:

  Strategy A (Variant 1 — multi-circle, blue UI):
    Scans for brightly colored circles (yellow, green, orange).
    If found → clicks immediately.

  Strategy B (Variants 2 & 3 — ring timing, purple UI):
    Scans for a white/gray inner circle.  Measures the pixel
    gap between the inner circle and the shrinking dark ring.
    When the ring is close enough → clicks.

Whichever strategy finds a target first wins.  No manual
switching needed — it handles all 3 variants and all 4
difficulty levels automatically.


REQUIREMENTS
------------
1. AutoHotkey v1.1+  (free: https://www.autohotkey.com)
   During install, pick "AutoHotkey v1.1" (not v2).
2. Windows 10 or 11.
3. Roblox in WINDOWED or BORDERLESS-WINDOWED mode
   (full-screen exclusive may block pixel detection).


QUICK START
-----------
1. Install AutoHotkey v1.1.
2. Double-click  FishingMacro.ahk  — tooltip appears.
3. Open Roblox, load into the fishing game.
4. Press F4 to calibrate the game area:
     - Click the TOP-LEFT corner of the minigame UI.
     - Click the BOTTOM-RIGHT corner of the minigame UI.
5. Equip the Super Rod, press F5 to cast.
6. Press F1 to start the macro.
7. The macro detects and clicks circles automatically.
8. Press F1 again to stop.


HOTKEY REFERENCE
----------------
  F1   Toggle macro ON / OFF
  F4   Calibrate game area (click two corners)
  F5   Cast rod (single left-click)
  F6   Color picker (hover over any pixel, press F6 for value)
  F7   Decrease gap threshold (more precise ring timing)
  F8   Increase gap threshold (more forgiving ring timing)
  F12  Emergency exit — kills script immediately


TUNING THE GAP THRESHOLD
-------------------------
The "gap threshold" controls when the macro clicks during the
ring-shrinking minigames (Variants 2 & 3).

  Default: 7 pixels

  F7 = decrease (click LATER — more precise, riskier)
  F8 = increase (click EARLIER — safer, less precise)

How to tune:
  1. Start a round with F1.
  2. Watch whether the macro clicks too early or too late.
  3. Adjust with F7/F8 while playing.
  4. Once you find the sweet spot, edit GapThresh in the
     script to save it permanently.


CUSTOMIZATION
-------------
Open FishingMacro.ahk in any text editor (Notepad works).

>> Circle colors (Strategy A):
   If circles aren't being detected, use F6 to check actual
   colors on YOUR screen.  Update V1_Yellow, V1_Green,
   V1_Orange values.  Increase *Var values (e.g., 55 → 70)
   for more tolerance.

>> White circle detection (Strategy B):
   Adjust V23_White and V23_WhiteVar if the inner circle isn't
   being found.

>> Ring darkness:
   RingMinBrightness (default 80) controls what counts as "dark
   ring".  Lower = stricter.  Raise if ring isn't being detected.

>> Humanization:
   HumanDelayMin/Max — random delay before each click (15-55ms).
   ClickJitter — random pixel offset (4px).
   PostClickPause — cooldown after click (170ms).

>> Hotkeys:
   Change "F1::" to any key.  Examples:
     ^F1::   = Ctrl+F1
     !F1::   = Alt+F1
     Numpad1:: = numpad 1


TROUBLESHOOTING
---------------
Problem: Nothing happens when macro is ON.
  → Recalibrate with F4.  Make sure area covers ONLY the
    minigame UI, not menus or toolbar.
  → Use F6 to verify circle colors match the script settings.
  → Try increasing *Var color tolerance values.

Problem: Clicks happen but game doesn't register them.
  → Right-click FishingMacro.ahk → Run as administrator.
  → Roblox sometimes blocks non-elevated input.

Problem: Macro clicks too early on ring minigames.
  → Press F7 a few times to decrease gap threshold.

Problem: Macro misses the ring (clicks too late).
  → Press F8 a few times to increase gap threshold.

Problem: Macro clicks on background/non-circle pixels.
  → Tighten the game area with F4.
  → Lower color *Var values for tighter matching.
  → Increase RingMinBrightness if it mistakes BG for ring.

Problem: AHK error on launch.
  → Make sure you have AutoHotkey v1.1, not v2.


NOTES
-----
- Only sends standard mouse clicks — same as physical mouse.
- Random timing + position jitter for human-like behavior.
- Does NOT read game memory, inject code, or modify files.
- The tooltip shows which detection mode is active (multi-
  circle or ring-timing) so you can verify it's working.
- If the game updates circle colors, use F6 to get new values.


==============================================================
  v2.0 — Auto-detect variant & difficulty
==============================================================
