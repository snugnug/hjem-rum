{pkgs, ...}: {
  name = "programs-kitty";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.kitty = {
        enable = true;
        settings = {
          cursor_trail = 5;
          font_family = "RobotoMono";
          map = [
            "ctrl+backspace send_text all \\x17"
            "ctrl+k kitten ${builtins.toFile "kitten.py" ""} foo"
            "ctrl+shift+t new_tab_with_cwd"
          ];
        };
        theme = {
          light = "${pkgs.kitty-themes}/share/kitty-themes/themes/1984_light.conf";
          dark = "${pkgs.kitty-themes}/share/kitty-themes/themes/1984_dark.conf";
          no-preference = "${pkgs.kitty-themes}/share/kitty-themes/themes/default.conf";
        };
      };
      programs.fish.enable = true;
      programs.zsh.enable = true;
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confPath = "/home/bob/.config/kitty/kitty.conf"
      lightThemePath = "/home/bob/.config/kitty/light-theme.auto.conf"
      darkThemePath = "/home/bob/.config/kitty/dark-theme.auto.conf"
      noPreferenceThemePath = "/home/bob/.config/kitty/no-preference-theme.auto.conf"

      # Checks if the kitty config files exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)
      machine.succeed("[ -r %s ]" % lightThemePath)
      machine.succeed("[ -r %s ]" % darkThemePath)
      machine.succeed("[ -r %s ]" % noPreferenceThemePath)

      # Assert that the generated config is applied correctly.
      # Drop the hash from all the /nix/store paths in the config
      machine.succeed("sed -i 's|/nix/store/[a-z0-9]\{32\}-|/nix/store/|g' %s" % confPath)
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)

      # Assert that the fish integration snippet is in place
      machine.succeed("grep -q 'kitty-shell-integration' %s" % "/home/bob/.config/fish/config.fish")

      # Assert that the zsh integration snippet is in place
      machine.succeed("grep -q 'kitty-integration' %s" % "/home/bob/.zshrc")
    '';
}
