#!/usr/bin/env python3
"""Draw the colouring diagrams the usage pages use.

Each diagram is a row of rounded squares -- one per track, named after the colour a rule is
meant to give it. Light grey means "no rule reached this track". The track that OPENS a
folder keeps its level and its children are drawn a third of a square higher, with a
bracket under the folder's extent. A square split into horizontal bands is one square
standing for several cases the row cannot tell apart -- see t()'s `alt`.

Nothing here is hand-coloured. A scenario names the tracks, the rules and the options, and
the colours are COMPUTED by a port of lib/apply.lua (plan() steps 1a-2, plus colors.lua's
HSL lerp). Edit a scenario, re-run this, and the picture follows the tool.

`diagrams_verify.lua` feeds the same scenarios through the REAL apply.plan() and diffs the
two, so the port cannot drift from the tool unnoticed:

    python3 scripts/diagrams.py             # write every SVG
    python3 scripts/diagrams.py --list      # names + resulting colours, no files
    python3 scripts/diagrams.py --verify    # ^ then diff against lib/apply.lua (needs lua)
"""

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "src" / "assets" / "usage" / "diagrams"
LIB = HERE.parent.parent / "Reaper" / "Scripts" / "MXM_AutoColor" / "lib"

# --------------------------------------------------------------------------- palette
# Pastels for the rule colours, each with a darker end for the gradient. The names are the
# track names in the scenarios, so a square labelled "red2" is coloured by the "red" entry.
PALETTE = {
    "red":    ("#F2A8A4", "#A8514C"),
    "green":  ("#A9D8AE", "#4B8A55"),
    "blue":   ("#A6C4EE", "#48699F"),
    "yellow": ("#EFD79A", "#9E8434"),
}
UNMATCHED = "#DEDEE2"       # a track no rule reached
SEPARATOR = "#4A4A52"       # the "a visual spacer sits here" band of a break square
INK       = "#33333A"       # label on a light square
INK_LIGHT = "#FFFFFF"       # label on the dark end of a gradient
INK_DIM   = "#7A7A83"       # brackets, legend, band rules -- readable on both site themes


