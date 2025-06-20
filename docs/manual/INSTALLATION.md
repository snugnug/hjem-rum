# Installing Hjem Rum

Welcome to Hjem Rum. Installing and configuring Hjem Rum is as easy as any other
module.

## Importing the Hjem Rum Flake

To begin using Hjem Rum, simply add and import Hjem and Hjem Rum into your
flake:

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

## Important Hjem Settings

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

## Configuring Hjem Rum Modules

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

Please see the options page for a thorough list of options you can set.
