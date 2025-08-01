{
  writers,
  python3Packages,
  ...
}:
writers.writePython3Bin "hjr-deprecate" {
  libraries = with python3Packages; [
    whenever
    ast-grep-py
  ];
}
(builtins.readFile ./hjr-deprecate.py)
