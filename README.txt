==============================================================
  ROBLOX FISHING MINIGAME MACRO v3.0 — FULLY AUTOMATIC
==============================================================

Press F1 and walk away.  The macro handles everything:
casting, playing the minigame, and recasting in a loop.


HOW IT WORKS
------------
The macro runs a 4-state loop:

  CASTING   → Left-clicks to cast the rod
  WAITING   → Scans for circles (minigame starting)
  PLAYING   → Detects and clicks circles automatically
  COOLDOWN  → Round ended, brief pause, then recasts

Circle detection uses 3 layered strategies:

  1. Known-color search:  Scans for 9 pre-defined circle
     colors (yellow, green, orange, pink, purple, red,
     light blue, deep blue, cyan).

  2. Saturation scan (fallback):  Grid-scans for ANY vivid
     pixel that stands out from the water background.
     Catches circle colors not in the pre-defined list.

  3. Ring-timing (Variants 2 & 3):  Finds the white inner
     circle, measures gap to the shrinking ring, clicks
     when the ring is close enough.


REQUIREMENTS
------------
1. AutoHotkey v1.1+  (free: https://www.autohotkey.com)
2. Windows 10 or 11
3. Roblox in WINDOWED or BORDERLESS-WINDOWED mode


QUICK START
-----------
1. Install AutoHotkey v1.1
2. Double-click FishingMacro.ahk
3. Open Roblox, go to the fishing spot
4. Press F4 to calibrate:
     - Click TOP-LEFT of the minigame area
     - Click BOTTOM-RIGHT of the minigame area
5. Equip the Super Rod
6. Press F1 — the macro starts casting and playing!
7. Press F1 again to stop


HOTKEYS
-------
  F1   Start / Stop the full-auto loop
  F4   Calibrate game area (click two corners)
  F6   Color picker (hover + press to see pixel info)
  F7   Decrease gap threshold (more precise ring timing)
  F8   Increase gap threshold (more forgiving ring timing)
  F12  Emergency exit


TUNING
------
>> Gap threshold (Variants 2 & 3 ring timing):
   Default: 7px.  Adjust live with F7 (tighter) / F8 (looser).
   If clicks are too early → F7.  Too late → F8.

>> Circle colors:
   If a new color appears that isn't detected, use F6 to
   check its value, then add it to CircleColors in the script.

>> Saturation scan:
   MinSaturation (default 90) — lower to catch less vivid circles.
   WaterBlueMargin (default 50) — raise if water is getting
   false-detected; lower if blue circles aren't being found.

>> Automation timing:
   CastClickDelay (300ms) — time for the cast click
   WaitForGameMax (8000ms) — how long to wait for minigame
   RoundEndTimeout (2500ms) — no circles for this long = round over
   RecastDelay (1500ms) — pause between rounds

>> Humanization:
   HumanDelayMin/Max (15-55ms) — random click delay
   ClickJitter (4px) — random position offset
   PostClickPause (170ms) — cooldown between clicks


TROUBLESHOOTING
---------------
Problem: Macro casts but never starts playing.
  → Recalibrate with F4.  Area must cover the minigame UI.
  → Circle colors might not match — use F6 to check and
    add new colors to CircleColors array.
  → Try lowering MinSaturation (e.g., 90 → 60).

Problem: Macro clicks on water instead of circles.
  → Tighten F4 calibration to just the minigame UI.
  → Raise WaterBlueMargin (e.g., 50 → 70).
  → Raise MinSaturation (e.g., 90 → 110).

Problem: Clicks don't register in game.
  → Run as Administrator (right-click → Run as admin).

Problem: Ring timing is off.
  → Use F7/F8 to fine-tune while playing.

Problem: Recasts too early / too late.
  → Adjust RoundEndTimeout (raise if ending too early).
  → Adjust RecastDelay (raise for longer pause between rounds).


==============================================================
  v3.0 — Fully automatic: cast, detect, play, recast loop
==============================================================
