--[[
  gui/window.lua -- top bar, banners, layout.

  Sizing rule for the whole window: every dimension is a multiple of
  ImGui.GetFontSize(ctx). ReaImGui already reports coordinates in logical,
  DPI-independent units and rasterises glyphs at the device resolution, so
  multiplying by GetWindowDpiScale (2.0 on a Retina Mac) would render the UI at
  double size. Sizing off the font is what makes this correct on any display.
]]

local config   = require 'config'
local rulesmod = require 'rules'
local app      = require 'gui.app'
local ruletbl  = require 'gui.rule_table'
local preview  = require 'gui.preview'
local theme    = require 'gui.theme'
local iconbrowser = require 'gui.icon_browser'
local dialog   = require 'gui.dialog'
local icons    = require 'icons'
local aboutmod = require 'about'

local M = {}

local ImGui, ctx
function M.init(imgui, context)
  ImGui, ctx = imgui, context
  ruletbl.init(imgui, context)
  preview.init(imgui, context)
  iconbrowser.init(imgui, context)
  dialog.init(imgui, context)
end

local function rgba(rgb, a) return ((rgb & 0xFFFFFF) << 8) | (a or 0xFF) end

local COL_DIM   = 0x9A9A9A
local COL_WARN  = 0xD9A441
local COL_ERR   = 0xC2413B
local COL_OK    = 0x5FB36A

local FOLDER_LABEL = {
  off            = 'off -- folders do not colour their children',
  fill_unmatched = 'fill gaps -- children with no rule of their own inherit',
  force          = 'force -- the folder colour overrides its children',
}

----------------------------------------------------------------------- bars
local function banners(FS)
  local st = app.st

  if st.readonly then
    ImGui.TextColored(ctx, rgba(COL_WARN),
      'This config file was written by a newer version. Editing is allowed but nothing will be saved.')
  end

end

--- The status line, at the foot of the window.
--- It ALWAYS occupies exactly one line, whether or not there is anything to
--- say: a line that comes and goes reflows everything above it, so the whole
--- window used to jump down and back each time a message timed out. `y` is the
--- content position reserved for it; the line is pushed there only when the
--- content above fell short, so it cannot overlap an overflowing layout.
local function status_line(y)
  if ImGui.GetCursorPosY(ctx) < y then ImGui.SetCursorPosY(ctx, y) end
  local toast = app.current_toast()
  if toast then
    ImGui.TextColored(ctx, rgba(COL_OK), toast)
  else
    ImGui.Text(ctx, '')
  end
end

-- The dialogs' window names.
local OPTIONS_TITLE = 'Options'
local ABOUT_TITLE   = 'About'

-- The text size while the slider is being dragged. Every dimension in the
-- window is a multiple of the font size, INCLUDING this slider, so applying the
-- value live moved the slider out from under the cursor and the drag chased
-- itself. The number under the handle follows the drag; the layout waits.
local pending_font = nil

-- The main window's geometry, remembered by M.draw. The dialog centres on it
-- but is drawn after End(), where GetWindowPos has no window left to report.
-- Seeded with the first-use size from MXM_AutoColor_GUI.lua.
local main_x, main_y, main_w, main_h = 0, 0, 78 * 14, 44 * 14

