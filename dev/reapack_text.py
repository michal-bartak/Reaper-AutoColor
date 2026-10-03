#!/usr/bin/env python3
"""Print what ReaPack shows for the package: the About text and the History.

Read from index.xml as reapack-index wrote it. The About text is RTF there, so
it goes through macOS textutil to come out as plain text; elsewhere it prints
raw. History is every version's changelog, newest first.

    make reapack-text                 # ./index.xml
    dev/reapack_text.py path/to/index.xml
"""

import subprocess
import sys
import xml.etree.ElementTree as ET


def rtf_to_text(rtf):
    try:
        return subprocess.run(["textutil", "-convert", "txt", "-stdin", "-stdout",
                               "-format", "rtf"], input=rtf.encode(),
                              capture_output=True, check=True).stdout.decode()
    except (OSError, subprocess.CalledProcessError):
        return rtf


def main(path):
    root = ET.parse(path).getroot()
    for pkg in root.iter("reapack"):
        desc = pkg.find("metadata/description")
        print("ABOUT")
        print()
        # Every RTF paragraph carries \sa180, space after it, which ReaPack shows
        # as a gap; textutil drops it, so a blank line stands in for it.
        text = rtf_to_text(desc.text or "") if desc is not None else "(none)"
        print("\n\n".join(line for line in text.strip().splitlines() if line.strip()))
        print()
        print("HISTORY")
        for version in reversed(pkg.findall("version")):
            print()
            print(f"{version.get('name')}  ({version.get('time', '')[:10]})")
            log = version.find("changelog")
            print((log.text or "").strip() if log is not None else "(no changelog)")
        print()


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "index.xml")
