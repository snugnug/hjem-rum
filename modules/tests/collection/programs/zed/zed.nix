{
  name = "programs-zed";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.zed = {
        enable = true;
        settings = {
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
        keymap = [
          {
            bindings = {
              ctrl-left = "editor::SelectSmallerSyntaxNode";
              ctrl-right = "editor::SelectLargerSyntaxNode";
            };
          }
          {
            bindings = {
              o = "project_panel::Open";
            };
            context = "ProjectPanel && not_editing";
          }
        ];
        snippets = {
          javascript = {
            "Log to console" = {
              prefix = "log";
              body = ["console.info(\"Hello, \${1:World}!\")" "$0"];
              description = "Logs to console";
            };
          };
        };
        themes = {
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
        tasks = [
          {
            label = "Example task";
            command = "for i in {1..5}; do echo \"Hello $i/5\"; sleep 1; done";
            env = {"foo" = "bar";};
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
      };
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confPath = "/home/bob/.config/zed"
      confFiles = [
          "settings.json",
          "keymap.json",
          "tasks.json",
          "snippets/javascript.json",
          "themes/my-cool-theme.json",
      ]

      machine.copy_from_host("${./settings.json}", "/home/bob/settings.json")
      machine.copy_from_host("${./keymap.json}", "/home/bob/keymap.json")
      machine.copy_from_host("${./tasks.json}", "/home/bob/tasks.json")
      machine.copy_from_host("${./javascript.json}", "/home/bob/snippets/javascript.json")
      machine.copy_from_host("${./my-cool-theme.json}", "/home/bob/themes/my-cool-theme.json")

      # Checks if the config files exist in the expected places with the expected config.
      for confFile in confFiles:
          machine.succeed(f"[ -r {confPath}/{confFile} ]")
          machine.succeed(f"diff -u -Z -b -B {confPath}/{confFile} /home/bob/{confFile}")
    '';
}
