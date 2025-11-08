{
  name = "programs-winboat";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.winboat = {
        enable = true;
        settings = {
          customApps = [
            {
              Name = "Bob's favourite app";
              Path = "C:\\Users\\bob\\Downloads\\App\\app.exe";
              Source = "custom";
            }
          ];
          experimentalFeatures = true;
          rdpMonitoringEnabled = false;
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

      # Checks if the winboat config file exists in the expected place.
      machine.succeed("[ -r %s ]" % "/home/bob/.config/winboat")
    '';
}
