let
  settings = {
    options.suppress_default_binds = true;
    binds = {
      "<Ctrl+r>" = "rotate by 90";
      "<period>" = "next_frame";
      "<space>" = "toggle_playing";
      "t" = "slideshow +1";
      "<Shift+T>" = "slideshow -1";
    };
  };
in {
  name = "programs-imv";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.imv = {
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

      confPath = "/home/bob/.config/imv/config"

      # Checks if the imv config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)
    '';
}
