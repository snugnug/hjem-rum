# Contributing {#contributing}

[commitizen]: https://github.com/commitizen-tools/commitizen
[article from GeeksforGeeks]: https://www.geeksforgeeks.org/how-to-create-a-new-branch-in-git/
[creating a PR]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
[documentation on forking repositories]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo
[documentation on reviewing PRs]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request
[Core Principles]: #ch-core-principles
[testing documentation]: ./TESTING.html
[reviewed]: #ch-reviewing-a-pr
[REVIEWING.md]: ./REVIEWING.html

Hjem Rum (or HJR) is always in need of contributions as a module collection. As
programs are developed, modules will need to be added, changed, removed, etc.,
meaning that the development of HJR is, in essence, unending.

Contributing is also a great way to learn the Nix module system and even
function writing. Don't be afraid to experiment and try learning something new.

If you are familiar with contributing to open source software, you can safely
skip ahead to [Core Principles]. Otherwise, read the following section to learn
how to fork a repo and open a PR.

## Getting Started {#ch-getting-started}

To begin contributing to HJR, you will first need to create a fork off of the
main branch in order to make changes. For info on how to do this, we recommend
GitHub's own [documentation on forking repositories].

Once you have your own fork, it is recommend that you create a branch for the
changes or additions you seek to make, to make it easier to set up multiple PRs
from your fork. To do so, you can read this [article from GeeksforGeeks] that
will also explain branches for you. Don't worry too much about the technical
details, the most important thing is to make and switch to a branch from HEAD.

### Commit Format {#sec-commit-format}

> [!TIP]
> Our dev shell allows for interactive commits, through the means of
> [commitizen]. If this is preferred, you can run `cz commit` to be prompted to
> build your commit.

For consistency, we do enforce a strict (but simple) commit style, that will be
linted against. The format is as follows (sections between `[]` are optional):

```console
<top_level_scope>[/<specific_scope>]: <message>

[<body>]
```

- \<top_level_scope>: the main scope of your commit. If making a change to a
  program, this would be `programs`). For changes unrelated to the modules API,
  we tend to use semantic scopes such as `meta` for CI/repo related changes.

- \[\<specific_scope>]: An optional, more specific scope for your module. If
  making changes to a specific program, this would be `programs/foot`.

- \<message>: A free form commit message. Needs to be imperative and without
  punctuation (e.g. `do stuff` instead of `did stuff.`).

- \[\<body>]: A free form commit body. Having one is encouraged when your
  changes are difficult to explain, unless you're writing in-depth code comments
  (it is still preferred however).

You can now make your changes in your editor of choice. After committing your
changes, you can run:

```shell
git push origin <branch-name>
```

and then open up a PR, or "Pull Request," in the upstream HJR repository. Again,
GitHub has good documentation for [creating a PR].

After you have setup a PR, it will be [reviewed] by maintainers and changes may
be requested. Make the changes requested and eventually it will likely be
accepted and merged into main.

## Core Principles {#ch-core-principles}

In creating HJR, we had a few principles in mind for development:

1. Minimize the number of options written.
2. Include only the module collection - leave functionality to Hjem.
3. Maintain readability of code, even for new users.

Please keep these in mind as you read through our general guidelines for
contributing.

## Guidelines {#ch-guidelines}

These guidelines, are, of course, merely guidelines. There are and will continue
to be exceptions. However, do your best to stick to them, and keep in mind that
reviewers will hold you to them as much as possible.

### Aliases {#sec-aliases}

