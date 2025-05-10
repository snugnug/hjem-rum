{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf oneOf str path;
  inherit (lib.attrsets) optionalAttrs mapAttrs' nameValuePair;
  inherit (lib.strings) typeOf;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.gammastep;
in {
  options.rum.programs.gammastep = {
    enable = mkEnableOption "gammastep";

    package = mkPackageOption pkgs "gammastep" {};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        general = {
          location-provider = "manual";
          temp-day = 5000;
        };

        manual = {
          lat = -12.5;
          lon = 55.6;
        };
      };
      description = ''
        Settings are written as an INI file to {file}`$HOME/.config/gammastep/config.ini`.

        Refer to https://gitlab.com/chinstrap/gammastep/-/blob/master/gammastep.conf.sample for
        all available options.
      '';
    };

    hooks = mkOption {
      type = attrsOf (oneOf [str path]);
      default = {};
      example = {
        my-hook = ''
          #!/usr/bin/env sh
          case $3 in
            daytime)
              echo "Day time!"
            ;;
            night)
              echo "Night time!"
            ;;
          esac
        '';
      };
      description = ''
        Attribute set of hooks, which can be written inline or given a path.

        Hooks are scripts that are executed when an event is trigged and are written to {file}`$HOME/.config/gammastep/hooks/`.
        The first parameter indicates the event, the second, the old period and the third, the new period.

        Refer to the {manpage}`gammastep(1)` for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files =
      {
        ".config/gammastep/config.ini".source = mkIf (cfg.settings != {}) (
          ini.generate "gammastep-config.ini" cfg.settings
        );
      }
      // optionalAttrs (cfg.hooks != {}) (mapAttrs' (
          name: val:
            nameValuePair ".config/gammastep/hooks/${name}" (
              if (typeOf val == "path")
              then {
                source = val;
                executable = true;
              }
              else {
                text = val;
                executable = true;
              }
            )
        )
        cfg.hooks);
  };
}
