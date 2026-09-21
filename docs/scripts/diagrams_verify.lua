--[[
  diagrams_verify.lua -- prove the diagrams still match the tool.

  scripts/diagrams.py computes its colours with a PORT of lib/apply.lua. This runs the very
  same scenarios through the real thing and prints what it chose, one scenario per block:

      <scenario id>
        <track name>\t#RRGGBB | nil

  diagrams.py --verify writes scenarios.lua into a temp dir, runs this there and diffs the
  two. Nothing here touches REAPER or your rule file -- plan() is pure, and none of the
  REAPER API is reached on this path.

      NC_LIB=<...>/MXM_AutoColor/lib lua diagrams_verify.lua      # from a dir holding scenarios.lua
]]

local lib = os.getenv('NC_LIB')
if not lib then
  io.stderr:write('NC_LIB must point at MXM_AutoColor/lib\n')
  os.exit(1)
end
package.path = lib .. '/?.lua;' .. package.path

local apply  = require 'apply'
local colors = require 'colors'

for _, scn in ipairs(dofile('scenarios.lua')) do
  local rules = { track = {} }
  for i, r in ipairs(scn.rules) do
    rules.track[i] = { id = 'r' .. i, enabled = true, mode = 'glob', ci = true,
                       pattern = r.pattern, color = r.color, color2 = r.color2,
                       gradient_scope = r.spread }
  end
  local entries = {}
  for i, e in ipairs(scn.tracks) do
    entries[i] = { kind = 'track', name = e.name, folderdepth = e.fd,
                   spacer_above = e.spacer or nil, guid = 't' .. i }
  end
  local _, _, desired = apply.plan(entries, rules,
    { propagate_folders = scn.folders, subfolder_splits_range = scn.split })
  print(scn.id)
  for i, e in ipairs(entries) do
    print(string.format('  %s\t%s', e.name, desired[i] and colors.tohex(desired[i]) or 'nil'))
  end
end
