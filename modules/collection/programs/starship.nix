{
  lib,
  pkgs,
  config,
  rumLib,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;

  inherit (rumLib.options) mkIntegrationOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.starship;
in {
  options.rum.programs.starship = {
    enable = mkEnableOption "starship module.";
    package = mkPackageOption pkgs "starship" {};
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
    integrations = {
      zsh.enable = mkIntegrationOption "starship" "zsh";
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = {
      ".config/starship.toml".source = mkIf (cfg.settings != {}) (
        toml.generate "starship.toml" cfg.settings
      );

      /*
      Needs to be added to the end of ~/.zshrc, hence the `mkIf` and `mkAfter`.
      https://starship.rs/guide/#step-2-set-up-your-shell-to-use-starship
      */
      ".zshrc".text = mkIf (config.rum.programs.zsh.enable && cfg.integrations.zsh.enable) (
        mkAfter ''eval "$(${getExe cfg.package} init zsh)"''
      );
    };
  };
}
