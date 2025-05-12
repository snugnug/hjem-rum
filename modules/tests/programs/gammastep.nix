let
  settings = {
    general.location-provider = "manual";

    manual = {
      lat = -12.5;
      lon = -10.7;
    };
  };

  hooks.my-hook = ''
    #!/usr/bin/env sh
    case $3 in
      daytime)
        echo "Hello, day!"
      ;;
    esac
  '';
in {
  name = "programs-gammastep";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.gammastep = {
        enable = true;
        inherit settings hooks;
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confPath = "/home/bob/.config/gammastep/config.ini"
      hookPath = "/home/bob/.config/gammastep/hooks/my-hook"

      # Verifying that something from the config has actually been written to the config file
      machine.succeed("grep '${settings.general.location-provider}' < %s" % confPath)

      # Verifying that something from the config has actually been written to the hook file
      machine.succeed("grep 'daytime' < %s" % hookPath)
    '';
}
