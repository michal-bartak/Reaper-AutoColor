--[[
  gui/icon_browser.lua -- picking a track icon, and drawing icon thumbnails.

  A dialog window (see dialog.lua), and the one that resizes: a bigger window
  shows more of the grid.

  Images are loaded lazily, only for cells on screen, and held attached to the
  context in a bounded cache: an unattached image dies after one frame
  unused, which would reload every icon scrolled back into view, and an
  unbounded one would hold every file of a large icon folder.
]]

local icons = require 'icons'
local app   = require 'gui.app'
local theme = require 'gui.theme'
local dialog = require 'gui.dialog'

local M = {}

local ImGui, ctx
function M.init(imgui, context) ImGui, ctx = imgui, context end

local function rgba(rgb, a) return ((rgb & 0xFFFFFF) << 8) | (a or 0xFF) end
local COL_DIM = 0x9A9A9A

----------------------------------------------------------------- the cache
local CACHE_MAX      = 256
local LOADS_PER_FRAME = 24     -- decoding is the cost; spread a first view out

local cache, ncache = {}, 0    -- abs path -> { img = image|false, used = frame }
local frame_no, loads = 0, 0

--- Call once per frame, before anything asks for an image.
function M.new_frame()
  frame_no, loads = frame_no + 1, 0
end

