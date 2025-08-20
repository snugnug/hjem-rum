{
  lib,
  rumLib,
  inputs,
}: {
  # Import the Hjem Rum module collection as an extraModule available under `hjem.users.<username>`
  # This allows the definition of rum modules under `hjem.users.<username>.rum`

  # Import the collection modules recursively so that all files
  # are imported. This then gets imported into the user's
  # 'hjem.extraModules' to make them available under 'hjem.users.<username>'
  imports = [inputs.hjem.nixosModules.hjem-lib] ++ lib.filesystem.listFilesRecursive ./collection;

  _module.args.rumLib = rumLib;
}
