---
title: Item colours
description: The Items tab — colouring items from their take names, items that follow their track's colour, and take colours
---

The **Items** tab of the configuration window colours media items according to their names. For example, a rule can colour every item whose name contains `comp` blue, so that comped takes stand out on the timeline.

An item's name, for AutoColor, is the name of its **active take**. An item without a take, such as an empty item, has an empty name.

Items can also take the colour of their track without a rule on this tab; see [Items and their track's colour](#items-and-their-tracks-colour).

## Item rules

Each row on the **Items** tab is one rule. A rule says which items it matches and what colour they get:

| Column | What it does |
|---|---|
| **Match** | How the pattern is compared with the item name: `contains` (default), `glob` or `regex`. See [Match modes](/Reaper-AutoColor/usage/matching/#match-modes). |
| **Pattern** | The text to look for in the item name. An empty pattern matches every name. |
| **Aa** | On by default: upper and lower case are ignored. |
| **Filter** | Only one filter is available for items: *has no name*. See [Filters](/Reaper-AutoColor/usage/matching/#filters). |
| **Colour** | The colour the matching items get. Click **+** to add a second colour, which spreads a [gradient](/Reaper-AutoColor/usage/colours/#gradients) across the items. |
| **Hits** | How many items this rule colours in the current project. See [The Hits column](/Reaper-AutoColor/usage/matching/#the-hits-column). |

To add a rule, click **+ item rule** on the action bar. [Editing rules](/Reaper-AutoColor/usage/#editing-rules) describes how to move, switch off and delete rules.

## Which rule colours an item

AutoColor compares each item name with the rules from top to bottom. The first rule that matches colours the item. Rules further down the list do not affect that item. To give a rule priority over another, move it higher in the list.

An item gradient runs from left to right along each track. Each track's items get a gradient of their own.

## Items and their track's colour

In REAPER, an item is drawn in one of two ways:

- An item with **no colour of its own** is drawn in its **track's** colour. The item follows its track: if you move the item to another track, REAPER draws it in the new track's colour at once.
- An item **with a colour of its own** keeps that colour. If you move the item to another track, the colour moves with it.

AutoColor can put an item into either state. Three settings decide which:

| Setting | What it does to the item |
|---|---|
| A rule on the **Items** tab | Gives the item the colour of that rule. |
| The **Items** switch on a rule on the **Tracks** tab | Gives every item on the tracks that the rule colours the track's colour, whatever the items are called. The item then has a colour of its own, so REAPER no longer draws it from the track it sits on. |
| **Options → Scope → Reset to the default colour when no rule matches**, ticked for **Items** | Removes the colour from every item that the first two settings do not colour, so REAPER draws those items in their track's colour again. See [Reset to the default colour when no rule matches](/Reaper-AutoColor/usage/clearing/#reset-to-the-default-colour-when-no-rule-matches). |

For a single item, AutoColor checks these settings in order:

1. If a rule on the **Items** tab matches the item, the item receives that rule's colour.
1. Otherwise, if the item's track is coloured by a rule with **Items** switched on, the item receives the track's colour.
1. Otherwise, if the reset is ticked for **Items**, AutoColor removes the item's colour.
1. Otherwise, AutoColor leaves the item's colour unchanged.

The reset never affects an item that step 1 or step 2 colours.

The **Items** switch also applies to the tracks inside a folder. If a track receives its colour from its folder track, and the folder track's rule has **Items** switched on, the items on that track also receive the colour.

If a track rule with **Items** switched on has two colours, each track's items receive that track's shade of the gradient. All items on one track have the same colour.

:::tip[To make items look like their track, prefer the reset]
The **Items** switch and the reset both make an item show its track's colour as soon as the rules are applied. They differ when you later move the item to another track:

- With the reset, the item has no colour of its own. REAPER draws it in the new track's colour at once.
- With the **Items** switch, the item keeps the colour that was written to it. The next time the rules are applied, the item receives the new track's colour only if the new track's rule also has **Items** switched on.

The **Items** switch is useful when items should keep their colour after they move to another track, or when the REAPER theme does not tint items with their track's colour.
:::

## Takes

In REAPER, an item holds one or more takes, and each take can have a colour of its own. A take colour can hide the item's colour; [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/) explains which colour REAPER draws.

AutoColor writes colours to the **item**, never to a take. When AutoColor writes a colour to an item, it also removes the colour from every take in that item. This keeps a take colour from hiding the item colour. For the same reason, AutoColor writes the colour again to an item whose colour is already correct if the item's active take has a colour of its own.

:::caution
Take colours and AutoColor item colours cannot be combined. When AutoColor colours an item, it removes any take colours you set in that item. A take colour on an item that AutoColor does not colour stays in place.
:::

There are no rules for takes. When you record, REAPER names each take after the track, and it does not rename the take when you later rename the track. Rules for takes would therefore duplicate the rules for tracks. To colour individual takes, use REAPER's own options, such as colouring each recording pass.

## When items are coloured

Editing a rule does not change the project. AutoColor writes the colours into the project when the rules are applied:

- **Apply now** colours every item in the project. One undo reverts the whole change.
- **Selection** colours only the selected items.
- While [auto-apply](/Reaper-AutoColor/usage/auto-apply/) is running, a new item is coloured as soon as you stop editing. A renamed item is coloured within a few seconds; see [How quickly changes are applied](/Reaper-AutoColor/usage/auto-apply/#how-quickly-changes-are-applied).

AutoColor does not remove colours unless you ask it to. To remove colours, use [Clear](/Reaper-AutoColor/usage/clearing/), or the reset described above.

While auto-apply is running, a colour that you set by hand stays until you rename the item or click **Apply now**. See [Colours and icons set by hand](/Reaper-AutoColor/usage/auto-apply/#colours-and-icons-set-by-hand).

[Applying colours and icons](/Reaper-AutoColor/usage/applying/) describes the apply buttons and actions in full.

## Limitations

- Whether item colours are visible at all depends on two [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/).
- A gradient rule on the **Items** tab can be slow in very large projects. See [Limitations of gradients](/Reaper-AutoColor/usage/colours/#limitations-of-gradients).
