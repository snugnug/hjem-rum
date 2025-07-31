# Hjem Rum

[Hjem]: https://github.com/feel-co/hjem
[contributing guidelines]: ./docs/CONTRIBUTING.md
[license]: LICENSE
[programs/fish]: modules/collection/programs/fish.nix
[programs/zsh]: modules/collection/programs/zsh.nix
[programs/nushell]: modules/collection/programs/nushell.nix
[desktops/hyprland]: modules/collection/desktops/hyprland.nix
[#17]: https://github.com/snugnug/hjem-rum/issues/17
[@eclairevoyant]: https://github.com/eclairevoyant
[@NotAShelf]: https://github.com/NotAShelf
[documentation]: snugnug.github.io/hjem-rum/

A module collection for managing your `$HOME` with [Hjem].

## A brief explanation

> [!IMPORTANT]
> Hjem, the tooling Hjem Rum is built off of, is still unfinished. Use at your
> own risk, and beware of bugs, issues, and missing features. If you do not feel
> like being a beta tester, wait until Hjem is more finished. It is not yet
> ready to fully replace Home Manager in the average user's configuration, but
> if you truly want to, an option could be to use both in conjunction. Either
> way, as Hjem continues to be developed, Hjem Rum will be worked on as we build
> modules and functionality out to support average users.

Based on the Hjem tooling, Hjem Rum (literally meaning "home rooms") is a
collection of modules for various programs and services to simplify the use of
Hjem for managing your `$HOME` files.

Hjem was initially created as an improved implementation of the `home`
functionality that Home Manager provides. Its purpose was minimal. Hjem Rum's
purpose is to create a module collection based on that tooling in order to
recreate the functionality that Home Manager's large collection of modules
provides, allowing you to simply install and configure a program.

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

> [!TIP]
> Consult the [documentation] for an overview of all available options.

### Optional: Manual Module Importing

> [!WARNING]
> Manual module importing is an advanced user feature and is not recommended for
> the average user. While it is supported and tested for, you may encounter more
> problems with it, and we advise users to become more familiar with the NixOS
> module system and Hjem Rum in particular before attempting to leave behind the
> automatic importing of all modules. Please skip ahead to [Environmental
> Variables] if you are not interested in this. While the default hjemModule
> imports all modules in the collection recursively, we have implemented
> functionality to support users who would prefer to only import modules that
> they plan to use. If you would like to do so, rather than importing the
> default hjemModule we provide, you will have to use the special `bare` module:

```nix
hjem.extraModules = [
    inputs.hjem-rum.hjemModules.bare # The alternative module
    # inputs.hjem-rum.hjemModules.default
];
```

This alternative module does not import any of our modules, which means that you
will not be able to do anything with Hjem Rum without manually importing our
modules yourself. To this end, we offer a `modulesPath` output for you to import
modules from.

```nix
hjem.extraModules = [
    # Notice the similarity to the programs.alacritty namespace
    "${inputs.hjem-rum.modulesPath}/programs/alacritty.nix" # Importing the alacritty module
];
```

We strongly recommend importing `environment/warning.nix`
when setting up Hjem Rum, as it offers useful checking and a warning if your
session variables are not actually being used.

```nix
hjem.extraModules = [
    "${modulesPath}/environment/warning.nix"
];
```

See more information below.

## Environmental Variables

Hjem provides attribute set "environment.sessionVariables" that allows the user
to set environmental variables to be sourced. However, Hjem does not have the
capability to actually source them. This can be done manually, which is what
Hjem Rum tries to do.

Currently, some of our modules may add environmental variables (such as our GTK
module), but cannot load them without the use of another module. Currently,
modules that load environmental variables include:

- [programs/fish]
- [programs/zsh]
- [programs/nushell]
- [desktops/hyprland]

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
