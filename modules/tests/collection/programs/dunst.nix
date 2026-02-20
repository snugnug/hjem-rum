{
  name = "programs-dunst";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.dunst = {
        enable = true;
        settings = {
          global = {
            font = "Roboto Mono 8";
            frame_width = 2;
            offset = "(40,50)";
            origin = "top-right";
            separator_height = 2;
            sort = true;
            transparency = 0;
            width = 300;
          };
          urgency_low = {
            background = "\"#191919\"";
            foreground = "\"#BBBBBB\"";
          };
          urgency_normal = {
            background = "\"#191919\"";
            foreground = "\"#BBBBBB\"";
          };
          urgency_critical = {
            background = "\"#191919\"";
            foreground = "\"#DE6E7C\"";
          };
        };
      };
    };
  };

  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    confPath = "/home/bob/.config/dunst/dunstrc"

    # Check if the dunst config file exists in the expected place.
    machine.succeed("[ -r %s ]" % confPath)

    # Validate the contents of the config file.
    machine.fail("su bob -c 'dunst -config %s >/tmp/dunst.log 2>&1'" % confPath)
    stdout = machine.succeed("cat /tmp/dunst.log")
    logs, _ = stdout.split("WARNING: Cannot open X11 display.")
    if "WARNING" in logs:
      raise AssertionError(f"Unexpected WARNING in dunst logs:\n\n{logs}")
  '';
}
