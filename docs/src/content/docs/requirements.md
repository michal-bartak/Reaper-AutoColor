---
title: Requirements
description: The REAPER version AutoColor needs, and the ReaImGui extension for the configuration window
---

| Software | Required version | Needed for |
|---|---|---|
| REAPER | **7.03 or later** | Everything. Tested with REAPER 7.80 on macOS (Apple silicon) and Windows 10. |
| ReaImGui | **0.10 or later** | The configuration window only. |

## ReaImGui

ReaImGui is a REAPER extension that draws the AutoColor configuration window. Without it, the window does not open and AutoColor shows a message saying that ReaImGui is missing. The actions that apply or clear colours, and auto-apply, work without ReaImGui.

To install ReaImGui:

1. Open *Extensions → ReaPack → Browse packages*.
1. Search for `ReaImGui`.
1. Right-click the package and choose **Install**, then apply the change.
1. Restart REAPER.

If an older ReaImGui is installed, AutoColor asks you to update it. Update it the same way, through ReaPack, and restart REAPER.

## REAPER versions before 7.62

REAPER versions before 7.62 do not let a script remove the colour from a marker or region, and do not report which markers and regions are selected. On those versions:

- Marker and region colours cannot be cleared back to the default colour. This affects the **Clear…** menu, the `MXM_AutoColor_ClearColors.lua` action and the option **Reset to the default colour when no rule matches**. `MXM_AutoColor_ClearColors.lua` reports how many regions and markers it skipped. Giving markers and regions a colour still works.
- **Selection** and **Clear selected objects** leave all markers and regions unchanged.

To use these features, update REAPER to 7.62 or later.

## Where to go next

- [Installation](/Reaper-AutoColor/installation/): installing through ReaPack, or copying the files by hand.
