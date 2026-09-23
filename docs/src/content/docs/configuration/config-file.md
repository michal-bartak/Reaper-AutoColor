---
title: Config file
description: Where the rule set lives, what is in it, and how it is protected
---

Every project shares one global rule set:

```
<REAPER resource path>/MXM_AutoColor/config.json
```

| OS | Path |
|----|------|
| macOS | `~/Library/Application Support/REAPER/MXM_AutoColor/config.json` |
| Windows | `%AppData%\REAPER\MXM_AutoColor\config.json` |
| Linux | `~/.config/REAPER/MXM_AutoColor/config.json` |

*Options → Show REAPER resource path in explorer/finder* opens the parent directory. The **Rules
file** section of [Options](/Reaper-AutoColor/configuration/) also prints the path.

:::note[Why it is not in `Scripts/`]
Stored **outside** the script folder, to prevent reinstalling or updating the scripts from
overwriting it.
:::

## The files beside it

| File | When it appears |
|---|---|
| `config.bak.json` | The previous version, kept on every save and before a migration. |
| `config.bad.json` | An unreadable file, parked rather than lost. The tool then starts from defaults and says so. |

## What is in it

```json
{
  "version": 3,
  "options": {
    "propagate_folders": "fill_unmatched",
    "subfolder_splits_range": true,
    "clear_unmatched": { "track": false, "item": true, "region": false, "marker": false, "icon": false },
    "auto_undo": false,
    "tick_interval": 0.2,
    "cold_budget_ms": 4,
    "cold_interval": 5,
    "font_size": 14
  },
  "rules": {
    "track":  [ { "label": "Bass", "mode": "regex", "pattern": "^(sub )?bass", "color": 8142034 } ],
    "item":   [],
    "region": [],
    "marker": [],
    "icon":   [ { "label": "Kick", "mode": "substring", "pattern": "kick", "icon": "kick.png", "children": "off" } ]
  }
}
```

`rules` holds one ordered list per kind, and the order **is** the precedence.

### Rule fields

| Field | Meaning |
|---|---|
| `label` | The rule's name in the window. |
| `enabled` | `false` switches the rule off without deleting it. |
| `mode` | `substring`, `glob` or `regex`. **contains** in the window is `substring` here. |
| `pattern` | What to match. Empty means "match on the filter alone". |
| `ci` | Ignore case (ASCII only), the **Aa** column. `true` unless set otherwise. |
| `only` | The filter: `folder`, `children`, `instrument`, `midi_in`, `bus`, `unnamed`, or absent. |
| `color`, `color2` | The rule's colour, and the second colour that makes a gradient. `0xRRGGBB` as a decimal number: `8142034` is `#7C3CD2`. |
| `gradient_scope` | `all`, `run`, `folder` or `both`. |
| `cascade_items` | Track rules: also colour the items on the matched tracks. |
| `icon` | Icon rules: the icon, relative to `Data/track_icons` or absolute. `""` removes the icon. |
| `children` | Icon rules: `off`, `fill` or `force`. |
| `note` | A message the tool has attached to the rule, such as why it was disabled on load. |
| `id` | Internal identity, used to follow a rule across reorders. Not to be edited. |
| `invert` | Match everything the pattern does **not** match. Honoured by the engine; the window has no control for it. File-only. |

## Editing it by hand

Close the configuration window first. It holds the rule set in memory and writes it back on every
edit, overwriting changes made underneath it.

:::tip
The file is plain JSON, so it diffs and merges cleanly, and it is the entire configuration — copying
it to another machine is the whole of "sync".
:::

## Version handling

`version` is the schema version, and is what makes upgrading safe in both directions:

- An **older** file is migrated on load, the previous one kept as `config.bak.json`. The single-list
  layout becomes one list per kind, preserving relative order within each kind. Version 3 adds the
  `icon` list.
- A **newer** file loads read-only. The window shows a banner and allows editing but saves nothing,
  to prevent an older build from rewriting a config it does not understand.

A rule using a feature this build has dropped is **disabled** on load, with the reason in its
`note`, rather than silently losing the setting.
