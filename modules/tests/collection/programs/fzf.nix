{
  name = "programs-fzf";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.fzf.enable = true;
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

      # Assert that the fish integration snippet is in place
      pattern = r'^/nix/store/[^/]+/bin/fzf --fish | source$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/fish/config.fish")

      # Assert that the zsh integration snippet is in place
      pattern = r'^source <\(/nix/store/[^/]+/bin/fzf --zsh\)$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.zshrc")
    '';
}
