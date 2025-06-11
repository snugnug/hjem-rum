{lib}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;
in {
  mkIntegrationOption = from: to:
    mkOption {
      default = false;
      example = true;
      description = "Whether to enable ${from} integration with ${to}.";
      type = bool;
    };
}
