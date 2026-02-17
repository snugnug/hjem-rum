let
  settings = {
    logo.source = "nixos_old_small";
    display = {
      constants = ["██ "];
    };
    modules = [
      {
        key = "{$1}Distro";
        keyColor = "38;5;210";
        type = "os";
      }
    ];
  };
in {
  name = "programs-fastfetch";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.fastfetch = {
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

      confPath = "/home/bob/.config/fastfetch/config.jsonc"

      # Checks if the fastfetch config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)
    '';
}
