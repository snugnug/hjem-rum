let
  settings = {
    buffer = {
      images = true;
      autofocus = true;
    };
    page."C-k" = "() => pager.load('ddg:')";
  };
in {
  name = "programs-chawan";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.chawan = {
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

      confPath = "/home/bob/.config/chawan/config.toml"

      # Checks if the chawan config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)
    '';
}
