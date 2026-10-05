---
title: Clearing colours
description: The three clearing scopes, and the per-type reset for unmatched objects
---

Clearing sets an object back to the **theme default**, removing the custom colour rather than writing a new one.

## The Clear menu

| Scope | What it resets |
|---|---|
| **Clear colours the rules match** | Only objects a rule currently claims. |
| **Clear selected objects** | The selection, whether or not a rule matches it. |
| **Clear EVERY custom colour in the project…** | Everything, including colours this tool never set. Asks first. |

**Clear selected objects** follows the same focus rule as **Selection**: with both a track and some items selected, the last one clicked wins, and selected regions and markers are always included.

:::caution
The third scope also removes colours set by hand or by other tools. REAPER's undo (`Cmd`/`Ctrl`+`Z`) restores them.
:::

On the **Icons** tab the menu removes track icons instead, with the same three scopes.

`MXM_AutoColor_ClearColors.lua` offers the first two scopes from the Action List. Clearing *every* custom colour is deliberately GUI-only, to keep a single keystroke from doing it.

## Reset unmatched objects

**Options → Scope → Reset to the default colour when no rule matches** is set **per object type**, off everywhere by default.

When on, every apply removes the colour from objects of that type that no rule claims. The **Icons** checkbox removes the icon from tracks no icon rule claims.

:::caution[Careful with tracks]
For tracks this also strips every hand-set track colour.
:::

### For items it is usually the better setting

REAPER draws an item with **no colour of its own** in its **track's** colour, so an item copied to another track takes that track's colour at once.

Two ways to make items match their track:

| | How it works | On copy/paste to another track |
|---|---|---|
| **also colour items** on a track rule | Writes the track's colour onto the item | Stays wrong until something re-applies, and remains stale where the new track's rule does not cascade |
| **reset unmatched items** | Removes the item's colour, so REAPER draws it from the track | Correct instantly, permanently |

**reset unmatched items** is preferred, except where items should differ from their track, or the theme does not tint item backgrounds by track colour.

:::note[Older REAPER builds]
On REAPER older than 7.62, marker and region colours cannot be cleared. Colouring still works, and the scripts report how many were skipped.
:::

## Where to go next

- [REAPER preferences](/Reaper-AutoColor/configuration/reaper-preferences/) — whether item colours are drawn at all.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — a colour that will not go away.
