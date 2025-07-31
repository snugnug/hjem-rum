let
  settings = {
    display = {
      compact = false;
      use_pager = true;
    };
    style.command_name.foreground = "red";
    style.example_code.foreground = "blue";
    style.example_text.foreground = "green";
    style.example_variable = {
      foreground = "blue";
      underline = true;
    };
    updates.auto_update = true;
  };
in {
  name = "programs-tealdeer";
  nodes.machine = {self, ...}: {
    hjem.extraModules = ["${self.modulesPath}/programs/tealdeer.nix"];
    hjem.users.bob.rum = {
      programs.tealdeer = {
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

      confPath = "/home/bob/.config/tealdeer/config.toml"

      # Checks if the tealdeer config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)
    '';
}
