# Reaper AutoColor docs

The user documentation, built with [Astro](https://astro.build/) +
[Starlight](https://starlight.astro.build/) and published to GitHub Pages at
<https://michal-bartak.github.io/Reaper-AutoColor/>.

From the repository root:

```bash
make docs          # build and serve at http://localhost:4321/Reaper-AutoColor/
make docs-dev      # live-reload dev server, for writing
```

`make` alone lists every target. Directly, from this folder:

```bash
npm install
npm run dev        # http://localhost:4321/Reaper-AutoColor/
npm run build      # static site into dist/
```

## Layout

```
astro.config.mjs               site config and the sidebar
src/content/docs/              the pages, as Markdown
src/assets/<section>/          screenshots, referenced relatively from the pages
src/styles/custom.css          accent colour, figures, the screenshot lightbox
scripts/diagrams.py            the colouring diagrams, computed from a port of lib/apply.lua
scripts/diagrams_verify.lua    runs the same scenarios through the real apply.lua, to diff
scripts/icon.mjs               renders every icon output from icon/icon.svg
```

Adding a page means creating the Markdown file **and** adding it to the `sidebar` array in
`astro.config.mjs`.

## Screenshots

Every screenshot is taken by hand — the window is a ReaImGui script inside REAPER, so there is
nothing for CI to drive. They live under `src/assets/<section>/` and the pages reference them
relatively, so replacing one is "save over the file, rebuild": no markdown edit.

A page that references an image which is not there fails the build, with
`[ImageNotFound] Could not find requested image`. Add the figure and the file together.

Markdown images go through Astro's image pipeline, which converts them to `webp` and stamps the
width and height, so a PNG straight from REAPER is the right thing to commit.

## Not part of the site

`DECISIONS.md` and `RESEARCH.md` sit in this folder too. They are the engineering notes — why the
tool is built the way it is, and external facts verified against source — and Astro does not read
them. They keep their paths so the root `README.md` and every link to them still work.
