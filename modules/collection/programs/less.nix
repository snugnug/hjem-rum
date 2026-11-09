{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) lines;

  cfg = config.rum.programs.less;
in {
  options.rum.programs.less = {
    enable = mkEnableOption "less";

    package = mkPackageOption pkgs "less" {nullable = true;};

    settings = mkOption {
      default = "";
      type = lines;
      description = ''
        The configuration for less, written verbatim to
        {file}`$XDG_CONFIG_HOME/lesskey`.

        See {manpage}`lesskey(1)` for the format, and {manpage}`less(1)` for the
        available options and variables.

        Variables set in the `#env` section are visible only to less and take
        precedence over the system environment, so a `LESS` defined here
        overrides one exported by a caller such as git. The exceptions are
        variables that decide where less looks for its configuration, or that
        must exist before it is read (`LESSKEYIN`, `LESSKEYIN_SYSTEM`,
        `LESSNOCONFIG`, `POSIXLY_CORRECT`); set those with
        {option}`environment.sessionVariables` instead.
      '';
      example = literalExpression ''
        '''
          #env
          LESS = -i -R --mouse --use-color --color=Nc$ --color=Sky$
          LESSHISTFILE = -
          LESSOPEN = |''${pkgs.lesspipe}/bin/lesspipe.sh %s

          #command
          x quit
        '''
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."lesskey" = mkIf (cfg.settings != "") {text = cfg.settings;};
  };
}
