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

    # New: themes block (for themes/default.toml)
    themes = mkOption {
      type = toml.type;
      default = {};
      description = ''
        The theme configuration converted into TOML and written to
        {file}`$HOME/.config/walker/themes/default.toml`.
      '';
    };

    # New: styles block (for themes/default.css)
    styles = mkOption {
      type = lib.types.lines;
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

    # Write the theme TOML if provided
    files.".config/walker/themes/default.toml".source = mkIf (cfg.themes != {}) (
      toml.generate "default.toml" cfg.themes
    );

    # Write the theme CSS if provided
    files.".config/walker/themes/default.css".text = mkIf (cfg.styles != "") (
      cfg.styles
    );
  };
}
