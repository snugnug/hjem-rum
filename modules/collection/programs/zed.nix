{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExample mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.zed;
in {
  options.rum.programs.zed = {
    enable = mkEnableOption "zed";

    package = mkPackageOption pkgs "zed-editor" {};

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
        autosave = "on_focus_change";
        base_keymap = "Atom";
        buffer_font_fallbacks = ["Nerd Font"];
        languages.JavaScript = {
          formatter = {
            external = {
              command = "prettier";
              arguments = ["--stdin-filepath" "{buffer_path}"];
            };
          };
          tab_size = 2;
        };
        load_direnv = "shell_hook";
        theme = {
          mode = "system";
          light = "One Light";
          dark = "One Dark";
        };
      };
      description = ''
        Configuration written to {file}`$HOME/.config/zed/settings.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/configuring-zed
      '';
    };

    keymap = mkOption {
      type = json.type;
      default = {};
      example = [
        {
          bindings = {
            ctrl-right = "editor::SelectLargerSyntaxNode";
            ctrl-left = "editor::SelectSmallerSyntaxNode";
          };
        }
        {
          bindings = {
            o = "project_panel::Open";
          };
          context = "ProjectPanel && not_editing";
        }
      ];
      description = ''
        Configuration written to {file}`$HOME/.config/zed/keymap.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/key-bindings
      '';
    };

    snippets = mkOption {
      type = attrsOf json.type;
      default = {};
      example = {
        javascript = {
          "Log to console" = {
            prefix = "log";
            body = ["console.info(\"Hello, \${1:World}!\")" "$0"];
            description = "Logs to console";
          };
        };
      };
      description = ''
        Custom scoped snippets written to {file}`$HOME/.config/zed/snippets/*.json`
        Please reference [zed's documentation] for more details.

        [zed's documentation]: https://zed.dev/docs/snippets
      '';
    };

    themes = mkOption {
      type = attrsOf json.type;
      default = {};
      example = {
        my-cool-theme = {
          name = "Bob's cool themes";
          author = "Bob Rum";
          themes = {
            name = "Bob's dark theme";
            appearance = "dark";
            style = {
              "border" = "#3f4043ff";
              "border.variant" = "#2d2f34ff";
              "border.focused" = "#1b4a6eff";
              "border.selected" = "#1b4a6eff";
              "border.transparent" = "#00000000";
              "border.disabled" = "#383a3eff";
              "elevated_surface.background" = "#1f2127ff";
              "surface.background" = "#1f2127ff";
              "background" = "#313337ff";
            };
            syntax = {
              attribute = {
                color = "#5ac1feff";
                font_style = null;
                font_weight = null;
              };
              boolean = {
                color = "#d2a6ffff";
                font_style = null;
                font_weight = null;
              };
            };
          };
        };
      };
      description = ''
        Custom themes written to {file}`$HOME/.config/zed/themes/*.json`
        Please reference [zed's documentation] for more details.

        [zed's documentation]: https://zed.dev/docs/extensions/themes
      '';
    };

    tasks = mkOption {
      type = json.type;
      default = {};
      example = [
        {
          label = "Example task";
          command = "for i in {1..5}; do echo \"Hello $i/5\"; sleep 1; done";
          env = {foo = "bar";};
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
          shell = "system";
          show_summary = true;
          show_output = true;
          tags = [];
        }
      ];
      description = ''
        Configuration written to {file}`$HOME/.config/zed/tasks.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/tasks
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files =
      {
        ".config/zed/settings.json" = mkIf (cfg.settings != {}) {
          source = json.generate "zed-settings.json" cfg.settings;
        };
        ".config/zed/keymap.json" = mkIf (cfg.keymap != {}) {
          source = json.generate "zed-keymap.json" cfg.keymap;
        };
        ".config/zed/tasks.json" = mkIf (cfg.tasks != {}) {
          source = json.generate "zed-tasks.json" cfg.tasks;
        };
      }
      // (mapAttrs' (name: value:
        nameValuePair ".config/zed/snippets/${name}.json" {
          source = json.generate "zed-${name}-snippet.json" value;
        })
      cfg.snippets)
      // (mapAttrs' (name: value:
        nameValuePair ".config/zed/themes/${name}.json" {
          source = json.generate "zed-${name}-theme.json" value;
        })
      cfg.themes);
  };
}
