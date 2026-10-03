--[[
  MXM_AutoColor_AutoLoop.lua -- the background auto-colouring loop.

  Started and stopped by MXM_AutoColor_AutoToggle.lua; not meant to be bound to
  a button. The toggle clears the shared instance token to stop it, and the
  loop notices on its next tick.

  Set the ExtState MXM_AutoColor / auto_debug to "1" for a periodic console
  readout of ticks, sweeps, writes and per-tick cost.
]]

local sep = package.config:sub(1, 1)
local _, thisFile = reaper.get_action_context()
local ROOT = thisFile:match('^(.*[\\/])')
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib' .. sep .. '?.lua;' .. package.path

local autoloop = require 'autoloop'
local config   = require 'config'
local entry    = require 'entry'

local SECT = config.EXT_SECTION

if reaper.GetExtState(SECT, 'auto_instance') ~= '' then return end

math.randomseed(math.floor(reaper.time_precise() * 1e6) % 2147483647)
local TOKEN = string.format('%d:%d', os.time(), math.random(1, 1e9))
reaper.SetExtState(SECT, 'auto_instance', TOKEN, false)

--- The toolbar button belongs to the toggle action, not to this script.
local function set_toggle(state)
  local sec = tonumber(reaper.GetExtState(SECT, 'auto_section'))
  local cmd = tonumber(reaper.GetExtState(SECT, 'auto_cmdid'))
  if sec and cmd then
    reaper.SetToggleCommandState(sec, cmd, state)
    reaper.RefreshToolbar2(sec, cmd)
  end
end

set_toggle(1)
reaper.atexit(function()
  set_toggle(0)
  if reaper.GetExtState(SECT, 'auto_instance') == TOKEN then
    reaper.DeleteExtState(SECT, 'auto_instance', false)
  end
  reaper.DeleteExtState(SECT, 'auto_heartbeat', false)
end)

-- Set by the start-up script: a dialog on every REAPER launch would be a nuisance.
if reaper.GetExtState(SECT, 'auto_boot') == '1' then
  reaper.DeleteExtState(SECT, 'auto_boot', false)
else
  entry.warn_sws_once()
end
autoloop.reset()

--------------------------------------------------------------------- the loop
local errors = 0
local last_debug = 0

local function loop()
  -- The toggle (or the GUI) asked us to stop.
  if reaper.GetExtState(SECT, 'auto_instance') ~= TOKEN then return end

  if reaper.GetExtState(SECT, 'auto_enabled') ~= '0' then
    local ok, err = pcall(autoloop.tick)
    if not ok then
      errors = errors + 1
      -- Do not spam a broken loop at 5 Hz: say it once and stop cleanly.
      entry.msg('Background auto-colouring hit an error and has stopped:\n\n' ..
                tostring(err), 'AutoColor')
      return
    end
  end

  local now = os.time()
  reaper.SetExtState(SECT, 'auto_heartbeat', tostring(now), false)

  if reaper.GetExtState(SECT, 'auto_debug') == '1' and now - last_debug >= 5 then
    last_debug = now
    local s = autoloop.state.stats
    reaper.ShowConsoleMsg(string.format(
      'AutoColor auto: %d ticks, %d sweeps, %d writes, %d left alone, last tick %.2f ms\n',
      s.ticks, s.sweeps, s.writes, s.skipped, s.last_ms))
  end

  reaper.defer(loop)
end

reaper.defer(loop)
