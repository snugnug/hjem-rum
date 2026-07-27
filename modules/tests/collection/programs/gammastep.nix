{pkgs, ...}: {
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

        hooks = {
          record-period = pkgs.writeShellScript "record-period" ''
            case $1 in
              period-changed)
                echo "$2 -> $3" >> "$HOME/gammastep-period";;
            esac
          '';
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

    with subtest("Verify if the config files are in place"):
        confPath = "/home/bob/.config/gammastep/config.ini"
        machine.succeed("[ -r %s ]" % confPath)

        hookPath = "/home/bob/.config/gammastep/hooks/record-period"
        machine.succeed("[ -r %s ]" % hookPath)
        machine.succeed("test -x %s" % hookPath)

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

    with subtest("Verify if gammastep is able to correctly exec our hook"):
        machine.succeed("su bob -c 'timeout 5 gammastep -m dummy -v || true'")
        machine.wait_for_file("/home/bob/gammastep-period")
        startup, shutdown = machine.succeed("cat /home/bob/gammastep-period").strip().splitlines()

        old, _, new = startup.partition(" -> ")
        assert old == "none" and new in ("daytime", "night", "transition"), (
            "Unexpected startup event: %r" % startup
        )
        old, _, new = shutdown.partition(" -> ")
        assert old in ("daytime", "night", "transition") and new == "none", (
            "Unexpected shutdown event: %r" % shutdown
        )
  '';
}
