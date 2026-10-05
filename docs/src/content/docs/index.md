---
title: Overview
description: Colour REAPER tracks, items, regions and markers from their names
---

AutoColor colours **tracks, items, regions and markers** and sets **track icons** by matching their names against a plain substring, a glob, or a regular expression.

Rules are global, shared by every project, though the colours and icons they set are stored with the project.

<figure class="shot">

![The configuration window](../../assets/usage/window-overview.png)

<figcaption>The configuration window</figcaption>
</figure>

## Main features

- **Background auto-colouring.** A loop keeps objects updated automatically, leaving manually set colours and icons alone.
- **One ordered list per object type.** Tracks, Items, Regions, Markers and Icons each have a tab. Within a tab the first rule that matches wins.
- **Three match modes.** `contains`, `glob` and full `regex`, per rule.
- **Non-name filters.** A rule can be narrowed to folder tracks, tracks inside a folder, tracks with an instrument, a MIDI input or receives, or unnamed objects.
- **Gradients.** A rule with a second colour spreads its matches along a ramp. Matches interrupted by other objects or by folders can get a ramp each.
- **Items follow their track.** A track rule can colour the items on it, whatever they are called.
- **Live preview.** The window shows each rule's hit count, and the matched objects before anything is applied.

:::tip[SWS Auto Color]
SWS matches case-insensitive substrings only, and has no item support. [Matching names](/Reaper-AutoColor/usage/matching/) covers what the three modes do differently. Do not run SWS Auto Color and AutoColor at once — see [Troubleshooting](/Reaper-AutoColor/troubleshooting/).
:::

## How a colour is decided

1. AutoColor tests the object's name against the rules on **its own tab**, top to bottom.
1. The **first** rule that matches wins. Its colour becomes the object's colour.
1. If that rule has a second colour, the object's shade comes from its place in the [gradient](/Reaper-AutoColor/usage/colours/#gradients).
1. A track that no rule claims can inherit from its **folder parent**, depending on the [folder setting](/Reaper-AutoColor/usage/colours/#folders).
1. Otherwise the object is left alone, unless unmatched objects of that type are set to [reset](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects).
1. An item that no item rule claims shows its **track's** colour: REAPER draws it so while the item has no colour of its own, or the track's rule [writes the colour onto it](/Reaper-AutoColor/usage/colours/#items).

The rules are applied to the project by pressing **Apply now**, or, with [auto-apply](/Reaper-AutoColor/usage/auto-apply/) on, whenever objects change — a track added or renamed, for example.

## Where to go next

- [Requirements](/Reaper-AutoColor/requirements/) — the REAPER version and the one extension required.
- [Installation](/Reaper-AutoColor/installation/) — install through ReaPack, or copy the folder in by hand.
- [The configuration window](/Reaper-AutoColor/usage/) — the tabs, the rule row, the action bar.
- [Matching names](/Reaper-AutoColor/usage/matching/) — modes, supported regex, filters.
- [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) — the background loop and what it leaves alone.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — when the colour is not the expected one.
