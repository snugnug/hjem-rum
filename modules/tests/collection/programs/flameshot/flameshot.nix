let
  settings = {
    General = {
      disabledTrayIcon = true;
      saveLastRegion = true;
      showDesktopNotification = false;
      showStartupLaunchMessage = false;
    };
    Shortcuts = {
      TYPE_ARROW = "A";
      TYPE_CIRCLE = "C";
    };
  };
in {
  name = "programs-flameshot";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.flameshot = {
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

      confPath = "/home/bob/.config/flameshot/flameshot.ini"

      # Checks if the flameshot config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)

      # Letting flameshot check the validity of the config file
      machine.succeed("su bob -c 'flameshot config --check'");
    '';
}
