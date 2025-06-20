{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.meta) getExe;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types) lines listOf str;

  gitIni = pkgs.formats.gitIni {};
  cfg = config.rum.programs.git;
in {
  options.rum.programs.git = {
    enable = mkEnableOption "git";

    package = mkPackageOption pkgs "git" {nullable = true;};

    settings = mkOption {
      type = gitIni.type;
      default = {};
      example = {
        user = {
          email = "alice@example.com";
          name = "alice";
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
      description = ''
        Settings that will be written to your configuration file.
      '';
    };

    ignore = mkOption {
      type = lines;
      default = "";
      example = ''
        .direnv
      '';
      description = ''
        Global user-level version of .gitignore written to
        {file}`$HOME/.config/git/ignore`.
      '';
    };

    attributes = mkOption {
      type = lines;
      default = "";
      example = ''
        # Auto detect text files and perform LF normalization
        * text=auto

        # Detect Markdown files
        *.md linguist-detectable=true
      '';
      description = ''
        Global user-level version of .gitattributes written to
        {file}`$HOME/.config/git/attributes`.
      '';
    };

    integrations = {
      difftastic = {
        enable = mkEnableOption "git integration with difftastic";
        package = mkPackageOption pkgs "difftastic" {};
        flags = mkOption {
          type = listOf str;
          default = [];
          example = [
            "--background light"
            "--display inline"
            "--ignore-comments"
          ];
          description = ''
            Command-line flags passed to `difft`. Please run `difft --help` for
            configuration options.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    files = {
      ".config/git/config".source = mkIf (cfg.settings != {} || cfg.integrations.difftastic.enable) (
        gitIni.generate "config" (
          cfg.settings
          // (let
            difft-command = concatStringsSep " " ([(getExe cfg.integrations.difftastic.package)] ++ cfg.integrations.difftastic.flags);
          in
            optionalAttrs (cfg.integrations.difftastic.enable) {
              diff.external = difft-command;
              diff.tool = "difftastic";
              difftool.difftastic.cmd = "${difft-command} $LOCAL $REMOTE";
            })
        )
      );
      ".config/git/ignore".text = mkIf (cfg.ignore != {}) cfg.ignore;
      ".config/git/attributes".text = mkIf (cfg.attributes != {}) cfg.attributes;
    };
  };
}
