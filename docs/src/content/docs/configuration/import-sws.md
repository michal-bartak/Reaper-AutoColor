---
title: Importing from SWS
description: Moving an SWS Auto Color setup across, and what does not survive the trip
---

**Options ▸ Config file ▸ Import from SWS** converts an existing **SWS Auto Color** setup into rules
here, so nothing has to be retyped.

It reads SWS first and reports what it found — how many rules, how they split across tabs, how many
will arrive switched off — and imports only on confirmation. Cancelling changes nothing.

It only ever **adds**, appending below existing rules, so nothing already configured changes
meaning. **Undo** takes an import back while the window is open, and nothing reaches the project
until **Apply** runs.

For SWS's rules alone, **Remove Rules** first — that one also asks — then import into the empty
set.

## What it reads

`sws-autocoloricon.ini`, in the REAPER resource folder — *Options ▸ Show REAPER resource path* in
REAPER's own menu. The location is found automatically; with SWS never installed, the import reports
that and changes nothing.

Gradient colours come from `reaper.ini`, where SWS keeps them. With none set, the import falls back
to SWS's own default of black to white.

Both files are only ever read. No part of the SWS setup is changed or removed.

## What comes across exactly

SWS matches on a **case-insensitive piece of the name**, and the first matching rule wins. Both are
exactly how this tool works, so an ordinary SWS rule arrives unchanged: same colour, same position
in the list, same behaviour.

| In SWS | Here |
|---|---|
| A name filter, e.g. `Kick` | A `contains` rule with the same text |
| `(any)` | A rule with no pattern and no filter |
| `(unnamed)`, `(folder)`, `(children)`, `(instrument)`, `(MIDI input)`, `(receive)` | The equivalent [filters](/Reaper-AutoColor/usage/matching/#filters) |
| A track rule's **icon** | A rule on the **Icons** tab with the same filter, in the same order |
| **Gradient** | A real [gradient](/Reaper-AutoColor/usage/colours/#gradients), using the start and end colours SWS was set to |
| Rule order | Preserved — it is the priority order on both sides |

## What does not

Some SWS features have no equivalent. Those rules are **still imported**, but they arrive
**switched off**, with the reason added to the rule's name, to make them findable in the list:

| In SWS | Why it does not come across |
|---|---|
| **Random** colours | No colour is ever assigned that a rule did not specify. |
| **Custom** (cycling REAPER's palette) | Same. |
| **Parent** colour | Covered differently, by [Folders](/Reaper-AutoColor/configuration/#folders) — one setting for the whole rule set instead of a per-rule colour. |
| **None** | There is no "clear the colour" rule; that is *Clear…* on the action bar, or [reset unmatched objects](/Reaper-AutoColor/usage/clearing/). |
| **Ignore** | See the warning below. |
| `(master)` | REAPER [ignores a custom colour on the master track](/Reaper-AutoColor/troubleshooting/#the-master-track-is-never-coloured), so this never did anything visible in SWS either. |
| `(record armed)`, `(audio input)`, `(audio output)`, `(MIDI output)`, `(vca master)` | No equivalent filter. |

Those rules keep the SWS keyword as their pattern, which matches nothing, so leaving them switched
off is harmless. They are worth reading before switching any on: a rule whose pattern is
`(record armed)` will not do what its name suggests.

:::caution[Ignore rules change more than themselves]
In SWS, an **Ignore** rule matched a track, left it alone, **and stopped every rule below it**. The
blocking is the part with no equivalent here, so the rules *underneath* an Ignore rule may now
colour tracks they never used to — the only one of these losses that affects anything beyond its own
rule.
:::

TCP/MCP layouts are read and discarded.

An icon rule does not lose what its colour lost: in SWS the two are decided separately, so an
**Ignore** or **Random** colour still leaves its icon rule switched on.

## Afterwards

Importing does not switch SWS off. Until it is, both are live colour engines fighting over the same
tracks, and each affected tab shows a warning while that holds. SWS's is switched off under
**SWS ▸ Auto Color/Icon/Layout**.

Worth checking before applying:

- Anything switched off carries its reason in its name.
- An SWS `(any)` catch-all matches *everything*. It lands below the existing rules, so those still
  win where they apply, but it claims every object they leave over — often more than intended.
- **Hits** in the rule list reports what each rule actually wins. See
  [Applying](/Reaper-AutoColor/usage/applying/).
