---
title: Auto-apply
description: The background loop, what it leaves alone, and what it costs
---

`MXM_AutoColor_AutoToggle.lua` starts a background loop that applies the rules whenever objects are added or renamed. Running the action again stops it. The toolbar button lights while it runs.

## What it will not do

- **It never reverts a colour or icon set by hand.** The loop leaves it alone until the object is renamed.
- It adds **no undo points**, to keep a rename from shredding the undo history. *Undo points for automatic changes* in [Options](/Reaper-AutoColor/configuration/) enables them.
- It pauses **while recording**, record-pause included.
- Tracks are updated immediately. Items, regions and markers follow once the project has settled.

:::tip[Taking an object back]
**Apply now**, from the window or `MXM_AutoColor_ApplyAll.lua`, returns every object to the rules.
:::

## Starting and stopping

The **Auto** button on the action bar shows the loop's state — `Auto: off`, `Auto: on`, or `Auto: paused`. Once the `AutoToggle` action has run in the current REAPER session, the button also starts and stops the loop. Before that it only shows the state.

Opening the configuration window does **not** stop or pause the loop.

## Starting with REAPER

*Autostart* in [Options](/Reaper-AutoColor/configuration/) decides whether the loop starts at launch: **Never**, **Always**, or **Last** (default), which restores the state REAPER was closed in. The window and the `AutoToggle` action add a marked entry to `Scripts/__startup.lua` when it is missing, and that entry runs `MXM_AutoColor_Startup.lua`.

:::note[Uninstalling]
The entry in `Scripts/__startup.lua` does nothing once the scripts are gone. To remove it, delete the lines between `-- MXM_AutoColor BEGIN` and `-- MXM_AutoColor END`.
:::

## What it re-reads, and when

REAPER reports every project change the same way, a fader move like a rename, so the loop limits what it re-reads:

| | When it is re-read |
|---|---|
| **Tracks** | At the next check after any change. |
| **Items, regions and markers** | Once the project has settled, and only when one appeared or vanished, a track changed, or **Item/marker rescan (s)** has elapsed. |

**Item/marker rescan (s)**, 5 s by default, is the delay before an item, region or marker **renamed in place** is recoloured. `0` re-reads them on every change, which is slow on a large project.

`Check frequency (s)` in [Options](/Reaper-AutoColor/configuration/) sets how often the project is checked, and so the delay before a track rename is picked up. `Work budget (ms)` limits how long one check may spend on items, regions and markers before yielding.

:::caution[Gradients on items]
Moving one object in a gradient recolours its whole range. A gradient rule on **items** can be slow on very large projects.
:::

## Debug output

ExtState `MXM_AutoColor` / `auto_debug` set to `1` produces a console readout of what the loop is doing and why.

## Where to go next

- [Options](/Reaper-AutoColor/configuration/) — the timing settings and undo behaviour.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — when a colour disagrees with the rules.
