---
title: Track icons
description: The Icons tab, the icon browser, and folder propagation
---

The **Icons** tab sets each track's icon from its name, the same way the Tracks tab sets its
colour. It is a list of its own, with its own precedence: the first icon rule that matches wins, so
a track can take its colour from one rule and its icon from another.

Icon rules match tracks only. They have the same **Name**, **Match**, **Pattern**, **Aa** and
[**Filter**](/Reaper-AutoColor/usage/matching/#filters) columns as the Tracks tab. **Icon** and
**Children** replace **Colour** and **Items**.

| Column | What it is |
|---|---|
| **Icon** | The icon the rule sets. Click the thumbnail to open the icon browser. A rule set to **None** removes the icon from what it matches. |
| **Children** | What a folder track matched by this rule hands down to its children. |

## The icon browser

The browser lists every PNG and JPEG under `Data/track_icons` in the REAPER resource folder,
subfolders included, ordered by path.

- **Search** narrows the grid to file names containing the text, subfolder names included. Case is
  ignored.
- A click marks an icon. **Select**, a double-click or `Enter` applies it; **Cancel** or `Esc`
  closes the browser with the rule unchanged.
- **None**, the first cell, removes the icon.
- **Browse…** picks an image file anywhere on disk.
- **Refresh** reads the folder again, after icons have been added to it.

An icon inside `Data/track_icons` is stored relative to it, so the
[config file](/Reaper-AutoColor/configuration/config-file/) carries over to another machine. An icon
picked elsewhere is stored as an absolute path.

## Children

**Children** applies when the rule matches a folder track.

| Setting | Effect |
|---|---|
| **off** | The icon goes on the folder track only. The default. |
| **fill** | Children that no icon rule matches take the folder's icon. |
| **force** | Every child takes the folder's icon, whatever rule matches it. Among nested folders set to force, the outermost wins. |

A subfolder whose own rule is **off** does not stop an outer **fill**: the children inside it still
take the outer folder's icon when nothing matches them.

This is set per rule, unlike [Folders](/Reaper-AutoColor/configuration/#folders) for colours.

## Unmatched tracks and hand-set icons

By default a track no icon rule matches keeps its icon. **Options → Scope → Icons** removes it
instead; see [Reset unmatched objects](/Reaper-AutoColor/usage/clearing/#reset-unmatched-objects).

The [background loop](/Reaper-AutoColor/usage/auto-apply/) leaves an icon set by hand alone until
the track is renamed, the same as a hand-set colour. **Apply now** returns it to the rules.

On the Icons tab, **Clear…** removes icons instead of colours, with the same three scopes.

## Where to go next

- [Matching names](/Reaper-AutoColor/usage/matching/) — modes and filters, shared with the other tabs.
- [Importing from SWS](/Reaper-AutoColor/configuration/import-sws/) — SWS icon rules come across too.
