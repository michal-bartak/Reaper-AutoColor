--[[
  about.lua -- who made this, where it lives, and which version you are running.

  The version is duplicated: ReaPack reads it from the header of
  Color/MXM_AutoColor.lua, which is a manifest and never ships to Scripts/, so
  nothing at runtime can see it. The copy here is the one the About dialog
  shows. A test keeps the two from drifting -- see MXM_AutoColor_RunTests.lua,
  "the shipped version matches the ReaPack manifest".
]]

return {
  -- Inside REAPER the tool is "AutoColor"; the repository and the docs site are
  -- "Reaper AutoColor". Both names are deliberate.
  NAME    = 'AutoColor',
  VERSION = '1.1.0beta1',
  AUTHOR  = 'Michal MaXyM Bartak',
  LICENCE = 'MIT',
  COPYRIGHT = 'Copyright (c) 2026 Michal Bartak',

  TAGLINE = 'Colour tracks, items, regions and markers, and set track icons, from their names.',

  URL_REPO = 'https://github.com/michal-bartak/Reaper-AutoColor',
  URL_DOCS = 'https://michal-bartak.github.io/Reaper-AutoColor/',
}
