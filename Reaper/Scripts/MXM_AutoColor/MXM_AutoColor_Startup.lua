--[[
  MXM_AutoColor_Startup.lua -- run from Scripts/__startup.lua at REAPER launch.
  Starts background auto-colouring according to the Autostart option.
  Added to or removed from __startup.lua in the Options dialog.
]]

local sep = package.config:sub(1, 1)
local ROOT = debug.getinfo(1, 'S').source:match('^@(.*[\\/])')
if not ROOT then return end
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib' .. sep .. '?.lua;' .. package.path

local ok, startup = pcall(require, 'startup')
if ok then pcall(startup.boot, ROOT) end
