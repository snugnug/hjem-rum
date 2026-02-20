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
        plugins = {inherit (pkgs.yaziPlugins) git;};
        flavors = let
          yaziFlavors = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "flavors";
            rev = "2d73b79da7c1a04420c6c5ef0b0974697f947ef6";
            hash = "sha256-+awiEG5ep0/6GaW8YXJ7FP0/xrL4lSrJZgr7qjh8iBc=";
          };
        in {
          dracula = "${yaziFlavors}/dracula.yazi";
        };
      };
    };
  };

  testScript = let
    schemaSrc = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "schemas";
      rev = "c70a80ea3d2acaeeb8b8b0dfcd86360320df4348";
      hash = "sha256-vVN1glI+4mxmvurEclzCPt434Hn0p/SPzm50tpk2lHE=";
    };
  in
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confDir = "/home/bob/.config/yazi"
      yaziConfPath = confDir + "/yazi.toml"
      keymapConfPath = confDir + "/keymap.toml"
      themeConfPath = confDir + "/theme.toml"
      gitPluginDir = confDir + "/plugins/git.yazi"
      draculaFlavorDir = confDir + "/flavors/dracula.yazi"

      # Checks if the yazi config files exists in the expected place.
      machine.succeed("[ -r %s ]" % yaziConfPath)
      machine.succeed("[ -r %s ]" % keymapConfPath)
      machine.succeed("[ -r %s ]" % themeConfPath)
      machine.succeed("[ -d %s ]" % gitPluginDir)
      machine.succeed("[ -d %s ]" % draculaFlavorDir)

      # Checks if the yazi config files are valid
      machine.succeed("su bob -c 'taplo check --schema file://${schemaSrc}/schemas/yazi.json %s'" % yaziConfPath)
      machine.succeed("su bob -c 'taplo check --schema file://${schemaSrc}/schemas/keymap.json %s'" % keymapConfPath)
      machine.succeed("su bob -c 'taplo check --schema file://${schemaSrc}/schemas/theme.json %s'" % themeConfPath)
    '';
}
