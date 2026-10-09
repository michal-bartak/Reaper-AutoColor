---
title: Config file
description: Where the rules and options are stored, what the file contains, and how it is protected
---

AutoColor stores all its rules and settings in configuration file located at:
```
<resource folder>/MXM_AutoColor/config.json
```

Knowing this location is useful when you want to back up your setup, copy it to another computer.

It's exact location is shown in AutoColor's [Options](/Reaper-AutoColor/configuration/) dialog. 

The file is created the first time you change a rule or an option.

:::note[Why it is not in `Scripts/`]
The file is stored **outside** the folder that holds the AutoColor scripts, to prevent reinstalling or updating the scripts from overwriting it.
:::

## Backup files

AutoColor may create two more files in the same folder:

| File | What it contains |
|---|---|
| `config.bak.json` | The config file as it was before the most recent save. |
| `config.bad.json` | A config file that AutoColor could not read. |

AutoColor writes `config.bak.json` each time it saves the config file. Because the window saves after every change, `config.bak.json` holds the state from one change earlier. It does not keep older versions. To keep a particular state, copy `config.json` somewhere else.

To restore `config.bak.json`, close the AutoColor window, then rename `config.bak.json` to `config.json`, replacing the current file.

AutoColor writes `config.bad.json` when `config.json` cannot be read, for example because a hand edit left the JSON invalid. AutoColor copies the unreadable contents to `config.bad.json`, so that nothing is lost. It then starts with no rules and with default options, and shows a message saying so. To recover, correct the error in `config.bad.json`, close the AutoColor window, and copy the corrected file over `config.json`.

## Copying the setup to another computer

The config file contains the entire AutoColor setup: every rule and every option. To use the same setup on another computer, copy `config.json` to the same location on that computer.

