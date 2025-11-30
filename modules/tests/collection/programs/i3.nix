{
  lib,
  pkgs,
  ...
}: {
  name = "desktops-i3";
  nodes.machine = {
    hjem.users.bob.rum = {
      desktops.i3 = {
        enable = true;
        commands = ''
          # Launch on startup
          exec --no-startup-id i3-msg 'workspace 1; exec ${lib.getExe pkgs.firefox}'

          # Key bindings - Workspaces
          ${lib.concatStrings (
            map (n: ''
              bindsym $mod+${toString n} workspace number ${
                if n == 0
                then "10"
                else toString n
              }
              bindsym $mod+Shift+${toString n} move container to workspace number ${
                if n == 0
                then "10"
                else toString n
              }
            '') (builtins.genList (i: i) 10)
          )}
        '';
        layouts.main = [
          {
            layout = "stacked";
            percent = 0.6;
            type = "con";
            nodes = [
              {
                name = "chrome";
                type = "con";
                swallows = [
                  {
                    class = "^Google-chrome$";
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };

  testScript = ''
    # Waiting for our user to load.
    machine.succeed("loginctl enable-linger bob")
    machine.wait_for_unit("default.target")

    # Assert that the i3 config is valid
    machine.succeed("${lib.getExe pkgs.i3} -c %s -C -d all" % "/home/bob/.config/i3/config")

    # Check if the main layout file exists in the expected place.
    machine.succeed("[ -r %s ]" % "/home/bob/.config/i3/main.json")
  '';
}