At the top of any module, there should always be a `let ... in` set. Within
this, functions should have their location aliased, cfg should be aliased, and
any generators should have an alias as well. Here's an example for a module that
makes use of the TOML generator used in Nixpkgs:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  # in case you are unfamiliar, 'inherit func;' is the same as 'func = func;', and
  # 'inherit (cfg) func;' is the same as 'func = cfg.func;'
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.alacritty;
in {
  options.rum.programs.alacritty = {
```

Notice that each function has its location aliased with an inherit to its target
location. Ideally, this location should be where one could find it in the source
code. For example, rather than using {file}`lib.mkIf`, we use
{file}`lib.modules.mkIf`, because mkIf is declared at `lib/modules.nix` within
the Nixpkgs repo.

Also notice that in this case, `pkgs.formats.toml {}` includes both `generate`
and `type`, so the alias name is just `toml`.

Always be sure to include `cfg` that links to the point where options are
configured by the user.

### Writing Options {#sec-writing-options}

Writing new options is the core of any new module. It is also the easiest place
to blunder. As stated above, a core principle of HJR is to minimize the number
of options as much as possible. As such, we have created a general template that
should help inform you of what options are needed and what are not:

- `enable`: Used to toggle install and configuration of package(s).
- `package`: Used to customize and override the package installed.
  - As needed, `packages`: List of packages used in a module.
- `settings`: Primary configuration option, takes Nix code and converts to
  target lang.
  - As needed, one extra option for each extra file, such as `theme` for
    theme.toml.
- As needed, `extraConfig`: Extra lines of strings passed directly to config
  file for certain programs.

For the most part, this should be sufficient. Overrides of packages should be
simply offered through a direct override in `package`. For example, ncmpcpp's
package has a `withVisualizer ? false` argument. Rather than creating an extra
option for this, the contributor should note this with `extraDescription`, and
give an example of it like so:

```nix
options.rum.programs.ncmpcpp = {
  enable = mkEnableOption "ncmpcpp, a mpd-based music player.";

  package = mkPackageOption pkgs "ncmpcpp" {
    extraDescription = ''
        You can override the package to customize certain settings that are baked
        into the package.
    '';
    # Note that mkPackageOption's example automatically uses literalExpression
    example = ''
        pkgs.ncmpcpp.override {
            # useful overrides in the package
            outputsSupport = true; # outputs screen
            visualizerSupport = false; # visualizer screen
            clockSupport = true; # clock screen
            taglibSupport = true; # tag editor
        };
    '';
  };
```

and the user could simply pass:

```nix
config.hjem.users.<username>.rum.programs.ncmpcpp = {
    enable = true;
    package = (pkgs.ncmpcpp.override {
        withVisualizer = true;
    });
};
```

The `type` of `settings` and other conversion options should preferably be a
`type` option exposed by the generator (for example, TOML has
`pkgs.formats.toml {}.type` and `pkgs.formats.toml {}.generate`), or, if using a
custom generator, a `type` should be created in `lib/types/` (for example,
`hyprType`). Otherwise, a simple `attrsOf anything` would suffice.

As a rule of thumb, submodules should not be employed. Instead, there should
only be one option per file. For some files, such as spotify-player's
{file}`keymap.toml`, you may be tempted to create multiple options for `actions`
and `keymaps`, as Home Manager does. Please avoid this. In this case, we can
have a simple `keymap` option that the user can then include a list of keymaps
and/or a list of actions that get propagated accordingly:

```nix
  keymap = mkOption {
    inherit (toml) type; # We can use a streamlined inherit to say type = toml.type
    default = {};
    example = {
      keymaps = [
        {
          command = "NextTrack";
          key_sequence = "g n";
        }
      ];
      actions = [
        {
          action = "GoToArtist";
          key_sequence = "g A";
        }
      ];
    };
    description = ''
      Sets of keymaps and actions converted into TOML and written to
      {file}`$HOME/.config/spotify-player/keymap.toml`.
      See example for how to format declarations.

      Please reference https://github.com/aome510/spotify-player/blob/master/docs/config.md#keymaps
      for more information.
    '';
  };
```

Also note that the option description includes a link to upstream info on
settings options.

If an option is dependent on `config`, (e.g.
`default = config.myOption.enable;`) you must _also_ set `defaultText` alongside
`default`. Example:

```nix
integrations = {
    # We basically override the `default` and `defaultText` attrs in the mkEnableOption function
    fish.enable = mkEnableOption "starship integration with fish" // {
        default = config.programs.fish.enable;
        defaultText = "config.programs.fish.enable";
    };
};
```

It is essentially just a string that shows the user what the option is set to by
default. This can also be used in `mkOption`, but it is more common to use it in
`mkEnableOption`.

If you do not set this, the docs builder will break due to not knowing how to
resolve the reference to `config`.

### Conditionals in Modules {#sec-conditionals-in-modules}

Always use a `mkIf` before the `config` section. Example:

```nix
config = mkIf cfg.enable {
    ...
};
```

As a general guideline, **do not write empty strings to files**. Not only is
this poorly optimized, but it will cause issues if a user happens to be manually
using the Hjem tooling alongside HJR. Here are some examples of how you might
avoid this:

```nix
config = mkIf cfg.enable {
  packages = [cfg.package];
  files.".config/alacritty/alacritty.toml".source = mkIf (cfg.settings != {}) (
    toml.generate "alacritty.toml" cfg.settings # The indentation makes it more readable
  );
};
```

Here all that is needed is a simple `mkIf` with a condition of the `settings`
option not being left empty. In a case where you write to multiple files, you
can use `optionalAttrs`, like so:

```nix
files = (
    optionalAttrs (cfg.settings != {}) {
    ".gtkrc-2.0".text = toGtk2Text {inherit (cfg) settings;};
    ".config/gtk-3.0/settings.ini".text = toGtkINI {Settings = cfg.settings;};
    ".config/gtk-4.0/settings.ini".text = toGtkINI {Settings = cfg.settings;};
    }
    // optionalAttrs (cfg.css.gtk3 != "") {
    ".config/gtk-3.0/gtk.css".text = cfg.css.gtk3;
    }
    // optionalAttrs (cfg.css.gtk4 != "") {
    ".config/gtk-4.0/gtk.css".text = cfg.css.gtk4;
    }
);
```

This essentially takes the attribute set of `files` and _conditionally_ adds
attributes defining more files to be written to depending on _if_ the
corresponding option has been set. This is optimal because the first three files
written to share an option due to how GTK configuration works.

One last case is in the Hyprland module, where several checks and several
options are needed to compile into one file. Here is how it is done:

```nix
files = let
  check = {
    plugins = cfg.plugins != [];
    settings = cfg.settings != {};
    variables = {
      noUWSM = config.environment.sessionVariables != {} && !osConfig.programs.hyprland.withUWSM;
      withUWSM = config.environment.sessionVariables != {} && osConfig.programs.hyprland.withUWSM;
    };
    extraConfig = cfg.extraConfig != "";
  };
