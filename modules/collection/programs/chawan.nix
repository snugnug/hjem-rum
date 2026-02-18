{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.chawan;
in {
  options.rum.programs.chawan = {
    enable = mkEnableOption "chawan";

    package = mkPackageOption pkgs "chawan" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        buffer = {
          images = true;
          autofocus = true;
        };
        page."C-k" = "() => pager.load('ddg:')";
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/chawan/config.toml`.
        Please reference [chawan's documentation] for config options.

        [chawan's documentation]: https://git.sr.ht/~bptato/chawan/tree/master/doc/config.md
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."chawan/config.toml" = mkIf (cfg.settings != {}) {
      source = toml.generate "chawan-config.toml" cfg.settings;
    };
  };
}