def label_ink(fill):
    """Flip the label to white once the square is too dark to read #33333A on."""
    r, g, b = (int(fill[1:3], 16), int(fill[3:5], 16), int(fill[5:7], 16))
    return INK if (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5 else INK_LIGHT


# --------------------------------------------------------------------------- scenarios
SPACER_BAND = "spacer"      # the reserved alt name; no rule is ever called this


def t(name, fd=0, alt=None):
    """One track. `fd` is REAPER's folderdepth: 1 opens a folder, -n closes n of them.

    `alt` splits the square into horizontal bands: `name` on top, then one band per alt
    name below. Use it for "something here the rule does not win", where it makes no
    difference WHICH -- the row comes out the same either way, so one square says what
    three diagrams used to. Each alt band is filled from the first rule that matches that
    name, so keep alts on plain solid-colour rules; the reserved name "spacer" draws the
    dark separator band instead, standing for a REAPER visual spacer. A spacer takes no
    track slot of its own, so that band is the one deliberate abstraction here: it marks
    the POSITION of a break, not a track.

    Do NOT use it where the cases behave differently. Under `fill gaps` an unmatched child
    INHERITS the folder's rule and joins its ramp while a child with a rule of its own
    drops out, so folder-rule-gradient draws them as separate squares on purpose."""
    alt = [alt] if isinstance(alt, str) else list(alt or ())
    return {"name": name, "fd": fd, "alt": alt}


def rule(pattern, color, color2=None, spread="all"):
    """A rule. `color`/`color2` are PALETTE keys; spread is all | run | folder | both."""
    return {"pattern": pattern, "color": color, "color2": color2, "spread": spread}


# In page order. `page` is documentation only -- nothing reads it -- but it keeps the list
# and the prose from drifting apart when either is reordered.
SCENARIOS = [
    # ======================================================== usage/colours.md
    dict(
        id="colour-basic",
        page="colours",
        title="Three rules, one colour each",
        setting=None,
        rules=[rule("red*", "red"), rule("green*", "green"), rule("blue*", "blue")],
        tracks=[t("red1"), t("green"), t("blue1"), t("red2"), t("blue2"), t("bass")],
    ),
    dict(
        id="gradient-basic",
        page="colours",
        title="Two gradient rules over unbroken stretches",
        setting="spread: all matches",
        rules=[rule("red*", "red", "red"), rule("blue*", "blue", "blue")],
        tracks=[t("red1"), t("red2"), t("red3"), t("red4"),
                t("blue1"), t("blue2"), t("blue3"), t("blue4")],
    ),

    # The split square in the middle is one square saying three things: it makes no
    # difference to the red rule whether that position holds a track it matched nothing on
    # (grey), a track some other rule won (green), or a REAPER visual spacer (dark). All
    # three are "something red* does not win", and the row comes out the same for each.
    dict(
        id="gradient-all",
        page="colours",
        title="A track the rule does not win, spread across all matches",
        setting="spread: all matches",
        rules=[rule("red*", "red", "red", "all"), rule("green*", "green")],
        tracks=[t("red1"), t("red2"), t("red3"), t("bass", alt=["green", SPACER_BAND]),
                t("red4"), t("red5"), t("red6")],
    ),
    dict(
        id="gradient-runs",
        page="colours",
        title="The same tracks, spread across runs",
        setting="spread: runs",
        rules=[rule("red*", "red", "red", "run"), rule("green*", "green")],
        tracks=[t("red1"), t("red2"), t("red3"), t("bass", alt=["green", SPACER_BAND]),
                t("red4"), t("red5"), t("red6")],
    ),

    # The premise the subfolder option modifies: one ramp per folder. A folder PARENT is
    # part of the folder it opens, so it is the first step of its own ramp -- not the last
    # step of the one outside it.
    dict(
        id="spread-folders",
        page="colours",
        title="Spread across folders: a fresh ramp inside each one",
        setting="spread: folders",
        rules=[rule("red*", "red", "red", "folder")],
        tracks=[t("red1", fd=1), t("red2"), t("red3", fd=-1),
                t("red4", fd=1), t("red5"), t("red6", fd=-1)],
    ),
    dict(
        id="subfolder-split-on",
        page="colours",
        title="Subfolder splits the parent's colour range, on",
        setting="spread: folders · subfolder splits the range: on",
        folders="fill_unmatched",
        split=True,
        rules=[rule("red*", "red", "red", "folder")],
        tracks=[t("red1", fd=1), t("red2"), t("red3"),
                t("red4", fd=1), t("red5"), t("red6", fd=-1),
                t("red7"), t("red8", fd=-1)],
    ),

    # The caution, and it belongs right after split-on: with the range split at every
    # subfolder edge, a folder whose own tracks come one at a time leaves five groups of
    # one, and a group of one gets the FIRST colour. split-off below is the fix.
    dict(
        id="flatten-singletons",
        page="colours",
        title="A folder that is mostly subfolders comes out flat",
        setting="spread: folders · subfolder splits the range: on",
        folders="fill_unmatched",
        split=True,
        rules=[rule("red*", "red", "red", "folder")],
        tracks=[t("red1", fd=1),
                t("red2", fd=1), t("red3", fd=-1),
                t("red4"),
                t("red5", fd=1), t("red6", fd=-1),
                t("red7", fd=-1)],
    ),
    dict(
        id="subfolder-split-off",
        page="colours",
        title="Subfolder splits the parent's colour range, off",
        setting="spread: folders · subfolder splits the range: off",
        folders="fill_unmatched",
        split=False,
        rules=[rule("red*", "red", "red", "folder")],
        tracks=[t("red1", fd=1), t("red2"), t("red3"),
                t("red4", fd=1), t("red5"), t("red6", fd=-1),
                t("red7"), t("red8", fd=-1)],
    ),

    # A rule whose pattern is the FOLDER's own name, so no child matches it and every child
    # reaches the range by inheritance. That also lets each square be named for the colour
    # it ends up with, which a `red*` pattern could not: the children would have matched it
    # directly, and there would be no inheritance left to show.
    dict(
        id="folder-rule-gradient",
        page="colours",
        title="One rule names the folder; the ramp covers every track it owns",
        setting="folder colours: fill gaps \u00b7 spread: all matches",
        folders="fill_unmatched",
        rules=[rule("blue*", "blue"), rule("red1", "red", "red", "all")],
        tracks=[t("red1", fd=1), t("red2"), t("red3"), t("blue1"),
                t("red4"), t("red5"), t("red6", fd=-1)],
    ),

    # The same folder with a spread that counts runs. An inherited range breaks at a track
    # the rule does not win, exactly as a flat run does: `blue1` no longer just drops out,
    # it splits the ramp in two. `runs & folders` gives the same picture here -- there is
    # one folder, so the folder edge adds nothing. Under `force` nothing breaks, because
    # the folder's rule wins `blue1` as well.
    dict(
        id="folder-rule-gradient-runs",
        page="colours",
        title="The same folder, spread across runs: the inherited range breaks",
        setting="folder colours: fill gaps \u00b7 spread: runs",
        folders="fill_unmatched",
        rules=[rule("blue*", "blue"), rule("red1", "red", "red", "run")],
        tracks=[t("red1", fd=1), t("red2"), t("red3"), t("blue1"),
                t("red4"), t("red5"), t("red6", fd=-1)],
    ),

    # ======================================================== usage/items-and-folders.md
    dict(
        id="folders-off",
        page="items-and-folders",
        title="Folder colours off",
        setting="folder colours: off",
        folders="off",
        rules=[rule("red*", "red"), rule("green*", "green"), rule("blue*", "blue")],
        tracks=[t("red", fd=1), t("green"), t("bass"), t("blue", fd=-1)],
    ),
    dict(
        id="folders-fill",
        page="items-and-folders",
        title="Folder colours: fill gaps",
        setting="folder colours: fill gaps",
        folders="fill_unmatched",
        rules=[rule("red*", "red"), rule("green*", "green"), rule("blue*", "blue")],
        tracks=[t("red", fd=1), t("green"), t("bass"), t("blue", fd=-1)],
    ),
    dict(
        id="folders-force",
        page="items-and-folders",
        title="Folder colours: force",
        setting="folder colours: force",
        folders="force",
        rules=[rule("red*", "red"), rule("green*", "green"), rule("blue*", "blue")],
        tracks=[t("red", fd=1), t("green"), t("bass"), t("blue", fd=-1)],
    ),
]


# --------------------------------------------------------------------------- the engine
# A port of lib/apply.lua's plan(), tracks only. Keep the two in step: the step numbers in
# the comments are that function's.

def matches(pattern, name):
    rx = "^" + ".*".join(re.escape(p) for p in pattern.split("*")) + "$"
    return re.match(rx, name, re.IGNORECASE) is not None


def folder_groups(tracks, split):
    """Innermost folder per track; 0 = in none. With `split`, coming back out of a subfolder
    gives the level we return to a fresh id, so the tracks after it start a new group."""
    fg, stack, next_id, root = [0] * len(tracks), [], 0, 0
    for i, e in enumerate(tracks):
        fd = e["fd"]
        if fd >= 1:
            next_id += 1
            fg[i] = next_id
            stack.extend([next_id] * fd)
        else:
            fg[i] = stack[-1] if stack else root
            if fd < 0:
                inner = stack[-1] if stack else None
                for _ in range(-fd):
                    if not stack:
                        break
                    stack.pop()
                if split:
                    outer = stack[-1] if stack else None
                    if outer != inner:
                        next_id += 1
                        if outer is None:
                            root = next_id
                        else:
                            for j in range(len(stack) - 1, -1, -1):
                                if stack[j] != outer:
                                    break
                                stack[j] = next_id
    return fg


# Gradients interpolate in HSL, not RGB -- a straight RGB lerp sags through grey between
# two hues. This is lib/colors.lua's rgb_to_hsl / hsl_to_rgb / lerp, transcribed; a plain
# RGB lerp puts every intermediate step a few values off, which a side-by-side ramp shows.

def rgb_to_hsl(rgb):
    r, g, b = (int(rgb[1:3], 16) / 255, int(rgb[3:5], 16) / 255, int(rgb[5:7], 16) / 255)
    mx, mn = max(r, g, b), min(r, g, b)
    l = (mx + mn) / 2
    if mx == mn:
        return 0.0, 0.0, l                      # achromatic: hue is meaningless
    d = mx - mn
    s = d / (2 - mx - mn) if l > 0.5 else d / (mx + mn)
    if mx == r:
        h = (g - b) / d + (6 if g < b else 0)
    elif mx == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return h / 6, s, l


def hue2rgb(p, q, t):
    t = t + 1 if t < 0 else (t - 1 if t > 1 else t)
    if t < 1 / 6:
        return p + (q - p) * 6 * t
    if t < 1 / 2:
        return q
    if t < 2 / 3:
        return p + (q - p) * (2 / 3 - t) * 6
    return p


def hsl_to_rgb(h, s, l):
    if s == 0:
        r = g = b = l
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r, g, b = hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3)
    return "#%02X%02X%02X" % tuple(int(v * 255 + 0.5) for v in (r, g, b))


