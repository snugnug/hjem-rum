{
  name = "mpv";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.mpv = {
        enable = true;
        config = {
          hwdec = true;
        };
        profiles = {
          fast = {
            cache = true;
          };
        };
        bindings = {
          WHEEL_UP = "seek 10";
        };
        scriptOpts = {
          osc = {
            vidscale = false;
          };
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

      # Assert that the mpv config is in place
      pattern = 'hwdec=yes'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/mpv/mpv.conf")

      # Assert that the profiles are in place
      pattern = '[fast]'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/mpv/mpv.conf")

      # Assert that the bindings are in place
      pattern = 'WHEEL_UP seek 10'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/mpv/bindings.conf")

      # Assert that the script's options are in place
      pattern = 'vidscale=no'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/mpv/script-opts/osc.conf")
    '';
}
