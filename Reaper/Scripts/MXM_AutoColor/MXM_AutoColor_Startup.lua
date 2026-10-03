--[[
  MXM_AutoColor_Startup.lua -- run from Scripts/__startup.lua at REAPER launch.
  Starts background auto-colouring according to the Autostart option.

  Runs inside the one Lua state that __startup.lua shares with every other
  entry, so it leaves no trace there: modules load into a private table with a
  require of their own, never through package.path or package.loaded.
]]

local ROOT = debug.getinfo(1, 'S').source:match('^@(.*[\\/])')
if not ROOT then return end

local env, loaded = setmetatable({}, { __index = _G }), {}
function env.require(name)
  if loaded[name] == nil then
    local chunk = assert(loadfile(ROOT .. 'lib/' .. (name:gsub('%.', '/')) .. '.lua', 't', env))
    loaded[name] = chunk(name) or true
  end
  return loaded[name]
end

pcall(function() env.require('startup').boot(ROOT) end)