def lerp(c1, c2, t):
    """Hue takes the shorter way round the wheel; an achromatic endpoint borrows the
    other's hue so fading to grey does not swing through an unrelated colour."""
    if t <= 0:
        return c1
    if t >= 1:
        return c2
    h1, s1, l1 = rgb_to_hsl(c1)
    h2, s2, l2 = rgb_to_hsl(c2)
    if s1 == 0:
        h1 = h2
    if s2 == 0:
        h2 = h1
    dh = h2 - h1
    if dh > 0.5:
        dh -= 1
    elif dh < -0.5:
        dh += 1
    return hsl_to_rgb((h1 + dh * t) % 1, s1 + (s2 - s1) * t, l1 + (l2 - l1) * t)


def solve(scn):
    """Return the fill colour per track, plus the folder spans the drawing needs."""
    tracks = scn["tracks"]
    rules = scn["rules"]
    policy = scn.get("folders", "fill_unmatched")
    split = scn.get("split", True)
    fg = folder_groups(tracks, split)

    # 1a. the rule each track matches on its own name
    direct = [next((r for r in rules if matches(r["pattern"], e["name"])), None) for e in tracks]

    # 1b. a folder hands its RULE down, before any gradient is ranked
    winner = list(direct)
    if policy != "off":
        stack = []
        for i, e in enumerate(tracks):
            own, inh = direct[i], (stack[-1] if stack else None)
            fr = inh if (policy == "force" and inh is not None) else (own if own is not None else inh)
            winner[i] = fr
            fd = e["fd"]
            if fd >= 1:
                stack.extend([fr] * fd)
            elif fd < 0:
                for _ in range(-fd):
                    if stack:
                        stack.pop()

    # 1c. gradient grouping, over the effective owner
    rank, gid, groups = [0] * len(tracks), [0] * len(tracks), {}
    last_rule = last_fold = None
    nrun = nboth = 0
    run_seq = both_seq = 0
    for i, e in enumerate(tracks):
        r = winner[i]
        fold = fg[i]
        gap = (r is None) or (last_rule != id(r))
        if gap:
            nrun += 1
            run_seq = nrun
        if gap or last_fold != fold:
            nboth += 1
            both_seq = nboth
        last_rule = id(r) if r else None
        last_fold = fold
        if r:
            scope = r["spread"] if r["color2"] else "all"
            g = {"run": run_seq, "folder": fold, "both": both_seq}.get(scope, 0)
            gid[i] = g
            gg = groups.setdefault(id(r), {})
            gg[g] = gg.get(g, 0) + 1
            rank[i] = gg[g]

    # 2. colours
    fills = []
    for i, e in enumerate(tracks):
        r = winner[i]
        if r is None:
            fills.append(None)
            continue
        c1, dark = PALETTE[r["color"]]
        if r["color2"]:
            c2 = PALETTE[r["color2"]][1] if r["color2"] == r["color"] else PALETTE[r["color2"]][0]
            n = groups[id(r)][gid[i]]
            fills.append(c1 if n <= 1 else lerp(c1, c2, (rank[i] - 1) / (n - 1)))
        else:
            fills.append(c1)
    # the lower bands of a split square: the first rule that matches each alt name, flat.
    # A display device, not part of the grading above -- see t().
    alts = []
    for e in tracks:
        bands = []
        for name in e["alt"]:
            if name == SPACER_BAND:
                bands.append(SEPARATOR)
                continue
            r = next((r for r in rules if matches(r["pattern"], name)), None)
            bands.append(PALETTE[r["color"]][0] if r else UNMATCHED)
        alts.append(bands)
    return fills, alts


