---
title: Installation
description: Install through ReaPack, or copy the folder in by hand
---

The easy way, and the one that keeps itself up to date. Import the repository once:

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
Add these scripts to toolbar of your choice, assigning dedicated icons.

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

1. In REAPER, open *Actions → Show action list → New action → Load ReaScript*, and load the scripts
   you want from the table below. They are in `Scripts/MXM_AutoColor/`.

<figure class="shot">

![The Action List with the scripts loaded](../../assets/installation/action-list.png)

<figcaption>The Action List with the scripts loaded</figcaption>
</figure>

</details>

## The actions

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

Only the two with an icon reach the **Action List**. They are also the two that get a toolbar
button, and they are all most setups need. The other six install alongside them but stay out of the
list, so it does not fill up with entries you will never run.

Add any of the six when you want a keyboard shortcut, or to diagnose a colour that looks wrong:
*Actions → Show action list → New action → Load ReaScript*, then pick the file from
`Scripts/MXM_AutoColor/`.

:::tip[Toolbar buttons]
Right-click a toolbar → *Customize toolbar…* → **Add**, and pick the action. `AutoToggle` reports
its state back, so its button lights while the background loop runs.
:::

### The toolbar icons

Both buttons come with an icon. Installing, or copying `Reaper/` over the resource path, already put
them in place.

| | Name | Action |
|---|---|---|
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon"> | `mxm_toolbar_autocolor` | `MXM_AutoColor_AutoToggle.lua` |
| <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor-gui.svg" alt="Window toolbar icon"> | `mxm_toolbar_autocolor_gui` | `MXM_AutoColor_GUI.lua` |

Each name appears three times under `<resource path>/Data/toolbar_icons/`:

```
mxm_toolbar_autocolor.png            90x30
150/mxm_toolbar_autocolor.png       135x45
200/mxm_toolbar_autocolor.png       180x60
```

They use REAPER's own toolbar format: a three-state strip of square cells — normal, hover, pressed.
REAPER reaches for the `150` and `200` copies on a hi-DPI display, and finds them by the **same
filename** in those subfolders, so do not rename them.

To use them, restart REAPER, right-click the toolbar → *Customize toolbar…*, select a button and
pick its icon from REAPER's icon browser. The file names mirror the script names, so the two line
up in that list.

:::note[What the states look like]
A REAPER toolbar icon is three cells, and REAPER draws the third while a **toggle action is armed**,
not as a click flash. So the AutoToggle button says whether the loop is running: grey while it is
off, that grey lifted on hover, and the full six colours once it is working. The mark pays out its
colour only while the tool is doing something.

The window button is not a toggle, so it keeps its colours throughout and brightens under the
pointer.

The greys are REAPER's own — `#818989`, and `#939A9A` on hover — measured from the 528 icons it
ships, so an idle AutoColor button sits at the same weight as every other idle button.

REAPER also brightens the **button plate behind** the icon on hover, and turns it the theme's accent
colour while a toggle action is armed. That comes from the theme, not from the icon, and applies to
every button on the toolbar.
:::

<figure class="shot">

![The AutoToggle toolbar button](../../assets/installation/toolbar-button.png)

<figcaption>The AutoToggle toolbar button, lit while the loop runs</figcaption>
</figure>

## First run

Run `MXM_AutoColor_GUI.lua`. On the first run it writes a **starter rule set** so the window has
something to show, and tells you where:

```
<REAPER resource path>/MXM_AutoColor/config.json
```

That file is one global rule set shared by every project, and it sits **outside** `Scripts/` on
purpose: reinstalling or updating the scripts cannot destroy your rules. See
[Rules file](/Reaper-AutoColor/configuration/rules-file/).

:::caution[Editing the scripts]
The window and the auto-toggle hold their Lua state for as long as they run. After editing anything
under `Scripts/MXM_AutoColor/lib/`, close the window and re-run it, and toggle auto off and on
again. Otherwise the old code is still the code that is running. One-shot actions pick up changes
immediately.
:::

## Upgrading from the single-list version

Older configurations kept **one** rule list, where each rule carried track/item/region/marker
checkboxes. AutoColor migrates them on first load: a rule that ticked several boxes becomes one rule
**per tab**, in the same relative order, so the precedence you had survives within every kind.
Nothing is lost, and the previous file is kept as `config.bak.json`.

After migrating you may find duplicate rules on the **Items** tab, copies of track rules that
happened to match item *names*. If what you wanted was "colour the items on these tracks", delete
the copies and tick [also colour items](/Reaper-AutoColor/usage/colours/#items) on the track
rule instead.
