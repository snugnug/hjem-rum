let
  settings = {
    font_size = 12.0;
    cursor_shape = "beam";
    cursor_trail = 1;
  };
in {
  name = "programs-kitty";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.kitty = {
        enable = true;
        inherit settings;
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confPath = "/home/bob/.config/kitty/kitty.conf"

      # Verifying that something from the config has actually been written to the file
      machine.succeed("grep '${settings.cursor_shape}' < %s" % confPath)
    '';
}
