# Hjem Rum

[Hjem]: https://github.com/feel-co/hjem
[contributing guidelines]: ./docs/CONTRIBUTING.md
[license]: LICENSE
[`programs/fish.nix`]: modules/collection/programs/fish.nix
[`programs/zsh.nix`]: modules/collection/programs/zsh.nix
[`programs/hyprland.nix`]: modules/collection/programs/hyprland.nix
[#17]: https://github.com/snugnug/hjem-rum/issues/17
[@eclairevoyant]: https://github.com/eclairevoyant
[@NotAShelf]: https://github.com/NotAShelf
[`programs/starship.nix`]: modules/collection/programs/starship.nix
[`environment/warning.nix`]: modules/collection/environment/warning.nix
[Environmental Variables]: #environmental-variables

A module collection for managing your `$HOME` with [Hjem].

## A brief explanation

> [!IMPORTANT]
> Hjem, the tooling Hjem Rum is built off of, is still unfinished. Use at your
> own risk, and beware of bugs, issues, and missing features. If you do not feel
> like being a beta tester, wait until Hjem is more finished. It is not yet
> ready to fully replace Home Manager in the average user's config, but if you
> truly want to, an option could be to use both in conjunction. Either way, as
> Hjem continues to be developed, Hjem Rum will be worked on as we build modules
> and functionality out to support average users.

Based on the Hjem tooling, Hjem Rum (literally meaning "home rooms") is a
collection of modules for various programs and services to simplify the use of
Hjem for managing your `$HOME` files.

Hjem was initially created as an improved implementation of the `home`
functionality that Home Manager provides. Its purpose was minimal. Hjem Rum's
purpose is to create a module collection based on that tooling in order to
recreate the functionality that Home Manager's large collection of modules
provides, allowing you to simply install and config a program.

## Setup

To start using Hjem Rum, you must first import the flake and its modules into
your system(s):

```nix
# flake.nix
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem = {
        url = "github:feel-co/hjem";
        # You may want hjem to use your defined nixpkgs input to
        # minimize redundancies.
        inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-rum = {
        url = "github:snugnug/hjem-rum";
        # You may want hjem-rum to use your defined nixpkgs input to
        # minimize redundancies.
        inputs.nixpkgs.follows = "nixpkgs";
        # Same goes for hjem, to avoid discrepancies between the version
        # you use directly and the one hjem-rum uses.
        inputs.hjem.follows = "hjem";
    };
};

# One example of importing the module into your system configuration
outputs = {
    self,
    nixpkgs,
    ...
} @ inputs: {
    nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit inputs;};
            modules = [
                # Import the hjem module
                inputs.hjem.nixosModules.default
                # Whatever other modules you are importing
            ];
        };
    };
}
```

Be sure to first set the necessary settings for Hjem and import the Hjem module
from the input:

```nix
# configuration.nix
hjem = {
    # Importing the modules
    extraModules = [
        inputs.hjem-rum.hjemModules.default
    ];
    # Configuring your user(s)
    users.<username> = {
        enable = true;
        directory = "/home/<username>";
        user = "<username>";
    };
    # You should probably also enable clobberByDefault at least for now.
    clobberByDefault = true;
};
```

You may then configure any of the options defined in imported modules in your
own configuration:

```nix
# configuration.nix
hjem.users.<username>.rum.programs.alacritty = {
    enable = true;
    #package = pkgs.alacritty; # Default
    settings = {
        window = {
            dimensions = {
                lines = 28;
                columns = 101;
            };
            padding = {
                x = 6;
                y = 3;
            };
        };
    };
}
```

Please keep in mind that Hjem Rum does not currently import most modules
automatically. Continue reading to learn how to import modules.

### Optional Importing

Hjem Rum now offers a `modulesPath` output so that you can import our modules
manually, rather than importing all modules by default:

```nix
# Importing the alacritty module into `hjem.extraModules`
# Notice that it is very similar to the programs.alacritty namespace
hjem.extraModules = [
    "${inputs.hjem-rum.modulesPath}/programs/alacritty.nix"
]
```

Keep in mind that when writing modules, we generally assume all modules are
being imported, and therefore might rely on options from another module that may
or may not be imported in your config. If you do not keep track of this, you
will find an evaluation warning on build.

To accommodate this usage, however, we maintain a table of modules that, when
importing, you should also import other modules:

| Module                      |       Dependencies        | Explanation                                                          |
| --------------------------- | :-----------------------: | -------------------------------------------------------------------- |
| [`environment/warning.nix`] |   [`programs/zsh.nix`]    | Checks if any modules that load environmental variables are enabled. |
|                             |   [`programs/fish.nix`]   |                                                                      |
|                             | [`programs/hyprland.nix`] |                                                                      |
| [`programs/starship.nix`]   |   [`programs/zsh.nix`]    | Starship integration.                                                |
| [`programs/zsh.nix`]        | [`programs/starship.nix`] | A renamed option depended on zsh.                                    |

Example:

```nix
# configuration.nix
config.hjem = {
    # We don't just import the zsh module, but the starship module,
    # even if we don't use the starship module itself.
    extraModules = [
        "${modulesPath}/programs/zsh.nix"
        "${modulesPath}/programs/starship.nix"
    ];
    users.<username>.rum.programs.zsh = {
        enable = true;
    };
};
```

This is a bit inconvenient, yes, but better than enforcing mass importing, and
certainly better than disallowing modules from referencing other modules'
options.

We strongly recommend importing `environment/warning.nix` and its dependencies
when setting up Hjem Rum, as it offers useful checking and a warning if your
session variables are not actually being used.

```nix
hjem.extraModules = [
    "${modulesPath}/environment/warning.nix"
    "${modulesPath}/programs/zsh.nix"
    "${modulesPath}/programs/starship.nix" # A dependency of the zsh module
    "${modulesPath}/programs/fish.nix"
    "${modulesPath}/programs/hyprland.nix"
];
```

See more information under [Environmental Variables].

### Importing All Modules

Alternatively, you can replicate conventional functionality by importing all
modules automatically with `lib.filesystem.listFilesRecursive`:

```nix
# Feeding our module collection directly into hjem.extraModules
hjem.extraModules = lib.filesystem.listFilesRecursive inputs.hjem-rum.modulesPath;
```

Keep in mind this would increase eval times as our module collection grows.

## Environmental Variables

Hjem provides attribute set "environment.sessionVariables" that allows the user
to set environmental variables to be sourced. However, Hjem does not have the
capability to actually source them. This can be done manually, which is what
Hjem Rum tries to do.

Currently, some of our modules may add environmental variables (such as our GTK
module), but cannot load them without the use of another module. Currently,
modules that load environmental variables include:

- [`programs/fish.nix`]
- [`programs/zsh.nix`]
- [`programs/hyprland.nix`]

If you are either using something like our GTK module, or are manually adding
variables to `environment.sessionVariables`, but are neither loading those
variables manually, or using one of the above modules, those variables will not
be loaded, and may cause unintended problems. For example, GTK applications may
not respect your theme, as some rely on the environmental variable to actually
use the theme you declare.

Please see [#17] for status on providing support for shells and compositors. If
your shell or compositor is on listed there, please leave a comment and it will
be added. You are encouraged to open a PR to help support your shell or
compositor if possible.

## Contributing

Hjem Rum is always in need of contribution. Please see our
[contributing guidelines] for more information on how to contribute and our
guidelines.

## Credits

Credit goes to [@NotAShelf] and [@eclairevoyant] for creating Hjem.

## License

All the code within this repository is protected under the GPLv3 license unless
explicitly stated otherwise within a file. Please see [LICENSE] for more
information.
