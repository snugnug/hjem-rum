{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.vscode;
in {
  options.rum.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";

    package = mkPackageOption pkgs "vscode" {nullable = true;};

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
        "editor.fontFamily" = "Fira Code Nerdfont";
        "editor.fontLigatures" = true;
        "workbench.colorTheme" = "Catppuccin Mocha";
        "catppuccin"."accentColor" = "red";
      };
      description = ''
        The configuration converted into JSON and written to
        {file}`$XDG_CONFIG_HOME/Code/User/settings.json`.

        Please reference [Visual Studio Code's official documentation]
        for more information.

        [Visual Studio Code's official documentation]: https://code.visualstudio.com/docs/getstarted/settings#_settings-json-file
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files = {
      "Code/User/settings.json" = mkIf (cfg.settings != {}) {
        source = json.generate "settings.json" cfg.settings;
      };
    };
  };
}
