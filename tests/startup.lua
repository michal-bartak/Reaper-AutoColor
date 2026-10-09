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
check(once:find('("hi")\n\n-- MXM_AutoColor BEGIN', 1, true) ~= nil,
      'a blank line separates the block', once)

write(F, once .. '-- after\n')
assert(startup.remove())
check(read(F) == '-- mine\nreaper.ShowConsoleMsg("hi")\n-- after\n',
      'remove leaves everything else intact', tostring(read(F)))
check(not startup.installed(), 'no longer installed')

assert(startup.remove())
check(startup.ensure() and startup.installed(), 'ensure adds a missing block')
check(not startup.ensure(), 'ensure does nothing when the block is present')

-- A block written before the blank line existed gets one.
write(F, (read(F):gsub('\n\n%-%- MXM_AutoColor BEGIN', '\n-- MXM_AutoColor BEGIN')))
check(startup.ensure(), 'ensure adds the blank line to a block without one')
check(read(F):find('\n\n-- MXM_AutoColor BEGIN', 1, true) ~= nil, 'and it is there', read(F))
-- Saved with CRLF by an editor: still current.
write(F, (read(F):gsub('\r?\n', '\r\n')))
check(not startup.ensure(), 'a CRLF copy of a current block is left alone')

-- A block left by an older build, pointing at the wrong place, is replaced.
write(F, (read(F):gsub('MXM_AutoColor_Startup%.lua', 'Elsewhere/Startup.lua')))
check(startup.ensure(), 'ensure replaces a stale block')
check(read(F):find('MXM_AutoColor_Startup.lua', 1, true) ~= nil, 'and points at the bootstrap')
check(not startup.ensure(), 'then leaves it alone')
-- The path in the block is where the scripts really are.
local nc = (NC:gsub('\\', '/'))
check(read(F):find(nc, 1, true) ~= nil, 'block names the real script folder', read(F))

-- The block must run cleanly with the bootstrap absent.
assert(startup.install())
local missing = read(F):gsub('MXM_AutoColor_Startup%.lua', 'Missing.lua')
local ok, err = pcall(load(missing, '=startup'))
check(ok, 'block is a no-op when the bootstrap is missing', tostring(err))

--------------------------------------------------------------------- decision
check(startup.should_start('on', ''),  'always starts')
check(not startup.should_start('off', '1'), 'never does not start')
check(startup.should_start('last', '1'), 'last: was running -> start')
check(not startup.should_start('last', '0'), 'last: was stopped -> no start')
check(not startup.should_start('last', ''), 'last: no history -> no start')

------------------------------------------------------------------------- boot
local ran, registered
reaper.AddRemoveReaScript = function() registered = true; return 4242 end
reaper.Main_OnCommand = function(c) ran = c end
reaper.NamedCommandLookup = function(n) return n == '_RSabc' and 555 or 0 end

local function boot(mode, last, instance, name)
  local cfg = config.defaults(); cfg.options.autostart = mode
  assert(config.save(cfg))
  P.extstate[SECT] = { active_last = last, auto_instance = instance, auto_cmd_name = name }
  ran, registered = nil, nil
  return startup.boot(NC .. '/')
end

check(boot('on', '', '') and ran == 4242, 'boot runs the toggle action')
check(P.extstate[SECT].auto_boot == '1', 'boot flags the launch')
check(not boot('off', '1', '') and ran == nil, 'boot honours "never"')
check(not boot('last', '0', '') and ran == nil, 'boot honours a stopped last state')
check(boot('last', '1', '') and ran == 4242, 'boot resumes a running last state')
check(not boot('on', '', 'tok') and ran == nil, 'boot leaves a running loop alone')
check(boot('on', '', '', 'RSabc') and ran == 555 and not registered,
      'boot finds the toggle by its named id, registering nothing')
check(boot('on', '', '', 'RSgone') and ran == 4242,
      'and registers it only when the name does not resolve')

