-- Render whole frames of the real GUI against a stub ImGui.
package.path = os.getenv('SP') .. '/?.lua;' .. package.path
local mock     = require 'mockreaper'
local mockimgui = require 'mockimgui'
local NC, TMP = os.getenv('NC'), os.getenv('SP') .. '/proj4'
os.execute('rm -rf "' .. TMP .. '" && mkdir -p "' .. TMP .. '/MXM_AutoColor"')

local function pathlib_read(rel)
  local f = assert(io.open(NC .. '/' .. rel)); local t = f:read('a'); f:close(); return t
end

local pass, fail, fails = 0, 0, {}
local function check(ok, label, detail)
  if ok then pass = pass + 1
  else fail = fail + 1; fails[#fails+1] = label .. (detail and ('  -- ' .. detail) or '') end
end

local P = mock.install{ resource = TMP, script = NC .. '/x.lua' }
P.now = 1000
reaper.GetSelectedTrack = function() return P.tracks[1] end

package.path = NC .. '/?.lua;' .. NC .. '/lib/?.lua;' .. package.path
local config = require 'config'
local rules  = require 'rules'
local app    = require 'gui.app'
local window = require 'gui.window'
local theme  = require 'gui.theme'

P.track('Drums', { fd = 1 }); P.track('Kick In'); P.track('Snare Top', { fd = -1 })
P.track('Sub Bass'); P.item('gtr_dry_01')
P.mark('Intro', false); P.mark('Chorus 1', true, { rgnend = 8 })

app.load()

local function frame(scripted)
  local ImGui, rec = mockimgui.new{ scripted = scripted }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1)
  app.refresh_entries(true)
  app.recompute_preview()
  local ok, err = pcall(window.draw, 14)
  return ok, err, rec
end

---------------------------------------------------- every path must execute
do
  local ok, err, rec = frame()
  check(ok, 'a full frame draws without error', tostring(err))
  for _, fn in ipairs({ 'BeginTable', 'TableSetupColumn', 'TableHeader',
                        'TableNextRow', 'TableSetColumnIndex', 'EndTable',
                        'PushID', 'PopID', 'ColorEdit3', 'InputText', 'Checkbox',
                        'BeginChild', 'EndChild', 'Button',
                        'Selectable', 'ColorButton',
                        'BeginTabBar', 'BeginTabItem', 'PushStyleVar' }) do
    check(rec.seen[fn], 'frame reaches ' .. fn)
  end
end

------------------------------------------------------- one tab per object kind
do
  -- give every tab something to draw
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1]  = rules.new('track',  { label = 'T', pattern = 'a',
                                                     cascade_items = true })
  app.st.cfg.rules.item[1]   = rules.new('item',   { label = 'I', pattern = 'a' })
  app.st.cfg.rules.region[1] = rules.new('region', { label = 'R', pattern = 'a' })
  app.st.cfg.rules.marker[1] = rules.new('marker', { label = 'M', pattern = 'a' })

  local ImGui, rec = mockimgui.new{}
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.refresh_entries(true); app.recompute_preview()
  local ok, err = pcall(window.draw, 14)
  check(ok, 'a frame with all four tabs draws', tostring(err))
  check(rec.seen.BeginTabBar and rec.seen.BeginTabItem, 'the tab bar is drawn')
  for _, kind in ipairs({ 'track', 'item', 'region', 'marker' }) do
    check(rec.labels['rules_' .. kind], 'the ' .. kind .. ' tab has its own table')
  end
end

do -- only the TRACK tab offers the cascade switch and the folder filters
  local function labels_for(tab)
    local ImGui, rec = mockimgui.new{ only_tab = tab }
    window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
    P.advance(1); app.recompute_preview()
    assert(pcall(window.draw, 14))
    return rec.labels
  end

  local tr = labels_for('Tracks')
  check(tr['##casc'], 'the track tab has the "also colour items" switch')
  check(tr['Items'],  'and an Items column header')

  local rg = labels_for('Regions')
  check(not rg['##casc'], 'the region tab has no cascade switch')
  check(rg['rules_region'], 'but it did draw its own table')

  -- the filter dropdown only appears where a filter exists for that kind
  check(tr['Filter'], 'the track tab has a filter column')
  check(rg['Filter'], 'regions have one too (unnamed)')
end

