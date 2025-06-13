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
        The configuration converted to TOML and written to {file}`$HOME/.config/starship.toml`.
        Please reference [Starship's documentation] for configuration options.

        [Starship's documentation]: https://starship.rs/config
      '';
    };

    enableTransience = mkEnableOption "enable transience.";

    integrations = {
      zsh.enable = mkEnableOption "enable zsh integration.";
      fish.enable = mkEnableOption "enable fish integration.";
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    files = {
      ".config/starship.toml".source = mkIf (cfg.settings != {}) (
        toml.generate "starship.toml" cfg.settings
      );
    };

    /*
    Needs to be added to the end of the shell config file, hence the `mkAfter`s.
    https://starship.rs/guide/#step-2-set-up-your-shell-to-use-starship
    */
    rum.programs = {
      zsh.initConfig = mkIf cfg.integrations.zsh.enable (
        mkAfter ''eval "$(${getExe cfg.package} init zsh)"''
      );

      fish.config = mkIf (cfg.integrations.fish.enable) (
        mkAfter (
          "starship init fish | source"
          + (optionalString cfg.enableTransience "\nenable_transience")
        )
      );
    };
  };
}
