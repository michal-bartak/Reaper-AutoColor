---
title: The configuration window
description: Tabs, the rule row, the action bar, and the preview panes
---

`MXM_AutoColor_GUI.lua` opens AutoColor's configuration window. It holds the rules, a preview of
what they currently hit, and the buttons that write the colours into the project.

<figure class="shot">

![The configuration window](../../../assets/usage/window-overview.png)

<figcaption>The configuration window</figcaption>
</figure>

Every edit is saved to the [rules file](/Reaper-AutoColor/configuration/rules-file/) immediately;
there is no Save button. **Undo**, or `Cmd`/`Ctrl`+`Z` while the window has focus, steps back
through changes to the **rules**. Colour changes in the project use REAPER's own undo.

## One tab per object kind

<figure class="shot">

![The four tabs](../../../assets/usage/tabs.png)

<figcaption>Tracks, Items, Regions and Markers, with their rule counts</figcaption>
</figure>

Each tab holds its own ordered list. Within a tab, **the first rule that matches wins**, so
reordering changes precedence, like firewall rules.

Precedence is **per tab**: reordering track rules cannot change which region wins. Each tab offers
only the controls that apply to it — the folder filters exist on Tracks and nowhere else.

## The rule row

<figure class="shot">

![A rule row](../../../assets/usage/rule-row.png)

<figcaption>One rule, left to right</figcaption>
</figure>

| Column | What it is |
|---|---|
| handle | Drag to reorder. Click to highlight the rule — the target Objects preview jumps to when a rule name is clicked there. |
| on/off | Switches the rule off without deleting it. A tab whose rules are all off says so. |
| **Name** | A label for the rule, shown only in this window. |
| **Match** | `contains`, `glob` or `regex` — see [Matching names](/Reaper-AutoColor/usage/matching/). |
| **Pattern** | What to match. Empty matches on the filter alone. |
| **Aa** | Ignore case (ASCII only). |
| **Filter** | An extra condition on top of the pattern — see [Filters](/Reaper-AutoColor/usage/matching/#filters). |
| **Colour** | The rule's colour, and optionally a [second one](/Reaper-AutoColor/usage/colours/#gradients) for a gradient. |
| **Items** | Tracks tab only: [write the track's colour onto the items](/Reaper-AutoColor/usage/colours/#items) on the tracks this rule matches, instead of leaving REAPER to draw them from the track. |
| **Hits** | How many objects this rule wins in this project. |
| menu | Duplicate, Delete, and Move to top / up / down / bottom. |

:::tip[Hits reads 0 but objects are still coloured]
**Hits** counts what the rule *wins*, not what its pattern matches. An earlier rule that claimed
the same objects leaves this one on 0. Move it up to give it precedence.
:::

## The preview panes

<figure class="shot">

![Objects preview and Pattern tester](../../../assets/usage/preview.png)

<figcaption>Objects preview and Pattern tester</figcaption>
</figure>

**Objects preview** lists what the rules on the open tab claim in *this* project. It is resolved by
the same code Apply runs, so it is not an approximation. Each row carries the colour the object will
get, its name, and the rule responsible:

| The Rule column says | Meaning |
|---|---|
| a rule's name | That rule won it. Click to highlight it in the table. A trailing `~` marks a gradient. |
| `from track: …` | No item rule matched, so the item takes its track's colour. That track's rule has *also colour items* on. |
| `from folder` | No rule of its own; inherited from the folder parent. |

The list follows the open tab. Clicking a **name** reveals that object in the project.

**Pattern tester** is a scratch pad with its own mode, pattern and subject. It reports whether the
pattern matches, which part of the name it matched, and what each group captured.

:::tip[Independent of the rule list]
Deliberately so. Nothing typed here is saved, and nothing it does reaches the project.
:::

## The action bar

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>The action bar, below the rule table</figcaption>
</figure>

| Button | What it does |
|---|---|
| **+ *kind* rule** | Adds a rule to the open tab. |
| **Undo** | Steps back through changes to the rules. |
| **Apply now** | Colours the whole project, in one undo point. See [Applying colours](/Reaper-AutoColor/usage/applying/). |
| **Selection** | Colours the selection only. |
| **Clear…** | Three clearing scopes — see [Clearing colours](/Reaper-AutoColor/usage/clearing/). |
| **Auto: off / on / paused** | The state of the background loop, and a Pause button once it runs. See [Auto-apply](/Reaper-AutoColor/usage/auto-apply/). |
| **Options** | Folders, scope, the background loop's timing, text size, rules file. See [Options](/Reaper-AutoColor/configuration/). |
| **ⓘ** | About: the installed version, links to the source and these docs, the author, and the licence. |

The foot of the window keeps one line for status messages: what an Apply coloured, why a clear did
nothing, whether a save failed. The line is permanent, to keep the layout from jumping.

## Banners

Two conditions appear at the top of the window rather than in passing:

- **SWS Auto Color is enabled.** Both are live colour engines and they will fight. Switch one off;
  see [Troubleshooting](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).
- **This rule file was written by a newer version.** Editing is allowed but nothing is saved, to
  prevent an older build from destroying a config it does not understand.

## Where to go next

- [Matching names](/Reaper-AutoColor/usage/matching/) — the three modes, the supported regex, the filters.
- [Colours and gradients](/Reaper-AutoColor/usage/colours/) — one colour, two colours, and what a ramp spreads across.
- [Applying colours](/Reaper-AutoColor/usage/applying/) — Apply now, Selection, and the actions that do the same without the window.
