---
title: Installation
description: Install through ReaPack, or copy the folder in by hand
---

The easiest way is to use ReaPack.

```
https://github.com/michal-bartak/ReaPack/raw/main/index.xml
```

In REAPER
* open *Extensions → ReaPack → Import repositories* and paste that URL. 
* open *Extensions → ReaPack → Browse packages*, find **AutoColor** and install it.

ReaPack adds two actions to the Action List and dedicated [toolbar icons](#the-toolbar-icons):
* <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> `MXM_AutoColor_GUI.lua` - the configuration window
* <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> `MXM_AutoColor_AutoToggle.lua` - Start/stop background auto-colouring

:::note
Add these scripts to toolbar of your choice, assigning icons.

To quickly find actions or icons, search for `autocolor` or `mxm`.
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

In REAPER
* open *Actions → Show action list → New action → Load ReaScript*, and load at least the scripts listed above.
* add these actions to toolbar of choice, assigning provided icons
</details>

## The actions

All Scripts are located within `Scripts/MXM Scripts/MXM_AutoColor`.

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

Actions with an icon are comonly used by an end-user. These two are automatically added to Action List by ReaPack. Otherwise have to be added manually. Other scripts are called by the application or might be useful for debuging.


### The toolbar icons

The package comes with two toolbar icons designed to use with main scripts. 

| | Name | Action |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `mxm_toolbar_autocolor` | `MXM_AutoColor_AutoToggle.lua` |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `mxm_toolbar_autocolor_gui` | `MXM_AutoColor_GUI.lua` |

They are provided in 3 sizes, being located in `<resource path>/Data/toolbar_icons/`:

```
mxm_toolbar_autocolor.png            90x30
mxm_toolbar_autocolor_gui.png        90x30
150/mxm_toolbar_autocolor.png       135x45
150/mxm_toolbar_autocolor_gui.png   135x45
200/mxm_toolbar_autocolor.png       180x60
200/mxm_toolbar_autocolor_gui.png   180x60
```

## First run

Run `MXM_AutoColor_GUI.lua`. On the first run it writes a **starter rule set** so the window has
something to show, and tells you where:

```
<REAPER resource path>/MXM_AutoColor/config.json
```

That file is one global rule set shared by every project, and it sits **outside** `Scripts/` on
purpose: reinstalling or updating the scripts cannot destroy your rules. See
[Rules file](/Reaper-AutoColor/configuration/rules-file/).