def folder_spans(tracks):
    """(start, end, depth) per folder, for the brackets. The parent is part of its own folder."""
    spans, stack = [], []
    for i, e in enumerate(tracks):
        fd = e["fd"]
        if fd >= 1:
            for _ in range(fd):
                stack.append(i)
        elif fd < 0:
            for _ in range(-fd):
                if stack:
                    spans.append((stack.pop(), i, len(stack) + 1))
    while stack:
        spans.append((stack.pop(), len(tracks) - 1, len(stack) + 1))
    return spans


def levels(tracks):
    """Nesting level per track. The track that OPENS a folder keeps the level it was already
    on; its children are one deeper. Drawn, that puts each folder's children a third of a
    square higher than the parent, and a subfolder's children higher again."""
    out, depth = [], 0
    for e in tracks:
        fd = e["fd"]
        out.append(depth)
        if fd >= 1:
            depth += fd
        elif fd < 0:
            depth = max(0, depth + fd)
    return out


# --------------------------------------------------------------------------- drawing
S      = 66      # square
GAP    = 10
RADIUS = 9
RAISE  = round(S * 0.30)   # how far a folder parent sits above its children
PAD    = 12
LINE   = 18      # one line of legend text
FONT   = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
CH     = 6.7     # width of one character at 11px in that font, near enough


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def render(scn):
    tracks = scn["tracks"]
    fills, alts = solve(scn)
    spans = folder_spans(tracks)
    lvl = levels(tracks)
    maxlvl = max(lvl)
    maxdepth = max([d for _, _, d in spans], default=0)

    # The setting gets its own line above the rule chips: it is the thing a pair of pictures
    # differs by, and right-aligning it collides with the chips on a four-track diagram.
    setting = scn.get("setting")
    header = LINE * (2 if setting else 1)
    top = PAD + header
    brackets = maxdepth * 9 + 5 if maxdepth else 0
    row_w = len(tracks) * S + (len(tracks) - 1) * GAP
    w = PAD * 2 + row_w
    h = top + maxlvl * RAISE + S + brackets + PAD

    def x_of(i):
        return PAD + i * (S + GAP)

    def y_of(i):
        # level 0 sits on the baseline, each level deeper is drawn RAISE higher
        return top + (maxlvl - lvl[i]) * RAISE

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" '
         f'height="{h}" role="img" aria-label="{esc(scn["title"])}">',
         f'<title>{esc(scn["title"])}</title>']

    # A gradient def per two-colour rule, for its legend chip. SVG ids are document-global,
    # so they carry the scenario id: inline two diagrams in one page with a bare "g1" each
    # and the second one's chip silently renders the FIRST one's ramp.
    gid_ = scn["id"] + "-g"
    defs = []
    for n, r in enumerate(scn["rules"]):
        if r["color2"]:
            c1 = PALETTE[r["color"]][0]
            c2 = PALETTE[r["color2"]][1] if r["color2"] == r["color"] else PALETTE[r["color2"]][0]
            defs.append(f'<linearGradient id="{gid_}{n}"><stop offset="0" stop-color="{c1}"/>'
                        f'<stop offset="1" stop-color="{c2}"/></linearGradient>')
    if defs:
        o.append("<defs>" + "".join(defs) + "</defs>")

    y = PAD + 10
    if setting:
        o.append(f'<text x="{PAD}" y="{y}" font-family="{FONT}" font-size="11" '
                 f'fill="{INK_DIM}">{esc(setting)}</text>')
        y += LINE
    x = PAD
    for n, r in enumerate(scn["rules"]):
        fill = f"url(#{gid_}{n})" if r["color2"] else PALETTE[r["color"]][0]
        o.append(f'<rect x="{x}" y="{y - 9}" width="26" height="12" rx="3" fill="{fill}"/>')
        x += 31
        o.append(f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="11" '
                 f'fill="{INK_DIM}">{esc(r["pattern"])}</text>')
        x += len(r["pattern"]) * CH + 16

    # folder brackets under the row -- the innermost nearest the squares
    by = top + maxlvl * RAISE + S + 5
    for a, b, d in spans:
        yy = by + (maxdepth - d) * 9
        x0, x1 = x_of(a) + 1, x_of(b) + S - 1
        o.append(f'<path d="M{x0} {yy - 4} L{x0} {yy} L{x1} {yy} L{x1} {yy - 4}" fill="none" '
                 f'stroke="{INK_DIM}" stroke-width="1.25" stroke-opacity="0.7" '
                 f'stroke-linecap="round" stroke-linejoin="round"/>')

    for i, e in enumerate(tracks):
        sx, sy = x_of(i), y_of(i)
        fill = fills[i] or UNMATCHED
        stroke = "" if fills[i] else f' stroke="{INK_DIM}" stroke-opacity="0.35"'
        if alts[i]:
            # n equal bands inside one rounded outline: same rect, clipped
            cid = f'{scn["id"]}-c{i}'
            bands = [(e["name"], fill)] + list(zip(e["alt"], alts[i]))
            bh = S / len(bands)
            o.append(f'<clipPath id="{cid}"><rect x="{sx}" y="{sy}" width="{S}" height="{S}" '
                     f'rx="{RADIUS}"/></clipPath>')
            o.append(f'<g clip-path="url(#{cid})">' + "".join(
                f'<rect x="{sx}" y="{sy + n * bh}" width="{S}" height="{bh}" fill="{f}"/>'
                for n, (_, f) in enumerate(bands)) + '</g>')
            o.append(f'<rect x="{sx}" y="{sy}" width="{S}" height="{S}" rx="{RADIUS}" '
                     f'fill="none" stroke="{INK_DIM}" stroke-opacity="0.35"/>')
            for n in range(1, len(bands)):
                o.append(f'<line x1="{sx}" y1="{sy + n * bh}" x2="{sx + S}" y2="{sy + n * bh}" '
                         f'stroke="{INK_DIM}" stroke-width="1" stroke-opacity="0.5"/>')
            for n, (nm, hf) in enumerate(bands):
                o.append(f'<text x="{sx + S / 2}" y="{sy + (n + 0.5) * bh + 3.5}" '
                         f'text-anchor="middle" font-family="{FONT}" font-size="10" '
                         f'fill="{label_ink(hf)}" fill-opacity="'
                         f'{0.55 if hf == UNMATCHED else 1}">{esc(nm)}</text>')
        else:
            o.append(f'<rect x="{sx}" y="{sy}" width="{S}" height="{S}" rx="{RADIUS}" '
                     f'fill="{fill}"{stroke}/>')
            o.append(f'<text x="{sx + S / 2}" y="{sy + S / 2 + 4}" text-anchor="middle" '
                     f'font-family="{FONT}" font-size="11" fill="{label_ink(fill)}" '
                     f'fill-opacity="{0.55 if fills[i] is None else 1}">{esc(e["name"])}</text>')

    o.append("</svg>")
    return "\n".join(o)