in {
  ".config/hypr/hyprland.conf".text = mkIf (check.plugins || check.settings || check.variables.noUWSM || check.extraConfig) (
    optionalString check.plugins (pluginsToHyprconf cfg.plugins cfg.importantPrefixes)
    + optionalString check.settings (toHyprconf {
      attrs = cfg.settings;
      inherit (cfg) importantPrefixes;
    })
    + optionalString check.variables.noUWSM (toHyprconf {
      attrs.env =
        # https://wiki.hyprland.org/Configuring/Environment-variables/#xdg-specifications
        [
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
        ]
        ++ mapAttrsToList (key: value: "${key},${value}") config.environment.sessionVariables;
    })
    + optionalString check.extraConfig cfg.extraConfig
  );

  /*
  uwsm environment variables are advised to be separated
  (see https://wiki.hyprland.org/Configuring/Environment-variables/)
  */
  ".config/uwsm/env".text =
    mkIf check.variables.withUWSM
    (toEnvExport config.environment.sessionVariables);

  ".config/uwsm/env-hyprland".text = let
    /*
    this is needed as we're using a predicate so we don't create an empty file
    (improvements are welcome)
    */
    filteredVars =
      filterKeysPrefixes ["HYPRLAND_" "AQ_"] config.environment.sessionVariables;
  in
    mkIf (check.variables.withUWSM && filteredVars != {})
    (toEnvExport filteredVars);
};
```

An additional attribute set of boolean aliases is set within a `let ... in` set
to highlight the different checks done and to add quick ways to reference each
check without excess and redundant code.

First, the file is only written if any of the options to write to the file are
set. `optionalString` is then used to compile each option's results in an
optimized and clean way.

### Extending RumLib {#sec-extending-rumlib}

Rather than having functions scattered throughout the module collection, we
would rather keep our directories organized and purposeful. Therefore, all
custom functions should go into our extended lib, found at `modules/lib/`.

The most common functions that might be created are a `generator` and `type`
pair. The former should be prefixed with "to" to maintain style and describe
their function: conversion _to_ other formats. For example, `toNcmpcppSettings`
is the function that converts to the format required for ncmpcpp settings.

Likewise, types should be suffixed with "Type" to maintain style and describe
their function. For example, `hyprType` describes the type used in `settings`
converted to Hyprlang.

When it comes to directory structure, you should be able to infer how we
organize our lib by both our folder structure itself as well as the names of
functions. For example, {option}`rumLib.types.gtkType` is found in
`lib/types/gtkType.nix`. In cases where a file is a single function, always be
sure to make sure the name matches the file.

If a program uses multiple functions of the same kind (e.g. two generators), you
can put them in one file, like is done in `lib/generators/gtk.nix`.

Additionally, please follow how lib is structured in Nixpkgs. For example, the
custom function `attrsNamesHasPrefix` is under `attrsets` to signify that it
operates on an attribute set, just like in Nixpkgs.

### Docs {#sec-docs}

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
Make sure to use `lib.options.mkEnableOption`, like is done in
`rum.programs.fish.enable`
```

Then you will have to include {file} before it, or {option} if it is an option:[^1]

```md
Make sure to use {file}`lib.options.mkEnableOption`, like is done in
{option}`rum.programs.fish.enable`.
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

### Tests {#sec-tests}

Please refer to the [testing documentation] for more information on how tests
work.

## Reviewing a PR {#ch-reviewing-a-pr}

Even if you do not have write-access, you can always leave a review on someone
else's PR. Again, GitHub has great [documentation on reviewing PRs]. This is
great practice for learning the guidelines as well as learning exceptions to the
rules. For some guidelines on review practices, see [REVIEWING.md].
