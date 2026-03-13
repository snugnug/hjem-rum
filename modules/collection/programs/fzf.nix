{
  lib,
  pkgs,
  config,
  hjem-lib,
  rumLib,
  ...
}: let
  inherit (hjem-lib) envVarType;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (rumLib.attrsets) attrNamesHasPrefix;

  cfg = config.rum.programs.fzf;
in {
  options.rum.programs.fzf = {
    enable = mkEnableOption "fzf";

    package = mkPackageOption pkgs "fzf" {nullable = true;};

    env = mkOption {
      type = envVarType;
      default = {};
      example = {
        DEFAULT_COMMAND = "fd --type f";
        DEFAULT_OPTS = "--layout=reverse --inline-info";
        CTRL_T_OPTS = ''
          --walker-skip .git,node_modules,target
          --preview 'bat -n --color=always {}'
          --bind 'ctrl-/:change-preview-window(down|hidden|)'
        '';
      };
      description = ''
        Environment variables passed to fzf with its shell integration.

        Please note that each variable will have `FZF_` prepended to it.
      '';
    };

    integrations = {
      fish.enable = mkEnableOption "fzf integration with fish";
      zsh.enable = mkEnableOption "fzf integration with zsh";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !attrNamesHasPrefix "FZF_" cfg.env;
        message = ''
          Each env variable in {option}`rum.programs.fzf.env` is automatically prefixed with `FZF_`. Adding this prefix manually will cause it to be added twice, causing the actual env variable to not apply.
        '';
      }
    ];

    packages = mkIf (cfg.package != null) [cfg.package];

    environment.sessionVariables = mapAttrs' (n: v: nameValuePair "FZF_${n}" v) cfg.env;

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter "${getExe cfg.package} --fish | source"
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter "source <(${getExe cfg.package} --zsh)"
    );
  };
}
