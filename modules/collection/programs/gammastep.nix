{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) literalExpression mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf path;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.gammastep;
in {
  options.rum.programs.gammastep = {
    enable = mkEnableOption "gammastep";

    package = mkPackageOption pkgs "gammastep" {nullable = true;};

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
        Settings are written as an INI file to {file}`$XDG_CONFIG_HOME/gammastep/config.ini`.
        Refer to {manpage}`gammastep(1)` for more information. Its [example configuration]
        may also be useful.

        [example configuration]: https://gitlab.com/chinstrap/gammastep/-/blob/master/gammastep.conf.sample
      '';
    };

    hooks = mkOption {
      type = attrsOf path;
      default = {};
      example = literalExpression ''
        {
          echo-period = ./echo-period;
          notify-period = pkgs.writeShellScript "notify-period" '''
            case $1 in
              period-changed)
                exec ''${lib.getExe pkgs.libnotify} "gammastep" "Period changed from $2 to $3";;
            esac
          ''';
        }
      '';
      description = ''
        Executable hooks written to {file}`$XDG_CONFIG_HOME/gammastep/hooks/*`.
        Refer to {manpage}`gammastep(1)` for more information.

        Use any writer you like, such as {command}`pkgs.writeShellScript` or
        {command}`pkgs.writers.writePython3`, to build the script.
        If using a Nix path, make sure that gammastep can e[x]ecute the file.
      '';
    };

    integrations.systemd.enable =
      (mkEnableOption "gammastep integration with systemd")
      // {
        default = true;
        defaultText = literalExpression "config.systemd.enable";
        example = false;
      };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      packages = mkIf (cfg.package != null) [cfg.package];
      xdg.config.files =
        {
          "gammastep/config.ini" = mkIf (cfg.settings != {}) {
            source = ini.generate "gammastep-config.ini" cfg.settings;
          };
        }
        // mapAttrs' (name: script:
          nameValuePair "gammastep/hooks/${name}" {source = script;})
        cfg.hooks;
    }
    (mkIf cfg.integrations.systemd.enable {
      systemd.services.gammastep = {
        after = ["graphical-session.target"];
        description = "Screen color temperature manager";
        documentation = ["man:gammastep(1)" "https://gitlab.com/chinstrap/gammastep"];
        partOf = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = getExe cfg.package;
          Restart = "on-failure";
        };
        wantedBy = ["graphical-session.target"];
      };
    })
  ]);
}
