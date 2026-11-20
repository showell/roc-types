# roc-types

**roc-types prints the type of every expression and pattern in a Roc app, as
Roc's own type checker infers it, as plain text that any program can read.**

The code here was written by AI coding agents (Claude), with human supervision. Point an agent at it, and at [FORMAT.md](FORMAT.md), to build a tool on its output.

A parser gives the shape of Roc code. roc-types gives its types, that `xs`
is a `List(U8)` or that a function returns a `Bool`, because it runs the
compiler's checker. A lint, a refactoring tool, a type on hover or a
teaching tool needs that when the answer turns on a type.

It is one static binary for Linux on x86-64, and it stands alone: download
it, point it at an app, and read the types.

**It matches one Roc nightly**, the one [`roc-version`](roc-version) names
and the output's first line repeats. Build the code you give it with that
nightly. [The pin](#the-pin-one-roc-nightly) says why.

## An example

`tests/imported/` is a small app on a test platform. Its `main.roc` says, on
line 8:

    main = Greeting.hello("roc")

and the `Greeting.roc` module beside it says, on line 4:

    hello = |name| "hello ${name}"

Running roc-types on the app prints this, whole (from a checkout at
`/home/me/roc-types`; the paths are absolute):

    $ roc-types tests/imported/main.roc
    roc-types 1 nightly-2026-11-03-34bd006
    == /home/me/roc-types/tests/imported/main.roc
    t	pat	assign	8	1	8	5	Str
    t	expr	e_call	8	8	8	29	Str
    t	expr	e_lookup_external	8	8	8	22	Str -> Str
    t	expr	e_str	8	23	8	28	Str
    t	expr	e_str_segment	8	24	8	27	Str
    == /home/me/roc-types/tests/imported/Greeting.roc
    t	pat	assign	4	2	4	7	Str -> Str
    t	expr	e_lambda	4	10	4	32	Str -> Str
    t	pat	assign	4	11	4	15	Str
    t	expr	e_block	4	17	4	32	Str
    t	pat	assign	4	26	4	30	Str
    t	expr	e_lookup_local	4	26	4	30	Str
    t	expr	e_interpolation	4	17	4	32	Str
    t	expr	e_str_segment	4	18	4	24	Str
    t	expr	e_lookup_local	4	26	4	30	Str
    t	expr	e_str_segment	4	31	4	31	Str
    == /home/me/roc-types/tests/nested/pf/main.roc
    t	pat	assign	11	1	11	14	Str
    t	expr	e_lookup_required	11	17	11	21	Str

The first line names the output format and the Roc nightly whose checker
wrote the types. Each `==` line starts a module the app reaches: its own,
the modules it imports, and its platform's and packages'. Each `t` line is
one node, its fields separated by tabs: an expression or a pattern, the
compiler's name for its kind, its span (start line, start column, end line,
end column) and its type. So `Greeting.hello` on line 8, columns 8 to 22, is
a `Str -> Str`, and the whole call is a `Str`.

[FORMAT.md](FORMAT.md) is the full contract: the columns, how a type is
escaped, the order of the records, and the exit codes.

## Build your own tools on it

The output is lines of tab-separated fields, so a tool in any language can
read it. As a small example, this lists every function the app takes from
another module, with its type:

    $ roc-types tests/imported/main.roc | awk -F'\t' '/^== /{path=substr($0,4)} $3=="e_lookup_external"{print path":"$4":"$5"\t"$8}'
    /home/me/roc-types/tests/imported/main.roc:8:8	Str -> Str

A tool should rely on three things:

- **The exit code.** 0 means every module's types are on stdout. 1 means the
  checker refused the app (a type error, say), and stderr says why; stdout
  then holds no module, so a tool reads a whole answer or none.
- **The first line.** It names the format and the Roc nightly. A tool should
  check both before it trusts a type.
- **The argument is an app.** A module without an app header is refused;
  its types come from an app that imports it.

## Install

roc-types runs on Linux on x86-64. The binary is static, so it runs on any
distribution. To install the current release:

    curl -fsSLO https://github.com/showell/roc-apps/releases/download/roc-types-2026-11-16/roc-types-3-34bd006-linux-x86_64.tar.gz
    echo "cd845659c8f6e167d0dff543f7a342fe41c361f7d5f1f4fdb8597a2e35a2f527  roc-types-3-34bd006-linux-x86_64.tar.gz" | sha256sum -c
    tar -xzf roc-types-3-34bd006-linux-x86_64.tar.gz

That unpacks `bin/roc-types`. Put it on your `PATH` or call it by its path.
The file [`release`](release) always names the current asset's URL and
sha256.

