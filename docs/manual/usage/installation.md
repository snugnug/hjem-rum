# Usage: Installing Hjem Rum {#usage-installing-hjem-rum}

[**Options**]: ../options.html
[**Quirks, Tips, and Tricks**]: ./quirks.html

Welcome to Hjem Rum. Installing and configuring Hjem Rum is as easy as any other
module.

## Importing the Hjem Rum Flake {#ch-importing-the-hjem-rum-flake}

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
                ./configuration.nix
            ];
        };
    };
}
```

## Using Hjem Rum Modules {#ch-using-hjem-rum-modules}

You can declare Hjem Rum modules either in a NixOS module, imported into all
your hosts, or as a special Hjem module, imported directly into Hjem. If you do
not know which to choose, we recommend configuring Hjem Rum in NixOS modules.

> [!INFO]
> For the purposes of this example, we will be pretending your username is
> `alice`.

### Configuring in a NixOS Module {#sec-configuring-in-a-nixos-module}

To configure Hjem Rum in a NixOS Module, set the according settings, import Hjem
Rum's flake output, and configure away.

```nix
# configuration.nix
{
    pkgs,
    inputs,
    ...
}: {
    hjem = {
        # Import the module collection
        extraModules = [inputs.hjem-rum.hjemModules.default];

        # We recommend using the experimental linker
        linker = inputs.hjem.packages."x86_64-linux".smfh; # Use your host's system

        # Configuring your user(s)
        users.alice = {
            enable = true;
            directory = "/home/alice";
            user = "alice";
            rum.programs.alacritty = {
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
            };
        };
    };
}
```

This setup is ideal for a single-user configuration, as you can easily integrate
your home configuration right in your system. It minimizes friction and creates
a single-setup configuration. You can, of course, modularize your configuration
into files, like you should do for NixOS:

```nix
# configuration.nix
{
    imports = [./hjem];
}
```

```nix
# hjem/default.nix
{
    config,
    inputs,
    ...
}: {
    imports = [
        ./alacritty.nix
    ];
    config.hjem = {
        # Import the module collection
        extraModules = [inputs.hjem-rum.hjemModules.default];

        # We recommend using the experimental linker
        linker = inputs.hjem.packages."x86_64-linux".smfh; # Use your host's system

        # Configuring your user(s)
        users.alice = {
            enable = true;
            directory = "/home/alice";
            user = "alice";
        };
    };
}
```

```nix
# hjem/alacritty.nix
{pkgs,...}: {
    hjem.users.alice.rum.programs.alacritty = {
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
    };
}
```

Using this setup, a single-user configuration can be well implemented into your
existing NixOS configuration. For example, you could configure the necessary
system-wide configurations for your desktop environment and manage its dotfiles
in the same file or directory.

### Configuring in a Hjem Module {#sec-configuring-in-a-hjem-module}

Alternatively, if you would rather separate your Hjem modules from your NixOS
modules, you can simply import Hjem Rum's modules and Nix files written as Hjem
modules straight into your Hjem user.

```nix
# configuration.nix
{inputs, ...}: {
    hjem = {
        # Import the module collection
        extraModules = [inputs.hjem-rum.hjemModules.default];

        # We recommend using the experimental linker
        linker = inputs.hjem.packages."x86_64-linux".smfh; # Use your host's system

        # Configuring your user(s)
        users.alice = {
            enable = true;
            directory = "/home/alice";
            user = "alice";
            imports = [./hjem/alice];
        };
    };
}
```

```nix
# hjem/alice/default.nix
{
    imports = [./alacritty.nix];
}
```

```nix
# hjem/alice/alacritty.nix
{pkgs, ...}: {
    rum.programs.alacritty = {
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
    };
}
```

In this example, Alacritty would only be enabled and configured in the user the
module is imported into. Using this setup, you could also import Hjem Rum
exclusively into the user, rather than into {option}`hjem.extraModules`.

```nix
# configuration.nix
{inputs, ...}: {
    hjem = {
        # Don't import the flake into all users
        extraModules = [];

        # Instead, import it into a single user
        users.alice = {
            imports = [
                inputs.hjem-rum.hjemModules.default
                ./hjem/alice
            ];
        };
    };
}
```

Keep in mind, if you wish to access any specialArgs, you will need to declare
them in {option}`hjem.specialArgs`:

```nix
# configuration.nix
{inputs, ...}: {
    hjem = {
        specialArgs = {inherit inputs;}; # inputs = inputs
        users.alice.imports = [./hjem/alice];
    };
}
```

```nix
# hjem/alice/default.nix
{inputs, ...}: {
    imports = [inputs.hjem-rum.hjemModules.default];
}
```

In this example, this allows us to import the Hjem Rum collection inside of a
user-specific Hjem module.

## Beyond Installation {#ch-beyond-installation}

Please see [**Options**] for a thorough list of options you can set.

Additionally, please see [**Usage: Quirks, Tips, and Tricks**] for important
information regarding your usage of Hjem Rum.
