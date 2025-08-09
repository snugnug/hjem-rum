{pkgs, ...}: {
  name = "programs-fish";
  nodes.machine = {
    hjem.users.bob = {
      environment.sessionVariables = {
        RUM_TEST = "HEY";
      };

      rum.programs.fish = {
        enable = true;
        plugins = {inherit (pkgs.fishPlugins) z;};
        earlyConfigFiles = {
          hello = ''
            echo Welcome
          '';
        };
        abbrs = {
          foo = "bar";
        };
        aliases = {
          ping = "ping -c 5";
        };
      };
    };
  };
  testScript =
    #python
    ''
      fishConfD = "/home/bob/.config/fish"

      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      with subtest("Validate earlyConfigFiles"):
          file = "%s/conf.d/hello.fish" % fishConfD
          machine.succeed("test -f %s" % file)
          stdout = machine.succeed(file)
          assert stdout == "Welcome\n", "hello.fish did not output the expected string"

      with subtest("Validate abbreviations"):
          machine.succeed("su bob -c 'fish -c \"abbr --query foo\" '")
          machine.fail("su bob -c 'fish -c \"abbr --query missing\" '")

      with subtest("Validate aliases"):
          machine.succeed("su bob -c 'fish -c \"alias | grep ping\" '")

      with subtest("Loading of environment variables"):
          machine.succeed("su bob -c \"fish -c 'set -q RUM_TEST'\"")
          var = machine.succeed("su bob -c \"fish -c 'set -S RUM_TEST'\"")
          assert "HEY" in var, "Env var RUM_TEST does not contain HEY"
    '';
}
