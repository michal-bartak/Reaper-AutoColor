---
title: Matching names
description: How a rule decides which tracks, items, regions and markers it colours — the contains, glob and regex match modes, case, and filters
---

AutoColor decides what to colour by reading names. A rule looks at the name of each track, item, region or marker, and colours the ones whose names fit its pattern. This page explains how that comparison works, how to choose between the three ways of writing a pattern, and how a filter can restrict a rule further.

In this documentation, *object* is the general word for a track, an item, a region or a marker.

## Rules and matching

A rule is one row in the configuration window. The window has one tab per object type: **Tracks**, **Items**, **Regions** and **Markers**, plus **Icons**, whose rules match tracks and set their icons. The rules on a tab apply only to that tab's object type.

Each rule has a **Pattern**: the text it looks for. When an object's name fits the pattern, the rule *matches* that object. The **Match** column chooses the *match mode*, which decides what "fits" means. The three match modes are described in the next section.

The name that AutoColor reads depends on the object type:

- For a track, a region or a marker, it is the object's own name.
- For an item, it is the name of the item's active take. An item without a take has an empty name.

The rules on a tab are checked from top to bottom. The first rule that matches an object is the rule that colours it. Rules further down the list do not affect that object, even if they also match it. To give a rule priority over another, move it higher in the list.

### The Hits column

The **Hits** column of a rule counts the objects that this rule colours, which means the objects for which this rule is the first match. An object that also matches a rule higher in the list is coloured by that higher rule, and is not counted here.

When other objects match this rule but a higher rule colours them, their number is shown after the count, for example `12  +3`. To let this rule colour those objects, move it above the other rule.

The column can also show:

- `err`: the pattern is invalid, and the rule is skipped.
- `!` before the count: the pattern took too long to test on some names.

