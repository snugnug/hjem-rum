{lib}: let
  inherit (lib.types) nullOr listOf bool str submodule;
  inherit (lib.options) mkOption;
in (
  submodule {
    options = {
      binding = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          The key or command for which the set of actions is binded to.
        '';
        example = "p";
        apply = x:
          assert (!isNull x
            || ''
              A binding for ncmpcpp wasn't properly defined, as it's missing the key or command its binded to.
              You need to specify a key or a command which'll run the specified actions.
            ''); x;
      };
      actions = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = ''
          The actions to be ran on either the key's or command's activation.
        '';
        example = ["stop" "quit"];
      };
      deferred = mkOption {
        type = bool;
        default = false;
        description = ''
          Whether the binding or command should be deferred (true) or immediate (false).
        '';
        example = true;
      };
    };
  }
)
