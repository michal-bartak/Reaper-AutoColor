---
title: Matching names
description: contains, glob and regex, the supported syntax, and the non-name filters
---

Every rule tests one thing: the object's **name**. The **Match** mode decides how.

| Mode | Matches | Example |
|---|---|---|
| **contains** | anywhere in the name; nothing is interpreted | `bass` matches "Sub Bass DI" |
| **glob** | the **whole** name — see [Glob](#glob) | `*bass*`, `Gtr_?`, `[Bb]ass*` |
| **regex** | anywhere, unless anchored | `^(kick\|snare\|hh)\b` |

:::caution[contains and glob are not the same thing]
Globs are anchored to the whole name, so `bass` as a **glob** matches only a track named exactly "bass". As **contains**, it matches "Sub Bass DI". A glob rule unexpectedly on 0 hits is almost always this; wrap it in `*`.
:::

**Aa** on the row makes the comparison case-insensitive, on by default. It covers **ASCII only**: `Č` and `č` are not equated.

## Pattern Syntax

:::note
You can test patterns before they goes into rules with the **Pattern tester**.
:::

### Regex

```
.                           any character except newline (one whole UTF-8 character)
( )  (?: )                  capturing / non-capturing group
|                           alternation
* + ? {n} {n,} {n,m}        greedy; add ? for lazy (*? +? ??)
[abc] [^abc] [a-z] [0-9]    character classes
\d \D \w \W \s \S           digit / word / space classes
\b \B                       word boundary
^ $                         start / end of the name
\n \t \r \xHH               escapes
(?i)                        case-insensitive, at the very start only
```

Backreferences, lookaround and named groups are **not** supported. A pattern using them is rejected with a message on the row.

:::note[Non-ASCII names]
Byte classes accept non-ASCII, so `\w+` matches `Kytara_hlavní`. Only case *folding* is ASCII-only.
:::

:::caution[Patterns that are too slow]
A pattern that takes too long — `(a+)+$` and similar — is stopped, to prevent REAPER from hanging. The rule is flagged and treated as a no-match. Nested quantifiers are the usual cause.
:::

### Glob

A glob is anchored to the **whole** name. Four things are special:

| | Matches |
|---|---|
| `*` | any run of characters, including none |
| `?` | exactly one character, never none |
| `[abc]` | one character from the set. `[a-c]` is a range |
| `[!abc]` | one character not in the set. `[^abc]` does the same |

All other characters match themselves, so a name like `Gtr.1 (DI)` needs no special treatment.

To match a special character itself, put it in brackets:

| To match | Write | Example |
|---|---|---|
| `*` | `[*]` | `x[*]y` matches `x*y` only |
| `?` | `[?]` | `Take[?]` matches `Take?` only |
| `[` | `[[]` | `[[]1]` matches `[1]` |
| `]` in a set | `]` first | `[]x]` matches `]` or `x` |

## Filters

A rule can carry one optional non-name filter that **narrows** what it matches.

| Filter | Applies to | Matches |
|---|---|---|
| **is a folder track** | tracks, icons | a track that is the parent of a folder |
| **is inside a folder** | tracks, icons | any track nested under a folder parent |
| **has an instrument** | tracks, icons | a track with an instrument plugin in its FX chain, as REAPER classes it |
| **has a MIDI input** | tracks, icons | a track whose record input is MIDI |
| **has receives** | tracks, icons | a track with at least one receive, such as a bus or a return |
| **has no name** | all types | an object with an empty name |

The filter and the pattern combine with **and**: both must hold. An empty **pattern** matches on the filter alone — an empty pattern with *is a folder track* means "every folder track", while `^Drums` with the same filter means "folder tracks named Drums…".

A tab offers only the filters its object type can use.

## A worked example

Rules on the **Tracks** tab, top to bottom:

| # | Name | Match | Pattern | Filter | Wins |
|---|---|---|---|---|---|
| 1 | Drum bus | regex | `^Drums$` | is a folder track | the folder parent only |
| 2 | Drums | regex | `^(kick\|snare\|hh)\b` | — | the drum tracks by name |
| 3 | Anything in a folder | contains | *(empty)* | is inside a folder | everything else nested |

Rule 3 has no pattern, so without the filter it would match every track. Sitting last, it gets only what rules 1 and 2 did not claim. That is the normal shape: specific rules at the top, a catch-all at the bottom.

## Where to go next

- [Colours and gradients](/Reaper-AutoColor/usage/colours/) — what a matching rule then paints.
- [Items](/Reaper-AutoColor/usage/colours/#items) — how an item takes a colour without a rule of its own.
