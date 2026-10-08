---
title: Auto-apply
description: Keeping the project coloured automatically, what it leaves alone, and how quickly it reacts
---

AutoColor rules take effect only when they are applied. You can apply them by hand with **Apply now**, as described in [Applying colours](/Reaper-AutoColor/usage/applying/). Auto-apply applies them for you. While auto-apply is running, AutoColor watches the project and applies the rules whenever a track, item, region or marker is added, renamed or deleted. For example, when you add a track or rename it, the track receives its colour and icon within a fraction of a second.

Use auto-apply when you want the project to stay coloured while you work, without pressing **Apply now** after every change.

## Starting and stopping

Auto-apply is controlled by the action `MXM_AutoColor_AutoToggle.lua` <img class="tb-icon" src="/Reaper-AutoColor/toolbar-autocolor.svg" alt="AutoToggle toolbar icon">. Run the action once to start auto-apply. Run it again to stop auto-apply. If the action is on a toolbar, its button is lit while auto-apply is running.

The configuration window shows the same state on the **Auto** button at the right end of the action bar:

- `Auto: off` — auto-apply is not running. Click the button to start it.
- `Auto: on` — auto-apply is running. Click the button to stop it.

The **Auto** button can start auto-apply only after `MXM_AutoColor_AutoToggle.lua` has been run at least once from the Action List or a toolbar. Until then, clicking the button shows a message asking you to run the action.

Auto-apply runs on its own. The configuration window does not need to be open, and opening or closing the window does not start, stop or pause auto-apply.

## What auto-apply changes

When auto-apply starts, it applies the rules to the whole project. After that, it reacts to changes in the project:

- A track is added, deleted, renamed or moved.
- An item, region or marker is added, deleted or renamed.

