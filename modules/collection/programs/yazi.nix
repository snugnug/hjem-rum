{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.yazi;
in {
  options.rum.programs.yazi = {
    enable = mkEnableOption "yazi file manager";

    package = mkPackageOption pkgs "yazi" {nullable = true;};

    settings = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        mgr = {
          show_hidden = true;
        };
      };
      description = ''
        The configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/yazi.toml`.
        Please reference [yazi's configuration documentation] for configuration options.

        [yazi's configuration documentation]: https://yazi-rs.github.io/docs/configuration/yazi
      '';
    };

    keymap = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        mgr.prepend_keymap = [
          {
            on = "<C-a>";
            run = "my-cmd1";
            desc = "Single command with `Ctrl + a`";
          }
        ];
      };
      description = ''
        The keymap configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/keymap.toml`.
        Please reference [yazi's keymap configuration documentation] for configuration options.

        [yazi's keymap configuration documentation]: https://yazi-rs.github.io/docs/configuration/keymap
      '';
    };

    theme = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        flavor = {
          dark = "dracula";
          light = "gruvbox";
        };
      };
      description = ''
        The keymap configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/theme.toml`.
        Please reference [yazi's theming configuration documentation] for configuration options.

        [yazi's theming configuration documentation]: https://yazi-rs.github.io/docs/configuration/theme
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];

    xdg.config.files = {
      "yazi/yazi.toml".source = mkIf (cfg.settings != {}) (
        toml.generate "yazi-config.toml" cfg.settings
      );
      "yazi/keymap.toml".source = mkIf (cfg.keymap != {}) (
        toml.generate "yazi-keymap-config.toml" cfg.keymap
      );
      "yazi/theme.toml".source = mkIf (cfg.theme != {}) (
        toml.generate "yazi-theme-config.toml" cfg.theme
      );
    };
  };
}
