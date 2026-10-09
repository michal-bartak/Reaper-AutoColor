---
title: REAPER preferences
description: Two REAPER settings that decide whether item colours are visible
---

AutoColor writes colours into the project, but REAPER decides how to draw them. Two of REAPER's own preferences affect whether the colour that AutoColor gives an item is visible. AutoColor cannot change these preferences. You set them in REAPER's Preferences window.

If AutoColor reports that it coloured items but the items look unchanged, check these two preferences first.

## Track, item and take colours

REAPER can store a colour at three levels:

- A **track colour** belongs to the track.
- An **item colour** belongs to one media item on the track.
- A **take colour** belongs to one take inside an item. An item can contain several takes, for example one for each recording pass.

When more than one of these colours is set, REAPER draws an item in the most specific one. A take colour takes precedence over the item colour, and the item colour takes precedence over the track colour. An item with no item colour and no take colour is drawn in its track's colour.

AutoColor writes item colours, and removes take colours from the items it colours. See [Takes](/Reaper-AutoColor/usage/items/#takes).

## Which colour an item is drawn in

**Preferences → Appearance → Peaks/Waveforms**, under *Extra peaks display options*, has two rows of checkboxes:

```
Tint media item waveform peaks to:   [Track color] [Item color] [Take color]
Tint media item background to:       [Track color] [Item color] [Take color]
```

The first row decides which colours tint the waveform of an item. The second row decides which colours tint the item's background.

If **Item color** is not ticked in either row, item colours may not show, whatever colour AutoColor writes. To see the colours AutoColor gives items, tick **Item color** for the background, the waveform peaks, or both.

:::note
REAPER's own tooltip for these options warns: *"Color theme may override this preference"*. With some themes, the setting may not change what you see.
:::

## Automatic take colours

**Preferences → Appearance → Media** has this option:

```
Automatically color any recording pass that adds takes or lanes
```

REAPER's tooltip describes it: *"When recording, automatically apply the same random color to all takes created in the same recording pass."*

When this option is on, recording gives each new take a colour. Because a take colour takes precedence over the item colour, these take colours can hide item colours. A take colour also stays with the item when you copy and paste it. As a result, an item can carry a take colour from a recording onto a track where that colour has no meaning.

:::tip
Turn this option off to prevent take colours from hiding item colours.

To check which colour your setup draws, give one item a custom item colour, and give its take a different take colour. The colour you see is the one that takes precedence.
:::