Tracks are updated immediately. Items, regions and markers are updated once the project stops changing, for example when you release the mouse after dragging an item. [How quickly changes are applied](#how-quickly-changes-are-applied) gives the exact timing.

Auto-apply works on the project in the active project tab. When you switch to another project tab, auto-apply applies the rules to that project.

### Editing rules while auto-apply is running

Editing a rule does not recolour the project immediately, even while auto-apply is running. See [When edited rules take effect](/Reaper-AutoColor/usage/applying/#when-edited-rules-take-effect).

## What auto-apply leaves alone

### Colours and icons set by hand

Auto-apply does not undo a colour that you set by hand. If you change the colour of a track, item, region or marker while auto-apply is running, auto-apply leaves that object's colour alone. The same applies to a track icon that you change by hand.

To replace a hand-set colour or icon with the one from the matching rule, do one of the following:

- You rename the object. AutoColor treats a new name as a request to apply the rules again.
- You press **Apply now**, or run `MXM_AutoColor_ApplyAll.lua`. Either one applies the rules to every object, including objects you coloured by hand.

For example, a rule colours tracks containing `kick` red:

1. You add a track named `Kick`. Auto-apply colours it red.
1. You pick blue for the track in REAPER. The track stays blue.
1. You rename the track to `Kick In`. Auto-apply colours it red again.

A track's colour and its icon are handled separately. Changing a track's icon by hand does not stop auto-apply from setting its colour, and changing its colour by hand does not stop auto-apply from setting its icon.

Auto-apply keeps a hand-set colour or icon only if you set it while auto-apply is running on that project. In the following cases, auto-apply replaces hand-set colours and icons with the ones from the matching rules:

- When auto-apply starts. This includes colours you set while auto-apply was stopped.
- When you switch to another project tab. The replacement happens in the project you switch to.
- When you change the rules or options in the configuration window. The replacement happens at the next change to the project.
- When the option [Reset to the default colour when no rule matches](/Reaper-AutoColor/usage/clearing/#reset-to-the-default-colour-when-no-rule-matches) is on for an object type. Auto-apply then removes hand-set colours from objects of that type that no rule matches.

### Recording

Auto-apply does nothing while REAPER is recording, including while recording is paused. Changes made during recording are applied after recording stops.

### Undo history

By default, auto-apply does not add undo points. Otherwise every track rename would be followed by an extra undo point for the colour. REAPER still marks the project as modified, so the new colours are stored when you save the project.

To add undo points for automatic changes, turn on **Undo points for automatic changes** in [Options](/Reaper-AutoColor/configuration/). With the setting off, you can restore the colours at any time by applying the rules again.

## Starting with REAPER

The **Autostart** setting in [Options](/Reaper-AutoColor/configuration/) decides whether auto-apply starts when REAPER starts:

| Setting | Effect |
|---|---|
| **Last** (default) | Auto-apply starts if it was running when REAPER was last closed. |
| **Always** | Auto-apply starts every time REAPER starts. |
| **Never** | Auto-apply does not start with REAPER. |

REAPER runs the file `Scripts/__startup.lua`, in the REAPER resource folder, each time it starts. Autostart relies on an entry in that file. The configuration window and `MXM_AutoColor_AutoToggle.lua` add the entry when it is missing or out of date, whatever the **Autostart** setting is. Other content in `__startup.lua` is kept. The entry is marked with the lines `-- MXM_AutoColor BEGIN` and `-- MXM_AutoColor END`.

:::note[Uninstalling]
After AutoColor is uninstalled, the entry in `Scripts/__startup.lua` does nothing and causes no errors. To remove it, delete the lines from `-- MXM_AutoColor BEGIN` to `-- MXM_AutoColor END`.
:::

## How quickly changes are applied

Auto-apply checks the project for changes at a regular interval, five times a second by default. How quickly a change is applied depends on what changed.

| What changed | When auto-apply applies the rules |
|---|---|
| A track was added, deleted, renamed or moved | At the next check. |
| An item, region or marker was added or deleted | At the first check after the project stops changing. |
| An item, region or marker was renamed, or an item was moved to another track | After the **Item/marker rescan (s)** interval, 5 s by default. |

Items, regions and markers are handled more cautiously than tracks because a project can contain many thousands of them. Reading all of them after every change could slow REAPER down on a large project.

Some changes leave the number of items, regions and markers the same and do not change any track. Renaming an item and moving an item to another track are two examples. Auto-apply cannot detect these changes quickly, so it looks for them on a timer, set by **Item/marker rescan (s)**. To apply such a change immediately, press **Apply now**.

Three settings in [Options](/Reaper-AutoColor/configuration/) control the timing:

| Setting | Default | Effect |
|---|---|---|
| **Check frequency (s)** | 0.20 | How often auto-apply checks the project, and so the delay before a track change is applied. A lower value reacts faster and uses more CPU. |
| **Work budget (ms)** | 4 | The longest time one check may spend writing colours to items, regions and markers. On a large project, the remaining writes continue at the next checks, so REAPER stays responsive. A higher value finishes large changes in fewer checks, but each check can take longer. |
| **Item/marker rescan (s)** | 5 | The longest delay before a renamed item, region or marker is recoloured. `0` checks all items, regions and markers after every change, which is slow on a large project. |

When nothing in the project changes, auto-apply does no work apart from these regular checks.

## Limitations

- If SWS Auto Color is enabled, starting auto-apply shows a warning. See [Colours keep changing back](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).
- If auto-apply encounters an error, it stops and shows a message with the error.

:::caution[Gradients on items]
When one item in an item [gradient](/Reaper-AutoColor/usage/colours/#gradients) changes, AutoColor recalculates the whole gradient. On a project with very many items, a gradient rule on the **Items** tab can make auto-apply slow.
:::

## Diagnostic output

Auto-apply can print a summary of its activity to the REAPER console every 5 seconds. To turn the summary on, run the following line as a ReaScript (Lua):

```lua
reaper.SetExtState('MXM_AutoColor', 'auto_debug', '1', false)
```

Each line shows counters for the work auto-apply has done since it started. The counters include how many colours and icons it has written, and how many changes it skipped because a colour or icon was set by hand. The line ends with how long the last check took. To turn the summary off, run the same line with `'0'` in place of `'1'`, or restart REAPER.

## Where to go next

- [Options](/Reaper-AutoColor/configuration/) — the timing settings, Autostart and undo behaviour.
- [Troubleshooting](/Reaper-AutoColor/troubleshooting/) — when a colour does not match the rules.