------------------------------------------------------------------ SWS import
--- The confirmation: counts only.
---
--- WHY a rule arrives switched off is a table in the documentation, not
--- something to read in a modal with a Yes button waiting.
local function confirm_text(res)
  local kinds = {}
  for _, k in ipairs({ 'track', 'region', 'marker', 'icon' }) do
    local n = #(res.rules[k] or {})
    if n > 0 then
      kinds[#kinds + 1] = n .. ' ' .. rulesmod.KIND_NOUN[k] .. (n == 1 and '' or 's')
    end
  end

  local lines = { string.format('Import %d rule%s from SWS Auto Color?',
                                res.imported, res.imported == 1 and '' or 's'),
                  '', '  ' .. table.concat(kinds, ', ') }
  if res.disabled > 0 then
    lines[#lines + 1] = string.format('  %d of them switched off', res.disabled)
  end
  if res.skipped > 0 then
    lines[#lines + 1] = string.format('  %d line%s could not be read',
                                      res.skipped, res.skipped == 1 and '' or 's')
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'Appended below existing rules.'
  return table.concat(lines, '\n')
end

--- One button. It reads SWS, says what it found, and only then changes
--- anything -- so the dialog is the last chance to say no rather than a
--- receipt for something already done.
local function do_import()
  local res, err = app.scan_sws()
  if not res then
    reaper.ShowMessageBox(err, 'AutoColor', 0)
    return
  end

  if reaper.ShowMessageBox(confirm_text(res), 'AutoColor', 4) ~= 6 then return end

  app.merge_sws(res)
  app.toast(string.format('Imported %d rule%s from SWS.',
                          res.imported, res.imported == 1 and '' or 's'))
end

--- The Options dialog. See dialog.lua for why it is a window.
function M.draw_options(FS)
  local st = app.st
  if not st.options_open then return end

  -- Fixed width, automatic height. Wide enough for the longest fixed line in
  -- here -- the Scope question -- with the checkboxes under it rather than
  -- beside it. The config-file path is the one thing with no bound on its
  -- length, so it wraps instead (see below).
  local visible, open = dialog.begin(FS, OPTIONS_TITLE, {
    x = main_x + main_w * 0.5, y = main_y + main_h * 0.5, w = FS * 42 })
  if open == false then st.options_open = false end
  if not visible then return end      -- End() only when Begin returned true


  local o = st.cfg.options
  local rv, v

  theme.section('Folders')
  ImGui.SetNextItemWidth(ctx, FS * 34)
  if ImGui.BeginCombo(ctx, '##folders', FOLDER_LABEL[o.propagate_folders]) then
    for _, k in ipairs({ 'off', 'fill_unmatched', 'force' }) do
      if ImGui.Selectable(ctx, FOLDER_LABEL[k], o.propagate_folders == k) then
        app.snapshot(); o.propagate_folders = k; app.mark_dirty()
      end
    end
    ImGui.EndCombo(ctx)
  end

  rv, v = theme.checkbox('Subfolder splits the parent\'s colour range',
                         o.subfolder_splits_range)
  if rv then app.snapshot(); o.subfolder_splits_range = v; app.mark_dirty() end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      'Only affects rules that spread their gradient across "folders".\n\n' ..
      'On: a nested folder ends the range around it, so the tracks after it\n' ..
      'start the ramp again and each stretch gets the full range. A folder at\n' ..
      'the top level does the same to the tracks around it.\n\n' ..
      'Off: one ramp for the whole folder -- the tracks after a nested folder\n' ..
      'carry on from where the ones before it left off.\n\n' ..
      'A stretch with only one track in it shows the FIRST colour, so a folder\n' ..
      'made mostly of subfolders ends up flat.')
  end

  theme.section('Scope', true)
  ImGui.Text(ctx, 'Reset to the default colour when no rule matches:')
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      'Makes the rules the single source of truth for that kind.\n\n' ..
      'Careful: it also strips colours you set by hand.')
  end
  -- On their own line, under the question: the four of them beside a sentence
  -- that long overflowed the dialog.
  for i, k in ipairs(rulesmod.KINDS) do
    if i > 1 then ImGui.SameLine(ctx) end
    local rvc, vc = theme.checkbox(rulesmod.KIND_LABEL[k] .. '##cu' .. k,
                                   o.clear_unmatched[k])
    if rvc then app.snapshot(); o.clear_unmatched[k] = vc; app.mark_dirty() end
    if k == 'icon' then
      ImGui.SetItemTooltip(ctx, 'Removes the icon from tracks no icon rule matches.')
    end
    if ImGui.IsItemHovered(ctx) and k == 'item' then
      ImGui.SetTooltip(ctx,
        'Recommended for items.\n\n' ..
        'An item with no custom colour is drawn by REAPER in its TRACK\'s\n' ..
        'colour, live -- so copying it to another track makes it follow that\n' ..
        'track immediately, with no rule and nothing to go stale.\n\n' ..
        'This is usually better than "also colour items" on the track rules,\n' ..
        'which freezes a colour onto the item instead.')
    end
  end

  theme.section('Background auto-colouring', true)
  rv, v = theme.checkbox('Create undo points for automatic changes', o.auto_undo)
  if rv then app.snapshot(); o.auto_undo = v; app.mark_dirty() end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Off by default: an undo point every time you rename\n' ..
                          'a track would shred your undo history, and colours\n' ..
                          'can always be re-derived from the rules.')
  end

  ImGui.SetNextItemWidth(ctx, FS * 10)
  rv, v = ImGui.SliderDouble(ctx, 'Check every (s)', o.tick_interval, 0.05, 2.0, '%.2f')
  if rv then o.tick_interval = v; app.mark_dirty(true) end

  ImGui.SetNextItemWidth(ctx, FS * 10)
  rv, v = ImGui.SliderInt(ctx, 'Work budget (ms)', math.floor(o.cold_budget_ms), 1, 50)
  if rv then o.cold_budget_ms = v; app.mark_dirty(true) end

  ImGui.SetNextItemWidth(ctx, FS * 10)
  rv, v = ImGui.SliderInt(ctx, 'Rescan items at most every (s)',
                          math.floor(o.cold_interval), 0, 60)
  if rv then o.cold_interval = v; app.mark_dirty(true) end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      'Tracks are checked on every change. Items and regions are\n' ..
      'much more numerous, so they are only re-read when something\n' ..
      'says they need it -- one appeared or vanished, a track\n' ..
      'changed, or this long has passed.\n\n' ..
      'It is the delay before an item RENAMED in place is noticed;\n' ..
      'nothing else waits on it. 0 re-reads everything on every\n' ..
      'change, which is slow on a large project.')
  end

  theme.section('Window', true)
  ImGui.SetNextItemWidth(ctx, FS * 10)
  rv, v = ImGui.SliderInt(ctx, 'Text size',
                          math.floor(pending_font or o.font_size), 8, 20)
  if rv then pending_font = v end
  -- Committed on RELEASE, not on change: see pending_font above. This also
  -- covers a ctrl-click typed value, which deactivates the same way.
  if ImGui.IsItemDeactivatedAfterEdit(ctx) and pending_font then
    o.font_size = pending_font
    app.mark_dirty(true)
  end
  if ImGui.IsItemDeactivated(ctx) then pending_font = nil end

  theme.section('Config file', true)
  -- WRAPPED, not TextColored: a path has no bound on its length, and the one
  -- thing asked of this line is that it always shows the whole thing. Wrapping
  -- costs a second line on a long path; truncation costs the part you needed.
  -- TextWrapped has no colour argument, hence the push.
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, rgba(COL_DIM))
  ImGui.TextWrapped(ctx, config.path())
  ImGui.PopStyleColor(ctx)
  -- Equal widths: auto-sized buttons on one row come out ragged. Derived, not
  -- a constant: the dialog is FS*42 wide less MODAL_PAD each side, so three
  -- buttons at the old FS*13 plus two ItemSpacing gaps overflow it. Splitting
  -- the content region three ways also survives the text-size slider, which
  -- sits three sections above this one.
  local spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
  local rw = math.floor((ImGui.GetContentRegionAvail(ctx) - spacing * 2) / 3)

  -- A read-only config (written by a newer version) is never saved back, so
  -- letting these run would destroy the user's view of their rules and persist
  -- nothing. app.import_sws refuses on its own too; this is what makes the
  -- refusal visible before the click.
  ImGui.BeginDisabled(ctx, app.st.readonly)

  if theme.button('Example rules', rw) then
    local ans = reaper.ShowMessageBox(
      'Replace your current rules with the built-in example set?\n\n' ..
      'Your existing rules will be gone. This can be undone with the ' ..
      'Undo button while the window is open.',
      'AutoColor', 4)
    if ans == 6 then
      app.snapshot()
      app.st.cfg.rules = config.starter().rules
      app.mark_dirty()
      app.toast('Loaded the example rules.')
    end
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      'Replaces every rule with the built-in example set.\n\n' ..
      'Asks for confirmation.')
  end

  ImGui.SameLine(ctx)
  if theme.button('Remove Rules', rw) then
    local ans = reaper.ShowMessageBox(
      'Remove every rule, on all four tabs?\n\n' ..
      'This can be undone with the Undo button while the window is open.',
      'AutoColor', 4)
    if ans == 6 then
      app.snapshot()
      app.st.cfg.rules = config.empty_rules()
      -- the selection can only be pointing at a rule that no longer exists
      app.st.sel_id = nil
      app.mark_dirty()
      app.toast('Removed every rule.')
    end
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx,
      'Empties all four tabs.\n\n' ..
      'Asks for confirmation.')
  end

  -- Third, so the two above keep the positions people already know. No '...':
  -- it acts, it does not open anything.
  ImGui.SameLine(ctx)
  if theme.button('Import from SWS', rw) then do_import() end
  if ImGui.IsItemHovered(ctx) then
    -- Two lines. The detail belongs on the documentation page, not in a
    -- tooltip somebody is reading with the mouse already on the button.
    ImGui.SetTooltip(ctx,
      'Appends the rules from SWS Auto Color below existing rules.\n\n' ..
      'Unsupported SWS modes are imported as inactive.\n\n' ..
      'Asks for confirmation.')
  end

  ImGui.EndDisabled(ctx)

  if app.st.readonly then
    ImGui.TextColored(ctx, rgba(COL_WARN),
      'Read-only: this file was written by a newer version of AutoColor.')
  end

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)
  local bw = FS * 8
  theme.center(bw)
  if theme.button('Close', bw) then st.options_open = false end

  if dialog.dismissed() then st.options_open = false end

  ImGui.End(ctx)
