---
title: Clearing colours
description: The three clearing scopes, and the per-kind reset for unmatched objects
---

Clearing sets an object back to the **theme default**, removing the custom colour rather than
writing a new one.

## The Clear menu

| Scope | What it resets |
|---|---|
| **Clear colours the rules match** | Only objects a rule currently claims. |
| **Clear selected objects** | The selection, whether or not a rule matches it. |
| **Clear EVERY custom colour in the project…** | Everything, including colours this tool never set. Asks first. |

**Clear selected objects** follows the same focus rule as **Selection**: with both a track and some
items selected, the last one clicked wins, and selected regions and markers are always included.

:::caution
The third scope reaches colours unrelated to these rules. It asks for confirmation and REAPER's
undo (`Cmd`/`Ctrl`+`Z`) restores them, but it is the one clearing scope that can lose work.
:::

On the **Icons** tab the menu removes track icons instead, with the same three scopes.

`MXM_AutoColor_ClearColors.lua` offers the first two scopes from the Action List. Clearing *every*
custom colour is deliberately GUI-only, to keep a single keystroke from doing it.

## Reset unmatched objects

**Options → Scope → Reset to the default colour when no rule matches** is set **per kind**, off
everywhere by default.

On for a kind, every apply strips the colour from any object of that kind the rules do not claim,
making the rules the single source of truth for that kind. The **Icons** checkbox removes the icon
from tracks no icon rule claims.

:::caution[Careful with tracks]
For tracks this also strips every hand-set track colour.
:::

### For items it is usually the better setting

It answers "my pasted item kept its old colour". REAPER draws an item with **no custom colour** in
its **track's** colour, live: copied to another track, it follows that track at once — no rule, no
sweep, and nothing that can go stale.

Two ways to make items match their track, and they are not equal:

| | How it works | On copy/paste to another track |
|---|---|---|
| **also colour items** on a track rule | Writes the track's colour onto the item | Stays wrong until something re-applies, and remains stale where the new track's rule does not cascade |
| **reset unmatched items** | Removes the item's colour, so REAPER draws it from the track | Correct instantly, permanently |

The second is the default choice, except where items should differ from their track, or the theme
does not tint item backgrounds by track colour.

:::note[Older REAPER builds]
On REAPER older than 7.62 the marker/region *clear* path is unavailable: `SetProjectMarker4` reads
colour 0 as "leave unchanged". Colouring still works, and the scripts report how many
markers/regions were skipped.
:::

## Where to go next

- [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/) — whether item colours are drawn at all.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — a colour that will not go away.