local function evict()
  local old = {}
  for k, c in pairs(cache) do
    if c.used < frame_no then old[#old + 1] = { k = k, used = c.used } end
  end
  table.sort(old, function(a, b) return a.used < b.used end)
  for i = 1, #old do
    if ncache <= CACHE_MAX * 0.75 then break end
    local c = cache[old[i].k]
    if c.img then ImGui.Detach(ctx, c.img) end
    cache[old[i].k] = nil
    ncache = ncache - 1
  end
end

--- The image for a resolved path, or nil while it is still to be loaded or
--- when it cannot be. A failure is remembered, so it is not retried each frame.
function M.image(abs)
  if abs == nil or abs == '' then return nil end
  local c = cache[abs]
  if c then c.used = frame_no; return c.img or nil end
  if loads >= LOADS_PER_FRAME then return nil end
  loads = loads + 1
  local img = ImGui.CreateImage(abs, ImGui.ImageFlags_NoErrors)
  if img then ImGui.Attach(ctx, img) end
  cache[abs] = { img = img or false, used = frame_no }
  ncache = ncache + 1
  if ncache > CACHE_MAX then evict() end
  return img
end

--- Draw an image fitted into a square, keeping its aspect ratio.
local function draw_fit(dl, img, x, y, size)
  local w, h = ImGui.Image_GetSize(img)
  if not w or w <= 0 or h <= 0 then return end
  local s = math.min(size / w, size / h)
  local dw, dh = w * s, h * s
  local ox, oy = x + (size - dw) * 0.5, y + (size - dh) * 0.5
  ImGui.DrawList_AddImage(dl, img, ox, oy, ox + dw, oy + dh)
end

--- A clickable square showing a rule's icon, for the rule table.
--- @return true when clicked
function M.thumb(id, stored, size)
  local x, y = ImGui.GetCursorScreenPos(ctx)
  local clicked = ImGui.InvisibleButton(ctx, id, size, size)
  local dl = ImGui.GetWindowDrawList(ctx)
  local bg = ImGui.IsItemHovered(ctx) and ImGui.Col_FrameBgHovered or ImGui.Col_FrameBg
  ImGui.DrawList_AddRectFilled(dl, x, y, x + size, y + size,
                               ImGui.GetColor(ctx, bg), size * theme.ROUNDING * 0.5)
  local img = M.image(icons.resolve(stored))
  if img then
    local pad = math.floor(size * 0.1)
    draw_fit(dl, img, x + pad, y + pad, size - 2 * pad)
  end
  return clicked
end

--------------------------------------------------------------- the window
local index = nil              -- icons.list(), built on first open
local clipper = nil

--- Shorten `s` with an ellipsis until it fits `w`.
local function fit_text(s, w)
  if ImGui.CalcTextSize(ctx, s) <= w then return s end
  local ell = '\u{2026}'
  while #s > 1 do
    s = s:sub(1, -2)
    if ImGui.CalcTextSize(ctx, s .. ell) <= w then return s .. ell end
  end
  return ell
end

local function filtered(b)
  if b.cache_q == b.query and b.cache_index == index then return b.items end
  local q = b.query:lower()
  local items = {}
  if q == '' then items[1] = { none = true } end
  for _, it in ipairs(index) do
    if q == '' or it.key:find(q, 1, true) then items[#items + 1] = it end
  end
  b.items, b.cache_q, b.cache_index = items, b.query, index
  return items
end

function M.open(rule)
  if not index then index = icons.list(false) end
  app.st.icon_browser = { id = rule.id, mark = rule.icon, query = '', appearing = true }
end

function M.is_open() return app.st.icon_browser ~= nil end

local function close() app.st.icon_browser = nil end

local function choose(stored)
  local b = app.st.icon_browser
  local r = b and app.rule_by_id(b.id)
  if r and r.icon ~= stored then
    app.snapshot(); r.icon = stored; app.mark_dirty()
  end
  close()
end

--- One grid cell. Clicking marks it, double-clicking chooses it.
local function cell(b, it, k, cw, ch, isz)
  ImGui.PushID(ctx, k)
  local x, y = ImGui.GetCursorScreenPos(ctx)
  if ImGui.InvisibleButton(ctx, '##cell', cw, ch) then
    b.mark = it.none and '' or it.rel
  end
  local hot = ImGui.IsItemHovered(ctx)
  if hot and ImGui.IsMouseDoubleClicked(ctx, 0) then
    b.mark = it.none and '' or it.rel
    b.chosen = true
  end
  if hot and not it.none then ImGui.SetItemTooltip(ctx, it.rel) end

  local dl = ImGui.GetWindowDrawList(ctx)
  local marked = (it.none and b.mark == '') or (not it.none and it.rel == b.mark)
  if marked or hot then
    ImGui.DrawList_AddRectFilled(dl, x, y, x + cw, y + ch,
      ImGui.GetColor(ctx, marked and ImGui.Col_Header or ImGui.Col_HeaderHovered),
      ImGui.GetFontSize(ctx) * theme.ROUNDING)
  end

  local pad = (cw - isz) * 0.5
  local ix, iy = x + pad, y + pad * 0.6
  if it.none then
    ImGui.DrawList_AddRect(dl, ix + isz * 0.1, iy + isz * 0.1, ix + isz * 0.9, iy + isz * 0.9,
                           ImGui.GetColor(ctx, ImGui.Col_Border), 0, 0, 1)
  else
    local img = M.image(it.abs)
    if img then draw_fit(dl, img, ix, iy, isz) end
  end

  local label = fit_text(it.none and 'None' or it.name, cw - 4)
  local tw = ImGui.CalcTextSize(ctx, label)
  ImGui.DrawList_AddText(dl, x + (cw - tw) * 0.5, iy + isz + pad * 0.4,
                         ImGui.GetColor(ctx, ImGui.Col_Text), label)
  ImGui.PopID(ctx)
end

--- @param mx, my, mw, mh  the main window's rect, to centre on when opening
function M.draw(FS, mx, my, mw, mh)
  local st = app.st
  local b = st.icon_browser
  if not b then return end

  -- The file dialog runs with the window gone for a frame: a TopMost window
  -- could otherwise sit on top of it.
  if b.browsing == 'now' then
    b.browsing = nil
    -- No default extension: it would narrow the dialog to one type, and REAPER
    -- takes JPEG as well as PNG.
    local ok, path = reaper.GetUserFileNameForRead(icons.dir() .. package.config:sub(1, 1),
                                                   'Track icon', '')
    if ok and path ~= '' then choose(icons.to_stored(path)) end
    return
  elseif b.browsing then
    b.browsing = 'now'
    return
  end

  local r = app.rule_by_id(b.id)
  local what = r and (r.label ~= '' and r.label or r.pattern) or ''
  local visible, open = dialog.begin(FS,
    (what ~= '' and ('Icon for "' .. what .. '"') or 'Icon') .. '###mxm_iconbrowser', {
      x = mx + mw * 0.5, y = my + mh * 0.5, w = FS * 45, h = FS * 34,
      resizable = true, min_w = FS * 24, min_h = FS * 16 })

  if not r then close() end               -- its rule was deleted or undone away
  if not visible then
    if open == false then close() end
    return
  end

  local availw = ImGui.GetContentRegionAvail(ctx)
  local items = filtered(b)

  -------------------------------------------------------------- search row
  local bw = FS * 6
  local count = string.format('%d of %d', #items - (b.query == '' and 1 or 0), #index)
  local cw_count = ImGui.CalcTextSize(ctx, count)
  local sp = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
  ImGui.SetNextItemWidth(ctx, availw - cw_count - 2 * bw - 3 * sp)
  if b.appearing then ImGui.SetKeyboardFocusHere(ctx) end
  local rvq, q = ImGui.InputTextWithHint(ctx, '##iconq', 'search file names', b.query)
  if rvq then b.query = q; items = filtered(b) end
  ImGui.SameLine(ctx)
  ImGui.TextColored(ctx, rgba(COL_DIM), count)
  ImGui.SameLine(ctx)
  if theme.button('Browse...', bw) then b.browsing = true end
  ImGui.SetItemTooltip(ctx, 'Pick an image file anywhere on disk.')
  ImGui.SameLine(ctx)
  if theme.button('Refresh', bw) then index = icons.list(true); items = filtered(b) end
  ImGui.SetItemTooltip(ctx, 'Read ' .. icons.dir() .. ' again.')

  -------------------------------------------------------------------- grid
  local footh = ImGui.GetFrameHeightWithSpacing(ctx) + sp
  if ImGui.BeginChild(ctx, '##icongrid', 0, -footh, ImGui.ChildFlags_Borders) then
    local gw = ImGui.GetContentRegionAvail(ctx)
    local isz = math.floor(FS * 4)
    local cw  = math.floor(FS * 6)
    local ch  = isz + ImGui.GetTextLineHeight(ctx) + math.floor((cw - isz) * 1.1)
    local cols = math.max(1, math.floor((gw + sp) / (cw + sp)))
    local rows = math.ceil(#items / cols)
    local _, spy = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)

    if b.appearing then
      for k, it in ipairs(items) do
        if (it.none and b.mark == '') or it.rel == b.mark then
          ImGui.SetScrollY(ctx, math.floor((k - 1) / cols) * (ch + spy))
          break
        end
      end
    end

    if not (clipper and ImGui.ValidatePtr(clipper, 'ImGui_ListClipper*')) then
      clipper = ImGui.CreateListClipper(ctx)
    end
    ImGui.ListClipper_Begin(clipper, rows, ch + spy)
    while ImGui.ListClipper_Step(clipper) do
      local s, e = ImGui.ListClipper_GetDisplayRange(clipper)
      for row = s, e - 1 do
        for c = 0, cols - 1 do
          local k = row * cols + c + 1
          local it = items[k]
          if not it then break end
          if c > 0 then ImGui.SameLine(ctx, 0, sp) end
          cell(b, it, k, cw, ch, isz)
        end
      end
    end
    ImGui.ListClipper_End(clipper)

    if #index == 0 then
      ImGui.TextColored(ctx, rgba(COL_DIM), 'No icons in ' .. icons.dir())
    end
    ImGui.EndChild(ctx)
  end

  ------------------------------------------------------------------ footer
  ImGui.Spacing(ctx)
  local startx = ImGui.GetCursorPosX(ctx)
  if theme.button('Cancel', bw) then close() end
  ImGui.SameLine(ctx, startx + availw - bw)
  if theme.button('Select', bw) then b.chosen = true end

  if dialog.dismissed() then close() end
  if not ImGui.IsPopupOpen(ctx, '', ImGui.PopupFlags_AnyPopupId | ImGui.PopupFlags_AnyPopupLevel)
     and (ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter)) then
    b.chosen = true
  end

  b.appearing = false
  ImGui.End(ctx)

  if b.chosen and st.icon_browser == b then choose(b.mark) end
  if open == false then close() end
end

return M
