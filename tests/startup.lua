package.path = os.getenv('SP') .. '/?.lua;' .. package.path
local mock = require 'mockreaper'
local NC, TMP = os.getenv('NC'), os.getenv('SP') .. '/startup'
os.execute('rm -rf "' .. TMP .. '" && mkdir -p "' .. TMP .. '/Scripts" "' .. TMP .. '/MXM_AutoColor"')

local pass, fail, fails = 0, 0, {}
local function check(ok, label, detail)
  if ok then pass = pass + 1
  else fail = fail + 1; fails[#fails+1] = label .. (detail and ('  -- ' .. detail) or '') end
end

local P = mock.install{ resource = TMP, script = NC .. '/x.lua' }
package.path = NC .. '/?.lua;' .. NC .. '/lib/?.lua;' .. package.path

local config  = require 'config'
local startup = require 'startup'
local SECT = config.EXT_SECTION

local function read(p) local f = io.open(p, 'rb'); if not f then return nil end
  local s = f:read('a'); f:close(); return s end
local function write(p, s) local f = assert(io.open(p, 'wb')); f:write(s); f:close() end

---------------------------------------------------------------- __startup.lua
local F = startup.path()
check(not startup.installed(), 'not installed when the file is missing')

assert(startup.install())
check(startup.installed(), 'install creates the file')
check(read(F):find('MXM_AutoColor_Startup.lua', 1, true) ~= nil, 'block names the bootstrap')

assert(startup.remove())
check(read(F) == nil, 'removing the only content deletes the file')

write(F, '-- mine\nreaper.ShowConsoleMsg("hi")\n')
assert(startup.install())
local once = read(F)
assert(startup.install())
check(read(F) == once, 'a repeated install changes nothing')
check(once:sub(1, 36) == '-- mine\nreaper.ShowConsoleMsg("hi")\n', 'existing content kept')

write(F, once .. '-- after\n')
assert(startup.remove())
check(read(F) == '-- mine\nreaper.ShowConsoleMsg("hi")\n-- after\n',
      'remove leaves everything else intact', tostring(read(F)))
check(not startup.installed(), 'no longer installed')

assert(startup.remove())
check(startup.ensure() and startup.installed(), 'ensure adds a missing block')
check(not startup.ensure(), 'ensure does nothing when the block is present')

-- A block left by an older build, pointing at the wrong place, is replaced.
write(F, (read(F):gsub('MXM_AutoColor_Startup%.lua', 'Elsewhere/Startup.lua')))
check(startup.ensure(), 'ensure replaces a stale block')
check(read(F):find('MXM_AutoColor_Startup.lua', 1, true) ~= nil, 'and points at the bootstrap')
check(not startup.ensure(), 'then leaves it alone')
-- The path in the block is where the scripts really are.
local nc = (NC:gsub('\\', '/'))
check(read(F):find(nc, 1, true) ~= nil, 'block names the real script folder', read(F))

-- The block runs with nothing but reaper.* in reach: __startup.lua is a state
-- shared with other entries, so package, require and globals are off limits.
assert(startup.install())
local function run_block(exists)
  local calls = {}
  local env = { reaper = {
    GetResourcePath = reaper.GetResourcePath,
    file_exists = function(p) calls.checked = p; return exists end,
    AddRemoveReaScript = function(add, sec, p, commit)
      calls.registered = p; return 99 end,
    Main_OnCommand = function(id) calls.ran = id end,
  } }
  local ok, err = pcall(load(read(F), '=startup', 't', env))
  return ok, err, calls, env
end

local ok, err, calls = run_block(false)
check(ok, 'block runs with only reaper.* available', tostring(err))
check(calls.registered == nil and calls.ran == nil,
      'block is a no-op when the bootstrap is missing')

local ok2, err2, calls2, env2 = run_block(true)
check(ok2, 'block runs when the bootstrap is present', tostring(err2))
check(calls2.registered == calls2.checked
      and calls2.checked:find('MXM_AutoColor_Startup.lua', 1, true) ~= nil,
      'block registers the bootstrap it checked', tostring(calls2.registered))
check(calls2.ran == 99, 'and runs it as an action')
local leaked = {}
for k in pairs(env2) do if k ~= 'reaper' then leaked[#leaked + 1] = k end end
check(#leaked == 0, 'block leaves no globals behind', table.concat(leaked, ', '))

--------------------------------------------------------------------- decision
check(startup.should_start('on', ''),  'always starts')
check(not startup.should_start('off', '1'), 'never does not start')
check(startup.should_start('last', '1'), 'last: was running -> start')
check(not startup.should_start('last', '0'), 'last: was stopped -> no start')
check(not startup.should_start('last', ''), 'last: no history -> no start')

------------------------------------------------------------------------- boot
local ran
reaper.AddRemoveReaScript = function() return 4242 end
reaper.Main_OnCommand = function(c) ran = c end

local function boot(mode, last, instance)
  local cfg = config.defaults(); cfg.options.autostart = mode
  assert(config.save(cfg))
  P.extstate[SECT] = { active_last = last, auto_instance = instance }
  ran = nil
  return startup.boot(NC .. '/')
end

check(boot('on', '', '') and ran == 4242, 'boot runs the toggle action')
check(P.extstate[SECT].auto_boot == '1', 'boot flags the launch')
check(not boot('off', '1', '') and ran == nil, 'boot honours "never"')
check(not boot('last', '0', '') and ran == nil, 'boot honours a stopped last state')
check(boot('last', '1', '') and ran == 4242, 'boot resumes a running last state')
check(not boot('on', '', 'tok') and ran == nil, 'boot leaves a running loop alone')

------------------------------------------------------------------- the toggle
do
  local launched, state = nil, nil
  reaper.AddRemoveReaScript = function() return 7 end
  reaper.Main_OnCommand = function(c) launched = c end
  reaper.SetToggleCommandState = function(_, _, s) state = s end
  local function click(instance)
    local was = P.extstate[SECT] and P.extstate[SECT].active_last
    P.extstate[SECT] = { auto_instance = instance, active_last = was }
    launched, state = nil, nil
    dofile(NC .. '/MXM_AutoColor_AutoToggle.lua')
  end

  click('')
  check(launched == 7, 'toggle starts the loop when it is not running')
  check(P.extstate[SECT].active_last == '1', 'and records the intent to run')
  check(state == 1, 'and lights the button')

  click('tok')
  check(launched == nil, 'toggle does not launch a second loop')
  check(P.extstate[SECT].auto_instance == '', 'a click while running clears the token')
  check(P.extstate[SECT].active_last == '0', 'and records the intent to stop')
  check(state == 0, 'and dims the button')
end

print('\n=== startup (mock REAPER) ===')
for _, f in ipairs(fails) do print('  FAIL  ' .. f) end
print(string.format('%d passed, %d failed\n', pass, fail))
os.exit(fail == 0 and 0 or 1)
