---
title: The configuration window
description: Tabs, the rule row, the action bar, and the preview panes
---

`MXM_AutoColor_GUI.lua` opens AutoColor's configuration window. It holds the rules, a preview of what they currently match, and the buttons that apply them to the project.

<figure class="shot">

![The configuration window](../../../assets/usage/window-overview.png)

<figcaption>The configuration window</figcaption>
</figure>

Every edit is saved to the [config file](/Reaper-AutoColor/configuration/config-file/) immediately; there is no Save button. **Undo**, or `Cmd`/`Ctrl`+`Z` while the window has focus, steps back through changes to the **rules**. Colour changes in the project use REAPER's own undo.

## One tab per object type

<figure class="shot">

![The four tabs](../../../assets/usage/tabs.png)

<figcaption>Tracks, Items, Regions and Markers, with their rule counts</figcaption>
</figure>

Each tab holds its own ordered list. Within a tab, **the first rule that matches wins**, so reordering changes precedence. Rules on one tab never affect another.

Each tab offers only the filters that apply to its object type — the folder filters exist on Tracks and Icons only.

The **Icons** tab sets track icons rather than colours; see [Track icons](/Reaper-AutoColor/usage/icons/).

## The rule row

<figure class="shot">

![A rule row](../../../assets/usage/rule-row.png)

<figcaption>One rule, left to right</figcaption>
</figure>

| Column | What it is |
|---|---|
| handle | Drag to reorder. Click to highlight the rule; clicking a rule name in Objects preview does the same. |
| on/off | Switches the rule off without deleting it. A tab whose rules are all off says so. |
| **Name** | A label for the rule, shown only in this window. |
| **Match** | `contains`, `glob` or `regex` — see [Matching names](/Reaper-AutoColor/usage/matching/). |
| **Pattern** | What to match. Empty matches on the filter alone. |
| **Aa** | Ignore case (ASCII only). |
| **Filter** | An extra condition on top of the pattern — see [Filters](/Reaper-AutoColor/usage/matching/#filters). |
| **Colour** | The rule's colour, and optionally a [second one](/Reaper-AutoColor/usage/colours/#gradients) for a gradient. |
| **Items** | Tracks tab only. Instead of leaving the items' default colour (always inheriting from the track), [write the track's colour onto the items](/Reaper-AutoColor/usage/colours/#items) of the tracks this rule matches. |
| **Hits** | How many objects this rule wins in this project. |
| [...] | Menu button; Duplicate, Delete, and Move to top / up / down / bottom. |

:::tip[Hits reads 0 but objects are still coloured]
**Hits** counts what the rule *wins*, not what its pattern matches. An earlier rule that claimed the same objects leaves this one on 0. Move it up to give it precedence.
:::

## The preview panes

<figure class="shot">

![Objects preview and Pattern tester](../../../assets/usage/preview.png)

<figcaption>Objects preview and Pattern tester</figcaption>
</figure>

**Objects preview** lists what the rules on the open tab claim in *this* project — exactly what an apply would do. Each row carries the colour the object will get, its name, and the rule responsible:

| The Rule column says | Meaning |
|---|---|
| a rule's name | That rule won it. Click to highlight it in the table. A trailing `~` marks a gradient. |
| `from track: …` | No item rule matched, so the item takes its track's colour. That track's rule has *also colour items* on. |
| `from folder` | No rule of its own; inherited from the folder parent. |

Clicking a **name** reveals that object in the project.

**Pattern tester** tests a pattern against a name, with its own mode, pattern and subject. It shows whether the pattern matches, which part of the name it matched, and what each group captured. Nothing typed there is saved or applied.

## The action bar

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>The action bar, below the rule table</figcaption>
</figure>

| Button | What it does |
|---|---|
| **+ *type* rule** | Adds a rule to the open tab. |
| **Undo** | Steps back through changes to the rules. |
| **Apply now** | Colours the whole project, in one undo point. See [Applying colours](/Reaper-AutoColor/usage/applying/). |
| **Selection** | Colours the selection only. |
| **Clear…** | Three clearing scopes — see [Clearing colours](/Reaper-AutoColor/usage/clearing/). |
| **Auto: off / on / paused** | The state of the background loop, and a Pause button once it runs. See [Auto-apply](/Reaper-AutoColor/usage/auto-apply/). |
| **Options** | Folders, scope, the background loop's timing, text size, config file. See [Options](/Reaper-AutoColor/configuration/). |
| **ⓘ** | About: the installed version, links to the source and these docs, the author, and the licence. |

The bottom line of the window shows status messages: what an apply coloured, why a clear did nothing, whether a save failed.

## Warnings

- **SWS Auto Color (or Auto Icon) is enabled**, shown on each tab whose object type SWS also colours, while that tab has rules. Switch one of them off — see [Troubleshooting](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).
- **This config file was written by a newer version**, at the top of the window. Editing is allowed but nothing is saved, to prevent an older version from overwriting a config it does not understand.

## Where to go next

- [Matching names](/Reaper-AutoColor/usage/matching/) — the three modes, the supported regex, the filters.
- [Colours and gradients](/Reaper-AutoColor/usage/colours/) — one colour, two colours, and what a ramp spreads across.
- [Track icons](/Reaper-AutoColor/usage/icons/) — the Icons tab and the icon browser.
- [Applying colours](/Reaper-AutoColor/usage/applying/) — Apply now, Selection, and the actions that do the same without the window.
