{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.walker;
in {
  options.rum.programs.walker = {
    enable = mkEnableOption "Walker";

    package = mkPackageOption pkgs "walker" {};

    settings = mkOption {
      type = toml.type;
      default = {};
      description = ''
        The configuration converted into TOML and written to
        {file}`$HOME/.config/walker/walker.toml`.
        Please reference [Walker's documentation]
        for config options.
        [Walker's documentation]: https://github.com/abenz1267/walker/wiki/Basic-Configuration
      '';
    };
    themes = mkOption {
      type = toml.type;
      default = {};
      description = ''
        The theme configuration converted into TOML and written to
        {file}`$HOME/.config/walker/themes/default.toml`.
      '';
    };
    styles = mkOption {
      type = lines;
      default = "";
      description = ''
        The CSS styles written to
        {file}`$HOME/.config/walker/themes/default.css`.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/walker/config.toml".source = mkIf (cfg.settings != {}) (
      toml.generate "config.toml" cfg.settings
    );
    files.".config/walker/themes/default.toml".source = mkIf (cfg.themes != {}) (
      toml.generate "default.toml" cfg.themes
    );
    files.".config/walker/themes/default.css".text = mkIf (cfg.styles != "") (
      cfg.styles
    );
  };
}
