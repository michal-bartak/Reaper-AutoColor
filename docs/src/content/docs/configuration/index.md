---
title: Options
description: Everything in the Options dialog, and what each setting costs
---

Everything that is not a rule lives in **Options**, at the right-hand end of the action bar. The
settings are global: one rule set, one set of options, shared by every project.

<figure class="shot">

![The Options dialog](../../../assets/configuration/options.png)

<figcaption>Options</figcaption>
</figure>

## Folders

How a folder's colour reaches its children. See
[Folder colours](/Reaper-AutoColor/usage/colours/#folders).

| Setting | Meaning |
|---|---|
| **fill gaps** *(default)* | Children with no rule of their own inherit. |
| **force** | The folder colour overrides its children. |
| **off** | Folders do not colour their children. |

**Subfolder splits the parent's colour range**, on by default. It affects only rules that
[spread a gradient across **folders**](/Reaper-AutoColor/usage/colours/#gradients). A nested folder
ends the range around it, so the tracks after it start the ramp again instead of resuming it. A
folder at the top level does the same to the tracks around it. Off gives one ramp per folder,
however deep the nesting. Take care in a folder made mostly of subfolders: a range of one track
shows the first colour only.

## Scope

**Reset to the default colour when no rule matches**, one checkbox per kind — Tracks, Items, Regions,
Markers. Off everywhere by default. See
[Reset unmatched objects](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects).

:::tip
Recommended for **items**, where it makes an item follow its track live. Careful on **tracks**,
where it also strips colours you set by hand.
:::

## Background auto-colouring

| Setting | Default | What it does |
|---|---|---|
| **Create undo points for automatic changes** | off | Adds an undo point per automatic recolour. Off because renaming a track would otherwise shred your undo history, and the rules can always re-derive the colours. |
| **Check every (s)** | 0.20 | How often the loop wakes. |
| **Work budget (ms)** | 4 | How long it may work before yielding back to REAPER. |
| **Rescan items at most every (s)** | 5 | The delay before an item *renamed in place* is noticed. `0` re-reads everything on every change. |

[Auto-apply](/Reaper-AutoColor/usage/auto-apply/) explains what the loop re-reads and why the rescan
interval exists.

## Window

**Text size**, 8 to 20. Every dimension in the window is a multiple of the font size, so this scales
the whole layout rather than just the labels.

The dialog stays **open** when you switch to another application and back, or click elsewhere in
REAPER. Close it with its **Close** button, `Escape`, or a click on the AutoColor window behind it.

## Rules file

Shows the path to [`config.json`](/Reaper-AutoColor/configuration/rules-file/), and two buttons that
replace the **whole** rule set, every tab rather than just the one you are looking at:

| Button | What it does |
|---|---|
| **Example rules** | The built-in set, as written on first run. |
| **Remove Rules** | Empties every tab. |

Both ask for confirmation, and **Undo** takes either one back while the window is open.

## Where to go next

- [Rules file](/Reaper-AutoColor/configuration/rules-file/) — what is stored, where, and what happens when it goes wrong.
- [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/) — two settings outside this tool that decide what you see.
