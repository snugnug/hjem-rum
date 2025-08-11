{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.tealdeer;
in {
  options.rum.programs.tealdeer = {
    enable = mkEnableOption "tealdeer";

    package = mkPackageOption pkgs "tealdeer" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        updates = {
          auto_update = true;
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/tealdeer/config.toml`.
        Please reference [tealdeer's documentation] for config options.

        [tealdeer's documentation]: https://tealdeer-rs.github.io/tealdeer/config.html
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."tealdeer/config.toml".source = mkIf (cfg.settings != {}) (
      toml.generate "tealdeer-config.toml" cfg.settings
    );
  };
}
