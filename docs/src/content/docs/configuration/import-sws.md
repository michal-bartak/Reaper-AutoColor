---
title: Importing from SWS
description: Moving an SWS Auto Color setup into AutoColor, and what does not come across
---

SWS Auto Color is a feature of the SWS extension for REAPER. Like AutoColor, it colours tracks, regions and markers by name, and it can set track icons. **Import from SWS** converts the rules you set up in SWS Auto Color into AutoColor rules, so you do not have to recreate them by hand.

Importing the SWS rules lets you switch SWS Auto Color off and continue with AutoColor.

## Importing

1. Open **Options** and find the **Config file** section.
1. Click **Import from SWS**.
1. AutoColor reads the SWS rules and shows what it found: the number of rules, how many go to each tab, how many will arrive switched off, and how many lines it could not read.
1. Click **Yes** to import the rules. Click **No** to cancel. Cancelling changes nothing.

The import only adds rules. It places the SWS rules below the rules already on each tab, and it never changes or removes existing rules. While the AutoColor window stays open, **Undo** reverses the import.

To replace your current rules with the SWS rules, click **Remove Rules** first, and then import.

The import changes only the rules. The colours in the project change the next time the rules are applied, for example when you click **Apply now**.

## Where the imported rules go

SWS Auto Color has separate rules for tracks, markers and regions. Each SWS rule goes to the matching tab in AutoColor:

| SWS rule | AutoColor tab |
|---|---|
| Track rule | **Tracks** |
| Marker rule | **Markers** |
| Region rule | **Regions** |
| Icon of a track rule | **Icons** |

SWS Auto Color has no rules for items, so the import adds nothing to the **Items** tab.

In SWS, a single track rule can set both a colour and an icon. AutoColor keeps colours and icons on separate tabs. A track rule with an icon therefore becomes two rules: a colour rule on the **Tracks** tab, and an icon rule with the same name and filter on the **Icons** tab. The icon rules keep the same order as the SWS rules.

## What it reads

The import reads the file `sws-autocoloricon.ini` in the [REAPER resource folder](/Reaper-AutoColor/installation/#the-reaper-resource-folder). AutoColor finds the file automatically. If the file does not exist, for example because SWS has never been installed, the import shows a message and imports nothing.

SWS keeps the start and end colours of its gradient in REAPER's `reaper.ini` file, so the import reads them from there. If no gradient colours are set, the import uses the SWS default, which runs from black to white.

The import only reads these two files. It does not change or remove anything in your SWS setup.

## What comes across unchanged

SWS Auto Color matches a rule when the rule's text appears anywhere in the name, ignoring upper and lower case. For each object, the first matching rule decides the colour. AutoColor's **contains** mode with **Aa** (ignore case) on works in the same way, and AutoColor also checks its rules from top to bottom. An ordinary SWS rule therefore colours exactly the same objects in AutoColor.

| In SWS | In AutoColor |
|---|---|
| A name filter, such as `Kick` | A **contains** rule with the same text, with case ignored |
| `(any)` | A rule with no pattern and no filter, which matches everything |
| `(unnamed)`, `(folder)`, `(children)`, `(instrument)`, `(MIDI input)`, `(receive)` | A rule with no pattern and the equivalent [filter](/Reaper-AutoColor/usage/matching/#filters): **has no name**, **is a folder track**, **is inside a folder**, **has an instrument**, **has a MIDI input**, **has receives** |
| A colour | The same colour |
| **Gradient** | A [gradient](/Reaper-AutoColor/usage/colours/#gradients) with the start and end colours set in SWS, spread across **all matches**, as in SWS |
| The icon of a track rule | An icon rule on the **Icons** tab |
| The order of the rules | The same order |

## What arrives switched off

Some SWS features have no equivalent in AutoColor. Rules that use them are still imported, so that you can see what your SWS setup contained. They arrive switched off, and the reason is added to the end of the rule's name, for example `Drums [SWS: random colours are not supported]`.

| In SWS | Why it is not supported |
|---|---|
| **Random** colours | AutoColor assigns only colours that a rule specifies. |
| **Custom** colours, which cycle through REAPER's colour palette | AutoColor assigns only colours that a rule specifies. |
| **Parent** colour | In AutoColor, the rule that colours a folder track decides whether the tracks inside the folder receive its colour, with its **Children** setting. The rules for the tracks inside the folder have no colour choice for this. See [Folders](/Reaper-AutoColor/usage/colours/#folders). |
| **None** | AutoColor has no rule that removes a colour. To remove colours, use **Clear…** on the action bar, or turn on [Reset to the default colour when no rule matches](/Reaper-AutoColor/usage/clearing/#reset-to-the-default-colour-when-no-rule-matches). |
| **Ignore** | See the warning below. |
| A rule with an empty filter | The SWS rule has no filter text, so there is nothing to convert into a pattern. The rule arrives named `(no filter)`. |
| `(master)` | REAPER [does not show a custom colour on the master track](/Reaper-AutoColor/troubleshooting/#the-master-track-is-never-coloured), so this filter had no visible effect in SWS either. |
| `(record armed)`, `(audio input)`, `(audio output)`, `(MIDI output)`, `(vca master)` | AutoColor has no equivalent filter. |

A rule with an unsupported filter, such as `(record armed)`, keeps the SWS keyword as its pattern. AutoColor matches that pattern as plain text in the name. Check such a rule before you switch it on: the pattern `(record armed)` matches only tracks whose name contains the text `(record armed)`, not tracks that are armed for recording.

:::caution[Ignore rules change more than themselves]
In SWS, an **Ignore** rule left the matching tracks unchanged, and it also stopped every rule below it from colouring those tracks. AutoColor cannot reproduce that blocking. After the import, the rules that were below an Ignore rule in SWS can colour tracks that they never coloured in SWS.
:::

An icon rule is switched off only when its filter cannot be imported. SWS decides the colour and the icon separately, so a colour that cannot be imported does not affect the icon. For example, a track rule with a **Random** colour and an icon arrives as a switched-off colour rule and a working icon rule.

SWS Auto Color can also set track layouts for the track control panel (TCP) and the mixer (MCP). AutoColor does not set layouts, so the import ignores them.

## After importing

The import does not switch SWS Auto Color off. Switch it off yourself; see [Colours keep changing back](/Reaper-AutoColor/troubleshooting/#colours-keep-changing-back).

Before you apply the imported rules, check them:

- Look for rules that arrived switched off. The reason is at the end of each rule's name.
- An SWS `(any)` rule matches every object on its tab. The import places it below your existing rules, so it colours every object that your existing rules do not match.
- Check the **Hits** column to see how many objects each rule colours in the current project. See [The Hits column](/Reaper-AutoColor/usage/matching/#the-hits-column).

Each imported rule also records the original SWS line in its `note` field in the [config file](/Reaper-AutoColor/configuration/config-file/). The note is not shown in the window, but you can read it in the file to compare a rule with its SWS source.
