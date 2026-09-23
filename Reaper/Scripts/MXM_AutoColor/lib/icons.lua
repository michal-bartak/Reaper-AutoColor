--[[
  icons.lua -- track icon paths, and the list of installed icons.

  REAPER keeps a track icon as a path in P_ICON. Measured on 7.80
  (dev/MXM_AutoColor_IconProbe.lua): it accepts a path relative to
  <resource>/Data/track_icons or an absolute one, but always READS BACK
  absolute -- after its own dialog too. So:

    * a rule stores a path inside track_icons RELATIVE, with '/', so the
      config carries over to another machine or resource path;
    * anything else is stored absolute, as picked;
    * plan() resolves the stored form before comparing it with what the track
      reports, and writes the resolved form, so a correct icon is never
      rewritten.

  '' means "no icon", both as a rule's choice and as P_ICON's value.
]]

local M = {}

-- What REAPER's own icon dialog accepts: *.JPG;*.JPEG;*.PNG
local EXT = { png = true, jpg = true, jpeg = true }

local function sep()
  return package.config:sub(1, 1)
end

--- Forward slashes, no trailing one. For comparing, never for writing.
local function unify(p)
  p = p:gsub('\\', '/')
  if #p > 1 then p = p:gsub('/+$', '') end
  return p
end

function M.dir()
  local res = (type(reaper) == 'table' and reaper.GetResourcePath) and reaper.GetResourcePath() or '.'
  return res .. sep() .. 'Data' .. sep() .. 'track_icons'
end

function M.is_absolute(p)
  return p:match('^/') ~= nil or p:match('^%a:[\\/]') ~= nil or p:match('^\\\\') ~= nil
end

--- A rule's stored path -> what to write to P_ICON.
function M.resolve(stored)
  if stored == nil or stored == '' then return '' end
  if M.is_absolute(stored) then return stored end
  local rel = stored
  if sep() ~= '/' then rel = rel:gsub('/', sep()) end
  return M.dir() .. sep() .. rel
end

--- A picked absolute path -> what a rule stores.
function M.to_stored(abs)
  if abs == nil or abs == '' then return '' end
  local d, a = unify(M.dir()) .. '/', unify(abs)
  -- Case-insensitive prefix: both default macOS and Windows file systems are.
  if a:sub(1, #d):lower() == d:lower() then return a:sub(#d + 1) end
  return abs
end

--- Do two P_ICON values name the same file?
function M.same(a, b)
  return unify(a or '') == unify(b or '')
end

--- The file name without folder or extension, as shown under an icon.
function M.basename(p)
  local f = unify(p):match('([^/]*)$') or p
  return (f:gsub('%.[^.]*$', ''))
end

function M.exists(stored)
  local f = io.open(M.resolve(stored), 'rb')
  if f then f:close(); return true end
  return false
end

------------------------------------------------------------------ the index
--- Every icon under track_icons, subfolders included, ordered by relative
--- path ignoring case.
--- @param rescan  make REAPER re-read the directories rather than answer from
---                its cache (index -1, per the API documentation)
--- @return list of { rel = 'subf/fx.png', abs = path, name = 'fx', key = lower rel }
function M.list(rescan)
  local out = {}
  local root = M.dir()

  local function walk(path, prefix, depth)
    if rescan then
      reaper.EnumerateFiles(path, -1)
      reaper.EnumerateSubdirectories(path, -1)
    end
    local i = 0
    while true do
      local f = reaper.EnumerateFiles(path, i)
      if not f then break end
      local ext = f:match('%.([^.]+)$')
      if ext and EXT[ext:lower()] then
        local rel = prefix .. f
        out[#out + 1] = { rel = rel, abs = path .. sep() .. f,
                          name = M.basename(f), key = rel:lower() }
      end
      i = i + 1
    end
    if depth >= 8 then return end        -- a symlink loop must not hang the GUI
    i = 0
    while true do
      local d = reaper.EnumerateSubdirectories(path, i)
      if not d then break end
      walk(path .. sep() .. d, prefix .. d .. '/', depth + 1)
      i = i + 1
    end
  end

  walk(root, '', 0)
  table.sort(out, function(a, b) return a.key < b.key end)
  return out
end

return M
