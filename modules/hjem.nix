{
  lib,
  rumLib,
  inputs,
}: {
  config,
  options,
  ...
}: let
  resolvedConfig =
    rumLib.modules.resolveModulesFromLazyModule {
      modulesDir = ./collection;
      deferredModule = config.rum;
      extraModules = [
        inputs.hjem.nixosModules.hjem-lib
        {_module.args.rumLib = rumLib;}
        (
          {
            config,
            options,
            ...
          }: {
            options = options.rum;
            config.rum = builtins.removeAttrs config ["rum"];
          }
        )
        ./deprecated.nix
      ];
      inherit rumLib options;
    }
    // {
      _module.args.rumLib = rumLib;
    };

  usedConfig = builtins.removeAttrs resolvedConfig ["rum"];
in {
  # Import the Hjem Rum module collection as an extraModule available under `hjem.users.<username>`
  # This allows the definition of rum modules under `hjem.users.<username>.rum`

  # Import the collection modules recursively so that all files
  # are imported. This then gets imported into the user's
  # 'hjem.extraModules' to make them available under 'hjem.users.<username>'
  options.rum = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config = {
    files = usedConfig;
  };
}
