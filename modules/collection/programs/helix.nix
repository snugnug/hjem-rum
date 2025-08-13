{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs mapAttrs' nameValuePair;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf;

  toml = pkgs.formats.toml {};

  mkThemes = themes:
    mapAttrs' (
      name: value:
        nameValuePair "helix/themes/${name}.toml" {
          source = toml.generate "helix-theme-${name}.toml" value;
        }
    )
    themes;

  cfg = config.rum.programs.helix;
in {
  options.rum.programs.helix = {
    enable = mkEnableOption "Helix";

    package = mkPackageOption pkgs "helix" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        editor = {
          line-number = "relative";
          editor.statusline.left = [
            "mode"
            "spinner"
          ];
        };
      };
      description = ''
        The editor configuration converted into TOML and written to
        {file}`$XDG_CONFIG_HOME/helix/config.toml`. Please reference
        [Helix's documentation] for config options.

        [Helix's documentation]: https://docs.helix-editor.com/editor.html
      '';
    };

    languages = mkOption {
      type = toml.type;
      default = {};
      example = {
        language-server.vscode-json-language-server.command = "vscode-json-languageserver";
      };
      description = ''
        The languages configurations converted into TOML and written to
        {file}`$XDG_CONFIG_HOME/helix/languages.toml`. Please reference
        [Helix's language documentation] for config options.

        [Helix's language documentation]: https://docs.helix-editor.com/languages.html
      '';
    };

    themes = mkOption {
      type = attrsOf toml.type;
      default = {};
      example = {
        theme1 = {
          "ui.background" = "white";
          "ui.text" = "black";
          palette = {
            white = "#ffffff";
            black = "#000000";
          };
        };
      };
      description = ''
        The custom themes converted into TOML and written to
        {file}`$XDG_CONFIG_HOME/helix/themes/`. Please reference
        [Helix's theming documentation] for config options.

        [Helix's theming documentation]: https://docs.helix-editor.com/themes.html
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files =
      {
        "helix/config.toml".source = mkIf (cfg.settings != {}) (
          toml.generate "helix-config.toml" cfg.settings
        );

        "helix/languages.toml".source = mkIf (cfg.languages != {}) (
          toml.generate "helix-languages.toml" cfg.languages
        );
      }
      // optionalAttrs (cfg.themes != {}) (mkThemes cfg.themes);
  };
}
