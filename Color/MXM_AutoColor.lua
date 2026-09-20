--[[
Description: AutoColor
Version: 0.9.1
Author: Michal MaXyM Bartak
Links:
  GitHub https://github.com/michal-bartak/Reaper-AutoColor
About:
  # AutoColor

  Colour tracks, items, regions and markers from their **names**, using plain
  substring, glob, or **real regular expressions**.

  One ordered rule list per object kind -- Tracks, Items, Regions, Markers --
  and within a kind the first rule that matches wins, so precedence works like
  firewall rules. Reordering track rules can never change which region wins.

  The configuration window needs ReaImGui 0.10+. Every other action, including
  Apply and Clear, works without it.

  Your rules live in `MXM_AutoColor/config.json` under REAPER's resource
  path, outside Scripts/, so updating or reinstalling never touches them.

  MIT licensed. Source: <https://github.com/michal-bartak/Reaper-AutoColor>
Metapackage: true
Changelog:
  Options dialog no longer closes when REAPER loses focus, and no longer
  flickers when you click elsewhere. It is always on top, dismissed with
  Escape, its Close button, or a click on the window behind.
  New About dialog: version, links, author, licence.
  Text size is capped at 20 and applied when the slider is released.
  "Example rules" (was "Replace with the starter rules") is joined by
  "Remove Rules", which empties every tab.
  The pattern tester's right edge lines up with the table above it again.
  The pattern tester's mode buttons are drawn as one divided control.
Provides:
  [main] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_GUI.lua > MXM_AutoColor/
  [main] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_AutoToggle.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ApplyAll.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ApplySelection.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ClearColors.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_Dump.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_RunTests.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_WhyThisColour.lua > MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/lib/*.lua > MXM_AutoColor/lib/
  [nomain] /Reaper/Scripts/MXM_AutoColor/lib/gui/*.lua > MXM_AutoColor/lib/gui/
  [data] /Reaper/Data/toolbar_icons/*.png > toolbar_icons/
  [data] /Reaper/Data/toolbar_icons/150/*.png > toolbar_icons/150/
  [data] /Reaper/Data/toolbar_icons/200/*.png > toolbar_icons/200/
]]--
