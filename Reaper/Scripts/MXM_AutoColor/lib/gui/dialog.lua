--[[
  gui/dialog.lua -- the one way this window opens a dialog.

  Options, About and the icon browser are ordinary top-level WINDOWS, drawn
  after the main window has ended, with a title bar and a close button, movable,
  and centred on the main window each time they open.

  Not a MODAL: its dim overlay cannot be controlled. ImGui paints
  Col_ModalWindowDimBg during Render(), long after any PushStyleColor has been
  popped, so it always uses the style default -- in the dark style
  (0.8, 0.8, 0.8, 0.35), i.e. WHITE, and the window appeared to BRIGHTEN. The
  dim is drawn by hand instead (theme.push_content_dim). A modal was swallowing
  Escape too.

  Not a POPUP either, though Options was one for a long time. ImGui owns a
  popup's visibility and closes it on a click outside, on Escape, and on losing
  focus -- so the dialog vanished across an alt-tab. Re-opening it every frame
  fixed that but not the flicker it caused: on the first click elsewhere in
  REAPER the popup is closed and re-opened, and it is not drawn again for
  several frames, inside ImGui where a script cannot reach. An ordinary window
  is never closed behind our back.

  What the popup gave away free and a window has to ask for:
    * TopMost, or the dimmed main window could be raised ABOVE the dialog;
    * theme.push_content_dim's BeginDisabled, or the faded content behind would
      still take clicks;
    * Escape -- M.dismissed.
]]

local theme = require 'gui.theme'

local M = {}

local ImGui, ctx
function M.init(imgui, context) ImGui, ctx = imgui, context end

--- Begin a dialog.
--- @param o { x, y = centre to open at; w = width; h = height, or nil to fit
---            the content on every frame; resizable = bool; min_w, min_h }
--- @return visible, open   End() only when visible; open is false once the
---         title bar's close button was pressed
function M.begin(FS, title, o)
  ImGui.SetNextWindowPos(ctx, o.x, o.y, ImGui.Cond_Appearing, 0.5, 0.5)
  if o.h then
    ImGui.SetNextWindowSize(ctx, o.w, o.h, ImGui.Cond_Appearing)
  else
    -- 0 on an axis means auto-fit. Every frame, so the height follows the
    -- content; the width is fixed so wrapped text has something to wrap to.
    ImGui.SetNextWindowSize(ctx, o.w, 0, ImGui.Cond_Always)
  end
  if o.min_w then
    ImGui.SetNextWindowSizeConstraints(ctx, o.min_w, o.min_h or 0, FS * 400, FS * 400)
  end

  local flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoDocking
              | ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_TopMost
  if not o.resizable then flags = flags | ImGui.WindowFlags_NoResize end

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,
                     FS * theme.MODAL_PAD, FS * theme.MODAL_PAD)
  local visible, open = ImGui.Begin(ctx, title, true, flags)
  ImGui.PopStyleVar(ctx)      -- window style is read at Begin
  return visible, open
end

--- Escape. Call inside the dialog. Suspended while any popup is open:
--- Escape belongs to a dropdown while it is up, or both would go on one
--- keystroke.
---
--- A click on the main window behind does NOT close a dialog. The main window
--- is dimmed and blocked anyway, and a stray click cost the dialog's state --
--- the icon browser's search and mark.
function M.dismissed()
  if ImGui.IsPopupOpen(ctx, '', ImGui.PopupFlags_AnyPopupId
                                | ImGui.PopupFlags_AnyPopupLevel) then
    return false
  end
  return ImGui.IsKeyPressed(ctx, ImGui.Key_Escape)
end

return M