Icon rules also need the icon files - especially custom images - on the other computer. [The icon browser](/Reaper-AutoColor/usage/icons/#the-icon-browser) explains how icon locations are stored.

## Editing it by hand

:::caution
It's not recommended
:::

The file is plain JSON, and you can edit it in a text editor. Follow these steps so that your changes are not lost or ignored:

1. Close the AutoColor window before you edit the file. The window keeps its own copy of the rules and writes that copy back after every change, which would overwrite your edits.
1. Edit and save the file.
1. If auto-apply is running, stop it and start it again. Auto-apply keeps using the rules it loaded when it started. See [Auto-apply](/Reaper-AutoColor/usage/auto-apply/).

Actions that run once, such as `MXM_AutoColor_ApplyAll.lua`, read the file each time they run, so they use your changes immediately.

AutoColor checks every value when it loads the file. A missing or invalid value is replaced by its default. A number outside the allowed range is changed to the nearest allowed value. A filter or gradient setting that does not apply to the rule's object type is removed or reset to the default.

## What is in it

The file has three parts: `version`, `options` and `rules`. Here is a short example:

```json
{
  "version": 4,
  "options": {
    "propagate_folders": "fill_unmatched",
    "propagate_icons": "off",
    "subfolder_splits_range": true,
    "clear_unmatched": { "track": false, "item": true, "region": false, "marker": false, "icon": false },
    "auto_undo": false,
    "tick_interval": 0.2,
    "cold_budget_ms": 4,
    "cold_interval": 5,
    "font_size": 14,
    "autostart": "last"
  },
  "rules": {
    "track":  [ { "label": "Bass", "mode": "regex", "pattern": "^(sub )?bass", "color": 8142034, "children": "default" } ],
    "item":   [],
    "region": [],
    "marker": [],
    "icon":   [ { "label": "Kick", "mode": "substring", "pattern": "kick", "icon": "kick.png", "children": "default" } ]
  }
}
```

In this example, one track rule colours tracks whose names start with `bass` or `sub bass`, and one icon rule gives the `kick.png` icon to tracks whose names contain `kick`. Under `options`, every value is the default except `clear_unmatched` for items.

### version

`version` identifies the layout of the file. AutoColor uses it to read files written by older and newer versions safely. See [Version handling](#version-handling). Do not change it by hand.

### options

Each field under `options` corresponds to a setting in the [Options](/Reaper-AutoColor/configuration/) dialog.

| Field | Setting in Options | Default | Allowed values |
|---|---|---|---|
| `propagate_folders` | Folders → Tracks | `"fill_unmatched"` | `"fill_unmatched"` (**fill**), `"force"`, `"off"` |
| `propagate_icons` | Folders → Icons | `"off"` | `"off"`, `"fill_unmatched"` (**fill**), `"force"` |
| `subfolder_splits_range` | Subfolder splits the parent's colour range | `true` | `true`, `false` |
| `clear_unmatched` | Reset to the default colour when no rule matches | all `false` | `true` or `false` for each of `track`, `item`, `region`, `marker`, `icon` |
| `autostart` | Autostart | `"last"` | `"last"`, `"on"` (**Always**), `"off"` (**Never**) |
| `auto_undo` | Undo points for automatic changes | `false` | `true`, `false` |
| `tick_interval` | Check frequency (s) | `0.2` | 0.05 to 2 |
| `cold_budget_ms` | Work budget (ms) | `4` | 1 to 50 |
| `cold_interval` | Item/marker rescan (s) | `5` | 0 to 60 |
| `font_size` | Text size | `14` | 8 to 20 |

### rules

`rules` holds one list of rules for each tab in the AutoColor window:

| List | Tab |
|---|---|
| `track` | Tracks |
| `item` | Items |
| `region` | Regions |
| `marker` | Markers |
| `icon` | Icons |

Within a list, the rules are in the same order as on the tab. The order is the priority: for each object, the first rule in the list that matches it decides its colour or icon.

### Rule fields

Each rule is a JSON object with the fields below. A field that is missing takes the default shown.

| Field | Meaning | Default |
|---|---|---|
| `label` | The rule's name, shown in the **Name** column. | `""` |
| `enabled` | `false` switches the rule off without deleting it. | `true` |
| `mode` | How the pattern is matched: `"substring"`, `"glob"` or `"regex"`. The window shows `substring` as **contains**. | `"substring"` |
| `pattern` | The text to match against the name. An empty pattern matches every name, so the rule then matches every object that meets its filter. | `""` |
| `ci` | `true` ignores the difference between upper and lower case. This is the **Aa** column; see [Upper and lower case](/Reaper-AutoColor/usage/matching/#upper-and-lower-case). | `true` |
| `only` | The filter, an extra condition on top of the pattern. See the table below. | no filter |
| `color` | The rule's colour. See [Colours](#colours). | grey (`8421504`) |
| `color2` | A second colour. When it is present, the rule colours its matches with a gradient from `color` to `color2`. | none |
| `gradient_scope` | How a gradient is spread: `"all"` (**all matches**), `"run"` (**runs**), `"folder"` (**folders**) or `"both"` (**runs & folders**). `"folder"` and `"both"` are for track rules only. | `"run"` for tracks and items, `"all"` for regions and markers |
| `cascade_items` | Track rules only. `true` also colours the items on the tracks that the rule matches. This is the **FI** (force item colour) column. | `false` |
| `icon` | Icon rules only. The icon file, relative to REAPER's `Data/track_icons` folder or as a full path. `""` removes the icon from the matched tracks. | `""` |
| `children` | Track and icon rules only. Whether a folder track's colour or icon is also given to the tracks inside the folder: `"default"`, `"off"`, `"fill"` or `"force"`. `"default"`, shown as `--`, uses `propagate_folders` for track rules and `propagate_icons` for icon rules. This is the **Children** column. | `"default"` |
| `note` | A message that AutoColor attaches to a rule, for example the reason a rule was switched off when it was loaded. The window does not show it. | `""` |
| `id` | An identifier that AutoColor uses to keep track of the rule. Do not edit it. When it is missing or duplicated, AutoColor creates a new one. | created automatically |
| `invert` | `true` makes the rule match every name that the pattern does **not** match. The window has no control for this field, so it can be set only in the file. | `false` |

The `only` field accepts these filters:

| Value | Filter in the window | Object types |
|---|---|---|
| `"folder"` | is a folder track | Tracks, Icons |
| `"children"` | is inside a folder | Tracks, Icons |
| `"instrument"` | has an instrument | Tracks, Icons |
| `"midi_in"` | has a MIDI input | Tracks, Icons |
| `"bus"` | has receives | Tracks, Icons |
| `"unnamed"` | has no name | all |

See [Filters](/Reaper-AutoColor/usage/matching/#filters) for what each filter matches.

### Colours

`color` and `color2` are written as a single decimal number. To get the number from a hexadecimal colour code, read the code as one hexadecimal number and convert it to decimal. For example, the colour `#7C3CD2` is the hexadecimal number `7C3CD2`, which is `8142034` in decimal.

## Version handling

The `version` field allows AutoColor to read files written by both older and newer versions of AutoColor without losing rules. The current version is 4.

When AutoColor loads a file from an **older** version, it converts the file to the current layout. The converted file is written at the next save, and the original file is then kept as `config.bak.json` until the save after that. The conversions are:

- Version 1 kept all rules in a single list, and each rule had a checkbox for each object type. A rule that was ticked for several object types becomes one rule in each of those lists. The order of the rules within each list is preserved.
- Version 3 added the list of icon rules.
- Version 4 added the **Children** setting to track rules, and the value `"default"` to track and icon rules. Every track rule starts at `"default"`. An icon rule whose `children` was `"off"` changes to `"default"`, which gives the same result because `propagate_icons` is `"off"` by default. Icon rules set to `"fill"` or `"force"` keep their value.

When AutoColor loads a file from a **newer** version, it uses the rules but never saves over the file. This prevents an older version of AutoColor from overwriting settings that it does not understand. The window shows a banner: *This config file was written by a newer version. Editing is allowed but nothing will be saved.* You can still change rules in the window to try them out, but the changes are lost when the window closes. The **Example rules**, **Remove Rules** and **Import from SWS** buttons in Options are disabled. To edit the rules again, update AutoColor.

A rule that uses a feature removed from AutoColor is switched off when the file is loaded, and the reason is written to its `note` field. For example, a rule that used the former "master track" filter is switched off, because REAPER does not show a custom colour on the master track.
