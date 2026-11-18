# roc-types' output format

This is the contract between roc-types and the programs that read it. A
change a reader must know of is a new format number, in the header line and
in `main.zig`'s `format`. This file describes format 1.

## The argument

`roc-types <app.roc>` takes one argument, an app: one that names a platform,
or one that names none and runs on the Echo platform. A type module (no app
header) is refused as `NotAnAppHeader`; a type module's types are read
through an app that imports it. A relative path is fine: roc-types resolves
it to its real, absolute path before the compiler sees it.

## Stdout

The first line names the format and whose checker wrote the types, and it is
written before anything else, so a reader sees it even when the checker
crashes:

    roc-types 1 <roc-version>

`<roc-version>` is the whole line of `roc-version`, such as
`nightly-2026-11-03-34bd006`.

Then, for each module the app reaches (its own, its platform's, its
packages' and their packages' in turn):

    == <path>
    t<TAB>expr|pat<TAB>tag<TAB>line<TAB>col<TAB>end_line<TAB>end_col<TAB>type

- **The path** is absolute and holds no `.` or `..` part.
- **A `t` record** is a node of the module's canonical tree, an expression
  (`expr`) or a pattern (`pat`).
- **`tag`** is the node's kind, as the compiler names it: `e_call`,
  `e_lookup_external`, a pattern's `assign`.
- **The span** is the node's region. Lines and columns count from 1,
  columns are in bytes, and the end column is one past the last byte.
- **`type`** is the checker's, on one line as its type writer prints it
  (`Str -> Str`), with `\`, tab, newline and carriage return escaped as
  `\\`, `\t`, `\n` and `\r`.

Records come in the visitor's pre-order: a node comes before the nodes
inside it. So when several nodes share one region (a `?`'s desugaring, a
nominal tag, an `and`'s `if`), the outermost comes first.

## Stderr and the exit status

Every report the checker makes goes to stderr, rendered, before any module
is written. Nothing is half-checked:

| exit | meaning |
|---|---|
| 0 | every module checked; stdout holds every module's types |
| 1 | refused: a report of error severity, a module the checker left failed or without its environment (named on stderr), a build that stopped, a path that cannot be read, or a root that is not an app; no module is written |
| 2 | not one argument |

A warning is only said on stderr and does not change the exit. A reader
holds a run that exits 0 to every module's types.

## An example

For `tests/imported/main.roc`, an app on a platform that imports a type
module `Greeting`, the whole output:

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
