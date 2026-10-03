---
title: Installation
description: Install through ReaPack, or copy the folder in by hand
---

ReaPack is the simplest route.

```
https://github.com/michal-bartak/ReaPack/raw/main/index.xml
```

In REAPER:
* *Extensions → ReaPack → Import repositories*, and paste that URL.
* *Extensions → ReaPack → Browse packages*, find **AutoColor**, install.

ReaPack adds two actions to the Action List and dedicated [toolbar icons](#the-toolbar-icons):
* <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> `MXM_AutoColor_GUI.lua` - the configuration window
* <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> `MXM_AutoColor_AutoToggle.lua` - Start/stop background auto-colouring

:::note
Both can be added to any toolbar with the icons supplied. Search `autocolor` or `mxm` to find the
actions and the icons.
:::

<details>
<summary>Manual installation steps</summary>

1. Open *Options → Show REAPER resource path in explorer/finder*. Everything below goes into that
   folder:

   | OS | Resource path |
   |----|------|
   | macOS | `~/Library/Application Support/REAPER/` |
   | Windows | `%AppData%\REAPER\` |
   | Linux | `~/.config/REAPER/` |

1. Copy the **contents** of `Reaper/` over it, merging with what is already there:

   ```
   Reaper/Scripts/MXM_AutoColor/  ->  <resource path>/Scripts/MXM_AutoColor/
   Reaper/Data/toolbar_icons/         ->  <resource path>/Data/toolbar_icons/
   ```

   The scripts and the [toolbar icons](#the-toolbar-icons) land in the right places together.

In REAPER:
* *Actions → Show action list → New action → Load ReaScript*, and load at least the two scripts
  listed above.
* Add them to a toolbar, with the icons supplied.
</details>

## The actions

Installed in `Scripts/MXM Scripts/MXM_AutoColor`.

| | Script | What it does |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `MXM_AutoColor_GUI.lua` | The configuration window |
| | `MXM_AutoColor_ApplyAll.lua` | Colour the whole project, one undo point |
| | `MXM_AutoColor_ApplySelection.lua` | Colour the selected tracks and items |
| | `MXM_AutoColor_ClearColors.lua` | Reset colours to the theme default |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `MXM_AutoColor_AutoToggle.lua` | Start/stop background auto-colouring |
| | `MXM_AutoColor_WhyThisColour.lua` | Explain the colour on the selected track or item |
| | `MXM_AutoColor_Dump.lua` | Read-only diagnostic listing |
| | `MXM_AutoColor_RunTests.lua` | Self-test, prints to the ReaScript console |

The two with an icon are the everyday ones, and ReaPack registers them in the Action List
automatically; a manual install registers them by hand. The rest are called internally or serve
diagnostics.


### The toolbar icons

Two toolbar icons ship with the package, for the two main scripts.

| | Name | Action |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `mxm_toolbar_autocolor` | `MXM_AutoColor_AutoToggle.lua` |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `mxm_toolbar_autocolor_gui` | `MXM_AutoColor_GUI.lua` |

Three sizes each, in `<resource path>/Data/toolbar_icons/`:

```
mxm_toolbar_autocolor.png            90x30
mxm_toolbar_autocolor_gui.png        90x30
150/mxm_toolbar_autocolor.png       135x45
150/mxm_toolbar_autocolor_gui.png   135x45
200/mxm_toolbar_autocolor.png       180x60
200/mxm_toolbar_autocolor_gui.png   180x60
```

## First run

Run `MXM_AutoColor_GUI.lua`. The first run writes a **starter rule set**, so the window opens with
something in it, and reports the location:

```
<REAPER resource path>/MXM_AutoColor/config.json
```

One global rule set, shared by every project, stored **outside** `Scripts/` to prevent
reinstalling or updating from overwriting it. See
[Config file](/Reaper-AutoColor/configuration/config-file/).
