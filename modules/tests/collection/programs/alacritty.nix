{pkgs, ...}: {
  name = "programs-alacritty";
  nodes.machine = {
    hjem.users.bob = {
      packages = [pkgs.xvfb-run];
      rum.programs.alacritty = {
        enable = true;
        settings = {
          window = {
            dimensions = {
              lines = 28;
              columns = 101;
            };
            padding = {
              x = 6;
              y = 3;
            };
          };
        };
      };
    };
  };

  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    confPath = "/home/bob/.config/alacritty/alacritty.toml"

    with subtest("Verify if alacritty is in $PATH"):
        machine.succeed("su bob -c 'which alacritty'")

    with subtest("Verify if the config file is in place"):
        machine.succeed("[ -r %s ]" % confPath)

    with subtest("Verify if alacritty is satisfied with the config file and its contents"):
        _, stdout = machine.execute("su bob -c 'xvfb-run alacritty --command true'")
        assert "alacritty_config_derive" not in stdout, f"alacritty reported an issue with the generated config:\n\n{stdout}"
  '';
}
