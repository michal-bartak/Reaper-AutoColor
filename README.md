# <img src="icon/autocolor-128.png" width="30" align="top" alt=""> Reaper AutoColor

Colour tracks, items, regions and markers from their **names**, using plain
substring, glob, or **real regular expressions**. One ordered rule list per
object kind, and within a kind the first rule that matches wins.

SWS's Auto Color does case-insensitive substring matching only, and has no item
support at all. If you already use it, **Options → Rules file → Import SWS**
brings your rules across — matching and priority order carry over exactly,
since SWS's substring-and-first-match-wins is a special case of this.

## Documentation

**<https://michal-bartak.github.io/Reaper-AutoColor/>**

| | |
|---|---|
| [Requirements](https://michal-bartak.github.io/Reaper-AutoColor/requirements/) | REAPER 7; ReaImGui 0.10+, for the configuration window only |
| [Installation](https://michal-bartak.github.io/Reaper-AutoColor/installation/) | ReaPack, or copy `Reaper/` over your resource path |
| [Usage](https://michal-bartak.github.io/Reaper-AutoColor/usage/) | the rule list, matching, colours, applying, auto-apply |
| [Configuration](https://michal-bartak.github.io/Reaper-AutoColor/configuration/) | options, the rules file, the REAPER preferences that interfere |
| [Troubleshooting](https://michal-bartak.github.io/Reaper-AutoColor/troubleshooting/) | when nothing happens, or the wrong thing does |
| [Development](https://michal-bartak.github.io/Reaper-AutoColor/development/) | repository layout, the test suite, building these docs |

## Install

Via ReaPack. Import this repository once, under *Extensions → ReaPack → Import
repositories*:

```
https://github.com/michal-bartak/ReaPack/raw/main/index.xml
```

Read [Installation](https://michal-bartak.github.io/Reaper-AutoColor/installation/) for further details.


MIT licensed — see [LICENSE](LICENSE).
