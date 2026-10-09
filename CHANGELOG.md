# Changelog

All notable changes to AutoColor. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow ReaPack, where a letter suffix (`1.1.0beta2`) marks a pre-release.

> **Feeds releases:** the section matching the manifest `Version` is extracted by
> [`.github/workflows/release.yml`](.github/workflows/release.yml) into the GitHub release
> description. Keep `[Unreleased]` current; at release time rename it to `## [X.Y.Z] - YYYY-MM-DD`.
> The ReaPack changelog lives separately, in the `Changelog:` block of
> [`Color/MXM_AutoColor.lua`](Color/MXM_AutoColor.lua).

## [Unreleased]

## [1.1.0beta2] - 2026-10-09

### Added

- **Children per track rule** — off, fill or force, as on icon rules; the default follows Options > Folders.
- **Autostart** — auto-colouring can start with REAPER (Options > Startup).

### Changed

- **Requires REAPER 7.03 or later.**
- **Items column renamed to FI** (force item colour) — items show their track colour without it.
- **Minor layout changes** — Options wording, wider filter column.

### Fixed

- **Toolbar buttons** toggle without the "already running" prompt.

Config file bumped to version 4. Earlier versions of AutoColor open it in read-only mode.

## [1.1.0beta1] - 2026-09-23

### Added

- **Track icons** — set from track names, with their own rule list.
- **New track filters** — has an instrument, has a MIDI input, has receives.
- **SWS import** — rules imported from SWS Auto Color.

### Changed

- **Minor layout changes.**

Config file bumped to version 3. Earlier versions of AutoColor open it in read-only mode.

## [1.0.0] - 2026-09-21

First public release.

### Added

- **Colour by name** — tracks, items, regions and markers, matched by substring, glob or regular expression.
- **One rule list per object type** — the first matching rule wins.
- **Configuration stored outside the scripts location**, to prevent overwriting on update.
- **Configuration window** — requires ReaImGui 0.10+.

Upgrading from 0.9.x: scripts moved to `Scripts/MXM Scripts/MXM_AutoColor/`. ReaPack relocates
the files; toolbar buttons, shortcuts and custom actions bound to the old path must be repointed.

## [0.9.1] - 2026-09-20

### Added

- **About dialog** — version, links, author, licence.
- **"Example rules" and "Remove Rules" buttons.**

### Changed

- **Text size** capped at 20, applied on slider release.

### Fixed

- **Options dialog** stays open when REAPER loses focus, without flicker.
- **Pattern tester** layout.

## [0.9.0] - 2026-09-19

Initial ReaPack release.
