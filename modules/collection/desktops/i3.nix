{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) concatMapStringsSep concatStringsSep optionalString;
  inherit (lib.types) attrsOf lines listOf path;

  json = pkgs.formats.json {};

  cfg = config.rum.desktops.i3;
in {
  options.rum.desktops.i3 = {
    enable = mkEnableOption "i3";

    package =
      mkPackageOption pkgs "i3" {
        nullable = true;
        extraDescription = ''
          Only used to validate the generated config file. Set to `null` to
          disable the check phase.
        '';
      }
      // {
        # This is not above because mkPackageOption's implementation will evaluate `osConfig`, causing eval failures for documentation and checks.
        default = osConfig.services.xserver.windowManager.i3.package;
        defaultText = literalExpression "osConfig.services.xserver.windowManager.i3.package";
      };

    commands = mkOption {
      type = lines;
      default = "";
      example = ''
        # Launch on startup
        exec --no-startup-id i3-msg 'workspace 1; exec ''${lib.getExe pkgs.firefox}'

        # Key bindings - Workspaces
        ''${lib.concatStrings (
          map (n: '''
            bindsym $mod+''${toString n} workspace number ''${if n == 0 then "10" else toString n}
            bindsym $mod+Shift+''${toString n} move container to workspace number ''${
              if n == 0 then "10" else toString n
            }
          ''') (builtins.genList (i: i) 10)
        )}
      '';
      description = ''
        Commands that will be run to configure i3 written to
        {file}`$HOME/.config/i3/config`. Please reference [i3's documentation]
        for possible commands.

        [i3's documentation]: https://i3wm.org/docs/userguide.html#configuring
      '';
    };

    includes = mkOption {
      type = listOf path;
      default = [];
      example = literalExpression ''
        [ ./assignments.conf ./''${hostname}.conf ]
      '';
      description = ''
        A list of other files that will be included in the configuration file.
        See [i3's docs] on the include directive for more information.

        [i3's docs]: https://i3wm.org/docs/userguide.html#include
      '';
    };

    layouts = mkOption {
      type = attrsOf (listOf json.type);
      default = {};
      example = {
        main = [
          {
            layout = "splitv";
            percent = 0.4;
            type = "con";
            nodes = [
              {
                border = "none";
                name = "irssi";
                percent = 0.5;
                type = "con";
                swallows = [
                  {
                    class = "^URxvt$";
                    instance = "^irssi$";
                  }
                ];
              }
              {
                layout = "stacked";
                percent = 0.5;
                type = "con";
                nodes = [
                  {
                    name = "notmuch";
                    percent = 0.5;
                    type = "con";
                    swallows = [
                      {
                        class = "^Emacs$";
                        instance = "^notmuch$";
                      }
                    ];
                  }
                  {
                    name = "midna: -";
                    percent = 0.5;
                    type = "con";
                  }
                ];
              }
            ];
          }
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
      description = ''
        Workspace layouts written to {file}`$HOME/.config/i3/*.json`.
        Read more about i3's layouts [here].

        Setting this option doesn't automatically load the defined layouts
        allowing users to load them in their preferred way. Reference i3's
        documentation on [restoring the layout] for possible options.

        [here]: https://i3wm.org/docs/layout-saving.html
        [restoring the layout]: https://i3wm.org/docs/layout-saving.html#_restoring_the_layout
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.config.files =
      {
        "i3/config" = mkIf (cfg.commands != "") {
          source = pkgs.writeTextFile {
            name = "i3-config";
            text = concatStringsSep "\n" [
              (concatMapStringsSep "\n" (file: "include \"${file}\"") cfg.includes)
              cfg.commands
            ];
            checkPhase = optionalString (cfg.package != null) ''
              ${getExe cfg.package} -c "$target" -C -d all
            '';
          };
        };
      }
      // (mapAttrs' (name: value:
        nameValuePair "i3/${name}.json" {
          source = json.generate "i3-${name}-layout.json" value;
        })
      cfg.layouts);
  };
}
