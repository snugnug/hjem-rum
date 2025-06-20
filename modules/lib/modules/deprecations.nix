{lib}: let
  inherit (builtins) match trace;
  inherit (lib.asserts) assertMsg;
  inherit (lib.modules) doRename;
  inherit (lib.options) showOption;

  isValidISODate = dateString: (match "[0-9]{4}-[0-9]{2}-[0-9]{2}" dateString != null);

  mkRenamedOptionModuleUntil = from: to: date:
    assert assertMsg (isValidISODate date) "Cannot rename `${showOption from}` to `${showOption to}`: Your date needs to be in ISO 8601 format, ie. yyyy-mm-dd (got ${date} instead).";
      doRename {
        inherit from to;
        visible = false;
        warn = true;
        use = trace "Obsolete option `${showOption from}' is used. It was renamed to `${showOption to}', and will be removed on ${date}";
      };
in {
  inherit isValidISODate mkRenamedOptionModuleUntil;
}
