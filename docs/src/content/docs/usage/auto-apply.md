---
title: Auto-apply
description: The background loop, what it refuses to touch, and what it costs
---

`MXM_AutoColor_AutoToggle.lua` starts a background loop that keeps the project in step with
renames. Running the action again stops it. The toolbar button lights while it runs.

## What it will not do

- **It never reverts a hand-set colour or icon.** Once an object's colour stops matching what the
  tool last wrote, its name unchanged, the loop leaves that colour alone until the next rename. A
  track icon is tracked the same way, separately.
- It adds **no undo points**, to keep a rename from shredding the undo history. *Create undo points
  for automatic changes* in [Options](/Reaper-AutoColor/configuration/) enables them.
- It writes nothing when nothing changed, and pauses entirely **while recording**, record-pause
  included.
- It sweeps tracks immediately. Items and regions follow once the project has settled, in
  time-budgeted chunks.

:::tip[Taking an object back]
**Apply now**, from the window or `MXM_AutoColor_ApplyAll.lua`, drops those hand-colour marks and
returns every object to the rules.
:::

## Starting and stopping

The **Auto** button on the action bar shows the loop's state — `Auto: off`, `Auto: on`, or
`Auto: paused`. Once the loop has run at least once in the REAPER session, the button also starts and stops it.
Before that it can only report: REAPER must run the action once for the script to learn its command
ID.

Opening the configuration window does **not** stop or pause the loop. The window reports status and
offers its own **Pause**; only the `AutoToggle` action starts and stops the loop.

## What it re-reads, and when

REAPER reports a single project-wide "something changed" counter, so a fader move arrives looking
exactly like a rename. The loop works around that rather than re-reading everything:

| | When it is re-read |
|---|---|
| **Tracks** | On every change, because a rename is visible only by reading names. Re-planned only when what it read differs. |
| **Items and regions** | Only when something says they need it: one appeared or vanished, a track changed, or **Rescan items at most every (s)** has elapsed. |

The rescan interval is 5 s by default. The only thing waiting on it is an item **renamed in place**,
which nothing cheaper can detect. 0 re-reads everything on every change: correct, and slow on a
large project.

`Check every (s)` and `Work budget (ms)` in [Options](/Reaper-AutoColor/configuration/) control how
often the loop wakes and how long it may work before yielding.

:::caution[Gradients on items]
A gradient cannot be computed incrementally: moving one member re-plans the whole range. A gradient
rule aimed at **items** is the one case that becomes expensive on very large projects.
:::

## Debug output

ExtState `MXM_AutoColor` / `auto_debug` set to `1` produces a console readout of what the loop is
doing and why.

## Where to go next

- [Options](/Reaper-AutoColor/configuration/) — the timing settings and undo behaviour.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — when a colour disagrees with the rules.
