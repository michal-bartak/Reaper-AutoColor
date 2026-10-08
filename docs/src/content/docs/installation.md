---
title: Installation
description: Install AutoColor through ReaPack, or copy the files in by hand
---

AutoColor can be installed in two ways. The recommended way is through ReaPack, REAPER's package manager, which also installs updates. Alternatively, you can copy the files into REAPER's resource folder by hand.

Before installing, check the [requirements](/Reaper-AutoColor/requirements/).

## The REAPER resource folder

REAPER keeps scripts, icons and settings in its *resource folder*. AutoColor installs its scripts there and stores its [config file](/Reaper-AutoColor/configuration/config-file/) there. To open the folder, choose *Options → Show REAPER resource path in explorer/finder* in REAPER's menu. The default locations are:

| OS | Resource folder |
|----|------|
| macOS | `~/Library/Application Support/REAPER/` |
| Windows | `%AppData%\REAPER\` |
| Linux | `~/.config/REAPER/` |

## Installing through ReaPack

AutoColor is published in the following ReaPack repository:

```
https://github.com/michal-bartak/ReaPack/raw/main/index.xml
```

In REAPER:

1. Open *Extensions → ReaPack → Import repositories*, paste the URL above, and confirm.
1. Open *Extensions → ReaPack → Browse packages*, find **AutoColor**, and install it.

ReaPack installs the scripts into `Scripts/MXM Scripts/MXM_AutoColor/` in the REAPER resource folder. It adds two actions to the Action List, each with its own [toolbar icon](#the-toolbar-icons):

- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> `MXM_AutoColor_GUI.lua` opens the configuration window.
- <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> `MXM_AutoColor_AutoToggle.lua` switches [auto-apply](/Reaper-AutoColor/usage/auto-apply/) on and off.

:::note
To find these actions in the Action List, search for `autocolor` or `mxm`. The toolbar icons can be found with the same search terms.
:::

<details>
<summary>Manual installation steps</summary>

1. Open the [REAPER resource folder](#the-reaper-resource-folder).

1. From the AutoColor download, copy the **contents** of the `Reaper/` folder into the resource folder. Merge the folders with the ones that already exist there; do not replace them:

   ```
   Reaper/Scripts/MXM_AutoColor/  ->  <resource folder>/Scripts/MXM_AutoColor/
   Reaper/Data/toolbar_icons/     ->  <resource folder>/Data/toolbar_icons/
   ```

1. In REAPER, open *Actions → Show action list*, click *New action → Load ReaScript*, and load `MXM_AutoColor_GUI.lua` and `MXM_AutoColor_AutoToggle.lua` from `Scripts/MXM_AutoColor/`.
1. Optionally, add the two actions to a toolbar, using the [toolbar icons](#the-toolbar-icons) supplied.
</details>

## The actions

AutoColor consists of several scripts. Each script becomes a REAPER action once it is loaded into the Action List.

ReaPack registers only the two main actions, marked with an icon in the table below. The other scripts are installed in the same folder. To run one of them from the Action List, a keyboard shortcut or a toolbar, load it with *New action → Load ReaScript*.

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

The auto-apply button lights up while auto-apply is on.

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
