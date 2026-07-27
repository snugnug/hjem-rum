{
  name = "programs-gammastep";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.gammastep = {
        enable = true;
        settings = {
          general = {
            temp-day = 5700;
            temp-night = 3600;
            brightness-day = "0.9";
            brightness-night = "0.7";
            gamma-day = "0.8:0.7:0.6";
            gamma-night = "0.5";
            elevation-high = 5;
            elevation-low = -3;
            adjustment-method = "randr";
            location-provider = "manual";
          };

          manual = {
            lat = "55.7";
            lon = "12.6";
          };
        };
      };
    };
  };

  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    with subtest("Verify if gammastep is in $PATH"):
        machine.succeed("su bob -c 'which gammastep'")

    with subtest("Verify if the config file is in place"):
        confPath = "/home/bob/.config/gammastep/config.ini"
        machine.succeed("[ -r %s ]" % confPath)

    with subtest("Verify if gammastep is able to correctly read our config"):
        stdout = machine.succeed("su bob -c 'gammastep -vp' 2>&1")
        expected_lines = [
            "Notice: Solar elevations: > 5.0 (Day), < -3.0 (Night)",
            "Notice: Temperatures: 5700K (Day), 3600K (Night)",
            "Notice: Brightness: 0.90:0.70",
            "Notice: Gamma (Day): 0.800, 0.700, 0.600",
            "Notice: Gamma (Night): 0.500, 0.500, 0.500",
            "Notice: Location: 55.70 N, 12.60 E",
        ]
        for line in expected_lines:
            assert line in stdout, (
                "Expected line not found in gammastep output: %r\n"
                "Full output was:\n%s" % (line, stdout)
            )
  '';
}
