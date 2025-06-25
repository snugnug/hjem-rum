# Contributing: Extending the Documentation {#contributing-extending-the-documentation}

If you would like to contribute to our documentation, we ask a few things of
you:

1. Please aim to write in a formal tone.
2. Use proper grammar and check for misspellings or typos.
3. Try to be concise, but also explain things in full.

In general, the requirements are very loose, but maintainers may have more
specific asks of you depending on the case. Writing can be very personal and
very fluid, so there are less rigid expectations here, but that does not mean
standards are lower.

If you are including an option or function labeled like:

```md
Make sure to use \`lib.options.mkEnableOption\`, like is done in
\`rum.programs.fish.enable\`.
```

Then you will have to include {file} before it, or {option} if it is an option:[^1]

```md
Make sure to use {file}\`lib.options.mkEnableOption\`, like is done in
{option}\`rum.programs.fish.enable\`.
```

[^1]: It is admittedly a bit confusing why we could use {file} for `lib`, but
    the best way to think of it is that {file}`lib.modules.mkIf` literally
    corresponds to file {file}`lib/modules.nix` in Nixpkgs, which contains the
    `mkIf` function.

If you do not do it like this, the link check on the docs will fail, since our
docs generator will attempt to make hyperlinks out of those function names.

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
