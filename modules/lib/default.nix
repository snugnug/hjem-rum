{lib}: {
  attrsets = import ./attrsets {inherit lib;};
  generators = import ./generators {inherit lib;};
  modules = import ./modules {inherit lib;};
  types = import ./types {inherit lib;};
}
