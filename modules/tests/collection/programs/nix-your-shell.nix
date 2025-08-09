{
  name = "programs-nix-your-shell";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.nix-your-shell = {
        enable = true;
        integrations.fish.enable = true;
        integrations.zsh.enable = true;
        integrations.nushell.enable = true;
      };
      programs.fish.enable = true;
      programs.zsh.enable = true;
      programs.nushell.enable = true;
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      # Assert that the fish integration snippet is in place
      pattern = r'^/nix/store/[^/]+/bin/nix-your-shell fish | source$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/fish/config.fish")

      # Assert that the zsh integration snippet is in place
      pattern = r'^/nix/store/[^/]+/bin/nix-your-shell zsh | source /dev/stdin$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.zshrc")

      # Assert that the nushell integration snippet is in place
      pattern = r'^source /nix/store/[^/]+nix-your-shell-init-nu$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/nushell/config.nu")
    '';
}
