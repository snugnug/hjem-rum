{...}: {
  name = "ncmpcpp-test";
  nodes = {
    machine = {
      hjem.users.bob.rum = {
        programs.ncmpcpp = {
          enable = true;

          # This aims to test the ncmpcpp generator type conversion
          # Options were chose at random
          settings = {
            mpd_host = "localhost";
            mpd_port = 6600;
            mpd_crossfade_time = 32;
            incremental_seeking = true;
          };

          bindings = {
            keys = [
              {
                binding = "ctrl-q";
                actions = ["stop" "quit"];
              }
              {
                binding = "q";
                actions = ["quit"];
                deferred = true;
              }
            ];
            commands = [
              {
                binding = "!sq";
                actions = ["stop" "quit"];
              }
              {
                binding = "!q";
                actions = ["quit"];
                deferred = true;
              }
            ];
          };
        };
      };
    };
  };
  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    # Checks if ncmpcpp config file exists in the expected place.
    machine.succeed("[ -r ~bob/.config/ncmpcpp/config ]")

    # Checks if ncmpcpp bindings file exists in the expected place.
    machine.succeed("[ -r ~bob/.config/ncmpcpp/bindings ]")

    # These statements copy the specified files from the nix sandbox (left argument)
    # and write them to a specified location in the host vm (right argument).
    # By doing this, we can access these files from our vm shell!
    machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
    machine.copy_from_host("${./expected_bindings}", "/home/bob/expected_bindings")

    # Assert that both files have the expected content.
    machine.succeed("diff -u -Z -b -B /home/bob/.config/ncmpcpp/config /home/bob/expected_config")
    machine.succeed("diff -u -Z -b -B /home/bob/.config/ncmpcpp/bindings /home/bob/expected_bindings")
  '';
}
