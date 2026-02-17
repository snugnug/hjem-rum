{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  inherit (lib.modules) mkIf;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.fastfetch;
in {
  options.rum.programs.fastfetch = {
    enable = mkEnableOption "Fastfetch";

    package = mkPackageOption pkgs "fastfetch" {nullable = true;};

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
        logo.source = "nixos_old_small";
        display = {
          constants = ["██ "];
        };
        modules = [
          {
            key = "{$1}Distro";
            keyColor = "38;5;210";
            type = "os";
          }
        ];
      };
      description = ''
        The configuration written to {file}`$XDG_CONFIG_HOME/fastfetch/config.jsonc`.
        Please reference [Json Schema] for more information.

        [Json Schema]: https://gitlab.com/CarterLi/fastfetch/-/wikis/Json-Schema
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = lib.mkIf (cfg.package != null) [cfg.package];

    xdg.config.files = {
      "fastfetch/config.jsonc" = mkIf (cfg.settings != {}) {
        source = json.generate "fastfetch-config.jsonc" cfg.settings;
      };
    };
  };
}
