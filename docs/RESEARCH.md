# Research notes

External facts this project relies on, with where they came from. Recorded
because several were verified against source or the installed binaries rather
than documentation, and would be expensive to re-establish.

Verified against **REAPER 7.80** (macOS/arm64), **SWS 2.14.0 build 7**,
**ReaImGui 0.10.0.5**, in Sep 2026.

## Prior art

| Tool | Matching | Tracks | Items | Regions/markers |
|---|---|---|---|---|
| SWS Auto Color 2.14.0.7 | case-insensitive substring (`stristr`) | yes | **no** | yes |
| joshnt Auto-Color Items (Aug 2024) | Lua patterns, undocumented | no | yes | no |
| mpl "user defined filter" (2021) | rules hardcoded in source | folders only | no | no |
| nvk_THEME ($19) | `*` wildcards | yes | no | no |
| REAPER itself | — | — | — | — |

* SWS matching is two `stristr` call sites in `Color/Autocolor.cpp`; `*`, `?`,
  `.` and `[` are matched literally. Its only non-substring filters are a fixed
  keyword list (`(any)`, `(unnamed)`, `(folder)`, `(master)`, …) compared with
  `strcmp`.
* [SWS PR #1291](https://github.com/reaper-oss/sws/pull/1291) proposed
  `$`-prefixed regex; closed unmerged 27 Feb 2025. Blockers: C++11 `<regex>`
  unavailable on SWS's macOS 10.5 deployment target, and an invalid pattern
  could crash REAPER at startup and brick the install.
* [SWS issue #1868](https://github.com/reaper-oss/sws/issues/1868) asks for
  `only`/`not` so "bass" does not hit "bassoon"; open, no commitment.
* REAPER changelog 6.0 → 7.80: zero hits for `auto.?colo`.
* ReaPack indexes (ReaTeam Scripts, X-Raym, MPL, acendan, Joshnt): no
  rule-based colouriser. Every take-colour script is manual or random.

## SWS Auto Color's file format

Needed for the importer. Read out of `reaper_sws-arm64.dylib`'s string table and
the `reaper-oss/sws` sources (`Color/Autocolor.cpp`, `Color/Color.cpp`) plus
WDL's `projectcontext.cpp`, then checked against a real file. None of it is
documented anywhere.

Rules live in `<resource path>/sws-autocoloricon.ini`, in a single `[SWS]`
section — **not** in `S&M.ini`, and not in `reaper.ini` (SWS migrated them out
of `reaper.ini` and deletes the old keys on first run).

```ini
[SWS]
AutoColor 1=0 "(MIDI input)" 50331644 "" "" ""
AutoColor 2=0 (any) 0 "" "" ""
AutoColorCount=2
AutoColorEnable=0
AutoColorMarkerEnable=0
AutoColorRegionEnable=0
```

`AutoColorSaveState` writes each record with `"%d %s %d %s %s %s"`:

| token | meaning |
|---|---|
| 0 | type — `0` Track, `1` Marker, `2` Region. No item type; no master *type* (master is a filter) |
| 1 | filter — a name substring, or a bracketed keyword |
| 2 | colour, encoded as below |
| 3 | icon path, `""` for none |
| 4, 5 | TCP and MCP layout names; `(hide)` is magic |

* A **legacy three-token form** (`filter colour icon`, implicitly a track rule)
  is still accepted on read, and the **token count** is the only thing that
  distinguishes the two. A parser that skips empty tokens will read a modern
  record as a legacy one.
* **Order is priority order** — the `AutoColor n` index is the rank, and the
  dialog's Up/Down rewrites the whole numbered block. First match wins, and a
  track already coloured by an earlier rule is skipped.
* Icons and layouts have their own global switches (`AutoIconEnable`,
  `AutoLayoutEnable`) and are track-only.

### Quoting

Fields go through WDL's `makeEscapedConfigString`, whose `getConfigStringQuoteChar`
defaults to `prefer_quoteless = true`. So a value is written **bare** when it
contains no whitespace and does not begin with `"`, `'`, `` ` ``, `#` or `;` —
which is why `(any)` is bare while `"(MIDI input)"` is quoted. Empty becomes
`""`. A value containing `"` is wrapped in `'`, then `` ` ``; if it contains all
three, the backticks inside are rewritten to `'`. There are **no backslash
escapes** — the writer picks a quote character the value does not contain rather
than escaping one it does, so a reader has nothing to unescape.

SWS reads it back with `LineParser lp(false)`, so a `;` or `#` *at the start of
a token* begins a comment to end of line. `a;b` is one token.

### Colours

`ImportColor` / `ExportColor` in `Color/Color.cpp`, with
`constexpr int PORTABLE_FLAG = 0x2000000`:

| stored | meaning |
|---|---|
| `< 0` | a sentinel, `-1 - index` into `{ CUSTOM, GRADIENT, RANDOM, NONE, PARENT, IGNORE }` |
| `== 0` | **black** — not "no colour" |
| `& 0x2000000` | portable `0xRRGGBB`; the colour is `n & 0xFFFFFF` (`0x1000000` is REAPER's enable bit) |
| `> 0`, no flag | written before the format was portable, so it is in the **byte order of whichever machine wrote it** |

That last row cannot be made correct across platforms: nothing in the file
records which order it is in. SWS decodes it through its own
`SWS_ColorFromNative`, which is a no-op off Windows, so an importer that routes
it through the host's `ColorFromNative` inherits SWS's limitation rather than
inventing a different one.

So: `50331644` = `0x2FFFFFC` = portable, enable bit set, colour `0xFFFFFC`.

The six sentinels, by number: `-1` Custom (cycles REAPER's 16 palette swatches),
`-2` Gradient, `-3` Random (once — skipped if the track is already coloured),
`-4` None (clears), `-5` Parent (copies `P_PARTRACK`'s colour, only if the parent
has one), `-6` Ignore (matches, leaves the object alone, and **blocks
lower-priority rules**).

**Gradient's endpoints are not in this file.** They live in `reaper.ini`, under
`[SWS]`, key `ColorGradients=<start> <end>`, both through the same decode. The
key is absent on a default install and SWS's own fallback is `"0 16777215"` —
black to white — so that is the common path, not the exception.

### Filter keywords

Compared with `strcmp`, so the match is exact and case-sensitive: `(ANY)` is a
literal substring filter, not a keyword.

* Tracks: `(any)` `(unnamed)` `(folder)` `(children)` `(receive)` `(master)`
  `(record armed)` `(vca master)` `(instrument)` `(audio input)`
  `(audio output)` `(MIDI input)` `(MIDI output)`
* Markers and regions: `(any)` and `(unnamed)` only.

In SWS a keyword **replaces** the name filter. Here a predicate **narrows** one,
which is why the importer maps a keyword to an empty pattern plus a predicate.

## PCRE is not usable from ReaScript

[Mavriq Lua Batteries](https://github.com/mavriq-dev/mavriq-lua-batteries) is
the only route to `lrexlib`. It ships `lua53.dylib` while REAPER 7 uses Lua 5.4,
is still a release candidate from May 2023, and has an open unanswered issue:
*hard crash when requiring a module on M4 Mac* (Jun 2025).

Pure-Lua alternatives: [reLua](https://github.com/o080o/reLua) is active but has
no anchors, no `{n,m}`, and is implicitly anchored at both ends.
`jsdotlua/LEGACY-regex-lua` was archived Aug 2023.

## REAPER preferences that affect what you see

**Preferences → Appearance → Peaks/Waveforms**, under *"Extra peaks display
options — many themes including the default override these"*:

```
Tint media item waveform peaks to:   [Track color] [Item color] [Take color]
Tint media item background to:       [Track color] [Item color] [Take color]
```

Precedence is **take > item > track**. REAPER's own tooltip: *"Custom take
colors override custom item colors, which override custom track colors."* Stored
in `reaper.ini` as `tinttcp`; the key is absent until changed.

**Preferences → Appearance → Media**:

```
Automatically color any recording pass that adds takes or lanes
```

Tooltip: *"When recording, automatically apply the same random color to all
takes created in the same recording pass, or all media items in the same fixed
lane."* This is the usual source of custom take colours nobody remembers
setting.

## Take colours

* The only recurring use case in the wild is **comping** — making each recording
  pass visually distinct. REAPER covers it natively, keyed off the *recording
  pass*, which a name matcher cannot see.
* For keepers vs rejects REAPER has take **ranking** (`Item: Up-rank active take
  or last recording pass`, down-rank, delete-by-rank), not colour.
* Take names come from the recorded filename, whose default pattern is
  track-derived (`$tracknumber-$track`, or with a timestamp). Renaming a track
  does **not** retro-rename existing takes.
* REAPER 7 comping uses fixed **item lanes**, not takes, so the modern version
  of that workflow is an item-colouring problem.
* Claimed-but-unfound uses: colouring by mic/DI/amp source, by session, by
  performer. Those are track-level concerns and people solve them with tracks.

`GetDisplayedMediaItemColor2(item, take)` resolves the whole track/item/take
cascade *according to the `tinttcp` preference* — it answers "what will the user
actually see", not "what is set". Zero means no colour, not black.

## ReaImGui 0.10 facts

* The repo moved to [codeberg.org/cfillion/reaimgui](https://codeberg.org/cfillion/reaimgui);
  the GitHub mirror was archived 3 Jun 2026. Same for ReaPack.
* Use the shim: `package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'` then
  `require 'imgui' '0.10'`. It version-guards and gives typo protection.
* `ImGui.End(ctx)` is called **only** if `Begin` returned true — a deliberate
  deviation from C++ Dear ImGui. Same for `BeginChild`/`EndChild`.
* There is **no `DestroyContext`** in 0.10; you close by not re-deferring.
* `CreateFont(family, flags)` takes **no size**; size is given at
  `PushFont(ctx, font, size)`, in logical pixels at 96 DPI. `Attach` is no
  longer required before use.
* DPI is automatic. All coordinates are logical units and glyphs rasterise at
  device resolution. `GetWindowDpiScale` returns 2.0 on Retina and is
  informational — multiplying by it double-scales the UI.
* There is no style preset API (`StyleColorsDark/Light`) and no `SetStyleColor`;
  only `GetStyleColor` and push/pop. ReaImGui does not follow REAPER's theme.
* **Popup visibility is ImGui's, not yours, and cannot be pinned.** The doc says
  so outright (line 1496: "Their visibility state is held internally instead of
  being held by the programmer … popups may be closed at any time") and names a
  click outside and Escape (1494, 1530); losing focus does it too, which the doc
  does not mention. The complete `PopupFlags_*` (1539-1562), `WindowFlags_*`
  (2779-2838), `FocusedFlags_*` (2914-2927), `ConfigFlags_*` (335-347) and
  `ConfigVar_*` (377-444) sets contain no switch for any of it. Hold the flag
  yourself and re-`OpenPopup` from it each frame; `PopupFlags_NoReopen` (1560)
  makes that free of repositioning. **But it is not enough** — ImGui does not
  redraw a re-opened popup for several frames, which is visible as a blink, and
  that gap is not reachable from a script. A dialog that must not vanish has to
  be a `Begin` window with `WindowFlags_TopMost`. See DECISIONS, "Bugs worth
  remembering".

The full API reference ships locally with the extension:
`<resource path>/Data/reaper_imgui_doc.html`.

## ReaScript colour API

* `ColorToNative(r,g,b)` / `ColorFromNative(col)`. Native layout is OS
  dependent — RGB on macOS, BGR on Windows — so **persist plain `0xRRGGBB`** and
  convert only at the API boundary.
* The `|0x1000000` "enabled" bit is required on `I_CUSTOMCOLOR` for tracks,
  items and takes. Without it the colour is *stored but not used*. Setting 0
  clears.
* Markers/regions: `EnumProjectMarkers3` to read, `SetProjectMarker4` to write.
  `SetProjectMarker4` treats `color = 0` as **leave unchanged**, so it cannot
  clear — clearing needs `SetRegionOrMarkerInfo_Value` (REAPER 7.62+), guarded
  with `APIExists`.
* `GetSetMediaTrackInfo_String(tr, 'P_NAME', …)` returns **false** on the master
  track. Media items have no `P_NAME` at all; match the active take.
* `UNDO_STATE_*` are `reaper_plugin.h` defines, not exposed to Lua:
  `TRACKCFG=1`, `ITEMS=4`, `MISCCFG=8` (markers and regions live under MISCCFG).
  `UNDO_STATE_ALL` forces a full project snapshot and is slow.
* `SetProjExtState` / `GetProjExtState` — not `SetProjectExtState`.
* ExtState values **must not contain newlines**; documented.

## Transport state

`GetPlayState()` is a bitmask: `1` playing, `2` paused, `4` recording. The bits
combine, and **record-pause keeps bit 4 set** — measured in REAPER 7.80 with a
defer probe watching every transition:

```
state  &1  &2  &4   reading
5      1   0   1    play+record
6      0   1   1    pause+record
```

That is why `autoloop.lua` guards with `GetPlayState() & 4 ~= 0` rather than
testing equality: one test holds the background loop for the whole of a take,
armed-and-rolling or armed-and-paused, and never fights the transport.