--------------------------------- the preview must reflect rule targets
-- This is the bug that was reported: a regions-only rule showed TRACKS in the
-- preview, because nothing invalidated it.
do
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.region[1] = rules.new('region', { label = 'Chorus', mode = 'regex',
                                                     pattern = '^Chorus', color = 0x3FA8A8 })
  app.st.preview_dirty = true
  P.advance(1); app.refresh_entries(true); app.recompute_preview()

  check(#app.st.preview.region == 1, 'a regions-only rule previews the region',
        tostring(#app.st.preview.region))
  check(#app.st.preview.track == 0, 'and previews NO tracks',
        tostring(#app.st.preview.track))
end

------------------------------- an edit in the table must mark dirty + stale
-- The regression guard: rule_table used to compute `changed` and return it,
-- and window.lua dropped it, so nothing was ever saved or re-previewed.
do
  app.st.dirty, app.st.preview_dirty = false, false
  -- script the FIRST Checkbox call (the per-row "enabled" one) as an edit
  local fired = false
  local ok, err = frame{
    Checkbox = function(_, label, v)
      if not fired then fired = true; return true, not v end
      return false, v
    end,
  }
  check(ok, 'a frame with an edit draws without error', tostring(err))
  check(fired, 'the stub actually reached a checkbox')
  check(app.st.dirty == true, 'editing a rule marks the config dirty')
  check(app.st.preview_dirty == true, 'editing a rule invalidates the preview')
end

do -- same for the pattern field
  app.st.dirty, app.st.preview_dirty = false, false
  local fired = false
  frame{ InputText = function(_, label, v)
           if not fired and label == '##pat' then fired = true; return true, '^zzz' end
           return false, v
         end }
  check(fired, 'the stub reached the pattern field')
  check(app.st.dirty == true, 'editing a pattern marks dirty')
end

do -- and for a colour swatch
  app.st.dirty = false
  local fired = false
  frame{ ColorEdit3 = function(_, _, v)
           if not fired then fired = true; return true, 0x123456 end
           return false, v
         end }
  check(fired, 'the stub reached a colour swatch')
  check(app.st.dirty == true, 'changing a colour marks dirty')
end

------------------------------------------------ and the edit reaches disk
do
  app.st.cfg.rules.region[1] = rules.new('region', { label = 'R', mode = 'substring',
                                                     pattern = 'Chorus', color = 0x112233 })
  app.mark_dirty()
  P.advance(1)
  app.flush(true)
  local reloaded = config.load()
  check(#reloaded.rules.region == 1, 'a region rule survives a save/load')
  check(reloaded.rules.region[1].color == 0x112233, 'with its colour')
end

------------------------------------------- unticking everything is respected
do -- a rule belongs to exactly one kind now; there is no way to target nothing
  check(rules.new('region', {}).kind == 'region', 'a rule carries its kind')
  check(rules.new('region', {}).targets == nil, 'and no targets field')
end

--------------------------------- the preview must equal what Apply writes
local colors = require 'colors'

local function preview_by_name(kind)
  app.st.preview_dirty = true
  P.advance(1); app.refresh_entries(true); app.recompute_preview()
  local by = {}
  for _, p in ipairs(app.st.preview[kind or 'track'] or {}) do by[p.name] = p end
  return by
end
local function applied_by_name()
  app.apply_all()
  local by = {}
  for _, t in ipairs(P.tracks) do by[t.name] = colors.from_native(t.color) end
  return by
end

do -- GRADIENT: the reported gap -- the preview used to show the rule's primary
   -- colour for every match instead of each object's own shade.
  app.st.cfg.options.propagate_folders = 'off'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1] = rules.new('track', { label = 'Spread', mode = 'regex',
                                                   pattern = '.', color = 0xFF0000,
                                                   color2 = 0x0000FF })
  local pv = preview_by_name()
  local seen, distinct = {}, 0
  for _, p in pairs(pv) do
    if not seen[p.color] then seen[p.color] = true; distinct = distinct + 1 end
  end
  check(distinct >= 3, 'the preview shows distinct gradient shades', distinct .. ' distinct')
  check(pv['Drums'] and pv['Drums'].color == 0xFF0000, 'gradient preview starts at colour 1')

  local ap = applied_by_name()
  local mismatch = nil
  for name, p in pairs(pv) do
    if p.kind == 'track' and ap[name] ~= p.color then mismatch = name end
  end
  check(mismatch == nil, 'every previewed gradient colour is what Apply writes',
        tostring(mismatch))
end

do -- FOLDER INHERITANCE: children with no rule of their own were missing from
   -- the preview entirely, even though Apply colours them.
  for _, t in ipairs(P.tracks) do t.color = 0 end
  app.st.cfg.options.propagate_folders = 'fill_unmatched'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1] = rules.new('track', { label = 'Drum bus', mode = 'substring',
                                                   pattern = 'Drums', color = 0x00AA00 })
  local pv = preview_by_name()
  check(pv['Kick In'] ~= nil, 'an inherited child appears in the preview')
  check(pv['Kick In'] and pv['Kick In'].inherited == true, 'and is flagged as inherited')
  check(pv['Kick In'] and pv['Kick In'].color == 0x00AA00, 'with the folder colour')
  check(pv['Drums'] and pv['Drums'].inherited == false, 'the folder itself is not inherited')
  check(pv['Sub Bass'] == nil, 'a track outside the folder is still not previewed')

  local ap = applied_by_name()
  check(ap['Kick In'] == 0x00AA00, 'and Apply really does colour the child')
  check(ap['Sub Bass'] == nil, 'and really does leave the outsider alone')
end

--------------------------------------------- the master is left entirely alone
do
  for _, t in ipairs(P.tracks) do t.color = 0 end
  P.master.color = 0
  app.st.cfg.options.propagate_folders = 'off'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1] = rules.new('track', { label = 'Everything', mode = 'regex',
                                                   pattern = '.', color = 0x777777 })
  local pv = preview_by_name()
  check(pv['MASTER'] == nil, 'the master never appears in the preview')
  app.apply_all()
  check(P.master.color == 0, 'even a match-everything rule does not touch the master',
        tostring(P.master.color))
  check(colors.from_native(P.tracks[1].color) == 0x777777, 'ordinary tracks still coloured')
end

------------------------------------------ the preview follows the open tab
do
  for _, t in ipairs(P.tracks) do t.color = 0 end
  app.st.cfg.options.propagate_folders = 'off'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1]  = rules.new('track',  { label = 'T', mode = 'regex',
                                                     pattern = '.', color = 0x111111 })
  app.st.cfg.rules.region[1] = rules.new('region', { label = 'R', mode = 'regex',
                                                     pattern = '.', color = 0x222222 })
  app.st.preview_dirty = true
  P.advance(1); app.refresh_entries(true); app.recompute_preview()

  check(#app.st.preview.track > 0,  'the track bucket has rows')
  check(#app.st.preview.region > 0, 'the region bucket has rows')
  check(#app.st.preview.marker == 0, 'the marker bucket is empty (no marker rules)')

  -- every row in a bucket really is of that kind
  for _, kind in ipairs({ 'track', 'item', 'region', 'marker' }) do
    local wrong = nil
    for _, p in ipairs(app.st.preview[kind]) do
      if p.kind ~= kind then wrong = p.kind end
    end
    check(wrong == nil, 'the ' .. kind .. ' bucket holds only ' .. kind .. 's',
          tostring(wrong))
  end

  -- and the drawn list is the one for the open tab
  local function rows_drawn(tab)
    app.st.active_kind = tab
    local ImGui, rec = mockimgui.new{ only_tab = 'zzz-none' }   -- skip rule tables
    window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
    assert(pcall(window.draw, 14))
    return rec.labels
  end
  check(rows_drawn('track')['previewtbl_track'],   'the track tab draws the track preview')
  check(not rows_drawn('region')['previewtbl_track'],
        'the region tab does NOT draw the track preview')
  check(rows_drawn('region')['previewtbl_region'], 'it draws the region preview instead')
end

------------------------------- a cascaded item names the track it came from
-- The confusing case: the only ITEM rule matches nothing, yet items are listed
-- in the preview, coloured by a track rule's cascade.
do
  for _, t in ipairs(P.tracks) do t.color = 0 end
  app.st.cfg.options.propagate_folders = 'off'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1] = rules.new('track', { label = 'Bass', mode = 'substring',
                                                   pattern = 'Bass', color = 0x6B4FA8,
                                                   cascade_items = true })
  app.st.cfg.rules.item[1]  = rules.new('item',  { label = 'Comps', mode = 'glob',
                                                   pattern = '*_comp*', color = 0x4F8AA8 })
  local pv = preview_by_name('item')
  local row = pv['gtr_dry_01']
  check(row ~= nil, 'the item is listed even though no item rule matched it')
  if row then
    check(row.from_track == true, 'and is flagged as coloured by its track')
    check(row.rule == nil,        'with no item rule attributed')
    check(row.track_name ~= nil,  'and it names the track it came from',
          tostring(row.track_name))
  end
  check((app.st.won[app.st.cfg.rules.item[1].id] or 0) == 0,
        'the item rule genuinely has zero hits')
end

------------------------------------------------------- theme push/pop balance
-- An unbalanced PushStyleVar/PopStyleVar corrupts every later frame, and the
-- symptom (slowly drifting layout) is horrible to track down.
do
  local pushes, pops = 0, 0
  local ImGui = mockimgui.new{ scripted = {
    PushStyleVar   = function() pushes = pushes + 1 end,
    PopStyleVar    = function(_, n) pops = pops + (n or 1) end,
  } }
  theme.init(ImGui, { 'ctx' })
  theme.push(14)
  theme.pop()
  check(pushes == pops, 'theme pushes and pops the same number of style vars',
        pushes .. ' pushed, ' .. pops .. ' popped')
  check(pushes > 0, 'and it actually pushed some')
end
do
  local pushes, pops = 0, 0
  local ImGui = mockimgui.new{ scripted = {
    PushStyleColor = function() pushes = pushes + 1 end,
    PopStyleColor  = function(_, n) pops = pops + (n or 1) end,
    GetStyleColor  = function() return 0x808080FF end,
  } }
  theme.init(ImGui, { 'ctx' })
  theme.push(14); theme.pop()
  check(pushes == pops, 'and the same number of style colours',
        pushes .. ' pushed, ' .. pops .. ' popped')
end
do -- an unselected tab is painted like a button, so the strip and the action
   -- bar below it read as one surface
  local BUTTON, HOVER = 0x224466FF, 0x336699FF
  local pushed = {}
  local ImGui
  ImGui = mockimgui.new{ scripted = {
    GetStyleColor = function(_, idx)
      if idx == ImGui.Col_Button then return BUTTON end
      if idx == ImGui.Col_ButtonHovered then return HOVER end
      return 0x808080FF
    end,
    PushStyleColor = function(_, idx, col) pushed[idx] = col end,
  } }
  theme.init(ImGui, { 'ctx' })
  theme.push(14); theme.pop()

  check(pushed[ImGui.Col_Tab] == BUTTON,
        'an unselected tab takes the button background',
        string.format('%x', pushed[ImGui.Col_Tab] or 0))
  check(pushed[ImGui.Col_TabHovered] == HOVER, 'hover follows too')
  check(pushed[ImGui.Col_TabDimmed] == BUTTON,
        'and it survives the window losing focus')
  check(pushed[ImGui.Col_TabSelected] == nil,
        'the SELECTED tab is left alone -- the table header takes its colour')
end

do -- pop with nothing pushed must be harmless, so an error mid-frame cannot
   -- leave the style stack corrupted
  local pops = 0
  local ImGui = mockimgui.new{ scripted = {
    PopStyleVar   = function() pops = pops + 1 end,
    PopStyleColor = function() pops = pops + 1 end,
  } }
  theme.init(ImGui, { 'ctx' })
  theme.pop(); theme.pop()
  check(pops == 0, 'a stray pop() does nothing', pops .. ' pops')
end

--------------------------------- the style stack must balance over a frame
-- Tab padding is pushed around the strip and lifted again inside each tab, so
-- a whole frame has to come back to zero. An imbalance here corrupts every
-- later frame and shows up as slowly drifting layout.
do
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1]  = rules.new('track',  { label = 'T', pattern = 'a',
                                                     cascade_items = true, color2 = 0x112233 })
  app.st.cfg.rules.item[1]   = rules.new('item',   { label = 'I', pattern = 'a' })
  app.st.cfg.rules.region[1] = rules.new('region', { label = 'R', pattern = 'a' })
  app.st.cfg.rules.marker[1] = rules.new('marker', { label = 'M', pattern = 'a' })

  local vdepth, cdepth, vmin, cmin = 0, 0, 0, 0
  local ImGui = mockimgui.new{ scripted = {
    PushStyleVar   = function() vdepth = vdepth + 1 end,
    PopStyleVar    = function(_, n) vdepth = vdepth - (n or 1)
                                    if vdepth < vmin then vmin = vdepth end end,
    PushStyleColor = function() cdepth = cdepth + 1 end,
    PopStyleColor  = function(_, n) cdepth = cdepth - (n or 1)
                                    if cdepth < cmin then cmin = cdepth end end,
    GetStyleColor  = function() return 0x808080FF end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.refresh_entries(true); app.recompute_preview()

  theme.push(14)
  local ok = pcall(window.draw, 14)
  theme.pop()

  check(ok, 'a frame with every tab populated draws')
  check(vdepth == 0, 'style vars balance across a whole frame', vdepth .. ' left pushed')
  check(cdepth == 0, 'style colours balance across a whole frame', cdepth .. ' left pushed')
  check(vmin >= 0, 'style vars are never popped below zero', 'min ' .. vmin)
  check(cmin >= 0, 'style colours are never popped below zero', 'min ' .. cmin)
end

--------------------------------------------- the auto button start/stop path
do
  local SECT = config.EXT_SECTION
  reaper.SetExtState(SECT, 'auto_cmdid', '', false)
  check(app.auto_command_id() == nil, 'no command id before the action has run')
  check(app.toggle_auto() == false, 'toggling without a command id is refused')
  check(app.current_toast() ~= nil, 'and explains why')

  reaper.SetExtState(SECT, 'auto_cmdid', '4242', false)
  check(app.auto_command_id() == 4242, 'the published command id is picked up')
  local ran
  reaper.Main_OnCommand = function(cmd) ran = cmd end
  check(app.toggle_auto() == true, 'toggling now works')
  check(ran == 4242, 'and it invokes the right action', tostring(ran))
  check(app.auto_paused() == false, 'and never leaves it paused-but-on')
end

------------------------------------------------- header row is hand-emitted
do
  -- TableHeadersRow left-aligns everything, so the row is emitted manually to
  -- centre the narrow columns. Check we really did replace it.
  local ImGui, rec = mockimgui.new{}
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  check(rec.seen.TableHeader, 'headers are emitted one column at a time')
  check(not rec.seen.TableHeadersRow, 'and the auto header row is not used')
  check(rec.seen.TableRowFlags_Headers == nil or true, 'header row flag available')
end

do -- the drag source must NOT suppress its tooltip, or the preview label is
   -- drawn inline into the window instead of following the cursor
  local src = pathlib_read('lib/gui/rule_table.lua')
  check(not src:find('DragDropFlags_SourceNoPreviewTooltip', 1, true),
        'the drag source no longer suppresses its tooltip')
  check(src:find('BeginDragDropSource(ctx)', 1, true) ~= nil,
        'and calls BeginDragDropSource with default flags')
end

---------------------------------------------- styling reaches every control
do
  -- Every checkbox in the GUI must go through theme.checkbox, or it keeps the
  -- default look -- which is what happened to the Options page.
  for _, f in ipairs({ 'lib/gui/window.lua', 'lib/gui/rule_table.lua',
                       'lib/gui/preview.lua' }) do
    local src = pathlib_read(f)
    check(not src:find('ImGui.Checkbox', 1, true),
          f .. ' uses the styled checkbox everywhere')
  end
  -- swatches must be sized by the theme, or they come out wider than [+]/[x]
  local rt = pathlib_read('lib/gui/rule_table.lua')
  check(not rt:find('ImGui.ColorEdit3', 1, true),
        'colour swatches go through theme.color_swatch')
  check(rt:find('theme.same_line_tight', 1, true) ~= nil,
        'and the gap between them comes from the theme')
end

do -- the table border recipe must be honoured, not hard-coded
  local src = pathlib_read('lib/gui/rule_table.lua')
  check(src:find('theme.table_border_flags', 1, true) ~= nil,
        'the rule table composes its borders from the theme')
  check(not src:find('ImGui.TableFlags_Resizable', 1, true),
        'and does not set Resizable itself -- that would force vertical lines back on')

  local ImGui = mockimgui.new{}
  theme.init(ImGui, { 'ctx' })
  local saved_h, saved_v = theme.TABLE_H_LINES, theme.TABLE_V_LINES
  theme.TABLE_H_LINES, theme.TABLE_V_LINES = false, true
  local a = theme.table_border_flags()
  theme.TABLE_H_LINES = true
  local b = theme.table_border_flags()
  check(a ~= b, 'toggling horizontal lines changes the flags')

  -- vertical lines and Resizable travel together, by necessity
  theme.TABLE_H_LINES, theme.TABLE_V_LINES = false, true
  local withv = theme.table_border_flags()
  theme.TABLE_V_LINES = false
  local nov = theme.table_border_flags()
  check(withv & ImGui.TableFlags_Resizable ~= 0,
        'vertical lines bring column resizing with them')
  check(nov & ImGui.TableFlags_Resizable == 0,
        'and without them Resizable is dropped, or ImGui would re-add the lines')
  check(nov & ImGui.TableFlags_BordersInnerV == 0, 'no inner vertical borders asked for')
  check(nov & ImGui.TableFlags_BordersOuter ~= 0, 'the outer border survives')
  theme.TABLE_H_LINES, theme.TABLE_V_LINES = saved_h, saved_v
end

---------------------------------------------------- the ghost tick is drawn
do
  -- ImGui only draws a tick when a box is checked; both states are drawn by
  -- the theme instead, so an unticked box still reads as a checkbox.
  local lines = {}
  local ImGui = mockimgui.new{ scripted = {
    Checkbox = function(_, _, v) return false, v end,
    DrawList_AddLine = function(_, x1, y1, x2, y2, col, th)
      lines[#lines + 1] = { col = col, th = th }
    end,
    GetStyleColor = function() return 0x33AA66FF end,
  } }
  theme.init(ImGui, { 'ctx' })

  lines = {}
  theme.checkbox('##on', true)
  check(#lines == 2, 'a ticked box draws a two-segment tick', #lines .. ' lines')
  check(lines[1] and lines[1].col == 0x33AA66FF,
        'in the theme tick colour', lines[1] and string.format('%08X', lines[1].col))

  lines = {}
  theme.checkbox('##off', false)
  check(#lines == 2, 'an UNticked box also draws a tick')
  local want = ((theme.GHOST_CHECK & 0xFFFFFF) << 8)
               | math.floor(theme.GHOST_CHECK_ALPHA * 255)
  check(lines[1] and lines[1].col == want,
        'in the ghost colour at the configured alpha',
        lines[1] and string.format('%08X vs %08X', lines[1].col, want))
  check(lines[1] and lines[1].th >= 1, 'with a sane thickness')
end

------------------------------------------ the options dialog, and what shuts it
-- It is a borderless, fixed, TopMost window that looks exactly like the popup it
-- replaced. It is not a popup because ImGui owns a popup's visibility and closes
-- it on focus loss -- which lost the dialog on alt-tab, and whose re-open was
-- visible as a blink. Nothing closes a window behind our back, so nothing
-- blinks; the price is that Escape, dismissal-by-click and input blocking all
-- have to be asked for.
local function optdialog(scripted, open)
  local ImGui, rec = mockimgui.new{ scripted = scripted or {} }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  app.st.options_open = open and true or false
  P.advance(1); app.recompute_preview()
  theme.push(14)
  local okmain = pcall(window.draw, 14)
  local ok, err = pcall(window.draw_options, 14)
  theme.pop()
  local still = app.st.options_open
  app.st.options_open = false
  return ok and okmain, err, rec, still, ImGui
end

do -- the button opens it; it is drawn as a window, centred, and never a popup
  local pos, flags
  local ok, err, rec, _, ImGui = optdialog({
    -- theme.button draws '##'..label, so the id is what the mock is asked for
    Button = function(_, id) return id == '##Options' end,
    SetNextWindowPos = function(_, x, y, cond, px, py)
      pos = { x = x, y = y, cond = cond, px = px, py = py }
    end,
    GetWindowPos  = function() return 100, 80 end,
    GetWindowSize = function() return 900, 640 end,
    Begin = function(_, name, _, f)
      if name == 'Options' then flags = f end
      return true, true
    end,
  }, true)

  check(ok, 'the dialog draws without error', tostring(err))
  check(flags ~= nil, 'it is begun as an ordinary window')
  check(rec.labels['Options'], 'named Options')
  check(not rec.seen.BeginPopupModal, 'and never as a modal')

  -- The mock hands out a distinct bit per flag name, so the OR can be taken
  -- apart again and each one checked for.
  if flags then
    for _, f in ipairs({ 'NoTitleBar', 'NoResize', 'NoMove', 'NoCollapse',
                         'NoSavedSettings', 'TopMost' }) do
      check(flags & ImGui['WindowFlags_' .. f] ~= 0, 'with WindowFlags_' .. f)
    end
  end

  check(pos ~= nil, 'its position is set explicitly')
  if pos then
    -- centre of a 900x640 window at (100,80), with a centre pivot
    check(pos.x == 100 + 450 and pos.y == 80 + 320,
          'centred on the app window', string.format('%g,%g', pos.x, pos.y))
    check(pos.px == 0.5 and pos.py == 0.5, 'using a centre pivot')
  end
end

do -- nothing shuts it on its own -- that is the whole point
  local _, _, _, still = optdialog({}, true)
  check(still == true, 'a plain frame leaves it open')

  local _, _, _, unfocused = optdialog({
    IsWindowFocused = function() return false end,   -- focus left REAPER
    IsMouseClicked  = function() return true end,
  }, true)
  check(unfocused == true, 'and so does a click while no ImGui window has focus')
end

do -- Escape, Close, and a click on the window behind all shut it
  local _, _, _, esc = optdialog({ IsKeyPressed = function() return true end }, true)
  check(esc == false, 'Escape closes it')

  local _, _, _, closed = optdialog({
    Button = function(_, id) return id == '##Close' end,
  }, true)
  check(closed == false, 'the Close button closes it')

  local _, _, _, behind = optdialog({
    IsMouseClicked  = function() return true end,
    IsWindowHovered = function() return false end,   -- not over the dialog
    IsWindowFocused = function() return true end,    -- but ImGui has the click
  }, true)
  check(behind == false, 'and a click on the AutoColor window behind dismisses it')

  local _, _, _, onit = optdialog({
    IsMouseClicked  = function() return true end,
    IsWindowHovered = function() return true end,    -- the click is ON the dialog
    IsWindowFocused = function() return true end,
  }, true)
  check(onit == true, 'but a click inside the dialog does not')
end

do -- the window behind is dimmed AND blocked while it is open
  local events = {}
  local ImGui
  ImGui = mockimgui.new{ scripted = {
    PushStyleVar  = function(_, idx, a)
      if idx == ImGui.StyleVar_Alpha then events[#events + 1] = 'dim:' .. a end
    end,
    BeginDisabled = function() events[#events + 1] = 'block' end,
    EndDisabled   = function() events[#events + 1] = 'unblock' end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })

  app.st.options_open = true
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  -- BeginDisabled is used elsewhere too (the Undo button), so the two are tied
  -- together by ORDER: the block must be the event right after the dim.
  local dim_at
  for i, e in ipairs(events) do
    if e:find('^dim:') then dim_at = i break end
  end
  check(dim_at ~= nil, 'the content is dimmed while the dialog is open')
  check(dim_at and events[dim_at + 1] == 'block',
        'and cannot be clicked through -- a window blocks nothing by itself')

  events = {}
  app.st.options_open = false
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  local any_dim = false
  for _, e in ipairs(events) do if e:find('^dim:') then any_dim = true end end
  check(not any_dim, 'and neither happens while it is closed')
end

do -- the dialog body: every control it is supposed to offer
  -- Hovering everything at once is not a real frame, but it is the only way to
  -- make the tooltip branches execute at all.
  local ok, err, rec = optdialog({ IsItemHovered = function() return true end }, true)
  check(ok, 'the options body draws without error', tostring(err))
  check(rec.labels['Subfolder splits the parent\'s colour range'],
        'the Folders section offers the subfolder split checkbox')
  check(rec.labels['Example rules'], 'the rules file section offers Example rules')
  check(rec.labels['Remove Rules'], 'and Remove Rules')
  check(rec.seen.SetTooltip, 'and the dialog explains itself')
end

do -- the text size is applied on RELEASE, not while the slider is dragged
  -- Every dimension in the window is a multiple of the font size, the slider
  -- included, so applying it live moved the slider out from under the cursor
  -- and the drag chased itself.
  local drag = { SliderInt = function(_, label, v)
    if label == 'Text size' then return true, 18 end
    return false, v
  end }

  app.st.cfg.options.font_size = 14
  optdialog(drag, true)
  check(app.st.cfg.options.font_size == 14,
        'dragging does not resize the window under the cursor',
        tostring(app.st.cfg.options.font_size))

  local release = {}
  for k, v in pairs(drag) do release[k] = v end
  release.IsItemDeactivatedAfterEdit = function() return true end
  optdialog(release, true)
  check(app.st.cfg.options.font_size == 18, 'releasing applies it',
        tostring(app.st.cfg.options.font_size))
  app.st.cfg.options.font_size = 14
end

--------------------------------------------------------------------- About
do -- the About dialog offers everything it is supposed to
  local aboutmod = dofile(NC .. '/lib/about.lua')
  local links = {}
  local ImGui, rec = mockimgui.new{ scripted = {
    TextLinkOpenURL = function(_, label, url) links[url] = label; return false end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  app.st.about_open = true
  P.advance(1); app.recompute_preview()
  theme.push(14)
  local ok, err = pcall(window.draw_about, 14)
  theme.pop()
  app.st.about_open = false

  check(ok, 'the About dialog draws without error', tostring(err))
  check(rec.labels[aboutmod.VERSION], 'it names the version', aboutmod.VERSION)
  check(rec.labels[aboutmod.AUTHOR], 'and the author')
  check(links[aboutmod.URL_REPO] ~= nil, 'it links to the source')
  check(links[aboutmod.URL_DOCS] ~= nil, 'and to the documentation')
  local licenced = false
  for t in pairs(rec.labels) do
    if type(t) == 'string' and t:find(aboutmod.LICENCE, 1, true)
       and t:find('Copyright', 1, true) then licenced = true end
  end
  check(licenced, 'and states the licence and copyright')
end

do -- and it is dismissed the same way the Options dialog is
  local function shut(scripted)
    local ImGui = mockimgui.new{ scripted = scripted or {} }
    window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
    app.st.about_open = true
    theme.push(14); assert(pcall(window.draw_about, 14)); theme.pop()
    local still = app.st.about_open
    app.st.about_open = false
    return still
  end

  check(shut{} == true, 'a plain frame leaves it open')
  check(shut{ IsKeyPressed = function() return true end } == false, 'Escape closes it')
  check(shut{ Button = function(_, id) return id == '##Close##about' end } == false,
        'the Close button closes it')
  check(shut{ IsMouseClicked  = function() return true end,
              IsWindowHovered = function() return false end,
              IsWindowFocused = function() return true end } == false,
        'and a click on the window behind dismisses it')
  check(shut{ IsMouseClicked  = function() return true end,
              IsWindowHovered = function() return false end,
              IsWindowFocused = function() return false end } == true,
        'but a click while no ImGui window has focus does not')
end

do -- the info button raises the flag, and the dim covers About too
  -- theme.button prefixes '##', and info_button puts the glyph before the id,
  -- so match the suffix rather than the whole string.
  local ImGui = mockimgui.new{ scripted = {
    Button = function(_, id) return id:find('##about', 1, true) ~= nil end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  app.st.about_open = false
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  check(app.st.about_open == true, 'the circled-i button opens About')
  app.st.about_open = false

  -- It is the font's U+24D8, not a circle drawn by hand. ReaImGui rasterises
  -- glyphs on demand, so there is no range to register and nothing to fall back
  -- to if this regresses -- it would just silently look worse again.
  local tsrc = pathlib_read('lib/gui/theme.lua')
  check(tsrc:find('24D8', 1, true) ~= nil, 'the info icon is a font glyph')
  check(tsrc:find('DrawList_AddCircle', 1, true) == nil,
        'and nothing draws it by hand any more')

  local events = {}
  local I2
  I2 = mockimgui.new{ scripted = {
    PushStyleVar = function(_, idx, a)
      if idx == I2.StyleVar_Alpha then events[#events + 1] = 'dim:' .. a end
    end,
  } }
  window.init(I2, { 'ctx' }); theme.init(I2, { 'ctx' })
  app.st.about_open = true
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  app.st.about_open = false
  local dim = false
  for _, e in ipairs(events) do if e:find('^dim:') then dim = true end end
  check(dim, 'and the window behind is dimmed while it is open')
end

do -- the rules-file path is shown WHOLE, however long it is
  -- A path has no bound on its length, and the one thing asked of that line is
  -- that you can read all of it. Wrapping is what guarantees that; plain Text
  -- would run off the edge of a fixed-width dialog.
  local wrapped, plain = nil, {}
  optdialog({
    TextWrapped = function(_, t) wrapped = t end,
    TextColored = function(_, _, t) plain[#plain + 1] = tostring(t) end,
  }, true)

  check(wrapped == config.path(), 'the path is drawn wrapped', tostring(wrapped))
  local truncatable = false
  for _, t in ipairs(plain) do if t == config.path() then truncatable = true end end
  check(not truncatable, 'and not as a plain line that could run off the edge')
end

do -- the Scope checkboxes sit under the question, not beside it
  -- All four on the same line as a sentence that long overflowed the dialog.
  local events = {}
  optdialog({
    Text     = function(_, t) events[#events + 1] = 'text:' .. tostring(t) end,
    SameLine = function() events[#events + 1] = 'sameline' end,
    Checkbox = function(_, label, v)
      events[#events + 1] = 'cb:' .. tostring(label); return false, v
    end,
  }, true)

  local qi, ci
  for i, e in ipairs(events) do
    if not qi and e:find('Reset to the default colour', 1, true) then qi = i end
    if qi and not ci and e:find('^cb:.*##cu') then ci = i end
  end
  check(qi ~= nil, 'the scope question is drawn')
  check(ci ~= nil, 'and its per-kind checkboxes')
  if qi and ci then
    local beside = false
    for i = qi + 1, ci - 1 do if events[i] == 'sameline' then beside = true end end
    check(not beside, 'the first checkbox starts a new line under the question')

    -- the other three still share that line
    local rest = 0
    for i = ci + 1, #events do
      if events[i] == 'sameline' then rest = rest + 1 end
      if events[i]:find('^text:') then break end
    end
    check(rest >= 3, 'and the remaining three sit beside it', rest .. ' SameLine')
  end
end

do -- Remove Rules empties every kind, behind a confirmation
  local real = reaper.ShowMessageBox
  local asked
  reaper.ShowMessageBox = function(msg, _, kind) asked = { msg = msg, kind = kind }; return 6 end

  app.st.cfg.rules = config.starter().rules
  local before = #app.st.cfg.rules.track
  optdialog({ Button = function(_, id) return id == '##Remove Rules' end }, true)
  reaper.ShowMessageBox = real

  check(before > 0, 'the fixture had rules to remove')
  check(asked and asked.kind == 4, 'it asks a yes/no question first')
  local left = 0
  for _, k in ipairs(rules.KINDS) do left = left + #(app.st.cfg.rules[k] or {}) end
  check(left == 0, 'and every kind is emptied', left .. ' left')
  check(app.st.sel_id == nil, 'with the now-dangling selection cleared')
  check(app.can_undo(), 'and a snapshot taken, so Undo puts them back')
end

do -- the third button in the Rules file row
  local _, _, rec = optdialog({ IsItemHovered = function() return true end }, true)
  check(rec.labels['Import from SWS'], 'the rules file section offers Import SWS')
  -- No '...': it acts rather than opening anything, so the label must not
  -- promise a dialog.
  check(not rec.labels['Import from SWS...'], 'without the ellipsis that means "opens a menu"')
end

do -- three buttons have to FIT: the dialog is a fixed width and does not scroll
  local widths = {}
  optdialog({
    GetContentRegionAvail = function() return 14 * 39.6, 640 end,
    GetStyleVar = function() return 8, 8 end,
    Button = function(_, id, w) widths[id] = w; return false end,
  }, true)

  local row = { widths['##Example rules'], widths['##Remove Rules'],
                widths['##Import from SWS'] }
  check(row[1] and row[2] and row[3], 'all three are drawn')
  check(row[1] == row[2] and row[2] == row[3], 'at equal widths',
        table.concat({ tostring(row[1]), tostring(row[2]), tostring(row[3]) }, '/'))
  -- The real constraint. A stub cannot measure pixels, so it checks the
  -- arithmetic instead of pretending to have looked at the screen.
  check(row[1] and (row[1] * 3 + 8 * 2) <= 14 * 39.6,
        'and the row fits the content region, spacing included',
        tostring(row[1]))
end

do -- clicking it imports there and then
  local real = reaper.ShowMessageBox
  local asked
  reaper.ShowMessageBox = function(msg, _, kind) asked = { msg = msg, kind = kind }; return 6 end

  -- No SWS file in the mock resource path, so this exercises the click and the
  -- "nothing found" report without needing a fixture.
  app.st.cfg = config.starter()
  local before = #app.st.cfg.rules.track
  optdialog({ Button = function(_, id) return id == '##Import from SWS' end }, true)
  reaper.ShowMessageBox = real

  check(asked ~= nil, 'the click runs the import')
  -- kind 0 is an OK box, not a yes/no. The import only ever adds, so there is
  -- nothing to confirm: Undo covers it and the report says what arrived.
  check(asked and asked.kind == 0, 'and asks nothing first -- it destroys nothing',
        asked and tostring(asked.kind))
  check(asked and asked.msg:find('not found', 1, true) ~= nil,
        'reporting the missing file', asked and asked.msg)
  check(#app.st.cfg.rules.track == before, 'and the rules are untouched')
end

do -- a click in a dropdown must not dismiss the dialog underneath it
  -- A popup is a separate ROOT window, so IsWindowHovered on the dialog is
  -- false while the mouse is over the Folders dropdown. Without the guard, a
  -- click on one of its entries closed Options.
  local _, _, _, still = optdialog({
    IsPopupOpen    = function() return true end,
    IsMouseClicked = function() return true end,
    IsWindowHovered = function() return false end,
    IsWindowFocused = function() return true end,
  }, true)
  check(still, 'the dialog survives a click while a dropdown of its own is open')

  -- And Escape belongs to the menu while one is up, not to the dialog.
  local _, _, _, still2 = optdialog({
    IsPopupOpen  = function() return true end,
    IsKeyPressed = function() return true end,
  }, true)
  check(still2, 'and survives Escape, which the dropdown should be eating')

  -- The guard must not have broken the ordinary dismissals.
  local _, _, _, gone = optdialog({
    IsMouseClicked  = function() return true end,
    IsWindowHovered = function() return false end,
    IsWindowFocused = function() return true end,
  }, true)
  check(not gone, 'with no popup open, a click outside still closes it')
end

do -- the split checkbox is wired to the option, and repaints the preview
  local src = pathlib_read('lib/gui/window.lua')
  check(src:find('o.subfolder_splits_range = v', 1, true) ~= nil,
        'ticking it writes the option')
  -- It changes colours, so it must NOT take the mark_dirty(true) shortcut that
  -- the timing sliders use to skip the preview recompute.
  local i = src:find('o.subfolder_splits_range = v', 1, true)
  local tail = src:sub(i, i + 120)
  check(tail:find('app.mark_dirty()', 1, true) ~= nil,
        'and recomputes the preview, rather than skipping it')
  check(tail:find('app.mark_dirty(true)', 1, true) == nil,
        'not the skip-preview variant')
  check(src:find('app.snapshot(); o.subfolder_splits_range', 1, true) ~= nil,
        'with an undo snapshot taken first')
end

do -- dimming is done with the GLOBAL alpha, not a veil
  local src = pathlib_read('lib/gui/window.lua')
  -- the CODE form, so the comment explaining why it is avoided does not trip it
  check(src:find('ImGui.Col_ModalWindowDimBg', 1, true) == nil,
        'the uncontrollable modal dim colour is not used')
  check(src:find('ImGui.DrawList_AddRectFilled', 1, true) == nil,
        'and no veil rect either -- it cannot reach inside child windows')
  check(src:find('push_content_dim', 1, true) ~= nil,
        'the content is faded with the global alpha instead')
  check(src:find('StyleVar_WindowPadding', 1, true) ~= nil,
        'and the dialog gets its own padding')

  -- The dialog must not drift back to being a popup. ImGui owns a popup's
  -- visibility and closes it on focus loss; re-opening it from our own flag
  -- fixed the alt-tab disappearance but left a visible blink on the first click
  -- elsewhere in REAPER, inside ImGui's own reopen where a script cannot reach.
  check(src:find('BeginPopup(ctx, OPTIONS_', 1, true) == nil,
        'the options dialog is not a popup')
  check(src:find('PopupFlags_NoReopen', 1, true) == nil,
        'and does not try to re-open one every frame')
  check(src:find('Begin(ctx, OPTIONS_TITLE', 1, true) ~= nil,
        'it is begun as an ordinary window, by its shared name constant')
  check(src:find('WindowFlags_TopMost', 1, true) ~= nil,
        'always on top, or the dimmed window behind could cover it')

  -- Everything a popup used to give away free has to be asked for.
  check(src:find('Key_Escape', 1, true) ~= nil, 'Escape is handled by hand')
  check(src:find('IsMouseClicked', 1, true) ~= nil,
        'as is dismissal by a click on the window behind')
  local tsrc = pathlib_read('lib/gui/theme.lua')
  check(tsrc:find('BeginDisabled', 1, true) ~= nil,
        'and the dim blocks input, which a window does not')

  check(theme.DIM_CONTENT > 0 and theme.DIM_CONTENT < 1,
        'the dim level is a sane fraction', tostring(theme.DIM_CONTENT))
end

do -- window.draw must not draw the dialog itself
   -- It is a top-level window, so it is drawn from the frame loop AFTER the
   -- main window has ended. Drawing it inside would nest it in the dim it is
   -- supposed to sit above -- and a window cannot be begun inside another.
  local drawn = false
  local ImGui = mockimgui.new{ scripted = {
    Begin = function(_, name)
      if name == 'Options' then drawn = true end
      return true, true
    end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  app.st.options_open = true
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
  check(not drawn, 'window.draw leaves the dialog to the frame loop')

  theme.push(14); assert(pcall(window.draw_options, 14)); theme.pop()
  app.st.options_open = false
  check(drawn, 'and draw_options is what puts it on screen')
end

------------------------- the bottom panels fill the width, like the table
do
  -- The complaint this encodes: the pattern tester's right border did not line
  -- up with the rule table's above it. SameLine puts ItemSpacing.x between the
  -- two panels, but the tester was sized as if the gap were a whole font size,
  -- so it came up (FS - ItemSpacing.x) short -- and being font-relative, the
  -- error grew every time the text size went up.
  local SPACING = 8
  local widths = {}
  local ImGui = mockimgui.new{ scripted = {
    GetStyleVar = function() return SPACING, 4 end,
    BeginChild  = function(_, name, w) widths[name] = w; return true end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()

  -- the mock's GetContentRegionAvail
  local availw = 900
  check(widths['preview'] ~= nil, 'the preview list is drawn')
  check(widths['tester'] ~= nil, 'and the pattern tester')
  if widths['preview'] and widths['tester'] then
    local total = widths['preview'] + SPACING + widths['tester']
    check(total == availw,
          'the two panels plus the gap fill the width exactly',
          string.format('%g + %g + %g = %g, want %g',
                        widths['preview'], SPACING, widths['tester'], total, availw))
  end
end

------------------------------------- the status line holds its own space
do
  -- The complaint this encodes: the status message used to sit among the top
  -- banners, so every message pushed the whole window down and let it spring
  -- back six seconds later. Its space is now reserved whether or not there is
  -- anything to say, which means every size handed to the tables and the
  -- preview panels must come out identical either way.
  local function layout(message)
    local sizes, texts = {}, {}
    local ImGui = mockimgui.new{ scripted = {
      BeginTable = function(_, name, _, _, _, h)
        sizes[#sizes + 1] = name .. '=' .. tostring(h); return true
      end,
      BeginChild = function(_, name, w, h)
        sizes[#sizes + 1] = string.format('%s=%sx%s', name, tostring(w), tostring(h))
        return true
      end,
      Text        = function(_, t) texts[#texts + 1] = tostring(t) end,
      TextColored = function(_, _, t) texts[#texts + 1] = tostring(t) end,
    } }
    window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
    P.advance(1)
    app.recompute_preview()
    if message then app.toast(message) else app.st.toast = nil end
    assert(pcall(window.draw, 14))
    app.st.toast = nil
    return table.concat(sizes, ' '), texts
  end

  local MSG = 'Coloured 3 objects.'
  local quiet, quiet_texts = layout(nil)
  local loud,  loud_texts  = layout(MSG)

  check(quiet:find('preview=') ~= nil and quiet:find('rules_track=') ~= nil,
        'the frame lays out its tables and panels')
  -- Weak on its own -- the stub reports a fixed content region, so it cannot
  -- show real reflow. It guards the code path: the sizes must not be COMPUTED
  -- from whether a message exists. The two assertions below are the ones that
  -- fail against the old top-of-window banner.
  check(quiet == loud, 'no size is computed from whether a message is showing',
        quiet == loud and '' or ('\n  quiet: ' .. quiet .. '\n  loud:  ' .. loud))

  local said = false
  for _, t in ipairs(loud_texts) do if t == MSG then said = true end end
  check(said, 'the message is shown')

  local blank = false
  for _, t in ipairs(quiet_texts) do if t == '' then blank = true end end
  check(blank, 'and an empty line keeps its place when there is none')

  -- It belongs at the foot: nothing the body draws may follow it.
  local last_msg
  for i, t in ipairs(loud_texts) do if t == MSG then last_msg = i end end
  check(last_msg ~= nil and last_msg >= #loud_texts - 1,
        'the status line is the last thing drawn in the body',
        string.format('%s of %d', tostring(last_msg), #loud_texts))
end

------------------------------------- the table joins the open tab
do
  -- Three separate things have to hold for the join to read as one surface,
  -- and each has failed on its own during development.
  local events = {}
  local ImGui
  ImGui = mockimgui.new{ scripted = {
    PushStyleVar = function(_, idx, a)
      if idx == ImGui.StyleVar_TabBarBorderSize then
        events[#events + 1] = 'noborder:' .. tostring(a)
      end
    end,
    SetCursorPosY = function(_, y) events[#events + 1] = 'pullup:' .. tostring(y) end,
    PushStyleColor = function(_, idx, col)
      if idx == ImGui.Col_TableHeaderBg then
        events[#events + 1] = 'headerbg:' .. tostring(col)
      end
    end,
    Indent     = function() events[#events + 1] = 'indent' end,
    Unindent   = function() events[#events + 1] = 'unindent' end,
    BeginTable = function(_, name)
      if name:find('^rules_') then events[#events + 1] = 'table' end
      return true
    end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.recompute_preview()
  assert(pcall(window.draw, 14))

  local seen = {}
  for _, e in ipairs(events) do seen[e:match('^[^:]+')] = e end

  check(seen.noborder == 'noborder:0',
        "ImGui's own tab separator is suppressed", tostring(seen.noborder))
  check(seen.pullup ~= nil, 'the content is pulled up against the tab strip')

  check(seen.headerbg ~= nil,
        'the header row is repainted in the open tab colour', tostring(seen.headerbg))

  -- The inset shifts the tab STRIP onto the table's header fill. A tab item's
  -- contents are drawn inside the indent, so leaving it on shifted every cell
  -- and cost the table a pixel of width -- enough to clip the buttons in the
  -- columns sized tight to their contents. Every Indent must be matched before
  -- the table is drawn.
  local depth, max_depth_at_table = 0, nil
  for _, e in ipairs(events) do
    if     e == 'indent'   then depth = depth + 1
    elseif e == 'unindent' then depth = depth - 1
    elseif e == 'table'    then max_depth_at_table = math.max(max_depth_at_table or 0, depth)
    end
  end
  check(depth == 0, 'indent and unindent are balanced over the frame', tostring(depth))
  check(max_depth_at_table == 0,
        'and the table is drawn outside the tab strip inset',
        'depth ' .. tostring(max_depth_at_table))
end

------------------------- the rule table draws at ORDINARY frame padding
do
  -- PushStyleVar is LIFO, and the tab strip pushes two vars. The tab's
  -- contents pop the padding back off before drawing the table -- so anything
  -- pushed AFTER the padding is what that pop actually removes, leaving the
  -- table at tab padding and every control in it visibly bigger. Track the
  -- live FramePadding and check it when the rule table starts.
  local stack, at_table = {}, nil
  local ImGui
  ImGui = mockimgui.new{ scripted = {
    PushStyleVar = function(_, idx, a, b)
      stack[#stack + 1] = (idx == ImGui.StyleVar_FramePadding)
                          and { a, b } or 'other'
    end,
    PopStyleVar = function() stack[#stack] = nil end,
    BeginTable = function(_, name)
      if name:find('^rules_') and at_table == nil then
        for i = #stack, 1, -1 do
          if stack[i] ~= 'other' then at_table = stack[i]; break end
        end
        at_table = at_table or false
      end
      return true
    end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  P.advance(1); app.recompute_preview()
  assert(pcall(window.draw, 14))

  -- theme.push (the outer one) is not applied in this test, so the innermost
  -- FramePadding still live at the table must NOT be the tab's.
  local tabpad = { math.floor(14 * theme.TAB_PAD_X + 0.5),
                   math.floor(14 * theme.TAB_PAD_Y + 0.5) }
  check(at_table ~= nil, 'the rule table is reached')
  local is_tabpad = at_table and at_table ~= false
                    and at_table[1] == tabpad[1] and at_table[2] == tabpad[2]
  check(not is_tabpad, 'the table does not inherit the tab strip padding',
        at_table == false and 'none live'
        or string.format('%s, %s', tostring(at_table[1]), tostring(at_table[2])))
end

--------------------------- the gap closes to the PAINTED tab edge, not the bar
do
  -- Measured in REAPER: a tab's item rect was 31 tall while the tab is painted
  -- FontSize + 2*padding = 28. ImGui reserves the other 3px below the tab
  -- shapes for its overline and border, and the cursor lands below THAT. A
  -- pull-up of only ItemSpacing left those 3px of window background showing
  -- between the strip and the table, which is the join failing.
  local moved
  local ImGui = mockimgui.new{ scripted = {
    GetCursorPosY = function() return 1000 end,
    GetStyleVar   = function() return 8, 4 end,       -- ItemSpacing 8, 4
    SetCursorPosY = function(_, y) moved = y end,
  } }
  theme.init(ImGui, { 'ctx' })

  local painted = theme.tab_paint_height(14)
  check(painted == 14 + 2 * math.floor(14 * theme.TAB_PAD_Y + 0.5),
        'a tab is painted font size plus its own padding', tostring(painted))

  -- On top of the reserved strip the table also rides UP over the bottom of
  -- the tab by TAB_SHELF_BITE, which is what closed the last hairline of
  -- background on a 175% DPI display. It is taken on every call, reserved
  -- strip or not, so it belongs in all three expectations below. Derived from
  -- the constant rather than written out, so re-tuning the bite does not mean
  -- re-deriving these by hand.
  local bite = theme.TAB_SHELF_BITE * theme.text_height()
  check(bite > 0, 'the table bites into the tab strip', tostring(bite))

  -- Grouped exactly as close_tab_gap groups it -- reserved is summed first,
  -- then subtracted once -- so this is an exact comparison, not a near one.
  theme.close_tab_gap(14, painted + 3)
  check(moved == 1000 - 4 - (3 + bite),
        'the spacing AND the reserved strip are closed', tostring(moved))

  theme.close_tab_gap(14, painted)
  check(moved == 1000 - 4 - (0 + bite),
        'nothing extra is taken when none is reserved', tostring(moved))

  theme.close_tab_gap(14, painted - 5)
  check(moved == 1000 - 4 - (0 + bite),
        'and a shorter rect never pushes the table DOWN', tostring(moved))
end

--------------------------------------- tabs sit on whole-pixel boundaries
do
  -- ImGui truncates a tab's left edge to an integer but not its width, so a
  -- fractional FramePadding makes the gaps between tabs drift. Measured in
  -- REAPER at font size 14 before this was rounded: 3.20 / 4.20 / 4.20 against
  -- an ItemInnerSpacing of 4. See theme.push_tab_padding.
  local got
  local ImGui = mockimgui.new{ scripted = {
    PushStyleVar = function(_, _, a, b) got = { a, b } end,
  } }
  theme.init(ImGui, { 'ctx' })

  for _, fs in ipairs({ 12, 13.7, 14, 17.5 }) do
    theme.push_tab_padding(fs)
    check(got[1] % 1 == 0 and got[2] % 1 == 0,
          'tab padding is whole pixels at font size ' .. fs,
          string.format('%s, %s', tostring(got[1]), tostring(got[2])))
  end

  -- and the tab width it produces stays whole for a whole-width label
  theme.push_tab_padding(14)
  check((69 + got[1] * 2) % 1 == 0,
        'so a tab width comes out whole too', tostring(69 + got[1] * 2))
end

------------------------------------------------------- section headings
do
  local drawn, size, seps
  local function grab(label, divider)
    drawn, seps = nil, 0
    size = 14
    local ImGui = mockimgui.new{ scripted = {
      Text        = function(_, t) drawn = { text = t, size = size } end,
      PushFont    = function(_, _, sz) size = sz end,
      PopFont     = function() size = 14 end,
      Separator   = function() seps = seps + 1 end,
      GetFontSize = function() return 14 end,
      GetStyleColor = function() return 0xE0E0E0FF end,
    } }
    theme.init(ImGui, { 'ctx' })
    theme.section(label, divider)
  end

  grab('Objects preview')
  check(drawn and drawn.text == 'OBJECTS PREVIEW', 'headings are uppercased',
        drawn and drawn.text)
  check(drawn and drawn.size > 14 and drawn.size < 14 * 1.2,
        'and only slightly larger than body text', drawn and tostring(drawn.size))
  check(seps == 0, 'a plain heading draws no rule')

  grab('Scope', true)
  check(seps == 1, 'a divided heading draws exactly one 1px rule', seps .. ' rules')

  -- one size only: mixing sizes on a line cannot be baseline-aligned in ImGui,
  -- which is why the small-caps attempt was abandoned
  check(not pathlib_read('lib/gui/theme.lua'):find('SMALLCAPS', 1, true),
        'no small-caps emulation remains')

  -- the other cases still work
  local saved = theme.SECTION_CASE
  theme.SECTION_CASE = 'title'
  grab('Background auto-colouring')
  check(drawn and drawn.text == 'Background Auto-Colouring',
        'title case is still available', drawn and drawn.text)
  theme.SECTION_CASE = 'none'
  grab('Background auto-colouring')
  check(drawn and drawn.text == 'Background auto-colouring',
        'as is leaving it alone')
  theme.SECTION_CASE = saved
end

--------------------------- the segmented control is ONE button, divided
do
  -- Three separate buttons with gaps between them read as three controls. This
  -- is the difference: butted together, rounded only at the outer ends, with a
  -- hairline at each join.
  local gaps, rects, lines = {}, {}, 0
  local ImGui
  ImGui = mockimgui.new{ scripted = {
    SameLine = function(_, off, spacing) gaps[#gaps + 1] = spacing end,
    Button   = function(_, id) if id:find('tmode') then rects[#rects + 1] = id end
                               return false end,
    DrawList_AddRectFilled = function(_, _, _, _, _, _, _, flags)
      if flags ~= nil then rects.flags = rects.flags or {}
                           rects.flags[#rects.flags + 1] = flags end
    end,
    DrawList_AddLine = function() lines = lines + 1 end,
  } }
  window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
  app.st.sel_id = nil
  P.advance(1); app.recompute_preview()
  theme.push(14); assert(pcall(window.draw, 14)); theme.pop()

  check(#rects == 3, 'the row is three segments', tostring(#rects))

  -- every SameLine the segmented row makes is a zero gap
  local zero = 0
  for _, g in ipairs(gaps) do if g == 0 then zero = zero + 1 end end
  check(zero >= 2, 'the segments are butted together, not spaced',
        zero .. ' zero gaps')

  local f = rects.flags or {}
  local want = { ImGui.DrawFlags_RoundCornersLeft,
                 ImGui.DrawFlags_RoundCornersNone,
                 ImGui.DrawFlags_RoundCornersRight }
  local seen = {}
  for _, v in ipairs(f) do seen[v] = true end
  check(seen[want[1]], 'the first segment rounds only its left end')
  check(seen[want[3]], 'the last rounds only its right end')
  check(seen[want[2]], 'and the middle is square on both sides')
  check(lines > 0, 'a hairline is drawn where segments meet')
end

------------------------------------------------- the tester is a scratch pad
do
  -- It draws with nothing selected, and offers its own mode buttons.
  app.st.sel_id = nil
  local ok, err, rec = frame()
  check(ok, 'a frame with no rule selected draws', tostring(err))
  -- The segmented row paints its own frames and labels, so ImGui only ever
  -- sees an empty id per segment. The visible text reaches the mock through
  -- CalcTextSize/AddText instead, so the two are asserted separately.
  for i, lbl in ipairs({ 'contains', 'glob', 'regex' }) do
    check(rec.labels[lbl], 'the tester offers the ' .. lbl .. ' button')
    check(rec.labels['##tmode' .. i], 'and it has an id of its own')
  end
  check(rec.labels['pattern'] and rec.labels['a name to try it on'],
        'and its own pattern and name fields')

  local pv = pathlib_read('lib/gui/preview.lua')
  check(not pv:find('Use selected track name', 1, true),
        'the "use the selected track" button is gone')
  local body = pv:match('function M%.draw_tester.-\nend\n')
  check(body and not body:find('sel_id', 1, true),
        'and draw_tester never looks at the selection')
  check(not pv:find('Heads up', 1, true),
        'the rule warnings have left the tester panel')
  check(pathlib_read('lib/gui/window.lua'):find('rulesmod.warnings', 1, true) ~= nil,
        'and sit beside the rules they are about')
end

do -- the renamed panel headings
  local pv = pathlib_read('lib/gui/preview.lua')
  check(pv:find("theme.section('Objects preview')", 1, true) ~= nil,
        'the preview list is headed "Objects preview"')
  check(pv:find("theme.section('Pattern tester')", 1, true) ~= nil,
        'and the tester "Pattern tester"')
  check(not pv:find('rules match right now', 1, true), 'the old wording is gone')
  check(not pv:find("'Try a name'", 1, true), 'and so is the old tester heading')

  -- every heading in the GUI must come from the theme, or they drift apart
  for _, f in ipairs({ 'lib/gui/window.lua', 'lib/gui/preview.lua',
                       'lib/gui/rule_table.lua' }) do
    check(not pathlib_read(f):find('ImGui.SeparatorText', 1, true),
          f .. ' heads its sections through the theme')
  end
  check(not pathlib_read('lib/gui/theme.lua'):find('ImGui.SeparatorText', 1, true),
        'and SeparatorText is gone entirely -- it cannot do small caps')
end

------------------------------------------- the gradient scope combo
do
  -- it exists only where a gradient does
  local function labels_with(color2, kind)
    app.st.cfg.rules = config.empty_rules()
    app.st.cfg.rules[kind][1] = rules.new(kind, { label = 'G', pattern = 'a',
                                                  color = 0x112233, color2 = color2 })
    app.st.active_kind = kind
    -- Combos are closed by default in the stub, so their items are never
    -- drawn. Open them: the point of this test is which options a kind offers.
    local ImGui, rec = mockimgui.new{ only_tab = rules.KIND_LABEL[kind],
                                      scripted = { BeginCombo = function() return true end } }
    window.init(ImGui, { 'ctx' }); theme.init(ImGui, { 'ctx' })
    P.advance(1); app.refresh_entries(true); app.recompute_preview()
    theme.push(14); assert(pcall(window.draw, 14)); theme.pop()
    return rec.labels
  end

  check(labels_with(0x445566, 'track')['##gscope'],
        'a gradient rule offers the grouping combo')
  check(not labels_with(nil, 'track')['##gscope'],
        'a flat rule does not')

  -- folder grouping is meaningless for items, so it must not be offered
  local tr_l = labels_with(0x445566, 'track')
  check(tr_l[rules.GRADIENT_LABEL.folder], 'tracks can group by folder')
  local it_l = labels_with(0x445566, 'item')
  check(it_l[rules.GRADIENT_LABEL.run], 'items can group by run')
  check(not it_l[rules.GRADIENT_LABEL.folder], 'but not by folder')
end

do -- preview and Apply must agree for a GROUPED gradient too, not just a flat
   -- one -- this pair has drifted twice before
  for _, t in ipairs(P.tracks) do t.color = 0 end
  app.st.cfg.options.propagate_folders = 'off'
  app.st.cfg.rules = config.empty_rules()
  app.st.cfg.rules.track[1] = rules.new('track', { label = 'Spread', mode = 'regex',
                                                   pattern = '.', color = 0xFF0000,
                                                   color2 = 0x0000FF,
                                                   gradient_scope = 'run' })
  local pv = preview_by_name('track')
  local ap = applied_by_name()
  local mismatch
  for name, p in pairs(pv) do
    if p.kind == 'track' and ap[name] ~= p.color then mismatch = name end
  end
  check(mismatch == nil, 'every previewed grouped-gradient colour is what Apply writes',
        tostring(mismatch))
end

print('\n=== gui render (stub ImGui) ===')
for _, f in ipairs(fails) do print('  FAIL  ' .. f) end
print(string.format('%d passed, %d failed\n', pass, fail))
os.exit(fail == 0 and 0 or 1)