end

--- The icon browser, centred on the main window.
function M.draw_icon_browser(FS)
  iconbrowser.draw(FS, main_x, main_y, main_w, main_h)
end

-- The About dialog. Same shape as the Options one.
function M.draw_about(FS)
  local st = app.st
  if not st.about_open then return end

  local visible, open = dialog.begin(FS, ABOUT_TITLE, {
    x = main_x + main_w * 0.5, y = main_y + main_h * 0.5, w = FS * 32 })
  if open == false then st.about_open = false end
  if not visible then return end


  ImGui.PushFont(ctx, nil, FS * theme.SECTION_SCALE)
  ImGui.Text(ctx, aboutmod.NAME)
  ImGui.PopFont(ctx)
  ImGui.SameLine(ctx)
  ImGui.TextColored(ctx, rgba(COL_DIM), aboutmod.VERSION)

  ImGui.Spacing(ctx)
  ImGui.TextWrapped(ctx, aboutmod.TAGLINE)

  theme.section('Links', true)
  -- TextLinkOpenURL opens the browser itself, so this needs no SWS and no
  -- shell-out of our own.
  ImGui.TextLinkOpenURL(ctx, 'Source code on GitHub', aboutmod.URL_REPO)
  ImGui.TextLinkOpenURL(ctx, 'Documentation', aboutmod.URL_DOCS)

  theme.section('Author', true)
  ImGui.Text(ctx, aboutmod.AUTHOR)

  theme.section('Licence', true)
  ImGui.TextWrapped(ctx, aboutmod.LICENCE .. '. ' .. aboutmod.COPYRIGHT .. '.')

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)
  local bw = FS * 8
  theme.center(bw)
  if theme.button('Close##about', bw) then st.about_open = false end

  if dialog.dismissed() then st.about_open = false end

  ImGui.End(ctx)
