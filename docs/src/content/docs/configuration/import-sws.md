---
title: Importing from SWS
description: Moving an SWS Auto Color setup across, and what does not survive the trip
---

**Options ▸ Config file ▸ Import from SWS** converts an existing **SWS Auto Color** setup into AutoColor rules.

It reads SWS first and reports what it found — how many rules, how they split across tabs, how many will arrive switched off — and imports only on confirmation. Cancelling changes nothing.

It only ever **adds**, appending below existing rules. **Undo** takes an import back while the window is open, and the project is not recoloured until the next apply.

To keep SWS's rules alone, use **Remove Rules** first, then import.

## What it reads

`sws-autocoloricon.ini`, in the REAPER resource folder — *Options ▸ Show REAPER resource path* in REAPER's own menu. The location is found automatically; with SWS never installed, the import reports that and changes nothing.

Gradient colours come from `reaper.ini`, where SWS keeps them. With none set, the import falls back to SWS's own default of black to white.

Both files are only ever read. No part of the SWS setup is changed or removed.

## What comes across exactly

SWS matches a **case-insensitive substring** of the name, and the first matching rule wins, as here, so an ordinary SWS rule arrives unchanged.

| In SWS | Here |
|---|---|
| A name filter, e.g. `Kick` | A `contains` rule with the same text |
| `(any)` | A rule with no pattern and no filter |
| `(unnamed)`, `(folder)`, `(children)`, `(instrument)`, `(MIDI input)`, `(receive)` | The equivalent [filters](/Reaper-AutoColor/usage/matching/#filters) |
| A track rule's **icon** | A rule on the **Icons** tab with the same filter, in the same order |
| **Gradient** | A real [gradient](/Reaper-AutoColor/usage/colours/#gradients), using the start and end colours SWS was set to |
| Rule order | Preserved — it is the priority order on both sides |

## What does not

Some SWS features have no equivalent. Those rules are **still imported**, but they arrive **switched off**, with the reason added to the rule's name:

| In SWS | Why it does not come across |
|---|---|
| **Random** colours | No colour is ever assigned that a rule did not specify. |
| **Custom** (cycling REAPER's palette) | Same. |
| **Parent** colour | Covered differently, by [Folders](/Reaper-AutoColor/configuration/#folders) — one setting for the whole rule set instead of a per-rule colour. |
| **None** | There is no "clear the colour" rule; that is *Clear…* on the action bar, or [reset unmatched objects](/Reaper-AutoColor/usage/clearing/). |
| **Ignore** | See the warning below. |
| `(master)` | REAPER [ignores a custom colour on the master track](/Reaper-AutoColor/troubleshooting/#the-master-track-is-never-coloured), so this never did anything visible in SWS either. |
| `(record armed)`, `(audio input)`, `(audio output)`, `(MIDI output)`, `(vca master)` | No equivalent filter. |

Those rules keep the SWS keyword as their pattern, matched as plain text. Check them before switching any on: `(record armed)` as a pattern does not match armed tracks.

:::caution[Ignore rules change more than themselves]
In SWS, an **Ignore** rule matched a track, left it alone, **and stopped every rule below it**. The blocking is the part with no equivalent here, so the rules *underneath* an Ignore rule may now colour tracks they never used to.
:::

TCP/MCP layouts are read and discarded.

An icon rule does not lose what its colour lost: in SWS the two are decided separately, so an **Ignore** or **Random** colour still leaves its icon rule switched on.

## Afterwards

Importing does not switch SWS off. Switch it off under **SWS ▸ Auto Color/Icon/Layout**; until then both recolour the same tracks, and each affected tab shows a warning.

Before applying, check:

- Anything switched off carries its reason in its name.
- An SWS `(any)` catch-all matches *everything*. It lands below the existing rules and claims every object they leave unmatched.
- **Hits** in the rule list reports what each rule actually wins. See [Applying](/Reaper-AutoColor/usage/applying/).
