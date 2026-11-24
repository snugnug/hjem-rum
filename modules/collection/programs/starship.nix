{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.strings) optionalString;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.starship;
in {
  options.rum.programs.starship = {
    enable = mkEnableOption "starship module.";
    package = mkPackageOption pkgs "starship" {nullable = true;};
    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        add_newline = false;
        format = lib.concatStrings [
          "$line_break"
          "$package"
          "$line_break"
          "$character"
        ];
        scan_timeout = 10;
        character = {
          success_symbol = "➜";
          error_symbol = "➜";
        };
      };

      description = ''
        The configuration converted to TOML and written to {file}`$XDG_CONFIG_HOME/starship.toml`.
        Please reference [Starship's documentation] for configuration options.

        [Starship's documentation]: https://starship.rs/config
      '';
    };

    transience.enable = mkEnableOption "enable transience";

    integrations = {
      fish.enable =
        mkEnableOption "starship integration with fish"
        // {
          default = true;
          example = false;
        };
      nushell.enable =
        mkEnableOption "starship integration with nushell"
        // {
          default = true;
          example = false;
        };
      zsh.enable =
        mkEnableOption "starship integration with zsh"
        // {
          default = true;
          example = false;
        };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."starship.toml" = mkIf (cfg.settings != {}) {
      source = toml.generate "starship.toml" cfg.settings;
    };

    rum.programs = {
      fish.config = mkIf cfg.integrations.fish.enable (
        mkAfter ("starship init fish | source" + (optionalString cfg.transience.enable "\nenable_transience"))
      );

      nushell.extraConfig = mkIf cfg.integrations.nushell.enable (
        mkAfter ''
          use ${
            pkgs.runCommand "starship-init-nu" {} ''
              ${getExe cfg.package} init nu >> "$out"
            ''
          }
        ''
      );

      zsh.initConfig = mkIf cfg.integrations.zsh.enable (
        mkAfter ''eval "$(${getExe cfg.package} init zsh)"''
      );
    };
  };
}
