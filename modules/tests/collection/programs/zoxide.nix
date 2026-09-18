{
  name = "programs-zoxide";
  nodes.machine = {
    hjem.users.bob.rum = {
      programs.zoxide = {
        enable = true;
        flags = ["--cmd cd"];
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
      pattern = r'^/nix/store/[^/]+/bin/zoxide init fish --cmd cd | source$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.config/fish/config.fish")

      # Assert that the zsh integration snippet is in place
      pattern = r'^eval "\$\(/nix/store/[^/]+/bin/zoxide init zsh --cmd cd\)"$'
      machine.succeed(f"grep -E '{pattern}' %s" % "/home/bob/.zshrc")

      # Assert that the nushell integration snippet is in place
      file = machine.succeed("grep -E 'source /nix/store/[^/]+zoxide-init-nu' %s | awk '{print $2}'" % "/home/bob/.config/nushell/config.nu")
      machine.succeed(f"su bob -c 'zoxide init nushell --cmd cd > /home/bob/zoxide-init-nu && diff -u -Z -b -B /home/bob/zoxide-init-nu {file}'")
    '';
}
