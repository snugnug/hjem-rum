# Contributing: Extending the Documentation {#contributing-extending-the-documentation}

[ndg]: https://github.com/feel-co/ndg

If you would like to contribute to our documentation, we ask a few things of
you:

1. Please aim to write in a formal tone.
2. Use proper grammar and check for misspellings or typos.
3. Try to be concise, but also explain things in full.

In general, the requirements are very loose, but maintainers may have more
specific asks of you depending on the case. Writing can be very personal and
very fluid, so there are less rigid expectations here, but that does not mean
standards are lower.

## Nixpkgs Markdown {#ch-nixpkgs-markdown}

[ndg] supports extended markdown syntax in accordance with Nixpkgs' flavor.

### Roles {#sec-roles}

If you are including an option or function labeled like:

```md
Make sure to use `lib.options.mkEnableOption`, like is done in
`rum.programs.fish.enable`.
```

Then you will have to include {file} before it, or {option} if it is an option:[^1]

```md
Make sure to use {file}`lib.options.mkEnableOption`, like is done in
{option}`rum.programs.fish.enable`.
```

[^1]: It is admittedly a bit confusing why we could use {file} for `lib`, but
    the best way to think of it is that {file}`lib.modules.mkIf` literally
    corresponds to the file {file}`lib/modules.nix` in Nixpkgs, which contains
    the `mkIf` function.

If you do not do it like this, the link check on the docs will fail, since our
docs generator will attempt to make hyperlinks out of those function names.

### Anchors {#sec-anchors}

Headers should always have an anchor with them to ensure the link checker can
follow header links at time of build. Follow these examples, and you should find
it simple:

```md
# My new document page {#my-new-document-page}

## My 1st chapter heading! {#ch-my-1st-chapter-heading}

### WHAT_DI-887-NI-DO>????? WRONG ? my cool section! {#sec-what-di-887-ni-do-wrong-my-cool-section}
```

Words should be separated by `-`, special characters should be removed, numbers
are fine to keep, extra spaces should be removed, everything should be lower
caps, first headings have no prefix, second headings have `ch` prefix, third
headings have `sec` prefix, etc. If you're unsure, just give it your best shot
and a reviewer will make sure it's as it should be.

## Other Guidelines {#ch-other-guidelines}

### Masked Links {#sec-masked-links}

All links should be "masked," meaning with in-line redirects to their links at
the top of the page directly under the first heading:

```md
# My Document Page {#my-document-page}

[cool link]: https://rum.aurabora.org

Here's my page.

## First Heading {#ch-first-heading}

Here's my [cool link]!
```

We do this so that paragraph clutter is minimized, making it easier for
reviewers to review and writers to edit. This should be done everywhere.
