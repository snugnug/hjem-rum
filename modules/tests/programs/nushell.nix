{pkgs, ...}: let
  envFile = ''
    $env.config.color_config.shape_bool = "green"
    $env.MY_VAR = "yellow"
  '';
  loginFile = ''
    #!/usr/bin/env nu

    let-env PROMPT_INDICATOR = { ">>" }
  '';
in {
  name = "programs-nushell";
  nodes.machine = {self, ...}: {
    hjem.extraModules = ["${self.modulesPath}/programs/nushell.nix"];
    hjem.users.bob = {
      environment.sessionVariables = {
        RUM_TEST = "HEY";
      };

      rum.programs.nushell = {
        enable = true;
        plugins = with pkgs.nushellPlugins; [
          formats
        ];
        settings = {
          show_banner = false;
          history = {
            max_size = "1_000_000";
            sync_on_enter = true;
          };
        };
        aliases = {
          ll = "ls -l";
        };

        extraConfig = ''
          $env.config.buffer_editor = "vi"
        '';

        inherit envFile loginFile;
      };
    };
  };
  testScript =
    #python
    ''
      configDir = "/home/bob/.config/nushell"
      configFile = "%s/config.nu" % configDir

      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      with subtest("Verify settings."):
        machine.succeed("test -f %s" % configFile)
        var = machine.succeed("su bob -c 'nu -c \"\$env.config.show_banner\" --config %s'" % configFile)
        assert "false" in var, "Config does not contain show_banner = false"
        extraVar = machine.succeed("su bob -c 'nu -c \"\$env.config.buffer_editor\" --config %s'" % configFile)
        assert "vi" in extraVar, "Config does not contain extraConfig string"

      with subtest("Verify aliases."):
        machine.succeed("su bob -c 'nu -c \"ll\" --config %s'" % configFile)

      with subtest("Verify environmental variables"):
        envVar = machine.succeed("su bob -c 'nu -c \"\$env.RUM_TEST\" --config %s'" % configFile)
        assert "HEY" in envVar, "Env var RUM_TEST does not contain HEY"

      with subtest("Verify plugins."):
        plugins = machine.succeed("su bob -c 'nu -c \"plugin list\"'")
        assert "formats" in plugins, "Plugins are not being loaded"

      with subtest("Verify other files."):
        envText = machine.succeed("cat %s/env.nu" % configDir)
        assert ''''${envFile}''''  in envText, "env.nu does not contain the set string"
        loginText = machine.succeed("cat %s/login.nu" % configDir)
        assert ''''${loginFile}'''' in loginText, "login.nu does not contain the set string"
    '';
}