# --------------------------------------------------------------------------- verification
# The engine above is a PORT. diagrams_verify.lua runs the same scenarios through the real
# lib/apply.lua and prints what it chose; anything that differs is the port drifting, not a
# judgement call. Needs a standalone lua (brew install lua); skipped, loudly, without one.

def lua_table():
    def lv(v):
        return {None: "nil", True: "true", False: "false"}.get(v, '"%s"' % v)
    out = ["return {"]
    for s in SCENARIOS:
        out.append("{ id=%s, folders=%s, split=%s, rules={"
                   % (lv(s["id"]), lv(s.get("folders")), lv(s.get("split"))))
        for r in s["rules"]:
            c1 = int(PALETTE[r["color"]][0][1:], 16)
            c2 = "nil"
            if r["color2"]:
                end = PALETTE[r["color2"]][1] if r["color2"] == r["color"] \
                    else PALETTE[r["color2"]][0]
                c2 = str(int(end[1:], 16))
            out.append("  { pattern=%s, color=%d, color2=%s, spread=%s },"
                       % (lv(r["pattern"]), c1, c2, lv(r["spread"])))
        out.append("}, tracks={")
        for e in s["tracks"]:
            out.append("  { name=%s, fd=%d }," % (lv(e["name"]), e["fd"]))
        out.append("} },")
    return "\n".join(out + ["}"])


