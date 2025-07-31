{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals all;

  # A list checking all modules that load variables. Enabled modules
  # will evaluate to true, disabled will evaluate to false. Results
  # in a list of bools, allowing us to
  variableLoaders = [
    (config.rum.programs.zsh.enable or false)
    (config.rum.programs.fish.enable or false)
    (config.rum.programs.nushell.enable or false)
    (config.rum.desktops.hyprland.enable or false)
  ];

  cfg = config.rum.environment;
in {
  options.rum.environment.hideWarning = mkEnableOption "a warning for env vars not being implemented";

  config = mkIf (!cfg.hideWarning) {
    # If all modules are disabled, then Hjem Rum is not loading variables
    warnings = optionals ((all (module: !module) variableLoaders) && (config.environment.sessionVariables != {})) [
      "environment.sessionVariables exist but are not being loaded by any Hjem Rum modules. Please see the README for more information. If you would like to disable this warning, enable rum.environment.hideWarning."
    ];
  };
}
