---
title: Marker colours
description: The Markers tab — colouring markers from their names
---

The **Markers** tab of the configuration window colours markers according to their names. For example, a rule can colour every marker whose name starts with `TODO` red, so that open tasks in the project stand out.

Regions have a tab of their own; see [Region colours](/Reaper-AutoColor/usage/regions/).

## Marker rules

Each row on the **Markers** tab is one rule. A rule says which markers it matches and what colour they get:

| Column | What it does |
|---|---|
| **Match** | How the pattern is compared with the marker name: `contains` (default), `glob` or `regex`. See [Match modes](/Reaper-AutoColor/usage/matching/#match-modes). |
| **Pattern** | The text to look for in the marker name. An empty pattern matches every name. |
| **Aa** | On by default: upper and lower case are ignored. |
| **Filter** | Only one filter is available for markers: *has no name*. See [Filters](/Reaper-AutoColor/usage/matching/#filters). |
| **Colour** | The colour the matching markers get. Click **+** to add a second colour, which spreads a [gradient](/Reaper-AutoColor/usage/colours/#gradients) across the markers. |
| **Hits** | How many markers this rule colours in the current project. See [The Hits column](/Reaper-AutoColor/usage/matching/#the-hits-column). |

To add a rule, click **+ marker rule** on the action bar. [Common controls](/Reaper-AutoColor/usage/#common-controls) describes how to reorder, duplicate and delete rules.

## Which rule colours a marker

AutoColor compares each marker name with the rules from top to bottom. The first rule that matches colours the marker. Rules further down the list do not affect that marker. To give a rule priority over another, move it higher in the list.

A marker gradient runs from left to right along the timeline. By default, one gradient covers every marker the rule colours, even when markers of other names lie between them. To start a new gradient after each interruption instead, see [Spread across](/Reaper-AutoColor/usage/colours/#spread-across).

## When markers are coloured

Editing a rule does not change the project. AutoColor writes the colours into the project when the rules are applied:

- **Apply now** colours every marker in the project. One undo reverts the whole change.
- **Selection** colours only the selected markers.
- While [auto-apply](/Reaper-AutoColor/usage/auto-apply/) is running, a new marker is coloured as soon as you stop editing. A renamed marker is coloured within a few seconds; see [How quickly changes are applied](/Reaper-AutoColor/usage/auto-apply/#how-quickly-changes-are-applied).

AutoColor does not remove colours unless you ask it to. To remove colours, use [Clear](/Reaper-AutoColor/usage/clearing/), or the option [Reset to the default colour when no rule matches](/Reaper-AutoColor/usage/clearing/#reset-to-the-default-colour-when-no-rule-matches).

While auto-apply is running, a colour that you set by hand stays until you rename the marker or click **Apply now**. See [Colours and icons set by hand](/Reaper-AutoColor/usage/auto-apply/#colours-and-icons-set-by-hand).

[Applying colours and icons](/Reaper-AutoColor/usage/applying/) describes the apply buttons and actions in full.

## Limitations

On REAPER older than 7.62, **Selection** leaves markers unchanged, and marker colours cannot be removed. See [REAPER versions before 7.62](/Reaper-AutoColor/requirements/#reaper-versions-before-762).
