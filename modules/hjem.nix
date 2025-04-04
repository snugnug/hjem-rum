{lib}: {
  # Import the Hjem Rum module collection as an extraModule available under `hjem.users.<username>`
  # This allows the definition of rum modules under `hjem.users.<username>.rum`

  # Import the collection modules recursively so that all files
  # are imported. This then gets imported into the user's
  # 'hjem.extraModules' to make them available under 'hjem.users.<username>'
  imports = lib.filesystem.listFilesRecursive ./collection;

  # Set lib in the modules with our extended library
  _module.args.lib = lib;

  # osConfig will be provided upstream by Hjem
}
