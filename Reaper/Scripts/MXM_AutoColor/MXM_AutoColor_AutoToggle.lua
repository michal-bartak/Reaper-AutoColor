--[[
  MXM_AutoColor_AutoToggle.lua -- start/stop background auto-colouring.

  Runs once and exits, so REAPER never has an instance of it to terminate or
  prompt about: every click reaches this code. The loop itself is
  MXM_AutoColor_AutoLoop.lua. This script is the one place that records the
  intended state (active_last), which the start-up script reads.
]]

local sep = package.config:sub(1, 1)
local _, thisFile, sectionID, cmdID = reaper.get_action_context()
local ROOT = thisFile:match('^(.*[\\/])')
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib' .. sep .. '?.lua;' .. package.path

local config = require 'config'
local SECT = config.EXT_SECTION

require('startup').ensure()

-- Remember how to invoke this action, so the configuration window can start
-- and stop it. A script's command id is only knowable from inside the script.
local known = sectionID and sectionID >= 0 and cmdID and cmdID ~= 0
if known then
  reaper.SetExtState(SECT, 'auto_cmdid', tostring(cmdID), true)
  reaper.SetExtState(SECT, 'auto_section', tostring(sectionID), true)
end

local function set_toggle(state)
  if known then
    reaper.SetToggleCommandState(sectionID, cmdID, state)
    reaper.RefreshToolbar2(sectionID, cmdID)
  end
end

if reaper.GetExtState(SECT, 'auto_instance') ~= '' then
  -- Running: clear the token, and the loop exits on its next tick.
  reaper.SetExtState(SECT, 'auto_instance', '', false)
  reaper.SetExtState(SECT, 'active_last', '0', true)
  set_toggle(0)
  return
end

reaper.SetExtState(SECT, 'active_last', '1', true)
set_toggle(1)

-- Registering is idempotent and returns the existing command id.
local loop = reaper.AddRemoveReaScript(true, 0, ROOT .. 'MXM_AutoColor_AutoLoop.lua', true)
if loop and loop > 0 then reaper.Main_OnCommand(loop, 0) end