def verify():
    import os, shutil, tempfile
    lua = shutil.which("lua") or shutil.which("lua5.4")
    if not lua:
        print("lua is not installed, so the diagrams were not checked against apply.lua.\n"
              "The SVGs are unaffected. To check them: brew install lua")
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        Path(tmp, "scenarios.lua").write_text(lua_table())
        r = subprocess.run([lua, str(HERE / "diagrams_verify.lua")], cwd=tmp,
                           capture_output=True, text=True,
                           env={**os.environ, "NC_LIB": str(LIB)})
    if r.returncode != 0:
        print("diagrams_verify.lua failed:\n" + (r.stderr or r.stdout))
        return 1
    ref, cur = {}, None
    for line in r.stdout.splitlines():
        if not line.startswith("  "):
            cur = line.strip()
            ref[cur] = []
        else:
            name, hexc = line.strip().split("\t")
            ref[cur].append((name, None if hexc == "nil" else hexc))
    bad = 0
    for s in SCENARIOS:
        mine = [(e["name"], f) for e, f in zip(s["tracks"], solve(s)[0])]
        if mine != ref.get(s["id"]):
            bad += 1
            print("MISMATCH " + s["id"])
            for a, b in zip(mine, ref.get(s["id"], [])):
                if a != b:
                    print("    port %-24s apply.lua %s" % (a, b))
    print("%d scenarios, %d mismatches" % (len(SCENARIOS), bad))
    return 1 if bad else 0


def main():
    if "--verify" in sys.argv:
        sys.exit(verify())
    if "--list" in sys.argv:
        for scn in SCENARIOS:
            print(f'{scn["id"]}: {scn["title"]}')
            for e, c in zip(scn["tracks"], solve(scn)[0]):
                alt = f'  / {e["alt"]}' if e["alt"] else ""
                print(f'    {e["name"]:<8} fd={e["fd"]:<3} {c or "-- unmatched"}{alt}')
        return
    OUT.mkdir(parents=True, exist_ok=True)
    for scn in SCENARIOS:
        (OUT / f'{scn["id"]}.svg').write_text(render(scn))
        print("wrote", scn["id"] + ".svg")


if __name__ == "__main__":
    main()
