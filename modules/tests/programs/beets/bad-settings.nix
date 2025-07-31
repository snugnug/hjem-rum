{
  name = "programs-beets-no-file-created";
  nodes.machine = {self, ...}: {
    hjem = {
      extraModules = ["${self.modulesPath}/programs/beets.nix"];
      users.bob.rum = {
        programs.beets = {
          enable = true;
          settings = {};
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

      confPath = "/home/bob/.config/beets/config.yaml"

      stdout = machine.fail("stat %s" % confPath)
    '';
}
