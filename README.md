# roc-types

**roc-types writes every expression's and pattern's type in a Roc app, as
Roc's own type checker infers it, one fact a line for a program to read.**

`roc-types app.roc` checks the app and every module it reaches (its
platform's and packages' too, and their packages' in turn) through the Roc
compiler's own front end, the `BuildEnv` that `roc check` and Roc's language
server build with. It then walks each checked module with the language
server's visitor and writes each node's kind, region and type. The checker
is roc-lang/roc's at the commit `roc-version` pins, so the types are what
that compiler infers.

## Who it's for

It is for tools that judge or rewrite Roc code and need the types a parser
cannot give. Shale's Roc recipes are its first readers: `cookbook/roc/types.shale`
in [Shale](https://github.com/showell/shale) reads the output, and the
recipes built on it (the typed lints and the method-call rewrite) use it to
decide what a call's first argument is. It is not a checker for people;
`roc check` is that.

## Install

roc-types is a static binary for Linux on x86-64, published as a tarball
that holds `bin/roc-types`. `release` names the asset: its URL and its
sha256.

- **With Shale**, from this checkout (a `tools` mount is needed, pointing at
  `~/tools`):

      shale install.shale

  It downloads the asset, holds it to `release`'s sha256 and unpacks it at
  `~/tools/roc-types/bin/roc-types`.
- **Without Shale**, download the URL in `release`, check its sha256 and
  unpack it where you keep tools.

The Shale recipes look first for `~/tools/roc-types-<pin>/bin/roc-types`
(the roc-types of the tree's Roc, so builds for several pins sit side by
side) and then `~/tools/roc-types/bin/roc-types`.

## Usage

    roc-types path/to/app.roc > types.txt

The argument must be an app; a type module's types are read through an app
that imports it. Exit 0 means every module's types are on stdout; exit 1
means the checker refused the app, and stderr says why, with no module
written. **[FORMAT.md](FORMAT.md) is the output's contract**: the header
line, the module and record lines, and the exits.

## The pin rule

**roc-types must be built against the same Roc the code it reads is built
with.** Its types are one compiler's: another Roc may infer, name or print a
type differently, or refuse code this one accepts. So the pin is held in
three places that must agree:

- `roc-version` names the Roc nightly and its commit;
- `build.zig.zon` depends on Roc's source at that commit, and `build.zig`
  refuses to build when the two differ;
- `cir_visitor.zig` is Roc's `src/lsp/cir_visitor.zig` copied at that
  commit, so the walk is the pinned compiler's own.

The header line names the pin, so a reader checks it against the compiler
its tree is built with before it trusts a type (Shale's `types.shale`
does). A new pin is a new build and a new asset.

## Building

roc-types is built on GitHub only, by `.github/workflows/build.yml`, run by
hand:

    gh workflow run build.yml -f ref=<branch, tag or commit>

Linking the compiler's front end builds most of Roc's compiler, with LLVM.
That takes far more CPU and memory than the tool's own few hundred lines
warrant, so a GitHub runner does it, not a development machine. The
workflow:

- installs the Zig that `zig-version` names, the one the pinned Roc builds
  with (from [patched-zig-compiler](https://github.com/showell/patched-zig-compiler));
- checks out Roc at the pinned commit in full and builds against it with
  `--fork`, since the archive `build.zig.zon` names leaves out Roc's
  `vendor/`;
- builds static, for `x86_64-linux-musl` at the baseline CPU, ReleaseSafe;
- runs the smoke test and the fixtures, so an asset that fails them is
  never made;
- tars `bin/roc-types` as `roc-types-<N>-<commit>-linux-x86_64.tar.gz` and
  keeps it as the run's artifact, its sha256 in the log.

Publishing is by hand: download the artifact (`gh run download`), publish
it as a release of this repo under a new name, and put its URL and sha256
in `release`. A published asset never changes. The current one was first
published as a release of [roc-apps](https://github.com/showell/roc-apps),
before roc-types had a repo of its own, and `release` still names it there.

## Tests

`shale test.shale` runs the installed roc-types (or `exe=` another) on the
fixtures in `tests/` and judges each by its exit, the modules it writes and
some of its records:

- `nested`: an app whose package has a package of its own, which the app's
  header does not name;
- `broken`: the same with a type error in the inner package, refused with
  no module written;
- `echo`: an app on the Echo platform, its call of `echo!` typed;
- `imported`: an app that imports a type module beside it;
- `notapp`: a type module given as the root, refused.

The build workflow runs the first four on every build, by their exits,
modules and header.

## Files

| file | what |
|---|---|
| `main.zig` | the program |
| `cir_visitor.zig` | Roc's language-server visitor, vendored at the pin |
| `build.zig`, `build.zig.zon` | the build, with Roc as a dependency at the pin |
| `roc-version`, `zig-version` | the pins: Roc's nightly, and the Zig it builds with |
| `release` | the published asset's URL and sha256 |
| `install.shale`, `test.shale` | the install and the fixture test, in Shale |
| `FORMAT.md` | the output's contract |
| `FINDINGS.md` | what was learned moving the pin |

## License

The Universal Permissive License 1.0 ([LICENSE](LICENSE)).
`cir_visitor.zig` comes from [Roc](https://github.com/roc-lang/roc), under
the same license; Roc's copyright notice is in [LICENSE-ROC](LICENSE-ROC).
