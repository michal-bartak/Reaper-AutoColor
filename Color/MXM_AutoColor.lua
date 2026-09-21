--[[
Description: AutoColor
Version: 1.0.0
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
  First public release.

  Colour tracks, items, regions and markers from their names -- plain
  substring, glob, or real regular expressions. One ordered rule list per
  object kind, and within a kind the first rule that matches wins, so
  precedence works like firewall rules. The configuration window needs
  ReaImGui 0.10+; every other action, Apply and Clear included, works
  without it. Your rules live outside Scripts/, so updating never touches
  them.

  The scripts install to Scripts/MXM Scripts/MXM_AutoColor/, matching the
  layout of the repository. If you ran one of the 0.9.x pre-releases,
  ReaPack moves the files for you, but REAPER identifies an action by its
  path: toolbar buttons, keyboard shortcuts and custom actions bound to the
  old Scripts/MXM Scripts/Color/MXM_AutoColor/ location have to be pointed
  at the new one.
Provides:
  [main] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_GUI.lua > ../MXM_AutoColor/
  [main] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_AutoToggle.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ApplyAll.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ApplySelection.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_ClearColors.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_Dump.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_RunTests.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/MXM_AutoColor_WhyThisColour.lua > ../MXM_AutoColor/
  [nomain] /Reaper/Scripts/MXM_AutoColor/lib/*.lua > ../MXM_AutoColor/lib/
  [nomain] /Reaper/Scripts/MXM_AutoColor/lib/gui/*.lua > ../MXM_AutoColor/lib/gui/
  [data] /Reaper/Data/toolbar_icons/*.png > toolbar_icons/
  [data] /Reaper/Data/toolbar_icons/150/*.png > toolbar_icons/150/
  [data] /Reaper/Data/toolbar_icons/200/*.png > toolbar_icons/200/
]]--
