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
Globs are anchored to the whole name, so `bass` as a **glob** matches only a track named exactly
"bass". As **contains**, it matches "Sub Bass DI". A glob rule unexpectedly on 0 hits is almost
always this; wrap it in `*`.
:::

**Aa** on the row makes the comparison case-insensitive. On by default, since track names are
typed casually and a rule missing "Bass" because it was written `bass` is a poor default. Folding
is **ASCII only**: `Č` and `č` are not equated.

## Pattern Syntax

The Pattern tester at the foot of the window works a pattern out before it goes into a rule. It has
its own mode, pattern and subject, reports where the match landed and what each group captured, and
touches neither the rules nor the project.

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

Backreferences, lookaround and named groups are **not** supported. A pattern using them is rejected
with a message on the row, rather than misbehaving silently.

:::note[Non-ASCII names]
Byte classes accept non-ASCII, so `\w+` matches `Kytara_hlavní`. Only case *folding* is ASCII-only.
:::

:::caution[Patterns that are too slow]
A step budget cuts off a pathological pattern — `(a+)+$` and similar — to prevent it hanging
REAPER. The rule is flagged and treated as a no-match. Nested quantifiers are the usual cause.
:::

### Glob

A glob is anchored to the **whole** name. Four things are special:

| | Matches |
|---|---|
| `*` | any run of characters, including none |
| `?` | exactly one character, never none |
| `[abc]` | one character from the set. `[a-c]` is a range |
| `[!abc]` | one character not in the set. `[^abc]` does the same |

Every other character is literal, so `.`, `+`, `(` and `|` match themselves.

There is no escape character. A literal `*` or `?` goes in a class: `x[*]y` matches `x*y` and
nothing else. A `[` with no closing `]` is a literal `[`. A `]` inside a class must come first, as
in `[]x]`.

## Filters

A rule can carry one optional non-name filter that **narrows** what it matches.

| Filter | Applies to | Matches |
|---|---|---|
| **is a folder track** | tracks | a track that is the parent of a folder |
| **is inside a folder** | tracks | any track nested under a folder parent |
| **has no name** | all kinds | an object with an empty name |

The filter and the pattern combine with **and**: both must hold. An empty **pattern** matches on the
filter alone — an empty pattern with *is a folder track* means "every folder track", while `^Drums`
with the same filter means "folder tracks named Drums…".

A tab offers only the filters its kind can use, to prevent building a rule that never matches.

## A worked example

Rules on the **Tracks** tab, top to bottom:

| # | Name | Match | Pattern | Filter | Wins |
|---|---|---|---|---|---|
| 1 | Drum bus | regex | `^Drums$` | is a folder track | the folder parent only |
| 2 | Drums | regex | `^(kick\|snare\|hh)\b` | — | the drum tracks by name |
| 3 | Anything in a folder | contains | *(empty)* | is inside a folder | everything else nested |

Rule 3 has no pattern, so without the filter it would match every track. Sitting last, it gets only
what rules 1 and 2 did not claim. That is the normal shape: specific rules at the top, a catch-all
at the bottom.

## Where to go next

- [Colours and gradients](/Reaper-AutoColor/usage/colours/) — what a matching rule then paints.
- [Items](/Reaper-AutoColor/usage/colours/#items) — how an item takes a colour without a rule of its own.
