---
title: Importing from SWS
description: Move your SWS Auto Color rules across, and what does not survive the trip
---

If you already colour tracks with **SWS Auto Color**, you do not have to retype anything.
**Options ▸ Rules file ▸ Import SWS…** reads its rules and turns them into rules here.

The menu offers two things:

| | |
|---|---|
| **Add SWS rules to mine** | Appends them below your own rules. Nothing you already had changes meaning. |
| **Replace my rules with SWS's** | Clears every tab first, then fills it with SWS's rules. Asks before it does it. |

**Undo** takes either one back while the window is open, and nothing is applied to your project
until you press **Apply**.

## What it reads

`sws-autocoloricon.ini`, from your REAPER resource folder — *Options ▸ Show REAPER resource path*
in REAPER's own menu. You do not point it at anything, and if SWS has never been installed it says
so and changes nothing.

Gradient colours come from `reaper.ini`, which is where SWS keeps them. If it has none set, the
import uses SWS's own default of black to white.

Both files are only ever read. Nothing about your SWS setup is changed or removed.

## What comes across exactly

SWS matches on a **case-insensitive piece of the name**, and the first matching rule wins. Both are
exactly how this tool works, so an ordinary SWS rule arrives unchanged — same colour, same position
in the list, same behaviour.

| In SWS | Here |
|---|---|
| A name filter, e.g. `Kick` | A `contains` rule with the same text |
| `(any)` | A rule with no pattern and no filter |
| `(unnamed)`, `(folder)`, `(children)` | The equivalent [filters](/Reaper-AutoColor/usage/matching/#filters) |
| **Gradient** | A real [gradient](/Reaper-AutoColor/usage/colours/#gradients), using the start and end colours SWS was set to |
| Rule order | Preserved — it is the priority order on both sides |

## What does not

Some SWS features have no equivalent. Those rules are **still imported**, but they arrive
**switched off**, with the reason added to the rule's name so you can find them in the list:

| In SWS | Why it does not come across |
|---|---|
| **Random** colours | Nothing here assigns a colour you did not choose. |
| **Custom** (cycling REAPER's palette) | Same. |
| **Parent** colour | Covered differently, by [Folders](/Reaper-AutoColor/configuration/#folders) — one setting for the whole rule set instead of a per-rule colour. |
| **None** | There is no "clear the colour" rule. Use *Clear…* on the action bar, or [clear unmatched objects](/Reaper-AutoColor/usage/clearing/). |
| **Ignore** | See the warning below. |
| `(master)` | REAPER [ignores a custom colour on the master track](/Reaper-AutoColor/troubleshooting/#the-master-track-is-never-coloured), so this never did anything visible in SWS either. |
| `(record armed)`, `(instrument)`, `(audio input)`, `(audio output)`, `(MIDI input)`, `(MIDI output)`, `(receive)`, `(vca master)` | No equivalent filter — these test a track's routing or state, not its name. |

Those rules keep the SWS keyword as their pattern, which matches nothing, so leaving them switched
off is harmless. Read them before switching any on: a rule whose pattern is `(record armed)` will
not do what its name suggests.

:::caution[Ignore rules change more than themselves]
In SWS, an **Ignore** rule matched a track, left it alone, **and stopped every rule below it**. That
blocking is the part with no equivalent here — so the rules *underneath* an Ignore rule may now
colour tracks they never used to. It is the only one of these whose loss affects anything beyond
its own rule.
:::

Icons and TCP/MCP layouts are read and discarded — this tool only sets colours.

:::caution[Replace empties the Items tab]
SWS has no item rules, so there is nothing to refill that tab with. **Add SWS rules to mine**
appends below your own instead, leaving everything you already had — and its precedence — intact.
:::

## Afterwards

Importing does not switch SWS off, and until you do, both are live colour engines fighting over the
same tracks. The window warns you in a banner while that is true. Turn SWS's off under
**SWS ▸ Auto Color/Icon/Layout**.

Then check the imported rules before applying:

- Anything switched off is telling you something — read the reason in its name.
- An SWS `(any)` catch-all matches *everything*, and if it sits above your own rules it will win
  over all of them. Drag it down, or switch it off.
- **Hits** in the rule list tells you what each rule actually wins. See
  [Applying](/Reaper-AutoColor/usage/applying/).
