{
  lib,
  rumLib,
}: {
  /*
  Import all modules contained within the collection directory recursively so that all files are passed into`imports` as a list. The user then imports this into `hjem.extraModules` to make them available under `hjem.users.<username>`.
  */
  imports = lib.filesystem.listFilesRecursive ./collection;

  # We declare special args needed within the Hjem Modules.
  _module.args.rumLib = rumLib;
}
