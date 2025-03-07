Hjem-rum's testing system is designed with simplicity in mind, so we shy away from other testing frameworks and stick with ``runTest``, from the [internal nixos lib](https://github.com/NixOS/nixpkgs/tree/master/nixos/lib/testing) located in the nixpkgs monorepo. There are no non-standard abstractions in regards to writing the tests, so they should be written just like any other test that uses the NixOS Test Driver.


## Creating tests

Every file is automatically imported with ``lib.filesystem.listFilesRecursive``, given that there is a check output that imports the directory (more on that later), so your only worry should be creating the tests in their relevant directories. If you're writing a test for btop, for instance, you should create a module under /modules/tests/programs, and probably name it after the program you're testing (so btop.nix).

If you're certain your test category doesn't get covered by any of the existing directories, you can create a new one together with a check that imports files in this directory. This is really easy to do:

``` nix
checks = { 
  ...
  # Just import ./modules/tests and pass mkCheckArgs with your brand-new directory to it.
  hjem-rum-services = import ./modules/tests (mkCheckArgs ./modules/tests/services);
};
```

This can also be used to import and run only individual test modules, although this isn't recommended (you can just build the test and run it yourself) and code doing that shouldn't be commited.


## Writing tests

Tests for ``hjem-rum`` are written just like any other test, so it might be worth to take a read at how NixOS tests work. There is [a guide](https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html) in nix.dev and also a [section on the nixos manual](https://nixos.org/manual/nixos/stable/index.html#sec-calling-nixos-tests)¹, both detailing how to use the framework.

Our test system has some pre-defined things aiming at avoid boilerplate code:

- An user named "bob" is already created², with no groups, ``isNormalUser`` set to true and no password.
- ``hjem`` and ``hjem-rum`` are already imported by default.

``self``, ``lib`` and ``pkgs`` are also passed to every test module, so you're free to use them as you will.

The [ncmpcpp test module](../modules/tests/programs/ncmpcpp/ncmpcpp.nix) was written to serve as an example for future tests, and provides comments for each step of the ``testScript``. Care should be taken to wait for the proper systemd targets to be reached, change users to run commands, and avoid other possible footguns. The approach this module uses to test its configuration is to have a file for each configuration alongside it, which then gets passed to the test vm and gets evaluated with diff. You can use other approachs if its more convenient, that's just a suggestion :D.

---

###### ¹ Although both guides refer to ``lib.tests.runNixOSTest`` instead of ``runTest``, the former is just a wrapper around the latter, abstracting certain concepts, so the code ran by them should be interchangeable between one another.

###### ² This is a reference to [Bob and Alice](https://en.wikipedia.org/wiki/Alice_and_Bob), two names that are commonly used as placeholders, and since Hjem went with Alice, we chose Bob ;D.
