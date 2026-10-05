---
title: Applying colours
description: Apply now, Selection, and the actions that do the same without the window
---

Rules decide colours; applying writes them into the project — with **Apply now**, or, with the [background loop](/Reaper-AutoColor/usage/auto-apply/) on, whenever objects are added or renamed.

Objects already in the colour the rules give them are not rewritten.

:::note
By default an apply never removes a colour: an object no rule claims keeps the colour it had, so an old item colour can survive every apply.

To remove colours, use [Clear](/Reaper-AutoColor/usage/clearing/), or turn on [reset unmatched objects](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects) for that object type.
:::

## From the window

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>Apply now and Selection, on the action bar</figcaption>
</figure>

**Apply now** colours the whole project — every track, item, region and marker — and sets track icons, in **one undo point**. It also returns objects coloured by hand, which the background loop leaves alone, to the rules.

**Selection** colours the selection only. With a track **and** some items selected, the last one clicked wins — the same rule REAPER uses for its own "depending on focus" actions. The status line reports which it took.

- With **items** in focus, tracks are left unchanged.
- With **tracks** in focus, items are left unchanged.
- **Selected regions and markers are always included**, whichever way the focus went.

## From the Action List

The same two operations exist as standalone actions, for a shortcut or a toolbar button:

| Action | Scope |
|---|---|
| `MXM_AutoColor_ApplyAll.lua` | The whole project. One undo point. Returns hand-coloured objects to the rules, like **Apply now**. |
| `MXM_AutoColor_ApplySelection.lua` | The selected **tracks and items**. |

:::note[The action and the button are not quite the same]
`MXM_AutoColor_ApplySelection.lua` never touches regions or markers, while the window's **Selection** button includes any that are selected.
:::

## When a rule change reaches the project

Editing a rule does **not** recolour the project. **Apply now** applies the edit immediately. With the background loop on, the edit is applied with the next change to the project, such as a track added or renamed, to the whole project at once.

## Where to go next

- [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) — keeping the project coloured without pressing anything.
- [Clearing colours](/Reaper-AutoColor/usage/clearing/) — the other direction.
