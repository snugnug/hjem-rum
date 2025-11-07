{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.neovide;
in {
  options.rum.programs.neovide = {
    enable = mkEnableOption "neovide";

    package = mkPackageOption pkgs "neovide" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        theme = "auto";
        srgb = false;
        title-hidden = true;
        vsync = true;
        wsl = false;
        font = {
          normal = [];
          size = 14.0;
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/neovide/config.toml`.
        Please reference [neovide's documentation] for config options.

        [neovide's documentation]: https://neovide.dev/config-file.html
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."neovide/config.toml" = mkIf (cfg.settings != {}) {
      source = toml.generate "neovide-config.toml" cfg.settings;
    };
  };
}
