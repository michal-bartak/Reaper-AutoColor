---
title: Installation
description: Install AutoColor through ReaPack, or copy the files in by hand
---

AutoColor can be installed in two ways. The recommended way is through ReaPack, REAPER's package manager, which also installs updates. Alternatively, you can copy the files into REAPER's resource folder by hand.

Before installing, check the [requirements](/Reaper-AutoColor/requirements/).

Instalation installs:
* scripts
* toolbar icons

After installation, add scripts onto toolbar of choice, assigning provided icons.

## Installing through ReaPack

AutoColor is published in the following ReaPack repository:

```
https://github.com/michal-bartak/ReaPack/raw/main/index.xml
```

In REAPER:

1. Open *Extensions → ReaPack → Import repositories*, paste the URL above, and confirm.
1. Open *Extensions → ReaPack → Browse packages*, find **AutoColor**, and install it.

ReaPack:
* installs scripts into `<resource folder>/Scripts/MXM Scripts/MXM_AutoColor/`
* installs [toolbar icon](#the-toolbar-icons) into `<resource folder>/Data/toolbar_icons/`
* adds two actions to the Action List

Add scripts to toolbar of choice assigning provided icons:
- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> `MXM_AutoColor_GUI.lua` opens the configuration window.
- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> `MXM_AutoColor_AutoToggle.lua` switches [auto-apply](/Reaper-AutoColor/usage/auto-apply/) on and off.


:::note
To find these actions in the Action List, search for `autocolor` or `mxm`. The toolbar icons can be found with the same search terms.
:::

<details>
<summary>Manual installation steps</summary>

1. Open the [REAPER resource folder](#the-reaper-resource-folder).

1. Download `MXM_AutoColor-<version>.zip` from the [GitHub releases page](https://github.com/michal-bartak/Reaper-AutoColor/releases).

1. Unpack the zip file into the resource folder. The zip file contains a `Scripts/` folder and a `Data/` folder. Merge them with the folders that already exist in the resource folder; do not replace them:

   ```
   Scripts/MXM_AutoColor/  ->  <resource folder>/Scripts/MXM_AutoColor/
   Data/toolbar_icons/     ->  <resource folder>/Data/toolbar_icons/
   ```

1. In REAPER, open *Actions → Show action list*, click *New action → Load ReaScript*, and load `MXM_AutoColor_GUI.lua` and `MXM_AutoColor_AutoToggle.lua` from `Scripts/MXM_AutoColor/`.
1. Add scripts to toolbar of choice assigning provided icons:
- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> `MXM_AutoColor_GUI.lua` opens the configuration window.
- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> `MXM_AutoColor_AutoToggle.lua` switches [auto-apply](/Reaper-AutoColor/usage/auto-apply/) on and off.

</details>

## The actions

While ReaPack adds only two scrips to Actions list (marked below with an icon) the AutoColor consists of more of them.

| | Script | What it does |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `MXM_AutoColor_GUI.lua` | Opens the configuration window. |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `MXM_AutoColor_AutoToggle.lua` | Switches auto-apply on and off. |
| | `MXM_AutoColor_ApplyAll.lua` | Colours the whole project according to the rules, like **Apply now**. |
| | `MXM_AutoColor_ApplySelection.lua` | Colours the selected tracks and items according to the rules. |
| | `MXM_AutoColor_ClearColors.lua` | Removes colours. See [Clearing colours](/Reaper-AutoColor/usage/clearing/#from-the-action-list). |
| | `MXM_AutoColor_WhyThisColour.lua` | Explains the colour of the selected track or item: which rule decided it, or why no rule did. Changes nothing. |
| | `MXM_AutoColor_Dump.lua` | Lists every track, item, region and marker with its name and current colour. Changes nothing. |
| | `MXM_AutoColor_RunTests.lua` | Runs AutoColor's self-test and prints the result to the ReaScript console. |
| | `MXM_AutoColor_Startup.lua` | Starts auto-apply when REAPER starts. Not meant to be run by hand. See [Starting with REAPER](/Reaper-AutoColor/usage/auto-apply/#starting-with-reaper). |

### The toolbar icons

AutoColor includes a toolbar icon for each of the two main actions.

| | Icon name | Action |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `mxm_toolbar_autocolor_gui` | `MXM_AutoColor_GUI.lua` |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `mxm_toolbar_autocolor` | `MXM_AutoColor_AutoToggle.lua` |

The icons are stored in `<resource folder>/Data/toolbar_icons/`, in three sizes for different interface scaling:

```
mxm_toolbar_autocolor.png            90x30
mxm_toolbar_autocolor_gui.png        90x30
150/mxm_toolbar_autocolor.png       135x45
150/mxm_toolbar_autocolor_gui.png   135x45
200/mxm_toolbar_autocolor.png       180x60
200/mxm_toolbar_autocolor_gui.png   180x60
```

## First run

Run `MXM_AutoColor_GUI.lua` to open the configuration window. On the first run, the window opens with a set of example rules, so that you have a starting point. The example rules colour common track names such as kick, snare, bass, guitars and vocals, and include a few item, region and marker rules. You can change them, delete them, or replace them with your own.

AutoColor saves the rules automatically to its [config file](/Reaper-AutoColor/configuration/config-file/).