end

local function clear_icons_popup()
  if ImGui.MenuItem(ctx, 'Clear icons the rules match') then app.clear_icons('matched') end
  ImGui.SetItemTooltip(ctx, 'Removes icons only from tracks an icon rule currently claims.')
  if ImGui.MenuItem(ctx, 'Clear icons on selected tracks') then app.clear_icons('selected') end
  if ImGui.MenuItem(ctx, 'Clear EVERY track icon in the project...') then
    local ans = reaper.ShowMessageBox(
      'Remove every track icon in this project?\n\n' ..
      'This includes icons this tool never set. Undo (Cmd+Z) will put them back.',
      'AutoColor', 4)
    if ans == 6 then app.clear_icons('all') end
  end
end

local function clear_popup()
  if not ImGui.BeginPopup(ctx, 'clearmenu') then return end
  if app.st.active_kind == 'icon' then
    clear_icons_popup()
    ImGui.EndPopup(ctx)
    return
  end

  if ImGui.MenuItem(ctx, 'Clear colours the rules match') then
    app.clear_colors('matched')
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Resets only objects a rule currently claims.')
  end

  if ImGui.MenuItem(ctx, 'Clear selected objects') then
    app.clear_colors('selected')
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Resets what is selected to the theme default,\n' ..
                          'whether or not a rule matches it.\n\n' ..
                          'Follows the same focus rule as Selection: with both\n' ..
                          'a track and items selected, whichever you clicked\n' ..
                          'last wins. Selected regions and markers are always\n' ..
                          'included -- there is no focus value to weigh them\n' ..
                          'against.')
  end

  if ImGui.MenuItem(ctx, 'Clear EVERY custom colour in the project...') then
    local ans = reaper.ShowMessageBox(
      'Reset every custom colour in this project to the theme default?\n\n' ..
      'This includes colours this tool never set. Undo (Cmd+Z) will put ' ..
      'them back.',
      'AutoColor', 4)
    if ans == 6 then app.clear_colors('all') end
  end

  ImGui.EndPopup(ctx)