-------------------------------------------------------- bootstrap isolation
-- __startup.lua is one Lua state for every entry. An earlier entry has cached
-- modules under our names; the bootstrap must neither use them nor leave
-- anything of its own behind.
do
  local cfg = config.defaults(); cfg.options.autostart = 'on'
  assert(config.save(cfg))
  P.extstate[SECT] = {}
  ran = nil

  local names = { 'startup', 'config', 'json', 'rules', 'predicates' }
  local saved, foreign = {}, {}
  for _, n in ipairs(names) do
    saved[n], foreign[n] = package.loaded[n], { foreign = true }
    package.loaded[n] = foreign[n]
  end
  local path_before = package.path
  local function keys(t) local s = {}; for k in pairs(t) do s[k] = true end; return s end
  local g_before, l_before = keys(_G), keys(package.loaded)

  local ok2, err2 = pcall(load(read(F), '=startup'))

  local same = true
  for _, n in ipairs(names) do same = same and package.loaded[n] == foreign[n] end
  local added = {}
  for k in pairs(_G) do if not g_before[k] then added[#added + 1] = '_G.' .. k end end
  for k in pairs(package.loaded) do if not l_before[k] then added[#added + 1] = k end end
  local path_after = package.path
  for _, n in ipairs(names) do package.loaded[n] = saved[n] end

  check(ok2, 'block runs the bootstrap', tostring(err2))
  check(ran == 4242, 'bootstrap boots despite foreign modules under its names', tostring(ran))
  check(same, 'and leaves those modules as they were')
  check(path_after == path_before, 'and leaves package.path alone')
  check(#added == 0, 'and adds no globals or modules', table.concat(added, ', '))
end

------------------------------------------------------------------- the toggle
do
  local entry, autoloop = require 'entry', require 'autoloop'
  local msg, opts, state, deferred, exitfn
  entry.msg = function(t) msg = t end
  entry.warn_sws_once = function() end
  reaper.set_action_options = function(f) opts = f end
  reaper.ReverseNamedCommandLookup = function() return 'RSabc' end
  reaper.SetToggleCommandState = function(_, _, s) state = s end
  reaper.defer = function(f) deferred = f end
  reaper.atexit = function(f) exitfn = f end
  local function ext() return P.extstate[SECT] or {} end
  local function click()
    msg, opts, state, deferred, exitfn = nil, nil, nil, nil, nil
    dofile(NC .. '/MXM_AutoColor_AutoToggle.lua')
  end

  P.extstate[SECT] = {}
  click()
  local exit1 = exitfn
  check(opts == 3, 'toggle asks REAPER to terminate and re-launch it on a second run')
  check(deferred ~= nil, 'toggle starts the loop when it is not running')
  check((ext().auto_instance or '') ~= '', 'and holds a token')
  check(ext().active_last == '1', 'and records the intent to run')
  check(state == 1, 'and lights the button')
  check(ext().auto_cmd_name == 'RSabc', 'and records its named command id')

  -- Second click: REAPER terminates the loop, then runs the script again.
  exit1()
  check((ext().auto_instance or '') ~= '', 'a terminated loop leaves its token for the re-launch')
  click()
  check(deferred == nil, 'the re-launch does not start a second loop')
  check(ext().auto_instance == nil and ext().auto_heartbeat == nil,
        'it clears the token and the heartbeat')
  check(ext().active_last == '0', 'and records the intent to stop')
  check(state == 0, 'and dims the button')

  -- REAPER quitting runs atexit too, and nothing re-launches.
  click()
  exitfn()
  check(ext().active_last == '1', 'a quit keeps the running state for the next launch')

  -- A token left by a loop ended some other way is stale: the click starts.
  P.extstate[SECT] = { auto_instance = 'old', auto_heartbeat = tostring(os.time() - 60) }
  click()
  check(deferred ~= nil and ext().auto_instance ~= 'old', 'a stale token does not swallow a start')

  -- Double-click: the re-launch may run before the old instance's atexit.
  P.extstate[SECT] = {}
  click()
  local exit3 = exitfn
  click()
  check(deferred == nil and ext().active_last == '0', 'a double-click starts, then stops')
  state = nil
  exit3()
  check(state == 0, 'and the old instance dims the button on its way out')

  -- A healthy tick re-arms; an error stops the loop, which then clears its token.
  local tick = autoloop.tick
  P.extstate[SECT] = {}
  autoloop.tick = function() end
  click()
  local loop, exit4 = deferred, exitfn
  deferred = nil
  loop()
  check(deferred == loop, 'a healthy tick re-arms the loop')
  autoloop.tick = function() error('boom') end
  deferred = nil
  loop()
  autoloop.tick = tick
  check(msg ~= nil and deferred == nil, 'an error stops the loop, with a message')
  exit4()
  check(ext().auto_instance == nil, 'a loop that stopped itself clears its token')
  click()
  check(deferred ~= nil, 'so the next click starts it')

  -- REAPER before 7.03.
  P.extstate[SECT] = {}
  local sao = reaper.set_action_options
  reaper.set_action_options = nil
  click()
  check(msg ~= nil and deferred == nil, 'before REAPER 7.03 it refuses, with a message')
  reaper.set_action_options = sao
end

print('\n=== startup (mock REAPER) ===')
for _, f in ipairs(fails) do print('  FAIL  ' .. f) end
print(string.format('%d passed, %d failed\n', pass, fail))
os.exit(fail == 0 and 0 or 1)
