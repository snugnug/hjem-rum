# Contributing: Writing Modules {#contributing-writing-modules}

[Noogle's page on it]: https://noogle.dev/f/lib/options/mkPackageOption

Writing modules is a core task of contributing to Hjem Rum, and makes up the
bulk of PRs. Learning to follow our guidelines, standards, and expectations in
writing modules is accordingly crucial. Please read the following to be made
aware of these.

## Aliases {#ch-aliases}

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

## Writing Options {#ch-writing-options}

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

For the most part, this should be sufficient.

### Package Overrides {#sec-package-overrides}

Overrides of packages should be simply offered through a direct override in
`package`. For example, ncmpcpp's package has a `withVisualizer ? false`
argument. Rather than creating an extra option for this, the contributor should
note this with `extraDescription`, and give an example of it like so:

```nix
options.rum.programs.ncmpcpp = {
  enable = mkEnableOption "ncmpcpp, a mpd-based music player.";

  package = mkPackageOption pkgs "ncmpcpp" {
    nullable = true; # Always enable `nullable` in `mkPackageOption`. Usually, this would be inline.
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

### Nullable Package Options {#sec-nullable-package-options}

When using `mkPackageOption`, you should always be sure to enable `nullable`, so
that the user can choose not to have Hjem Rum install the package into the
user's environment.

```nix
options.rum.programs.alacritty = {
    enable = mkEnableOption "Alacritty";

    package = mkPackageOption pkgs "alacritty" {nullable = true;};
};
```

`mkPackageOption` is a function with three required arguments: the source of the
package (usually `pkgs`), the name of the package, and an attribute set for
configuration. The latter has several options, such as `extraDescription`,
`example`, and, in this case `nullable`. For a complete list of options for this
function, see [Noogle's page on it].

Because the user can set the package to null, however, we must check for this
before adding the package to the user's environment, as adding `null` would
result in an error. Thankfully, this is relatively simple:

```nix
config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
};
```

This simply checks if the package is null before adding it to the list.

### Type {#sec-type}

The `type` of `settings` and other conversion options should preferably be a
`type` option exposed by the generator (for example, TOML has
`pkgs.formats.toml {}.type` and `pkgs.formats.toml {}.generate`), or, if using a
custom generator, a `type` should be created in `lib/types/` (for example,
`hyprType`). Otherwise, a simple `attrsOf anything` would suffice.

### Submodules / Nested Configuration {#sec-submodules-nested-configuration}

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

### Dependence on `config` {#sec-dependence-on-config}

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

## Conditionals in Modules {#ch-conditionals-in-modules}

Always use a `mkIf` before the `config` section. Example:

```nix
config = mkIf cfg.enable {
    # Module code
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
