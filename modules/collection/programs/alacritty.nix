{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.alacritty;
in {
  options.rum.programs.alacritty = {
    enable = mkEnableOption "Alacritty";

    package = mkPackageOption pkgs "alacritty" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        window = {
          dimensions = {
            lines = 28;
            columns = 101;
          };

          padding = {
            x = 6;
            y = 3;
          };
        };
      };
      description = ''
        The configuration converted into TOML and written to
        {file}`$XDG_CONFIG_HOME/alacritty/alacritty.toml`.
        Please reference [Alacritty's documentation]
        for config options.

        [Alacritty's documentation]: https://alacritty.org/config-alacritty.html
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."alacritty/alacritty.toml".source = mkIf (cfg.settings != {}) (
      toml.generate "alacritty.toml" cfg.settings
    );
  };
}
