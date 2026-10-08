---
title: Clearing colours
description: Removing colours once with Clear, or each time the rules are applied, from objects that no rule matches
---

Clearing removes the custom colour from a track, item, region or marker. It does not write a new colour. The object is then drawn in its **theme default** colour, the colour REAPER uses for an object that has no colour of its own. An item without a colour of its own is drawn in its track's colour.

Tracks, items, regions and markers are called *objects* in the window and on this page.

Use clearing to remove colours you no longer want, or to start over after you change your rules. AutoColor offers two ways to clear colours:

- The **Clear…** menu and the `MXM_AutoColor_ClearColors.lua` action clear colours once.
- **Reset to the default colour when no rule matches** clears colours every time the rules are applied, from objects that no rule matches.

## The Clear menu

The **Clear…** button is on the action bar of the configuration window. It opens a menu with three choices. Each choice decides which objects lose their colour.

| Menu item | What it clears |
|---|---|
| **Clear colours the rules match** | Only objects that the current rules assign a colour to. Other colours stay. |
| **Clear selected objects** | The selected objects, whether or not a rule matches them. |
| **Clear EVERY custom colour in the project…** | Every custom colour in the project, including colours that AutoColor never set. AutoColor asks for confirmation first. |

**Clear colours the rules match** includes items that are coloured because their track rule has the **Items** switch on. It also includes tracks that take their colour from a folder. See [Folders](/Reaper-AutoColor/usage/colours/#folders) and [Items](/Reaper-AutoColor/usage/colours/#items).

**Clear selected objects** decides which selected objects to clear in the same way as the **Selection** button. See [Selection](/Reaper-AutoColor/usage/applying/#selection).

Each clear is one undo point. REAPER's undo (`Cmd`/`Ctrl`+`Z`) restores the colours.

:::caution
**Clear EVERY custom colour in the project…** also removes colours you set by hand and colours set by other tools.
:::

Clearing an item's colour also clears the colours of all its takes. See [Takes](/Reaper-AutoColor/usage/colours/#takes).

### Clearing track icons

On the **Icons** tab, the **Clear…** menu removes track icons instead of colours. It offers the same three choices:

- **Clear icons the rules match** removes icons only from tracks that an icon rule currently matches.
- **Clear icons on selected tracks** removes icons from the selected tracks.
- **Clear EVERY track icon in the project…** removes every track icon, including icons that AutoColor never set. AutoColor asks for confirmation first.

## From the Action List

`MXM_AutoColor_ClearColors.lua` clears colours without opening the window. When you run it, it asks which objects to clear:

- **Yes** clears the selected tracks and items.
- **No** clears everything the current rules match.
- **Cancel** does nothing.

The action differs from the **Clear…** menu in these ways:

- It never clears regions or markers when clearing the selection.
- It clears both the selected tracks and the selected items. It does not choose between them by which you clicked last.
- It cannot clear every custom colour in the project. That choice is available only in the window, so that a single keyboard shortcut cannot remove every colour.
- It does not clear track icons.

## Reset to the default colour when no rule matches

By default, applying the rules never removes a colour. An object that no rule matches keeps whatever colour it has. **Reset to the default colour when no rule matches** changes this for one object type: each time the rules are applied, AutoColor removes the colour from every object of that type that no rule matches.

The setting is in **Options → Scope → Reset to the default colour when no rule matches**. It has one checkbox for each object type: **Tracks**, **Items**, **Regions**, **Markers** and **Icons**. All are off by default. The **Icons** checkbox removes the icon from tracks that no icon rule matches.

The reset applies whenever the rules are applied: with **Apply now**, with **Selection**, with the actions in the Action List, and with [auto-apply](/Reaper-AutoColor/usage/auto-apply/).

For example, with the reset on for regions and a single region rule matching `Chorus`:

- A region named `Chorus 1` gets the rule's colour.
- A region named `Bridge` loses any colour it had.

:::caution
The reset also removes colours that you set by hand on objects that no rule matches.
:::

### Items

For items, the reset is the recommended way to make items show their track's colour. An item without a colour of its own is drawn in its track's colour, and keeps following its track when you move it. The reset never removes a colour that comes from an item rule, or from a track rule with the **Items** switch on. [Items](/Reaper-AutoColor/usage/colours/#items) compares the reset with the **Items** switch and gives the full order in which an item's colour is decided.

## Limitations

On REAPER older than 7.62, region and marker colours cannot be cleared, and **Clear selected objects** leaves regions and markers unchanged. See [REAPER versions before 7.62](/Reaper-AutoColor/requirements/#reaper-versions-before-762).

## Where to go next

- [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/) — whether REAPER draws item colours at all.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — a colour that does not go away.
