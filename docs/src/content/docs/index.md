---
title: Overview
description: Colour REAPER tracks, items, regions and markers from their names
---

AutoColor colours **tracks, items, regions and markers** from their **names**, matching on a plain
substring, a glob, or a real regular expression.

Rules are global: one set, shared by every project. A track named `Sub Bass DI` turns purple as
soon as it is named, and the items on it follow.

<figure class="shot">

![The configuration window](../../assets/usage/window-overview.png)

<figcaption>The configuration window</figcaption>
</figure>

## Main features

- **One ordered list per object kind.** Tracks, Items, Regions and Markers each have a tab. Within
  a tab the first rule that matches wins, like firewall rules.
- **Three match modes.** `contains`, `glob` and full `regex`, per rule.
- **Non-name filters.** A rule can be narrowed to folder tracks, tracks inside a folder, or
  unnamed objects.
- **Gradients.** A rule with a second colour spreads its matches along a ramp, grouped by runs, by
  folders, or not at all.
- **Items follow their track.** A track rule can colour the items on it, whatever they are called.
- **Background auto-colouring.** A loop keeps the project in step with renames, adding no undo
  points and leaving manually set colours alone.
- **Live preview.** Every rule shows its hit count, and the panes at the foot of the window list the
  objects it claims in this project.

:::tip[SWS Auto Color]
SWS matches case-insensitive substrings only, and has no item support.
[Matching names](/Reaper-AutoColor/usage/matching/) covers what the three modes do differently. Do
not run both at once — see [Troubleshooting](/Reaper-AutoColor/troubleshooting/).
:::

## How a colour is decided

1. AutoColor tests the object's name against the rules on **its own tab**, top to bottom.
1. The **first** rule that matches wins. Its colour becomes the object's colour.
1. If that rule has a second colour, the object's shade comes from its place in the
   [gradient](/Reaper-AutoColor/usage/colours/#gradients).
1. An item that no item rule claims can take its **track's** colour, where the track's rule is set
   to [cascade](/Reaper-AutoColor/usage/colours/#items).
1. A track that no rule claims can inherit from its **folder parent**, depending on the
   [folder setting](/Reaper-AutoColor/usage/colours/#folders).
1. Otherwise the object is left alone, unless unmatched objects of that kind are set to
   [reset](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects).

Nothing reaches the project until **Apply** runs, or the background loop does.

## Where to go next

- [Requirements](/Reaper-AutoColor/requirements/) — the REAPER version and the one extension required.
- [Installation](/Reaper-AutoColor/installation/) — install through ReaPack, or copy the folder in by hand.
- [The configuration window](/Reaper-AutoColor/usage/) — the tabs, the rule row, the action bar.
- [Matching names](/Reaper-AutoColor/usage/matching/) — modes, supported regex, filters.
- [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) — the background loop and what it refuses to touch.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — when the colour is not the expected one.
