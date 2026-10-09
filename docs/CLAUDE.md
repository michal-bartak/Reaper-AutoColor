# Documentation writing rules

These rules apply to the user documentation under `docs/src/content/docs/`. They override the "Writing: short" section of the root `CLAUDE.md` for those pages: in user documentation, clarity is more important than brevity.

`development.md` is the one page written for developers. Technical detail belongs there, but every other rule below still applies to it.

Documentation is written for users of the application, not for its developers.

## Audience

Assume that the reader:

- knows the basic concepts of the application domain;
- does not know the application's internal architecture;
- has not read the source code;
- has not read the documentation for another feature;
- should be able to understand the page without knowing the context in which it was written.

Do not require the reader to reconstruct missing context from other parts of the application.

## Explain before using

Introduce a concept before referring to it.

Do not start a section with terms such as "rules", "objects", "applying", "background loop", or similar internal concepts unless the section has already explained what they mean.

If a sentence contains a reference such as "this", "it", "that", or "the above", make sure the referenced thing is unambiguous to a reader who has only read the current section.

## Prefer explicit wording

Prefer clear, explicit sentences over compressed technical phrasing.

Write:

> If a glob rule does not match any tracks, check whether the pattern matches the entire track name.

instead of:

> A glob rule unexpectedly on 0 hits is almost always this.

Do not optimize for brevity at the expense of clarity.

## One idea per sentence

Avoid sentences that combine several independent concepts, conditions, and consequences. Split a complex sentence when doing so makes the relationship between the concepts easier to understand.

## Use user terminology

Documentation should describe what the user sees and does. Avoid implementation terminology unless it is directly relevant to the user's task. For example, prefer:

- "tracks" over "objects", when the feature concerns tracks;
- "matches no tracks" over "0 hits";
- "automatically applies the rule" over "the background loop runs";
- "the entire track name" over "the value is anchored".

Use technical terms when they are part of the feature itself, but explain them when first introduced.

## Keep implementation details out of user documentation

Do not describe internal implementation, data structures, algorithms, event loops, callbacks, internal state, or source-code terminology unless the documentation is specifically intended for developers. Technical details belong in developer documentation when they do not help the end user understand or use the feature.

Before including an implementation detail, ask: "Does the user need to know this to understand or use the feature?" If not, omit it.

## Avoid unexplained context

Do not write sentences that assume the reader already understands why something is being discussed. Instead of:

> Rules decide colours; applying writes them into the project.

explain the relationship explicitly:

> AutoColor rules determine which colours are assigned to tracks. The rules take effect when you click Apply now. If automatic application is enabled, AutoColor also applies them when relevant tracks are added or renamed.

## Avoid conversational shortcuts

Avoid phrases such as "this is usually...", "this is almost always...", "just...", "simply...", "as above...", "the latter...", "the former...", "wrap it in...", "obviously", "of course" unless they are genuinely necessary and unambiguous.

Do not use "it", "this", or "that" when the referenced concept could reasonably be misunderstood.

## Do not invent empirical claims

Do not use phrases such as "almost always", "usually", "in most cases", "commonly", or similar claims unless they are supported by the application's actual behaviour or documentation.

## Documentation structure

For each feature, explain it in this order where appropriate:

1. What the feature does.
2. Why the user would use it.
3. The important concepts and terminology.
4. How to configure or use it.
5. Examples.
6. Important limitations or edge cases.

Do not begin with implementation details or edge cases before explaining the basic concept.

## Examples

Examples should teach the concept, not merely demonstrate syntax. For example, when explaining glob matching:

> `bass` matches only a track whose entire name is `bass`. `*bass*` matches track names containing `bass`, such as `Sub Bass DI`.

Avoid examples that require the reader to infer the underlying rule.

## Tone

Use clear, neutral, professional English. Prefer natural prose over compressed or clever wording. The documentation should read as if it were written by an experienced technical writer who understands the product, rather than by a programmer documenting their own implementation.

Do not try to make the text sound sophisticated. Clarity is more important than brevity.

## One place per topic

Every topic has one home section that holds all of its details. For example, invalid, unsupported and slow patterns are all described in one section of `usage/matching.md`. Other pages, and other sections of the same page, refer to the topic in one short sentence and link to its home. They do not repeat the details, and a link must lead to a section that adds information.

- Concepts and behaviour live on the usage pages. The Options page lists each setting with its default and links to the page that explains it.
- A troubleshooting entry states the symptom, the cause in one or two sentences, and the fix, and links to the home section for the rest.
- A fact that applies everywhere, such as the minimum REAPER version, is stated only on its home page. Do not repeat it on feature pages, not even as a pointer.
- Do not add a summary list (for example "Known limitations") that only repeats sections found elsewhere.
- The tab pages (`usage/tracks.md`, `items.md`, `regions.md`, `markers.md`, `icons.md`) are where a reader starts. Each one covers the rule columns, which rule wins, and when the project changes, a sentence or two per point with a link to the home section. These short repeats are intended. Details go to the home section, not to the tab page. The **In depth** pages (`matching.md`, `colours.md`) hold the full detail.

## Repository conventions

- Say "object type", not "object kind".
- State the default before the alternative.
- No hard wrapping in Markdown: one line per paragraph or list item.
- Headings are link targets (`/usage/colours/#gradients`). When a heading changes, update every link to it.
- Facts come from the source, not from memory. When a page states behaviour, check it against `Reaper/Scripts/MXM_AutoColor/lib/`.

## Final review

Before considering a documentation page complete, review it from the perspective of a new user. Ask:

- Can I understand the feature without knowing its implementation?
- Is every important concept introduced before it is used?
- Could any sentence be misunderstood without additional context?
- Are "it", "this", "that", "they", or similar references unambiguous?
- Are technical terms necessary for the user, or are they implementation leakage?
- Are there sentences that are technically correct but unnatural to read?
- Are examples understandable without additional knowledge?
- Does the text explain the user's mental model rather than the programmer's mental model?

If a sentence is technically precise but difficult to understand, rewrite it for clarity.
