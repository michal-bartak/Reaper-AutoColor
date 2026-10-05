---
title: REAPER preferences
description: Two settings outside this tool that decide whether its colours are visible
---

Two REAPER preferences decide whether the colours this tool writes are visible at all. Neither can be set from AutoColor. Both are common reasons for an apply that reports colouring but shows no change.

## Which colour an item is drawn in

**Preferences → Appearance → Peaks/Waveforms**, under *Extra peaks display options*:

```
Tint media item waveform peaks to:   [Track color] [Item color] [Take color]
Tint media item background to:       [Track color] [Item color] [Take color]
```

Precedence is **take > item > track**: a custom take colour beats a custom item colour, which beats the track colour.

With **Item color** unticked, item colours may not show, whatever this tool writes.

:::note
REAPER's own tooltip warns that *"Color theme may override this preference"*.
:::

## Automatic take colours

**Preferences → Appearance → Media**:

```
Automatically color any recording pass that adds takes or lanes
```

REAPER's tooltip: *"When recording, automatically apply the same random color to all takes created in the same recording pass."*

This is the usual source of custom take colours nobody remembers setting. Take colour beats item colour, and take colours travel with a copy/paste, so a stale one can follow an item onto a track where it no longer means anything.

:::tip
Turn it off, to keep take colours from hiding item colours. To check which of the two is drawn: give one item a custom colour and its take a different one. The visible one wins.
:::

Take colours are **reset** whenever a colour is written to an item — see [Takes](/Reaper-AutoColor/usage/colours/#takes).
