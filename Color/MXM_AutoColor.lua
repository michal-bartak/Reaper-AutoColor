--[[
Description: AutoColor
Version: 1.1.0beta1
Author: Michal MaXyM Bartak
Links:
  GitHub https://github.com/michal-bartak/Reaper-AutoColor
About:
  # AutoColor

  Colours tracks, items, regions and markers, and sets track icons, from their
  **names**: plain substring, glob or **regular expression**.

  Each object type configured by separate set of rules. Within a set the first
  matching rule wins.

  The configuration window requires ReaImGui 0.10+.

  Config file stored in `MXM_AutoColor/config.json` under the REAPER resource
  path, outside Scripts/, to prevent overwriting on update.

  MIT licensed. Source: <https://github.com/michal-bartak/Reaper-AutoColor>
Metapackage: true
Changelog:
  - Track icons support.
  - New track filters: has an instrument, has a MIDI input, has receives.
  - SWS import.
  - Minor layout changes.

  Config file bumped to version 3. Earlier versions of AutoColor will open it
  in read-only mode.
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
