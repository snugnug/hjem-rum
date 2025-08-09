let
  settings = {
    main = {
      term = "xterm-256color";
      font = "NotoSansM Nerd Font Mono:size=13";
    };
    mouse.hide-when-typing = "yes";
    colors.alpha = 0.8;
    scrollback = {
      lines = 90000;
      indicator-position = "none";
    };
  };
in {
  name = "programs-foot";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.foot = {
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

      confPath = "/home/bob/.config/foot/foot.ini"

      # Letting foot check the validity of the config file
      machine.succeed("su bob -c 'foot -C -c %s'" % confPath);

      # Verifying that something from the config has actually been written to the file
      machine.succeed("grep '${settings.main.font}' < %s" % confPath)
    '';
}
