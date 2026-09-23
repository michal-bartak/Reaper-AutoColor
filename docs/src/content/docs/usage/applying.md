---
title: Applying colours
description: Apply now, Selection, and the actions that do the same without the window
---

Rules decide colours; applying writes them into the project. Nothing in the rule table reaches the
tracks until an apply runs, or the [background loop](/Reaper-AutoColor/usage/auto-apply/) does.

Objects already holding the colour the rules want are **not rewritten**, so a second apply costs
nothing and changes nothing.

:::note
An apply writes colours and, by default, never removes one: an object no rule claims keeps whatever
colour it had, so an old item colour can survive every apply.

Removing a colour is [Clear](/Reaper-AutoColor/usage/clearing/), or
[reset unmatched objects](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects) for that kind,
which makes every apply strip the colour from anything the rules do not claim.
:::

## From the window

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>Apply now and Selection, on the action bar</figcaption>
</figure>

**Apply now** colours the whole project — every track, item, region and marker — and sets track
icons, in **one undo point**. It also clears the marks the background loop holds on hand-recoloured objects, returning
them to the rules. That is its purpose after hand-colouring something.

**Selection** colours the selection only. With a track **and** some items selected, the last one
clicked wins — the same rule REAPER uses for its own "depending on focus" actions. The status line
reports which it took.

- With **items** in focus, tracks are still read, since folder inheritance and the track → item
  cascade need them, but none are written.
- With **tracks** in focus, items are left out entirely.
- **Selected regions and markers are always included**, whichever way the focus went. There is no
  focus value to weigh them against.

## From the Action List

The same two operations exist as standalone actions, for a key or a toolbar without opening the
window:

| Action | Scope |
|---|---|
| `MXM_AutoColor_ApplyAll.lua` | The whole project. One undo point. Drops the hand-colour marks, like **Apply now**. |
| `MXM_AutoColor_ApplySelection.lua` | The selected **tracks and items**. |

:::note[The action and the button are not quite the same]
`MXM_AutoColor_ApplySelection.lua` never touches regions or markers, while the window's
**Selection** button includes any that are selected. The action has no window to report the
difference in, so it takes the narrower, more predictable scope.
:::

## When a rule change reaches the project

Editing a rule does **not** repaint the project, nor does anything else done in the window
afterwards. With the background loop running, the edit waits until an object actually changes, then
applies to everything at once, so the project is never half on the old rules.

**Apply now** commits an edit immediately.

## Where to go next

- [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) — keeping the project in step without pressing anything.
- [Clearing colours](/Reaper-AutoColor/usage/clearing/) — the other direction.
