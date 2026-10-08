---
title: The configuration window
description: The tabs, the rule list, the preview, the action bar and the warnings in the AutoColor window
---

The configuration window is where you create and edit AutoColor's rules. A rule tells AutoColor which colour, or which track icon, to give to tracks, items, regions or markers whose names match a pattern. On this page, *object* means any track, item, region or marker. The window also shows a preview of what the rules will do in the current project, and has the buttons that apply the rules to the project.

To open the window, run the action `MXM_AutoColor_GUI.lua`, or click its toolbar button. If the window does not open, see [Requirements](/Reaper-AutoColor/requirements/).

<figure class="shot">

![The configuration window](../../../assets/usage/window-overview.png)

<figcaption>The configuration window</figcaption>
</figure>

The window has four parts, from top to bottom:

- **The tabs**, one for each object type. Each tab holds the rule list for that object type.
- **The action bar**, with the buttons that add rules, apply them, clear colours, and open the options.
- **The preview panes**: *Objects preview* shows what the rules match in the current project, and *Pattern tester* lets you try out a pattern on a name.
- **The status line**, at the bottom, which shows the result of the last action.

## Saving and undo

There is no Save button. AutoColor saves every change to the rules automatically, shortly after you make it, to the [config file](/Reaper-AutoColor/configuration/config-file/). While a save is pending, `saving...` appears on the action bar.

The **Undo** button on the action bar reverts the last change to the rules. `Cmd`+`Z` on macOS, or `Ctrl`+`Z` on Windows and Linux, does the same while the window has focus. The undo history is kept only while the window is open.

Colours written into the project are not part of this undo history. To revert them, use REAPER's own Undo.

## One tab per object type

<figure class="shot">

![The four tabs](../../../assets/usage/tabs.png)

<figcaption>Tracks, Items, Regions and Markers, with their rule counts</figcaption>
</figure>

The window has five tabs: **Tracks**, **Items**, **Regions**, **Markers** and **Icons**. The first four set colours. The **Icons** tab sets track icons; see [Track icons](/Reaper-AutoColor/usage/icons/). When a tab has rules, the number of rules is shown in its label, for example `Tracks (12)`.