Both are described in [Invalid, unsupported and slow patterns](#invalid-unsupported-and-slow-patterns).

:::tip[Hits shows 0, but the objects are still coloured]
An object can be coloured without any rule on its tab matching it. An item can take the colour of its track, when the track's rule has **Items** switched on. A track can take the colour of its folder track. Such objects appear in *Objects preview*, but they are not counted in **Hits**.
:::

## Match modes

The default match mode for a new rule is **contains**. The other two modes, **glob** and **regex**, let a pattern describe names more precisely.

| Mode | Where the pattern must fit | Special characters | Example |
|---|---|---|---|
| **contains** *(default)* | Anywhere in the name | None | `bass` matches `Sub Bass DI` |
| **glob** | The entire name | `*`, `?` and `[ ]` | `*bass*` matches `Sub Bass DI` |
| **regex** | Anywhere in the name, unless the pattern uses `^` or `$` | The regular expression syntax listed below | `^(kick\|snare\|hh)\b` matches `Kick In` |

The examples on this page assume that **Aa** is switched on, which is the default. **Aa** makes the comparison ignore upper and lower case; see [Upper and lower case](#upper-and-lower-case).

### contains

A **contains** pattern matches when the pattern appears anywhere in the name. Every character in the pattern is taken literally, so dots, brackets and asterisks need no special treatment.

`bass` matches `Bass DI`, `Sub Bass` and `Bassoon`. The last example shows that **contains** does not look for whole words: any name with the letters `bass` in sequence matches.

### glob

A **glob** pattern describes the entire name, from its first character to its last. Wildcard characters stand for the parts of the name that can vary.

`bass` matches only a track whose entire name is `bass`. `*bass*` matches track names containing `bass`, such as `Sub Bass DI`. `bass*` matches names that start with `bass`, such as `Bass DI`, but not `Sub Bass`.

Four forms have a special meaning in a glob pattern:

| Wildcard | Matches | Example |
|---|---|---|
| `*` | Any sequence of characters, including no characters | `Gtr*` matches `Gtr`, `Gtr L` and `Gtr_DI` |
| `?` | Exactly one character | `Gtr_?` matches `Gtr_1` and `Gtr_L`, but not `Gtr_` or `Gtr_12` |
| `[abc]` | One character from the set in brackets. `[a-c]` is a range. | `[Bb]ass*` matches `Bass DI` and `bass` |
| `[!abc]` | One character that is not in the set. `[^abc]` does the same. | `Take[!0-9]` matches `TakeA`, but not `Take1` |

Every other character matches itself. A name such as `Gtr.1 (DI)` can be written into a glob pattern exactly as it is.

To match one of the wildcard characters literally, put it in square brackets:

| To match | Write | Example |
|---|---|---|
| `*` | `[*]` | `x[*]y` matches `x*y` only |
| `?` | `[?]` | `Take[?]` matches `Take?` only |
| `[` | `[[]` | `[[]1]` matches `[1]` |
| `]` inside a set | `]` as the first character of the set | `[]x]` matches `]` or `x` |

A `[` that has no closing `]` later in the pattern matches itself.

:::caution[contains and glob treat the same pattern differently]
If a glob rule matches no tracks, check whether the pattern describes the entire track name. As a **glob** pattern, `bass` matches only a track named `bass`. As a **contains** pattern, `bass` also matches `Sub Bass DI`. To make a glob pattern match names that contain `bass`, add `*` at both ends: `*bass*`.
:::

### regex

A regular expression, or *regex*, is a widely used notation for describing text. AutoColor supports the subset of regex syntax listed in [Regex syntax](#regex-syntax).

A regex matches when it fits any part of the name. Two characters tie the pattern to the ends of the name:

- `^` at the start of the pattern requires the match to begin at the first character of the name.
- `$` at the end of the pattern requires the match to end at the last character of the name.

With both, the pattern must describe the entire name. Examples:

- `kick` matches `Kick In` and also `Sidekick`, because `kick` appears in both names.
- `^kick` matches `Kick In`, but not `Sidekick`, because `Sidekick` does not start with `kick`.
- `^Drums$` matches only a name that is exactly `Drums`.
- `^(kick|snare|hh)\b` matches names that start with the word `kick`, `snare` or `hh`, such as `Kick In`, `Snare Top` and `hh open`. It does not match `hhat`, because `\b` requires the word to end after `hh`.

#### Regex syntax

```
.                           any one character, except a newline
( )  (?: )                  capturing group / non-capturing group
|                           alternative: a|b matches a or b
* + ?                       0 or more / 1 or more / 0 or 1 of the preceding item
{n} {n,} {n,m}              exactly n / at least n / n to m of the preceding item (n and m up to 255)
*? +? ?? {n,m}?             the same, matching as few characters as possible
[abc] [^abc] [a-z] [0-9]    one character from a set / not from a set / from a range
\d \D                       a digit / not a digit
\w \W                       a word character (letter, digit, _) / not a word character
\s \S                       a whitespace character / not a whitespace character
\b \B                       a word boundary / not a word boundary
^ $                         start of the name / end of the name
\n \t \r \f \v \0 \xHH      newline, tab, other control characters, a character by hex code
\. \* \( \\  and similar    the punctuation character itself
(?i)                        ignore case; allowed only at the very start of the pattern
```

Regex features that are not in this list are not supported. See [Invalid, unsupported and slow patterns](#invalid-unsupported-and-slow-patterns).

## Upper and lower case

The **Aa** checkbox on a rule makes its comparison ignore upper and lower case. **Aa** is switched on for new rules. With **Aa** on, `bass` matches `Bass` and `BASS`. With **Aa** off, `bass` matches only `bass` written in lower case.

In a regex, `(?i)` at the very start of the pattern also ignores case, regardless of the **Aa** setting.

Ignoring case works for the letters A to Z only. See [Non-ASCII characters](#non-ascii-characters).

## Non-ASCII characters

Names can contain letters outside the ASCII range, such as `č` or `í`. AutoColor handles them as follows:

- **Case.** Ignoring case, with **Aa** or `(?i)`, works for the letters A to Z only. `Č` and `č` count as different letters even when **Aa** is on.
- **Single characters.** In a regex, `.` matches one whole character, including a non-ASCII character such as `í`. In a glob pattern, `?` does the same.
- **Word characters.** In a regex, `\w` treats every non-ASCII character as a word character, so `\w+` matches all of `Kytara_hlavní`.
- **Square brackets.** Inside `[ ]`, use only ASCII characters. A non-ASCII letter in brackets, such as `[čć]`, does not reliably match that letter, in regex or in glob. To match one of several non-ASCII letters, list them as regex alternatives instead: `(č|ć)`.

## Testing a pattern

The **Pattern tester**, below the rule list in the configuration window, lets you try out a pattern before you put it into a rule. Nothing you enter in the tester changes a rule or the project.

To use the tester:

1. Choose a match mode: **contains**, **glob** or **regex**.
1. Type a pattern.
1. Type a name to test the pattern against.

The tester shows whether the name matches, and highlights the part of the name that matched. For a regex with groups, it also lists the text that each group captured. For an invalid pattern, it shows the error and its position in the pattern.

The tester has no **Aa** checkbox and always compares case-sensitively. To test a regex that ignores case, start the pattern with `(?i)`.

## Invalid, unsupported and slow patterns

AutoColor cannot use every pattern you type. This section describes the three kinds of problem pattern, what the window shows for each, and how to fix them.

### Invalid patterns

A glob or regex pattern is invalid when it breaks the syntax. For example, the regex `(kick` is invalid because the bracket is never closed.

### Unsupported regex features

A regex that uses a feature outside the [Regex syntax](#regex-syntax) list is also invalid. The following features are not supported:

- backreferences, such as `\1`;
- lookahead and lookbehind, such as `(?=...)` and `(?<=...)`;
- named groups;
- flags other than a leading `(?i)`.

### What the window shows for an invalid pattern

- The **Pattern** cell turns red. Its tooltip describes the error and the position of the character where it was found.
- The **Hits** column shows `err`.
- AutoColor ignores the rule until the pattern is fixed.

### Slow patterns

A regex can be valid but too slow. Some patterns require a very large amount of work to test against certain names. Repetition nested inside repetition, such as `(a+)+$`, can cause this. To prevent REAPER from freezing, AutoColor stops testing a pattern after a fixed amount of work.

When AutoColor stops testing a pattern:

- the name is treated as not matching;
- the **Hits** column shows `!` before the count, for example `!0`, and its tooltip says *This pattern is too slow and timed out*;
- in the **Pattern tester**, the result reads "Gave up: this pattern is too slow".

To fix a slow pattern, simplify it. Avoid a repeated group that itself contains a repetition.

## Filters

A filter is an extra condition on a rule that does not depend on the name. Filters let a rule select tracks by their role in the project: for example, every folder track, or every track with an instrument.

A rule can have one filter, chosen in the **Filter** column. The default is no filter.

| Filter | Available on | Matches |
|---|---|---|
| **is a folder track** | Tracks, Icons | A track that opens a folder, at any level of nesting |
| **is inside a folder** | Tracks, Icons | A track inside a folder, at any depth. This includes the folder track of a subfolder, but not a folder track at the top level. |
| **has an instrument** | Tracks, Icons | A track whose FX chain contains a plugin that REAPER classes as an instrument |
| **has a MIDI input** | Tracks, Icons | A track whose record input is set to a MIDI input |
| **has receives** | Tracks, Icons | A track that receives audio or MIDI from at least one other track, such as a bus or an effects return |
| **has no name** | All tabs | An object with an empty name |

A tab offers only the filters that its object type can use.

A rule with a filter matches an object only when both conditions are true: the name fits the pattern, and the object meets the filter's condition. A filter therefore narrows what the pattern matches; it never adds to it.

A rule with an empty pattern matches every name, so its filter alone decides what it matches. For example:

- An empty pattern with **is a folder track** matches every folder track.
- The regex `^Drums` with **is a folder track** matches only folder tracks whose names start with `Drums`.

The window shows a warning below the rule list when the selected rule has one of these problems:

- The rule has an empty pattern and no filter. It matches every object on its tab.
- The rule has the **has no name** filter and a pattern. An object without a name has nothing for the pattern to match, so the rule never matches.

## Example: colouring a drum folder

The following rules are on the **Tracks** tab, in this order:

| # | Name | Match | Pattern | Filter |
|---|---|---|---|---|
| 1 | Drum bus | regex | `^Drums$` | is a folder track |
| 2 | Drums | regex | `^(kick\|snare\|hh)\b` | — |
| 3 | Anything in a folder | contains | *(empty)* | is inside a folder |

- Rule 1 matches only a folder track named exactly `Drums`.
- Rule 2 matches tracks whose names start with the word `kick`, `snare` or `hh`, such as `Kick In` or `Snare Top`.
- Rule 3 has an empty pattern, so it matches every track inside a folder.

Because rule 3 is last, it colours only the tracks inside folders that rules 1 and 2 have not already matched. Without its filter, rule 3 would match every track in the project. This arrangement is useful in general: put specific rules at the top of the list, and a broad rule at the bottom to colour the objects that the specific rules do not match.

## Where to go next

- [Colours and gradients](/Reaper-AutoColor/usage/colours/) — what colour a rule gives to the objects it matches.
- [Items and their track's colour](/Reaper-AutoColor/usage/items/#items-and-their-tracks-colour) — how an item can take its track's colour without a rule of its own.
