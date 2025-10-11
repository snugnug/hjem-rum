{pkgs, ...}: {
  name = "programs-yazi";
  nodes.machine = {
    environment.systemPackages = [pkgs.taplo];

    hjem.users.bob.rum = {
      programs.yazi = {
        enable = true;
        settings = {
          mgr.show_hidden = true;
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = "<C-a>";
              run = "my-cmd1";
              desc = "Single command with `Ctrl + a`";
            }
          ];
        };
        theme = {
          flavor = {
            dark = "dracula";
            light = "gruvbox";
          };
        };
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confDir = "/home/bob/.config/yazi"
      yaziConfPath = confDir + "/yazi.toml"
      keymapConfPath = confDir + "/keymap.toml"
      themeConfPath = confDir + "/theme.toml"

      # Checks if the yazi config files exists in the expected place.
      machine.succeed("[ -r %s ]" % yaziConfPath)
      machine.succeed("[ -r %s ]" % keymapConfPath)
      machine.succeed("[ -r %s ]" % themeConfPath)

      # Checks if the yazi config files are valid
      machine.succeed("su bob -c 'taplo check --schema https://yazi-rs.github.io/schemas/yazi.json %s'" % yaziConfPath)
      machine.succeed("su bob -c 'taplo check --schema https://yazi-rs.github.io/schemas/keymap.json %s'" % keymapConfPath)
      machine.succeed("su bob -c 'taplo check --schema https://yazi-rs.github.io/schemas/theme.json %s'" % themeConfPath)
    '';
}