end

local function auto_button(FS, w)
  local running = app.auto_running()
  local paused  = running and app.auto_paused()

  local label, col
  if not running     then label, col = 'Auto: off',    COL_DIM
  elseif paused      then label, col = 'Auto: paused', COL_WARN
  else                    label, col = 'Auto: on',     COL_OK end

  ImGui.PushStyleColor(ctx, ImGui.Col_Text, rgba(col))
  local clicked = theme.button(label, w)
  ImGui.PopStyleColor(ctx)

  if ImGui.IsItemHovered(ctx) then
    if not running then
      ImGui.SetTooltip(ctx, app.auto_command_id()
        and 'Background auto-colouring is off.\nClick to start it.'
        or  'Background auto-colouring is off.\n\nRun the action\n' ..
            'MXM_AutoColor_AutoToggle.lua once; after that\n' ..
            'this button can start and stop it.')
    else
      ImGui.SetTooltip(ctx, 'Background auto-colouring is running.\n' ..
                            'Click to stop it.')
    end
  end

  if clicked then app.toggle_auto() end
end

--- The action bar. Drawn BELOW the rule table, so "+ rule" already knows which
--- tab is open in this frame rather than lagging one behind.
local function action_bar(FS)
  local st = app.st
  local startx = ImGui.GetCursorPosX(ctx)
  local availw = ImGui.GetContentRegionAvail(ctx)

  -- editing the list first, since that is what the table above is for
  local kindnoun = rulesmod.KIND_NOUN[app.st.active_kind] or 'rule'
  if theme.button('+ ' .. kindnoun .. ' rule', FS * 8) then app.add_rule() end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Add a rule to the ' ..
                          (rulesmod.KIND_LABEL[app.st.active_kind] or '') .. ' tab.')
  end

  ImGui.SameLine(ctx)
  ImGui.BeginDisabled(ctx, not app.can_undo())
  if theme.button('Undo', FS * 4) then app.undo() end
  ImGui.EndDisabled(ctx)
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Undo a change to the RULES (Cmd+Z in this window).\n' ..
                          'Colour changes in the project use REAPER\'s own undo.')
  end

  ImGui.SameLine(ctx)
  ImGui.TextColored(ctx, rgba(COL_DIM), '|')
  ImGui.SameLine(ctx)

  if theme.button('Apply now', FS * 7) then app.apply_all() end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Colour the whole project. One undo point.\n' ..
                          'Also tells background auto-colouring to stop treating\n' ..
                          'hand-picked colours as untouchable.')
  end

  ImGui.SameLine(ctx)
  if theme.button('Selection', FS * 6) then app.apply_selection() end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'Colour only what is selected.\n\n' ..
                          'When a track AND some items are selected, whichever\n' ..
                          'you clicked last wins -- the same rule REAPER uses\n' ..
                          'for its own "depending on focus" actions. The status\n' ..
                          'line says which it used.\n\n' ..
                          'Selected regions and markers are always included.')
  end

  ImGui.SameLine(ctx)
  if theme.button('Clear...', FS * 5) then ImGui.OpenPopup(ctx, 'clearmenu') end
  clear_popup()

  if st.dirty then
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, rgba(COL_DIM), 'saving...')
  end

  -- Auto, Options and About live on the right-hand end of the bar.
  local wauto, wopts, gap = FS * 9, FS * 6.5, FS * 0.5
  local winfo = theme.icon_size()
  ImGui.SameLine(ctx, startx + availw - (wauto + gap + wopts + gap + winfo))
  auto_button(FS, wauto)

  ImGui.SameLine(ctx, 0, gap)
  -- Only raises the flag. The dialogs are top-level windows drawn from the
  -- frame loop after this one has ended, so they sit outside the dim at full
  -- opacity.
  if theme.button('Options', wopts) then app.st.options_open = true end

  ImGui.SameLine(ctx, 0, gap)
  if theme.info_button('about') then app.st.about_open = true end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, 'About ' .. aboutmod.NAME .. ' -- version, links, licence.')
  end
