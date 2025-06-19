# Hjem Rum

[Hjem]: https://github.com/feel-co/hjem
[our docs]: ./CONTRIBUTING.md
[license]: ../LICENSE
[programs/fish]: modules/collection/programs/fish.nix
[programs/nushell]: modules/collection/programs/nushell.nix
[programs/zsh]: modules/collection/programs/zsh.nix
[programs/nushell]: modules/collection/programs/nushell.nix
[programs/hyprland]: modules/collection/programs/hyprland.nix
[#17]: https://github.com/snugnug/hjem-rum/issues/17
[@eclairevoyant]: https://github.com/eclairevoyant
[@NotAShelf]: https://github.com/NotAShelf
[documentation]: rum.snugnug.org
[contributors]: https://github.com/snugnug/hjem-rum/graphs/contributors
[Home Manager]: https://github.com/nix-community/home-manager

A module collection for managing your `$HOME` with [Hjem].

## A brief explanation

> [!WARNING]
> Hjem Rum is currently considered alpha software―here be dragons. While many of
> us currently use its modules in our NixOS configurations, that does not mean
> it will necessarily offer a seamless experience yet, nor does it mean there
> will not be breaking changes (there will). As Hjem Rum continues to grow and
> evolve, it should become more stable and expansive, but please be patient as
> it is a hobby project. Furthermore, Hjem, the tooling Hjem Rum is built off
> of, is still unfinished and missing critical features, such as services. Hjem
> Rum is still useable, but it is not for a novice user.

Built off the Hjem tooling, Hjem Rum (loosely translated to "rooms of a home")
is a collection of modules for various applications intended to simplify `$HOME`
management for usage and configuration of applications.

Hjem was initially created as a streamlined implementation of the `home`
functionality that Home Manager provides. Hjem Rum, in contrast, is intended to
provide an expansive module collection as a useful abstraction for users to
configure their applications with ease, recreating Home Manager's complete
functionality.

## Setup

To use Hjem Rum, simply add and import Hjem and Hjem Rum into your flake:

```nix
# flake.nix
inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    # To minimize redundancies, we suggest you set your flakes to follow your inputs.
    hjem = {
        url = "github:feel-co/hjem";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-rum = {
        url = "github:snugnug/hjem-rum";
        inputs = {
            nixpkgs.follows = "nixpkgs";
            hjem.follows = "hjem";
        };
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
                inputs.hjem.nixosModules.default # Import the hjem module
                ./modules
            ];
        };
    };
}
```

Be sure to first set the necessary settings for Hjem and import Hjem Rum's Hjem
module from the input:

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

You can then configure any of the options defined in this flake in any nix
module:

```nix
# configuration.nix
hjem.users.<username>.rum.programs.alacritty = {
    enable = true;
    package = pkgs.alacritty; # Default
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

## Environmental Variables

Hjem provides attribute set "environment.sessionVariables" that allows the user
to set environmental variables to be sourced. However, Hjem does not have the
capability to actually source them. This can be done manually, which is what
Hjem Rum tries to do.

Currently, some of our modules may add environmental variables (such as our GTK
module), but cannot load them without the use of another module. Currently,
modules that load environmental variables include:

- [programs/fish]
- [programs/nushell]
- [programs/zsh]
- [programs/hyprland]

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

## Contribution

If you are interested in contributing to Hjem Rum, please check out our
contributing guidelines on [our docs]. We are always interested in
contributions, particularly as Hjem Rum is inherently a very, very broad task.
If you are new, unfamiliar, or otherwise scared of trying to contribute, please
know that any contribution helps, big or small, and that reviewers are here to
help you contribute and write good code for this project.

## Credits

Credit goes to [@NotAShelf] and [@eclairevoyant] for creating Hjem.

We would also like to give special thanks to all [contributors], past and
present, for making Hjem Rum what it is today.

Additionally, we would like to thank everyone who has contributed or maintained
[Home Manager], as without them, this project likely would not be possible, or
even be conceived.

## License

All the code within this repository is protected under the GPLv3 license unless
explicitly stated otherwise within a file. Please see [LICENSE] for more
information.
