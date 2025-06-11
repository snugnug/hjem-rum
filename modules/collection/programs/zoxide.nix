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
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) listOf str;

  inherit (rumLib.options) mkIntegrationOption;

  toFlags = concatStringsSep " " cfg.flags;

  cfg = config.rum.programs.zoxide;
in {
  options.rum.programs.zoxide = {
    enable = mkEnableOption "zoxide";

    package = mkPackageOption pkgs "zoxide" {};

    flags = mkOption {
      type = listOf str;
      default = [];
      example = [
        "--cmd cd"
      ];
      description = ''
        Command-line flags passed to `zoxide init`.
        Please reference [zoxide's documentation] for configuration options.

        [zoxide's documentation]: https://github.com/ajeetdsouza/zoxide#flags
      '';
    };

    integrations = {
      fish.enable = mkIntegrationOption "zoxide" "fish";
      zsh.enable = mkIntegrationOption "zoxide" "zsh";
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = {
      /*
      Needs to be added to the end of the shell configuration files, hence the `mkIf` and `mkAfter`.
      https://github.com/ajeetdsouza/zoxide#installation
      */
      ".config/fish/config.fish".text = mkIf (config.rum.programs.fish.enable && cfg.integrations.fish.enable) (
        mkAfter "${getExe cfg.package} init fish ${toFlags} | source"
      );
      ".zshrc".text = mkIf (config.rum.programs.zsh.enable && cfg.integrations.zsh.enable) (
        mkAfter ''eval "$(${getExe cfg.package} init zsh ${toFlags})"''
      );
    };
  };
}
