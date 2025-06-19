# Testing setup for modules

[ncmpcpp test module]: ../modules/tests/programs/ncmpcpp/ncmpcpp.nix
[nix.dev provides a useful guide]: https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html
[NixOS Manual]: https://nixos.org/manual/nixos/stable/index.html#sec-calling-nixos-tests
[internal NixOS lib]: https://github.com/NixOS/nixpkgs/tree/master/nixos/lib/testing

Hjem Rum's testing system is designed with simplicity in mind, so we shy away
from other testing frameworks and stick with `runTest`, from the
[internal NixOS lib] located in the Nixpkgs monorepo. There are no non-standard
abstractions in regards to writing the tests, so they should be written just
like any other test that uses the NixOS Test Driver.

## Creating tests

Every file is automatically imported with `lib.filesystem.listFilesRecursive`,
given that there is a check output that imports the directory (more on that
later), so your only worry should be creating the tests in their relevant
directories. If you're writing a test for btop, for instance, you should create
a module as `/modules/tests/programs/btop.nix`.

If you're certain your test category doesn't get covered by any of the existing
directories, you can create a new one together with a check that imports files
in this directory. This is really easy to do:

```nix
checks = hjem-rum-services = import ./modules/tests (mkCheckArgs ./modules/tests/services);
  # Just // (import ./modules/tests and pass mkCheckArgs with your brand-new directory to it.
```

### Naming

To reduce CI run time, we only run checks for which the module or test file has
changed. For this association to work, the following naming scheme has to be
respected: `<category>-<module name>`.

Below is a list of files, and their corresponding name.

- `modules/collection/programs/foot.nix` -> `programs-foot`
- `modules/tests/programs/fish.nix` -> `programs-fish`
- `modules/tests/programs/ncmpcpp/ncmpcpp.nix` -> `programs-ncmpcpp`

You may declare multiple test files for a module by having all of those names
start with the aformentioned pattern, such as `programs-foot-test-plugins`.

> [!IMPORTANT]
> If you do not follow this rule, your tests will not be run during CI.

## Writing tests

Tests for Hjem Rum are written just like any other test, so it might be worth to
take a read at how NixOS tests work. [nix.dev provides a useful guide], as does
the [NixOS Manual],[^1] both detailing how to use the framework.

Our test system has some pre-defined things aiming at avoid boilerplate code:

- A user named "bob" is already created, with no groups, `isNormalUser` set to
  true and no password.
- Both Hjem and Hjem Rum are already imported by default.

`self`, `lib` and `pkgs` are also passed to every test module, so you're free to
use them as you will.

The [ncmpcpp test module] was written to serve as an example for future tests,
and provides comments for each step of the `testScript`. Care should be taken to
wait for the proper systemd targets to be reached, change users to run commands,
and avoid other possible footguns. The approach this module uses to test its
configuration is to have a file for each configuration alongside it, which then
gets passed to the test VM and gets evaluated with diff. You can use other
approaches if it's more convenient, that's just a suggestion.

You can also debug your tests through a Python REPL by running:

```bash
nix run .#checks.<arch>.vm-test-run-<category>-<module name>[-suffix].driver -- --interactive
```

[^1]: Although both guides refer to `lib.tests.runNixOSTest` instead of
    `runTest`, the former is just a wrapper around the latter, abstracting
    certain concepts, so the code ran by them should be interchangeable between
    one another.
