# Contributing: Introduction {#contributing-introduction}

[commitizen]: https://github.com/commitizen-tools/commitizen
[article from GeeksforGeeks]: https://www.geeksforgeeks.org/how-to-create-a-new-branch-in-git/
[creating a PR]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
[documentation on forking repositories]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo
[documentation on reviewing PRs]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request
[Core Principles]: #ch-core-principles
[**Contributing: Writing Modules**]: ./writing-modules.html
[#43]: https://github.com/snugnug/hjem-rum/pull/43
[**Contributing: Setting Up Module Tests**]: ./testing.html
[**Contributing: Extending Hjem Rum's Library**]: ./rumlib.html
[**Contributign: Expanding the Documentation**]: ./docs.html
[reviewed]: #ch-reviewing-a-pr
[**Contributing: Review Tips**]: ./reviewing.html

Hjem Rum (or HJR) is always in need of contributions as a module collection. As
programs are developed, modules will need to be added, changed, removed, etc.,
meaning that the development of HJR is, in essence, unending.

Contributing is also a great way to learn the Nix module system and even
function writing. Don't be afraid to experiment and try learning something new.

If you are familiar with contributing to open source software, you can safely
skip ahead to [Core Principles]. Otherwise, read the following section to learn
how to fork a repo and open a PR.

## Getting Started {#ch-getting-started}

To begin contributing to HJR, you will first need to create a fork off of the
main branch in order to make changes. For info on how to do this, we recommend
GitHub's own [documentation on forking repositories].

Once you have your own fork, it is recommend that you create a branch for the
changes or additions you seek to make, to make it easier to set up multiple PRs
from your fork. To do so, you can read this [article from GeeksforGeeks] that
will also explain branches for you. Don't worry too much about the technical
details, the most important thing is to make and switch to a branch from HEAD.

### Commit Format {#sec-commit-format}

> [!TIP]
> Our dev shell allows for interactive commits, through the means of
> [commitizen]. If this is preferred, you can run `cz commit` to be prompted to
> build your commit.

For consistency, we do enforce a strict (but simple) commit style, that will be
linted against. The format is as follows (sections between `[]` are optional):

```console
<top_level_scope>[/<specific_scope>]: <message>

[<body>]
```

- \<top_level_scope>: the main scope of your commit. If making a change to a
  program, this would be `programs`). For changes unrelated to the modules API,
  we tend to use semantic scopes such as `meta` for CI/repo related changes.

- \[\<specific_scope>]: An optional, more specific scope for your module. If
  making changes to a specific program, this would be `programs/foot`.

- \<message>: A free form commit message. Needs to be imperative and without
  punctuation (e.g. `do stuff` instead of `did stuff.`).

- \[\<body>]: A free form commit body. Having one is encouraged when your
  changes are difficult to explain, unless you're writing in-depth code comments
  (it is still preferred however).

You can now make your changes in your editor of choice. After committing your
changes, you can run:

```shell
git push origin <branch-name>
```

and then open up a PR, or "Pull Request," in the upstream HJR repository. Again,
GitHub has good documentation for [creating a PR].

After you have setup a PR, it will be [reviewed] by maintainers and changes may
be requested. Make the changes requested and eventually it will likely be
accepted and merged into main.

## Core Principles {#ch-core-principles}

In creating HJR, we had a few principles in mind for development:

1. Minimize the number of options written.
2. Include only the module collection - leave functionality to Hjem.
3. Maintain readability of code, even for new users.

Please keep these in mind as you read through our general guidelines for
contributing.

## Writing Modules {#ch-writing-modules}

Writing modules is a core task of contributing to Hjem Rum, and makes up the
bulk of PRs. Learning to follow our guidelines, standards, and expectations in
writing modules is accordingly crucial. Please see
[**Contributing: Writing Modules**] for more information.

## Tests {#ch-tests}

Since [#43], all modules are expected to have tests to ensure their maintained
function through development. Writing tests has a steep learning curve, but
becomes easier over time. Please see [**Contributing: Writing Module Tests**]
for more information.

## Extending RumLib {#ch-extending-rumlib}

In writing modules, you may often find yourself in need of a custom function or
two. While writing functions is certainly a more advanced contributing task, it
is absolutely within your range to do. Please see
[**Contributing: Extending Hjem Rum's Library**] for more information.

## Docs {#ch-docs}

Please see [**Contributing: Expanding the Documentation**] for information on
this.

## Reviewing a PR {#ch-reviewing-a-pr}

Even if you do not have write-access, you can always leave a review on someone
else's PR. GitHub has great [documentation on reviewing PRs]. This is great
practice for learning the guidelines as well as learning exceptions to the
rules. For some guidelines on review practices, see
[**Contributing: Review Tips**].
