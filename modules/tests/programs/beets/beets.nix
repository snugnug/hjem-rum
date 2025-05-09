{pkgs, ...}: let
  yaml = pkgs.formats.yaml {};

  settings = {
    plugins = "duplicates";
  };
  settingsFile = yaml.generate "settings.yaml" settings;
in {
  name = "programs-beets";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.beets = {
        enable = true;
        package = pkgs.beets.override {pluginOverrides.duplicates.enable = true;};
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

      confPath = "/home/bob/.config/beets/config.yaml"

      with subtest("beets is in path"):
          stdout = machine.succeed("su bob -c 'which beet'")

      with subtest("Verify that beets is aware of the config file"):
          stdout = machine.succeed("su bob -c 'beet config -p'")
          assert stdout == "%s\n" % confPath, "beets did not pick up on the config location"

      with subtest("Verify that the linked file contains the proper data"):
          stdout = machine.succeed("diff ${settingsFile} %s" % confPath)
          assert stdout == "", "The linked file contains incorrect data"
    '';
}
