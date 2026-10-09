---
title: Applying colours and icons
description: Apply now, Selection, and the actions that write colours and icons into the project
---

AutoColor rules determine which colour each track, item, region and marker should have, and which icon each track should have. Tracks, items, regions and markers are called *objects* in the window and on this page. Editing a rule does not change the project. The rules take effect only when they are applied.

Applying the rules means that AutoColor checks every name against the rules and writes the resulting colours and icons into the project. There are two ways to apply the rules:

- **By hand**, with **Apply now** or **Selection** in the configuration window, or with the matching actions in the Action List. This page describes these.
- **Automatically**, with [auto-apply](/Reaper-AutoColor/usage/auto-apply/) switched on. AutoColor then applies the rules when a track is added or renamed, and when items, regions or markers are added or renamed.

## What applying changes

Applying writes a colour only where the colour differs from the one the rules assign. If every object already has the right colour and icon, applying changes nothing and adds no undo point. The status line then reads `Already up to date.`

By default, applying never removes a colour. A track, item, region or marker that no rule matches keeps the colour it already has. For example, an item you coloured by hand last week keeps that colour after every apply, as long as no rule matches it.

To remove colours, use one of these:

- [Clear](/Reaper-AutoColor/usage/clearing/) removes colours once.
- [Reset to the default colour when no rule matches](/Reaper-AutoColor/usage/clearing/#reset-to-the-default-colour-when-no-rule-matches) removes the colour from every object of a chosen object type that no rule matches, each time the rules are applied.

## From the window

<figure class="shot">

![The action bar](../../../assets/usage/action-bar.png)

<figcaption>Apply now and Selection, on the action bar</figcaption>
</figure>

### Apply now

**Apply now** applies the rules to the whole project: every track, item, region and marker, and every track icon. All changes go into **one undo point**, so one undo reverts the whole apply.

If auto-apply is running, it does not change colours and icons that you set by hand. **Apply now** does change them: it replaces them with the colours and icons from the matching rules. See [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) for details.

The status line reports the result, for example `Coloured 12 objects, set 3 icons.`, or `No rule matched anything.`

### Selection

**Selection** applies the rules to the selected tracks, items, regions and markers only. Everything else in the project stays unchanged.

A selected track gets the same colour that **Apply now** would give it. Unselected tracks still count when AutoColor works out folder colours and gradient shades, but their own colours are not changed.

REAPER can have tracks and items selected at the same time. For example, you select a track, then click some items, and the track stays selected. In that case **Selection** colours only one of the two selections: the one you clicked last. REAPER's own actions whose names end in "depending on focus" decide the same way.

- If you clicked an **item** last, the selected items are coloured and the tracks are left unchanged.
- If you clicked a **track** last, the selected tracks are coloured and the items are left unchanged.
- If REAPER cannot tell which you clicked last, for example after you clicked an envelope, both are coloured.

The status line names which selection was used, for example `Coloured 4 of 4 selected items.`

Selected regions and markers are always included, whichever selection was used for tracks and items.

## From the Action List

**Apply now** and **Selection** are also available as actions. Use them to apply the rules from a keyboard shortcut or a toolbar button without opening the window.

| Action | What it applies the rules to |
|---|---|
| `MXM_AutoColor_ApplyAll.lua` | The whole project, exactly like **Apply now**. |
| `MXM_AutoColor_ApplySelection.lua` | The selected tracks and items. |

The actions report their result in the REAPER console. They show a message box when something needs attention, for example when no rule matches anything or a colour could not be written.

:::note[The action and the button differ]
`MXM_AutoColor_ApplySelection.lua` differs from the **Selection** button in two ways:

- It never changes regions or markers. The **Selection** button includes any that are selected.
- It colours both the selected tracks and the selected items. It does not choose between them by which you clicked last.
:::

## When edited rules take effect

Editing a rule in the window does **not** recolour the project. The window shows a preview of what the rules would do, but the project keeps its current colours.

- To apply the edited rules immediately, press **Apply now**.
- If auto-apply is running, it applies the edited rules at the next change to the project, such as a track being added or renamed. It then applies them to the whole project at once, not only to the object that changed.

## Limitations

- On REAPER older than 7.62, **Selection** leaves all regions and markers unchanged. See [REAPER versions before 7.62](/Reaper-AutoColor/requirements/#reaper-versions-before-762).
- If SWS Auto Color is enabled, `MXM_AutoColor_ApplyAll.lua` shows a warning first. See [Colours keep changing back](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).

## Where to go next

- [Auto-apply](/Reaper-AutoColor/usage/auto-apply/) — keep the project coloured without pressing a button.
- [Clearing colours](/Reaper-AutoColor/usage/clearing/) — remove colours instead of setting them.