Each tab holds an ordered list of rules for its own object type. The first rule in the list that matches an object decides its colour or icon; see [Rules and matching](/Reaper-AutoColor/usage/matching/#rules-and-matching). Rules on one tab never affect objects of another type.

The tabs offer different [filters](/Reaper-AutoColor/usage/matching/#filters), because some filters only make sense for tracks. The Tracks and Icons tabs offer every filter. The Items, Regions and Markers tabs offer only *has no name*.

## The rule row

<figure class="shot">

![A rule row](../../../assets/usage/rule-row.png)

<figcaption>One rule, left to right</figcaption>
</figure>

Each row in the list is one rule. The columns, from left to right:

| Column | What it does |
|---|---|
| handle | Drag the handle up or down to move the rule. Click it to select the rule; the selected rule is highlighted. |
| on/off | Switches the rule off without deleting it. A rule that is switched off is skipped. When every rule on a tab is switched off, a note below the list says so. |
| **Name** | A label for the rule. The label is shown only in this window and does not affect matching. |
| **Match** | How the pattern is compared with the object's name: `contains`, `glob` or `regex`. See [Matching names](/Reaper-AutoColor/usage/matching/). |
| **Pattern** | The text or pattern to look for in the name. When the pattern is empty, the rule matches every object that meets its filter, or every object if it has no filter. An invalid pattern is shown in red; see [Invalid, unsupported and slow patterns](/Reaper-AutoColor/usage/matching/#invalid-unsupported-and-slow-patterns). |
| **Aa** | Ignore case. See [Upper and lower case](/Reaper-AutoColor/usage/matching/#upper-and-lower-case). |
| **Filter** | An extra condition the object must meet in addition to the pattern, such as *is a folder track*. See [Filters](/Reaper-AutoColor/usage/matching/#filters). |
| **Colour** | The colour the rule gives. A [second colour](/Reaper-AutoColor/usage/colours/#gradients) turns the rule into a gradient. |
| **Items** | Tracks tab only. Off by default. When on, the items on the tracks this rule matches also receive the track's colour. See [Items](/Reaper-AutoColor/usage/colours/#items). |
| **Hits** | How many objects this rule colours in the current project. See below. |
| ... | A menu with **Move up**, **Move down**, **Move to top**, **Move to bottom**, **Duplicate** and **Delete**. |

On the Icons tab, the **Icon** and **Children** columns replace **Colour** and **Items**; see [Track icons](/Reaper-AutoColor/usage/icons/).

**+ *type* rule** on the action bar adds a rule at the bottom of the open tab, for example **+ track rule** on the Tracks tab. A new rule has an empty pattern and no filter. Until you enter a pattern or choose a filter, the new rule matches every object on its tab that no earlier rule matches.

### The Hits column

The **Hits** column counts the objects that this rule colours, which means the objects for which this rule is the first match. An object that also matches a rule higher in the list is coloured by that higher rule, and is not counted here.

When other objects match this rule but a higher rule colours them, their number is shown after the count, for example `12  +3`. To let this rule colour those objects, move it above the other rule.

The column can also show:

- `err`: the pattern is invalid, and the rule is skipped.
- `!` before the count: the pattern took too long to test on some names.

Both are described in [Invalid, unsupported and slow patterns](/Reaper-AutoColor/usage/matching/#invalid-unsupported-and-slow-patterns).

:::tip[Hits shows 0, but the objects are still coloured]
An object can be coloured without any rule on its tab matching it. An item can take the colour of its track, when the track's rule has **Items** switched on. A track can take the colour of its folder track. Such objects appear in *Objects preview*, but they are not counted in **Hits**.
:::

### Notes below the list

Some notes appear below the rule list:

- A warning when SWS Auto Color, or SWS Auto Icon on the Icons tab, is switched on for this object type and the tab has rules. See [Warnings](#warnings).
- A note when every rule on the tab is switched off.
- Notes about the selected rule, when there is something to point out. For example, a rule with an empty pattern and no filter shows that it matches every object on its tab.

## The preview panes

<figure class="shot">

![Objects preview and Pattern tester](../../../assets/usage/preview.png)

<figcaption>Objects preview and Pattern tester</figcaption>
</figure>

### Objects preview

**Objects preview** lists the objects of the open tab's type that the rules will colour in the current project. The list shows exactly what applying the rules would do, before anything is applied. The heading says how many objects will be coloured out of how many there are. The list shows at most 500 objects.

Each row shows the colour the object will get, the object's name, and where the colour comes from:

| The Rule column shows | Meaning |
|---|---|
| a rule's name | That rule colours the object. If the rule has no name, its pattern is shown instead. A `~` after the name means the rule has two colours and gives each object a shade of a gradient. Click the rule's name to select the rule in the list above. |
| `from track: …` | The object is an item that no item rule matches. It takes the colour of its track, because the track's rule has **Items** switched on. |
| `from folder` | No rule matches the track. It takes the colour of its folder track; see [Folders](/Reaper-AutoColor/usage/colours/#folders). |

Click an object's name to find it in the project. A track is selected and scrolled into view. An item is selected. For a region or marker, the edit cursor moves to its position.

### Pattern tester

**Pattern tester** lets you try out a pattern on a name before you put the pattern in a rule. See [Testing a pattern](/Reaper-AutoColor/usage/matching/#testing-a-pattern).

## The action bar

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>The action bar, below the rule table</figcaption>
</figure>

| Button | What it does |
|---|---|
| **+ *type* rule** | Adds a rule at the bottom of the open tab. |
| **Undo** | Reverts the last change to the rules. |
| **Apply now** | Applies all rules to the whole project. See [Applying colours](/Reaper-AutoColor/usage/applying/). |
| **Selection** | Applies the rules to the selected objects only. See [Applying colours](/Reaper-AutoColor/usage/applying/). |
| **Clear...** | Removes colours, or on the Icons tab track icons. See [Clearing colours](/Reaper-AutoColor/usage/clearing/). |
| **Auto: off** / **Auto: on** | Shows whether auto-apply is on, and switches it on or off. When auto-apply is on, AutoColor applies the rules automatically as objects are added or renamed. See [Auto-apply](/Reaper-AutoColor/usage/auto-apply/). |
| **Options** | Opens the options: folder colours, resetting the colour of objects that no rule matches, starting auto-apply with REAPER, auto-apply timing, text size, and the config file. See [Options](/Reaper-AutoColor/configuration/). |
| **ⓘ** | Shows the installed version, links to the source code and this documentation, the author, and the licence. |

## The status line

The line at the bottom of the window shows the result of the last action for a few seconds. For example, it shows how many objects **Apply now** coloured, `Already up to date.` when nothing needed to change, `Nothing is selected.` when **Selection** had nothing to work on, or an error if the rules could not be saved.

## Warnings

The window shows a warning in two situations:

- **SWS Auto Color or SWS Auto Icon is switched on.** The warning appears below the rule list of each affected tab that has rules, because SWS and AutoColor would overwrite each other's colours or icons. See [Colours keep changing back](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).
- **This config file was written by a newer version.** The warning appears at the top of the window. Changes to the rules are not saved until you update AutoColor. See [Version handling](/Reaper-AutoColor/configuration/config-file/#version-handling).

## Where to go next

- [Matching names](/Reaper-AutoColor/usage/matching/): the three match modes, the supported regular expressions, and the filters.
- [Colours and gradients](/Reaper-AutoColor/usage/colours/): rules with one colour, rules with two, and how a gradient is spread.
- [Track icons](/Reaper-AutoColor/usage/icons/): the Icons tab and the icon browser.
- [Applying colours](/Reaper-AutoColor/usage/applying/): **Apply now**, **Selection**, and the actions that do the same without opening the window.