roc-types holds the checker itself, apart from your `roc`. To build
and run your code with the same compiler, get the matching nightly from
[roc-lang/nightlies](https://github.com/roc-lang/nightlies/releases):

    gh release download nightly-2026-11-03-34bd006 -R roc-lang/nightlies -p 'roc_nightly-linux_x86_64-*.tar.gz'

## Companion: roc-ast

[roc-ast](https://github.com/showell/roc-ast) is roc-types' companion.
roc-types gives the type of every expression and pattern, but it needs a
whole app that checks. roc-ast gives the syntax of any one file, Roc's own
parse tree, type errors and all. So a tool reads the tree
from roc-ast and asks roc-types only where a type decides. Both print spans
the same way, lines and byte columns from 1 with an exclusive end, so a
tree's node and a type's record meet by their spans.

## The pin: one Roc nightly

Roc's new compiler is published as nightly builds, and its type checker
changes between them: a nightly may infer a type differently, print it
differently, or refuse code an earlier one accepted. roc-types is built from
Roc's source at one commit, so the types it prints are that compiler's. With
another nightly, roc-types and your compiler may disagree on what checks and
on its types.

So build your code with the nightly the release names. It is in
[`roc-version`](roc-version) and in the first line of the output. A new
nightly needs a new build of roc-types and a new release.

In this repository the pin is held in three places that must agree:

- `roc-version` names the Roc nightly and its commit;
- `build.zig.zon` depends on Roc's source at that commit, and `build.zig`
  refuses to build when the two differ;
- `cir_visitor.zig` is Roc's `src/lsp/cir_visitor.zig` copied at that
  commit, so the walk over each module is the pinned compiler's own.

## How it works

`roc-types app.roc` checks the app and every module it reaches through the
compiler's own front end, the `BuildEnv` that `roc check` and Roc's language
server use. It then walks each checked module with the language server's
visitor and prints each node's kind, region and type. The header comment of
`main.zig` says why it goes through `BuildEnv`.

## How Shale uses it

[Shale](https://github.com/showell/shale) is a scripting tool whose
[Roc recipes](https://github.com/showell/shale/blob/master/cookbook/roc/README.md)
check and rewrite Roc code. They read the syntax tree from Roc's own parser,
through [roc-ast](https://github.com/showell/roc-ast), and roc-types gives
them the types:

- [rewrite_method_calls](https://github.com/showell/shale/blob/master/cookbook/roc/rewrite_method_calls.shale)
  turns `List.map(xs, f)` into `xs.map(f)` where that is the same call:
  where the first argument's type is the module's own, a `List(...)` for a
  `List` call. A first argument of another type, such as a list given to
  `Str.from_utf8`, keeps its call, with the reason. A call the
  types leave open, where the first argument is a type variable, is tried
  with `roc check` and `roc test`.
- [hunt_names](https://github.com/showell/shale/blob/master/cookbook/roc/hunt_names.shale)
  flags names that disagree with their types, such as a question
  (`is_ready`) that returns something other than a `Bool`. With types, it also judges a
  definition with no annotation by its inferred type, and it counts an alias
  of `Bool` as a `Bool`.
- [check_errors](https://github.com/showell/shale/blob/master/cookbook/roc/check_errors.shale)
  flags a lookup by index that falls back to a number (`?? 0`), since an
  index past the end is a bug. With types, it goes by how the
  lookup can fail rather than by its name: a lookup that fails only with
  `[OutOfBounds]` is flagged, and one that can fail with `KeyNotFound` or
  `ListWasEmpty` passes. A fallback to a placeholder string is reported
  with its type and the tags the lookup fails with.
- [check_boundaries](https://github.com/showell/shale/blob/master/cookbook/roc/check_boundaries.shale)
  flags a parameter the checker types as `Bool` when a caller passes it
  `True` or `False`, since a flag reads better as a tag named for what it
  means. The types say which parameters are `Bool`s.

The reader is
[types.shale](https://github.com/showell/shale/blob/master/cookbook/roc/types.shale).
Before it reads any type, it checks the format number in the first line,
and that the nightly named there is the compiler the project is built with.

With Shale, `shale install.shale` in this checkout downloads the release,
checks its sha256 and unpacks it at `roc-types/bin/roc-types` under Shale's
`tools` mount. The recipes look there, after first looking for
`roc-types-<nightly>/bin/roc-types` beside it, so builds for several
nightlies can be installed side by side.

## Building from source

Building roc-types links most of Roc's compiler, LLVM included. That takes
far more time and memory than the tool's own code suggests, so it is built
on GitHub Actions by [`.github/workflows/build.yml`](.github/workflows/build.yml),
which runs when started by hand. In a fork, run the `build` workflow
from the Actions tab, or:

    gh workflow run build.yml -f ref=master

The workflow:

- installs the Zig that `zig-version` names, the one the pinned Roc builds
  with (from [patched-zig-compiler](https://github.com/showell/patched-zig-compiler));
- checks out Roc at the pinned commit in full and builds against it with
  `--fork`, since Roc's `vendor/` is outside the archive `build.zig.zon`
  names;
- builds static, for `x86_64-linux-musl` at the baseline CPU, ReleaseSafe;
- runs a smoke test and the fixtures, so a build that fails them makes no
  artifact;
- tars `bin/roc-types` as `roc-types-<format>-<commit>-linux-x86_64.tar.gz`,
  where `<format>` is the output format's number and `<commit>` is Roc's
  short commit, and keeps it as the run's artifact, with its sha256 in the
  log.

To build on your own machine, follow the same steps; the workflow file has
the exact commands.

## Tests

`shale test.shale` runs the installed roc-types (or `exe=` another) on the
fixtures in `tests/` and judges each by its exit, the modules it writes and
some of its records. It runs on Shale.

- `nested`: an app whose package has a package of its own, reached through
  that package alone;
- `broken`: the same with a type error in the inner package, refused with
  no module written;
- `echo`: an app with no platform, which runs on the Echo platform, its
  call of `echo!` typed;
- `imported`: an app that imports a type module beside it;
- `notapp`: a type module given as the argument, refused.

The build workflow checks the first four on every build, with plain shell
commands, by their exits, modules and header.

## Publishing a release

Publishing is by hand. Download the workflow's artifact
(`gh run download`), publish it as a release of this repository under a new
name, and put its URL and sha256 in `release`, then in this README's install
commands. A published asset stays as it is; `release` names where each one
lives.
[FINDINGS.md](FINDINGS.md) records what was learned trying newer nightlies.

## License

The Universal Permissive License 1.0 ([LICENSE](LICENSE)).
`cir_visitor.zig` comes from [Roc](https://github.com/roc-lang/roc), under
the same license; Roc's copyright notice is in [LICENSE-ROC](LICENSE-ROC).
