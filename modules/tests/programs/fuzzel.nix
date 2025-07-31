{
  name = "programs-fuzzel";
  nodes.machine = {self, ...}: {
    hjem.extraModules = ["${self.modulesPath}/programs/fuzzel.nix"];
    hjem.users.bob.rum = {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            icon-theme = "Papirus-Dark";
            width = 25;
            font = "Hack:weight=bold";
            line-height = 30;
            fields = "name,generic,comment";
            prompt = ''"❯   "'';
            layer = "overlay";
          };
          colors = {
            background = "282a36fa";
            selection = "3d4474fa";
            border = "fffffffa";
          };
          border = {
            radius = 20;
          };
          dmenu = {
            exit-immediately-if-empty = "yes";
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

      confPath = "/home/bob/.config/fuzzel/fuzzel.ini"

      # Letting fuzzel check the validity of the config file
      machine.succeed("su bob -c 'fuzzel --check-config --config %s'" % confPath);

      # Verifying that something from the config has actually been written to the file
      machine.succeed("grep 'Papirus-Dark' < %s" % confPath)
    '';
}
