{
  name = "programs-direnv";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.direnv = {
        enable = true;
        settings = {
          global.warn_timeout = "0s";
          whitelist.prefix = ["~/src"];
        };
        direnvrc = ''
          : ''${XDG_CACHE_HOME:=$HOME/.cache}
          declare -A direnv_layout_dirs
          direnv_layout_dir() {
          	echo "''${direnv_layout_dirs[$PWD]:=$(
          		echo -n "$XDG_CACHE_HOME"/direnv/layouts/
          		echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
          	)}"
          }
        '';
      };
      programs.fish.enable = true;
      programs.nushell.enable = true;
      programs.zsh.enable = true;
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      confPath = "/home/bob/.config/direnv/direnv.toml"

      # Checks if the direnv config file exists in the expected place.
      machine.succeed("[ -r %s ]" % confPath)

      # Assert that the generated config is applied correctly.
      machine.copy_from_host("${./expected_config}", "/home/bob/expected_config")
      machine.succeed("diff -u -Z -b -B %s /home/bob/expected_config" % confPath)

      # Assert that both personal and external extensions are in place
      machine.succeed("[ -r %s ]" % "/home/bob/.config/direnv/direnvrc")
      machine.succeed("[ -r %s ]" % "/home/bob/.config/direnv/lib/nix-direnv.sh")

      # Assert that the fish integration snippet is in place
      pattern = r'^/nix/store/[^/]+/bin/direnv hook fish | source$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/fish/config.fish")

      # Assert that the nushell integration snippet is in place
      machine.succeed("grep \"direnv\" %s" % "/home/bob/.config/nushell/config.nu")

      # Assert that the zsh integration snippet is in place
      pattern = r'^eval "\$\(/nix/store/[^/]+/bin/direnv hook zsh\)"$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.zshrc")
    '';
}
