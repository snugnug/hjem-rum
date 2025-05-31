{pkgs, ...}: let
  settings = {
    font_size = 12.0;
    cursor_shape = "beam";
    cursor_trail = 1;
  };

  theme.no-preference = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";

  extraConfFiles = {
    "diff.conf" = ''
      ignore_name .git
    '';
  };
in {
  name = "programs-kitty";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.kitty = {
        enable = true;
        inherit settings theme extraConfFiles;
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      kittyConfD = "/home/bob/.config/kitty"
      confPath = f"{kittyConfD}/kitty.conf"
      themePath = f"{kittyConfD}/no-preference-theme.auto.conf"
      diffCfgPath = f"{kittyConfD}/diff.conf"

      # Verifying that something from the config has actually been written to the file
      machine.succeed("grep '${settings.cursor_shape}' < %s" % confPath)

      # Verifying that the theme has actually been written to the file
      machine.succeed("grep 'Modus Vivendi' < %s" % themePath)

      # Verifying that something from the diff config has actually been written to the file
      machine.succeed("grep 'ignore_name .git' < %s" % diffCfgPath)

    '';
}
