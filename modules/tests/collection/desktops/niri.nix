{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkForce;
in {
  name = "desktops-niri";
  nodes.machine = {
    specialisation.nullPackage.configuration = {
      hjem.users.bob = {
        clobberFiles = mkForce true; # Enable clobber to clobber the generated file
        rum.desktops.niri = {
          # Create an action that is valid in the module but invalid in niri.
          # This ensures that the check phase is indeed skipped.
          binds."Mod+9".action = "bad-action";
          package = null;
        };
      };
    };
    hjem.users.bob = {
      environment.sessionVariables = {
        RUM_TEST = "HEY";
        INTEGER = 1;
        STRINGS = ["FOO" "BAR" "BAZ"];
      };

      rum.desktops.niri = let
        noCsdKdl = pkgs.writeText "no-csd.kdl" ''
          prefer-no-csd
        '';
      in {
        enable = true;
        includes = [noCsdKdl];
        extraVariables = {
          RUM_TEST_TWO = "HELLO";
          NULL = null;
        };
        binds = {
          "Mod+T" = {
            action = "focus-column-left";
          };
          "Mod+R" = {
            spawn = ["alacritty" "-e" "nu"];
            parameters = {
              hotkey-overlay-title = "Open Alacritty";
              allow-when-locked = true;
            };
          };
          "Mod+Y" = {
            action = "focus-column-right";
            parameters.cooldown-ms = 150;
          };
          "Mod+Escape" = {
            action = "toggle-overview";
            parameters = {
              repeat = false;
              hotkey-overlay-title = null;
            };
          };
        };
        spawn-at-startup = [
          ["waybar"]
          ["foot" "-e" "fish"]
        ];
        config = ''
          switch-events {
            lid-close { spawn "notify-send" "The laptop lid is closed!"; }
            lid-open { spawn "notify-send" "The laptop lid is open!"; }
          }
        '';
      };
    };
  };
  # Most of the functionality in niri is tested by the checkphase in the
  # generated linked file by niri itself. However, we still want to make sure
  # that our abstracted options are writing to that generated file, otherwise
  # we could run into a case where the file is valid but some of our settings
  # aren't actually being written and tested.
  testScript = {nodes, ...}: let
    baseSystem = nodes.machine.system.build.toplevel;
    specialisations = "${baseSystem}/specialisation";
  in
    #python
    ''
      config = "/home/bob/.config/niri/config.kdl"

      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      machine.succeed("test -L %s" % config)

      with subtest("Validate includes"):
        pattern = r'include ^/nix/store/[^/]+-no-csd.kdl$'
        machine.succeed(f"grep -E '{pattern}' %s" % config)

      with subtest("Validate binds"):
        machine.succeed("grep 'Mod+T  {focus-column-left;}' %s" % config)
        machine.succeed("grep 'Mod+Y cooldown-ms=150 {focus-column-right;}' %s" % config)
        # Split multi-parameter checks since it has two parameters
        # that might not necessarily be in one set order. If these
        # strings are here, and the file validates, it should be working
        # just fine.
        machine.succeed("grep 'Mod+Escape' %s" % config)
        machine.succeed("grep 'hotkey-overlay-title=null' %s" % config)
        machine.succeed("grep 'repeat=false' %s" % config)
        machine.succeed("grep '{toggle-overview;}' %s" % config)
        machine.succeed("grep '{spawn \"alacritty\" \"-e\" \"nu\";}' %s" % config)
        machine.succeed("grep 'hotkey-overlay-title=\"Open Alacritty\"' %s" % config)
        machine.succeed("grep 'allow-when-locked=true' %s" % config)

      with subtest("Validate environment"):
        machine.succeed("grep 'RUM_TEST \"HEY\"' %s" % config)
        machine.succeed("grep 'RUM_TEST_TWO \"HELLO\"' %s" % config)
        machine.succeed("grep 'INTEGER \"1\"' %s" % config)
        machine.succeed("grep 'STRINGS \"FOO:BAR:BAZ\"' %s" % config)
        machine.succeed("grep 'NULL null' %s" % config)

      with subtest("Validate spawn-at-startup"):
        machine.succeed("grep 'spawn-at-startup \"waybar\"' %s" % config)
        machine.succeed("grep 'spawn-at-startup \"foot\" \"-e\" \"fish\"' %s" % config)

      # Similar story here, if we tried to check the whole string,
      # python would throw a fit. So, instead, we just check for a snippet
      # If it was broken, the check phase on the file would let us know
      with subtest("Validate config"):
        machine.succeed("grep 'lid-close' %s" % config)

      with subtest("Validate skipping check phase"):
        machine.succeed("${specialisations}/nullPackage/bin/switch-to-configuration test")
        machine.succeed("grep 'bad-action' %s" % config)
    '';
}
