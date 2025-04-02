# Hjem Rum

A module collection for managing your `$HOME` with [Hjem](https://github.com/feel-co/hjem).

## A brief explanation

Based on the Hjem tooling, Hjem Rum (literally meaning "home rooms") is a collection of modules for various programs and services to simplify the use of Hjem for managing your `$HOME` files.

Hjem was initially created as an improved implementation of the `home` functionality that Home Manager provides. Its purpose was minimal. Hjem Rum's purpose is to create a module collection based on that tooling in order to recreate the functionality that Home Manager's large collection of modules provides, allowing you to simply install and config a program.

## Setup

To start using Hjem Rum, you must first import the flake and its modules into your system(s):

```nix
# flake.nix
inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem = {
        url = "github:feel-co/hjem";
        # You may want hjem to use your defined nixpkgs input to
        # minimize redundancies
        inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-rum = {
        url = "github:snugnug/hjem-rum";
        # You may want hjem-rum's inputs to follow your defined
        # inputs to minimize redundancies
        inputs.nixpkgs.follows = "nixpkgs";
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

Be sure to first set the necessary settings for Hjem and import the Hjem module from the input:

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

You can then configure any of the options defined in this flake in any nix module:

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

## Contributing

Hjem Rum is always in need of contribution. Please see [CONTRIBUTING.md](./docs/CONTRIBUTING.md) for more information on how to contribute and our guidelines.

## Credits

Credit goes to [@NotAShelf](https://github.com/NotAShelf) and [@éclairevoyant](https://github.com/eclairevoyant) for creating Hjem.

## License

All the code within this repository is protected under the GPLv3 license unless explicitly stated otherwise within a file. Please see [LICENSE](LICENSE) for more information.