end

------------------------------------------------------------------- the body
function M.draw(FS)
  local st = app.st

  -- Taken while we are still inside this window's Begin/End, for the Options
  -- dialog to centre on afterwards -- by then GetWindowPos has nothing to say.
  main_x, main_y = ImGui.GetWindowPos(ctx)
  main_w, main_h = ImGui.GetWindowSize(ctx)

  iconbrowser.new_frame()

  -- Everything below fades, and stops taking clicks, while a dialog is up.
  local dimmed = st.options_open or st.about_open or iconbrowser.is_open()
  if dimmed then theme.push_content_dim() end

  banners(FS)

  local availw, availh = ImGui.GetContentRegionAvail(ctx)

  -- Carve the status line off the bottom before anything else is measured, so
  -- the space is held for it whether or not a message is showing.
  local statush = ImGui.GetTextLineHeightWithSpacing(ctx)
  local statusy = ImGui.GetCursorPosY(ctx) + availh - statush
  availh = availh - statush

  local bottom = math.min(math.max(FS * 13, availh * 0.35), availh * 0.6)
  local barh   = ImGui.GetFrameHeight(ctx) + FS * 0.9   -- the action bar below
  local tableh = availh - bottom - barh - FS * 3.2      -- and the tab strip

  -- One ordered list per object kind. Precedence is per-kind, so reordering
  -- your track rules cannot change which region wins.
  -- The table draws an outer border, so its header FILL starts one pixel in.
  -- Without this the first tab overhangs the table by that pixel.
  ImGui.Indent(ctx, theme.TAB_INSET)
  -- Suppress ImGui's own tab-bar separator. It widens itself past the bar on
  -- both sides -- BarRect.Min.x - IM_TRUNC(WindowPadding.x * 0.5), and the
  -- same on the right -- so it overhung both the tabs and the table. The
  -- table's tab-coloured header row is the shelf instead.
  --
  -- This goes on the stack BEFORE the tab padding, not after. PushStyleVar is
  -- LIFO, and the tab's contents pop the padding back off to draw the table --
  -- with this on top, that pop took the border size instead and the table drew
  -- at tab padding, making every control in it bigger.
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBarBorderSize, 0)
  theme.push_tab_padding(FS)
  if ImGui.BeginTabBar(ctx, 'kinds') then
    for _, kind in ipairs(rulesmod.KINDS) do
      local on, total = app.count(kind)
      local label = string.format('%s%s###%s', rulesmod.KIND_LABEL[kind],
                                  total > 0 and (' (' .. total .. ')') or '', kind)
      local opened = ImGui.BeginTabItem(ctx, label)
      local _, ty0 = ImGui.GetItemRectMin(ctx)
      local _, ty1 = ImGui.GetItemRectMax(ctx)
      if opened then
        theme.pop_tab_padding()          -- contents use ordinary padding
        -- The inset belongs to the STRIP alone. A tab item's contents are
        -- drawn inside the indent, so leaving it on shifted every cell and made
        -- the table a pixel narrower -- enough to clip the buttons in the
        -- columns sized tight to their contents.
        ImGui.Unindent(ctx, theme.TAB_INSET)
        st.active_kind = kind

        -- The table joins the open tab: no gap, and the header row below picks
        -- up the tab's colour (theme.headers_row), so the two read as one
        -- surface. The header IS the shelf -- it is full width and the right
        -- colour -- so nothing extra is drawn between them.
        theme.close_tab_gap(FS, ty1 - ty0)

        -- Notes go below the table, not above it: anything between the shelf
        -- and the header would break the join, and they point at the action
        -- bar underneath anyway. The table gives up their height, or the page
        -- overflows and grows a scrollbar.
        local notes = {}
        -- Per tab, and only with rules to fight over: SWS's switches are per
        -- kind, and an empty list competes with nothing.
        local sws = total > 0 and app.sws_warning(kind)
        if sws then notes[#notes + 1] = { COL_WARN, sws } end
        if total > 0 and on == 0 then
          notes[#notes + 1] = { COL_WARN, 'Every rule on this tab is switched off.' }
        end
        -- The selected rule's advisory notes, beside the rule they are about.
        local sr = st.sel_id and app.rule_by_id(st.sel_id)
        if sr and sr.kind == kind then
          for _, wtext in ipairs(rulesmod.warnings(sr, st.cfg and st.cfg.options,
                                                   icons.exists)) do
            notes[#notes + 1] = { COL_WARN, wtext, bullet = true }
          end
        end

        local _, spy = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
        local noteh = 0
        local wrapw = ImGui.GetContentRegionAvail(ctx) - ImGui.CalcTextSize(ctx, '- ')
        for _, n in ipairs(notes) do
          local _, h = ImGui.CalcTextSize(ctx, n[2], nil, nil, false, n.bullet and wrapw or -1)
          noteh = noteh + h + spy
        end

        ruletbl.draw(kind, FS, math.max(tableh - noteh, FS * 6))

        for _, n in ipairs(notes) do
          if n.bullet then
            ImGui.TextColored(ctx, rgba(n[1]), '- ')
            ImGui.SameLine(ctx, 0, 0)
            ImGui.TextWrapped(ctx, n[2])
          else
            ImGui.TextColored(ctx, rgba(n[1]), n[2])
          end
        end

        ImGui.Indent(ctx, theme.TAB_INSET)  -- restore for the strip itself
        theme.push_tab_padding(FS)
        ImGui.EndTabItem(ctx)
      end
    end
    ImGui.EndTabBar(ctx)
  end
  theme.pop_tab_padding()
  ImGui.PopStyleVar(ctx)               -- TabBarBorderSize, pushed first
  ImGui.Unindent(ctx, theme.TAB_INSET)

  ImGui.Spacing(ctx)
  action_bar(FS)
  ImGui.Spacing(ctx)

  -- SameLine inserts ItemSpacing.x between the two panels, so THAT -- not FS --
  -- is what the right-hand one has to give up. Subtracting FS left the tester
  -- (FS - ItemSpacing.x) too narrow, so its right border sat inside the table's
  -- above it, and the error grew with the text size.
  local spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
  local leftw = math.floor(availw * 0.58)
  preview.draw_list(FS, leftw, bottom)
  ImGui.SameLine(ctx)
  preview.draw_tester(FS, availw - leftw - spacing, bottom)

  status_line(statusy)

  if dimmed then theme.pop_content_dim() end
end

return M
