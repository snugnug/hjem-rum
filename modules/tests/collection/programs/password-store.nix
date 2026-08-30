{pkgs, ...}: {
  name = "programs-password-store";
  nodes.machine = {
    # Needed to generate the key our store is encrypted with, as pass only exposes gpg to itself.
    environment.systemPackages = [pkgs.gnupg];

    hjem.users.bob.rum = {
      programs.password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (exts: [exts.pass-otp]);
        environment = {
          DIR = "/home/bob/.local/share/password-store";
          CLIP_TIME = 60;
        };
      };

      programs.fish.enable = true;
    };
  };

  testScript =
    #python
    ''
      # Waiting for our user to load.
      machine.succeed("loginctl enable-linger bob")
      machine.wait_for_unit("default.target")

      with subtest("Verify if pass is in $PATH"):
          machine.succeed("su bob -c 'which pass'")

      with subtest("Verify if the pass-otp extension is available"):
          machine.succeed("su bob -c 'pass otp --help'")

      with subtest("Verify if the environment variables are exported and prefixed"):
          store = machine.succeed("su bob -c \"fish -c 'echo $PASSWORD_STORE_DIR'\"").strip()
          assert store == "/home/bob/.local/share/password-store", "PASSWORD_STORE_DIR was not set correctly"

          clip = machine.succeed("su bob -c \"fish -c 'echo $PASSWORD_STORE_CLIP_TIME'\"").strip()
          assert clip == "60", "PASSWORD_STORE_CLIP_TIME was not set correctly"

      with subtest("Verify if pass is able to correctly read our config"):
          # pass needs a key to encrypt the store with.
          machine.succeed(
              "su bob -c \"gpg --batch --pinentry-mode loopback --passphrase ''' "
              "--quick-generate-key 'Bob <bob@rum.test>' default default never\""
          )

          # Our variables are loaded by fish, so pass is run through it.
          machine.succeed("su bob -c \"fish -c 'pass init bob@rum.test'\"")
          machine.succeed("[ -d /home/bob/.local/share/password-store ]")
    '';
}
