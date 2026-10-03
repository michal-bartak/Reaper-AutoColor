--[[
  startup.lua -- launching the auto-apply loop with REAPER.

  REAPER runs Scripts/__startup.lua at launch. install() adds a marked block to
  it that runs MXM_AutoColor_Startup.lua, which calls boot().

  The block runs the bootstrap as an action, in a Lua state of its own:
  __startup.lua is one state shared by every entry, and a loadfile there would
  leave our package.path and cached modules (config, json, ...) to collide with
  the others. The block itself touches only reaper.*, and is a no-op once the
  bootstrap is gone.
]]

local config = require 'config'

local M = {}

local BEGIN, END = '-- MXM_AutoColor begin', '-- MXM_AutoColor end'

--- Where the scripts actually are. ReaPack installs them under a folder of its
--- own choosing, so the path cannot be assumed.
local function root()
  local src = debug.getinfo(1, 'S').source:gsub('^@', '')
  local r = src:match('^(.*)[\\/]lib[\\/]startup%.lua$')
  return r and (r:gsub('\\', '/'))
end

--- The block. The bootstrap's path is relative to the resource folder where it
--- can be, so a portable install may move; absolute otherwise.
local function block()
  local file = (root() or '') .. '/MXM_AutoColor_Startup.lua'
  local res = (reaper.GetResourcePath():gsub('\\', '/'))
  local expr
  if file:sub(1, #res + 1) == res .. '/' then
    expr = 'reaper.GetResourcePath() .. ' .. string.format('%q', file:sub(#res + 1))
  else
    expr = string.format('%q', file)
  end
  return table.concat({
    BEGIN,
    'do',
    '  local f = ' .. expr,
    '  if reaper.file_exists(f) then',
    '    local id = reaper.AddRemoveReaScript(true, 0, f, true)',
    '    if id and id > 0 then reaper.Main_OnCommand(id, 0) end',
    '  end',
    'end',
    END,
  }, '\n')
end

function M.path() return reaper.GetResourcePath() .. '/Scripts/__startup.lua' end

local function read(p)
  local f = io.open(p, 'rb')
  if not f then return nil end
  local s = f:read('a')
  f:close()
  return s
end

--- The text with the marked block cut out, whether there was one, and the block.
local function strip(text)
  local a = text:find(BEGIN, 1, true)
  if not a then return text, false end
  local _, e = text:find(END, a, true)
  if not e then return text, false end
  local rest = text:sub(e + 1):gsub('^\r?\n', '')
  return text:sub(1, a - 1) .. rest, true, text:sub(a, e)
end

function M.installed()
  local s = read(M.path())
  return s ~= nil and select(2, strip(s))
end

local function write(p, s)
  local f, err = io.open(p, 'wb')
  if not f then return false, err end
  f:write(s)
  f:close()
  return true
end

--- Add the block, or refresh it in place. Everything else in the file is kept.
--- The file is read immediately before the write, to keep the window in which
--- an outside edit could be lost as short as it can be; nothing locks it.
function M.install()
  local s = read(M.path()) or ''
  s = strip(s)
  if s ~= '' and not s:match('\n$') then s = s .. '\n' end
  return write(M.path(), s .. block() .. '\n')
end

--- Install the block if it is missing or points somewhere else. Called whenever
--- the Toggle or the window starts, so a deleted, moved or stale entry heals
--- itself. Silent: a failed write must not interrupt either.
function M.ensure()
  local s = read(M.path())
  if s then
    local _, had, found = strip(s)
    -- Compared without carriage returns: the file may have been saved either way.
    if had and (found:gsub('\r', '')) == block() then return false end
  end
  return pcall(M.install) and true or false
end

function M.remove()
  local s = read(M.path())
  if not s then return true end
  local out, had = strip(s)
  if not had then return true end
  if out:match('^%s*$') then
    os.remove(M.path())
    return true
  end
  return write(M.path(), out)
end

--- Whether to start, given the option and the state saved at last shutdown.
function M.should_start(mode, last)
  return mode == 'on' or (mode == 'last' and last == '1')
end

--- Called from MXM_AutoColor_Startup.lua. Never raises.
function M.boot(root)
  local ok, cfg = pcall(config.load)
  if not ok or type(cfg) ~= 'table' then return false end
  local sect = config.EXT_SECTION
  if not M.should_start(cfg.options.autostart, reaper.GetExtState(sect, 'active_last')) then
    return false
  end
  -- The Toggle has no start-only mode: running it while the loop is up stops it.
  if reaper.GetExtState(sect, 'auto_instance') ~= '' then return false end

  -- Registering is idempotent and returns the existing id, so this does not
  -- depend on the action having been run once. Running it as an action keeps
  -- its command id and toolbar state correct.
  local cmd = reaper.AddRemoveReaScript(true, 0, root .. 'MXM_AutoColor_AutoToggle.lua', true)
  if not cmd or cmd <= 0 then return false end
  reaper.SetExtState(sect, 'auto_boot', '1', false)
  reaper.Main_OnCommand(cmd, 0)
  return true
end

return M
