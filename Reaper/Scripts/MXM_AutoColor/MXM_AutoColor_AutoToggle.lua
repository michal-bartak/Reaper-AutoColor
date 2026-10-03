--[[
  MXM_AutoColor_AutoToggle.lua -- start/stop background auto-colouring.

  Run once to start (the toolbar button lights up), run again to stop.
  set_action_options(3) makes a run while the loop is live terminate it and
  then run this script again, so every click reaches this code: the second run
  finds the token left behind and records the stop. This script is the one
  place that records the intended state (active_last), which the start-up
  script reads.

  Set the ExtState MXM_AutoColor / auto_debug to "1" for a periodic console
  readout of ticks, sweeps, writes and per-tick cost.
]]

local sep = package.config:sub(1, 1)
local _, thisFile, sectionID, cmdID = reaper.get_action_context()
local ROOT = thisFile:match('^(.*[\\/])')
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib' .. sep .. '?.lua;' .. package.path

local autoloop = require 'autoloop'
local config   = require 'config'
local entry    = require 'entry'

local SECT = config.EXT_SECTION

if not reaper.set_action_options then
  entry.msg('Background auto-colouring requires REAPER 7.03 or later.', 'AutoColor')
  return
end
reaper.set_action_options(3)

require('startup').ensure()

-- Remember how to invoke this action, so the configuration window and the
-- start-up script can run it. A script's command id is only knowable from
-- inside the script; the named one is the form that survives a restart.
local known = sectionID and sectionID >= 0 and cmdID and cmdID ~= 0
if known then
  reaper.SetExtState(SECT, 'auto_cmdid', tostring(cmdID), true)
  reaper.SetExtState(SECT, 'auto_section', tostring(sectionID), true)
  local name = reaper.ReverseNamedCommandLookup(cmdID)
  if name then reaper.SetExtState(SECT, 'auto_cmd_name', (name:gsub('^_', '')), true) end
end

local function set_toggle(state)
  if known then
    reaper.SetToggleCommandState(sectionID, cmdID, state)
    reaper.RefreshToolbar2(sectionID, cmdID)
  end
end

-- Set by the start-up script: a dialog on every REAPER launch would be a nuisance.
local booting = reaper.GetExtState(SECT, 'auto_boot') == '1'
reaper.DeleteExtState(SECT, 'auto_boot', false)

------------------------------------------------------------------------ stop
-- A token with a fresh heartbeat means this run is the re-launch that just
-- terminated the loop. A stale one is left by a loop ended some other way
-- (the Action list, an error), and this click is then a start.
local hb = tonumber(reaper.GetExtState(SECT, 'auto_heartbeat'))
if reaper.GetExtState(SECT, 'auto_instance') ~= '' and hb and os.time() - hb <= 3 then
  reaper.DeleteExtState(SECT, 'auto_instance', false)
  reaper.DeleteExtState(SECT, 'auto_heartbeat', false)
  reaper.SetExtState(SECT, 'active_last', '0', true)
  set_toggle(0)
  return
end

----------------------------------------------------------------------- start
math.randomseed(math.floor(reaper.time_precise() * 1e6) % 2147483647)
local TOKEN = string.format('%d:%d', os.time(), math.random(1, 1e9))
reaper.SetExtState(SECT, 'auto_instance', TOKEN, false)
-- Written now, not on the first tick, so a double-click still reads as a stop.
reaper.SetExtState(SECT, 'auto_heartbeat', tostring(os.time()), false)
reaper.SetExtState(SECT, 'active_last', '1', true)
set_toggle(1)

local stopped_self = false
reaper.atexit(function()
  local cur = reaper.GetExtState(SECT, 'auto_instance')
  if cur ~= TOKEN and cur ~= '' then return end   -- a newer start owns the button
  set_toggle(0)
  -- A re-launch and REAPER quitting look the same here, so the token and
  -- heartbeat stay for the re-launched run to read. Both are session-only.
  if stopped_self then
    reaper.DeleteExtState(SECT, 'auto_instance', false)
    reaper.DeleteExtState(SECT, 'auto_heartbeat', false)
  end
end)

if not booting then entry.warn_sws_once() end
autoloop.reset()

--------------------------------------------------------------------- the loop
local last_debug = 0

local function loop()
  if reaper.GetExtState(SECT, 'auto_instance') ~= TOKEN then return end

  if reaper.GetExtState(SECT, 'auto_enabled') ~= '0' then
    local ok, err = pcall(autoloop.tick)
    if not ok then
      -- Do not spam a broken loop at 5 Hz: say it once and stop cleanly.
      stopped_self = true
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
