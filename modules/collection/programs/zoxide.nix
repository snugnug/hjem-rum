{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) listOf str;

  toFlags = concatStringsSep " " cfg.flags;

  cfg = config.rum.programs.zoxide;
in {
  options.rum.programs.zoxide = {
    enable = mkEnableOption "zoxide";

    package = mkPackageOption pkgs "zoxide" {nullable = true;};

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
      fish.enable =
        mkEnableOption "zoxide integration with fish"
        // {
          default = true;
          example = false;
        };
      nushell.enable =
        mkEnableOption "zoxide integration with nushell"
        // {
          default = true;
          example = false;
        };
      zsh.enable =
        mkEnableOption "zoxide integration with zsh"
        // {
          default = true;
          example = false;
        };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != true) [cfg.package];

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter "${getExe cfg.package} init fish ${toFlags} | source"
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter ''eval "$(${getExe cfg.package} init zsh ${toFlags})"''
    );
    rum.programs.nushell.extraConfig = mkIf cfg.integrations.nushell.enable (
      mkAfter ''
        source ${
          pkgs.runCommand "zoxide-init-nu" {} ''${getExe cfg.package} init nushell ${toFlags} >> "$out"''
        }
      ''
    );
  };
}
