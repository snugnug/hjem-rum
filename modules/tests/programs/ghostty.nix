let
  settings = {
    theme = "example-theme";
    font-size = 10;
    keybind = [
      "ctrl+h=goto_split:left"
      "ctrl+l=goto_split:right"
    ];
  };
  themes = {
    example-theme = {
      background = "#303446";
      cursor-color = "#f2d5cf";
      cursor-text = "#c6d0f5";
      foreground = "#c6d0f5";
      palette = [
        "0=#51576d"
        "1=#e78284"
        "2=#a6d189"
        "3=#e5c890"
        "4=#8caaee"
        "5=#f4b8e4"
        "6=#81c8be"
        "7=#a5adce"
        "8=#626880"
        "9=#e67172"
        "10=#8ec772"
        "11=#d9ba73"
        "12=#7b9ef0"
        "13=#f2a4db"
        "14=#5abfb5"
        "15=#b5bfe2"
      ];
      selection-background = "#626880";
      selection-foreground = "#c6d0f5";
    };
  };
in {
  name = "programs-ghostty";
  nodes.machine = {self, ...}: {
    hjem.extraModules = ["${self.modulesPath}/programs/ghostty.nix"];
    hjem.users.bob.rum = {
      programs.ghostty = {
        enable = true;
        inherit settings themes;
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confDir = "/home/bob/.config/ghostty"
      confPath = confDir + "/config"

      # Letting Ghostty check the validity of the config file
      machine.succeed("su bob -c 'ghostty +validate-config --config-file=%s'" % confPath);

      # Testing that the theme exists at the expected location
      machine.succeed("su bob -c 'find %s -name ${settings.theme}'" % confDir);

      # Verifying that something from the config has actually been written to the file
      machine.succeed("grep '${toString settings.font-size}' %s" % confPath)
    '';
}
