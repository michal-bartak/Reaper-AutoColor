--[[
  MXM_AutoColor_Startup.lua -- run from Scripts/__startup.lua at REAPER launch.
  Starts background auto-colouring according to the Autostart option.
  Added to or removed from __startup.lua in the Options dialog.
]]

local sep = package.config:sub(1, 1)
local _, thisFile = reaper.get_action_context()
local ROOT = thisFile:match('^(.*[\\/])')
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib' .. sep .. '?.lua;' .. package.path

require('startup').boot(ROOT)
