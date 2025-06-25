# Usage: Installing Hjem Rum {#usage-installing-hjem-rum}

[**Options**]: ../options.html

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
                ./modules
            ];
        };
    };
}
```

## Using Hjem Rum Modules {#ch-using-hjem-rum-modules}

You can declare Hjem Rum modules either in a NixOS module, imported into all
your hosts, or as a special "Hjem" module, imported directly into Hjem. If you
do not know which to choose, we recommend configuring Hjem Rum in NixOS modules.

Please see [**Options**] for a thorough list of options you can set.

### Configuring in NixOS Modules {#sec-configuring-in-nixos-modules}

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

        # You should probably also enable clobberByDefault at least for now.
        clobberByDefault = true;

        # Configuring your user(s)
        users.<username> = {
            enable = true;
            directory = "/home/<username>";
            user = "<username>";
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
    imports = [
        ./hjem
    ];
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

        # You should probably also enable clobberByDefault at least for now.
        clobberByDefault = true;

        # Configuring your user(s)
        users.<username> = {
            enable = true;
            directory = "/home/<username>";
            user = "<username>";
        };
    };
}
```

```nix
# hjem/alacritty.nix
{pkgs,...}: {
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
    };
}
```

Using this setup, a single-user configuration can be well implemented into your
existing NixOS configuration. For example, you could configure the necessary
system-wide configurations for your desktop environment and manage its dotfiles
in the same file or directory.

### Configuring in Hjem Modules {#sec-configuring-in-hjem-modules}

Alternatively, if you would rather separate your Hjem modules from your NixOS
modules, you can simply import Hjem Rum's modules and Nix files written as Hjem
modules straight into your Hjem user.

```nix
# configuration.nix
{inputs, ...}: {
    hjem = {
        # Import the module collection
        extraModules = [inputs.hjem-rum.hjemModules.default];

        # You should probably also enable clobberByDefault at least for now.
        clobberByDefault = true;

        # Configuring your user(s)
        users.<username> = {
            enable = true;
            directory = "/home/<username>";
            user = "<username>";
            imports = [./hjem/<username>];
        };
    };
}
```

```nix
# hjem/<username>/default.nix
{
    imports = [./alacritty.nix];
}
```

```nix
# hjem/<username>/alacritty.nix
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
        users.<username> = {
            imports = [
                inputs.hjem-rum.hjemModules.default
                ./hjem/<username>
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
        users.<username>.imports = [./hjem/<username>];
    };
}
```

```nix
# hjem/<username>/default.nix
{inputs, ...}: {
    imports = [inputs.hjem-rum.hjemModules.default];
}
```

In this example, this allows us to import the Hjem Rum collection inside of a
user-specific Hjem module.
