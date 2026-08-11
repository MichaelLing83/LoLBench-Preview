> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# PEP 634: Structural Pattern Matching: Specification

## Abstract
This PEP provides the technical specification for the match
statement.  It replaces PEP 622, which is hereby split in three parts:

- PEP 634: Specification
- PEP 635: Motivation and Rationale
- PEP 636: Tutorial

This PEP is intentionally devoid of commentary; the motivation and all
explanations of our design choices are in PEP 635.  First-time readers
are encouraged to start with PEP 636, which provides a gentler
introduction to the concepts, syntax and semantics of patterns.

## Syntax and Semantics
See Appendix A for the complete grammar.

### Overview and Terminology
The pattern matching process takes as input a pattern (following
`case`) and a subject value (following `match`).  Phrases to
describe the process include "the pattern is matched with (or against)
the subject value" and "we match the pattern against (or with) the
subject value".

The primary outcome of pattern matching is success or failure.  In
case of success we may say "the pattern succeeds", "the match
succeeds", or "the pattern matches the subject value".

In many cases a pattern contains subpatterns, and success or failure
is determined by the success or failure of matching those subpatterns
against the value (e.g., for OR patterns) or against parts of the
value (e.g., for sequence patterns).  This process typically processes
the subpatterns from left to right until the overall outcome is
determined.  E.g., an OR pattern succeeds at the first succeeding
subpattern, while a sequence patterns fails at the first failing
subpattern.

A secondary outcome of pattern matching may be one or more name
bindings.  We may say "the pattern binds a value to a name".  When
subpatterns tried until the first success, only the bindings due to
the successful subpattern are valid; when trying until the first
failure, the bindings are merged.  Several more rules, explained
below, apply to these cases.

### The Match Statement
Syntax:

```
match_stmt: "match" subject_expr ':' NEWLINE INDENT case_block+ DEDENT
subject_expr:
    | star_named_expression ',' star_named_expressions?
    | named_expression
case_block: "case" patterns [guard] ':' block
guard: 'if' named_expression
```
The rules `star_named_expression`, `star_named_expressions`,
`named_expression` and `block` are part of the [standard Python grammar](https://docs.python.org/3.10/reference/grammar.html).

The rule `patterns` is specified below.

For context, `match_stmt` is a new alternative for
`compound_statement`:

```
compound_statement:
    | if_stmt
    ...
    | match_stmt
```
The `match` and `case` keywords are soft keywords, i.e. they are
not reserved words in other grammatical contexts (including at the
start of a line if there is no colon where expected).  This implies
that they are recognized as keywords when part of a match
statement or case block only, and are allowed to be used in all
other contexts as variable or argument names.

#### Match Semantics
The match statement first evaluates the subject expression.  If a
comma is present a tuple is constructed using the standard rules.

The resulting subject value is then used to select the first case
block whose patterns succeeds matching it *and* whose guard condition
(if present) is "truthy".  If no case blocks qualify the match
statement is complete; otherwise, the block of the selected case block
is executed.  The usual rules for executing a block nested inside a
compound statement apply (e.g. an `if` statement).

Name bindings made during a successful pattern match outlive the
executed block and can be used after the match statement.

During failed pattern matches, some subpatterns may succeed. For
example, while matching the pattern `(0, x, 1)` with the value ``[0,
1, 2]`, the subpattern `x`` may succeed if the list elements are
matched from left to right.  The implementation may choose to either
make persistent bindings for those partial matches or not. User code
including a match statement should not rely on the bindings being
made for a failed match, but also shouldn't assume that variables are
unchanged by a failed match.  This part of the behavior is left
intentionally unspecified so different implementations can add
optimizations, and to prevent introducing semantic restrictions that
could limit the extensibility of this feature.

The precise pattern binding rules vary per pattern type and are
specified below.


### Implementation Guidance

1. In `Parser/Python.asdl`, apply the required changes. Adds `Match(expr subject, match_case* cases)` as a new statement kind. Adds `MatchAs(expr pattern, identifier name)` and `MatchOr(expr* patterns)` as new expression kinds. Adds `match_case = (expr pattern, expr? guard, stmt* body)` as a new type.

2. In `Include/Python-ast.h`, update `_match_case`, `_stmt`, and `_expr`. Adds the `match_case_ty` typedef and `asdl_match_case_seq` sequence type. Updates `_stmt_kind` and `_expr_kind` enums to include `Match_kind`, `MatchAs_kind`, and `MatchOr_kind`. Adds struct fields and constructor declarations for the new AST node types.

3. In `Include/internal/pycore_ast.h`, update `ast_state`. Adds `MatchAs_type`, `MatchOr_type`, `Match_type`, `__match_args__`, `cases`, and `guard` fields to the `ast_state` struct for the AST module's cached type objects and attribute name strings.

4. In `Parser/asdl_c.py`, update `PyTypesVisitor`. Updates the ASDL-to-C code generator to emit `__match_args__` alongside `_fields` when creating AST type objects, and to set `__match_args__` as an empty tuple on the base AST type.

5. In `Python/Python-ast.c`, update `_PyAST_Fini`, `init_identifiers`, `make_type`, `add_ast_fields`, `init_types`, `Match`, `MatchAs`, `MatchOr`, `match_case`, `ast2obj_stmt`, `ast2obj_expr`, `ast2obj_match_case`, `ast_state.ast2obj_match_case`, `obj2ast_stmt`, `obj2ast_expr`, `obj2ast_match_case`, `ast_state.obj2ast_match_case`, and `astmodule_exec`. Implements constructors (`_Py_Match`, `_Py_match_case`, `_Py_MatchAs`, `_Py_MatchOr`), visitor functions (`ast2obj_*`, `obj2ast_*`), and initialization code for all new AST types. Adds `__match_args__` as an attribute on all AST node types.

6. In `Python/ast.c`, update `validate_expr`, `validate_pattern`, and `validate_stmt`. Adds `Match_kind` handling to `validate_stmt` that validates the subject expression, checks that `cases` is non-empty, and validates each case's pattern and optional guard. Adds `MatchAs_kind` and `MatchOr_kind` to `validate_expr`. Adds a `validate_pattern` stub function.

7. In `Python/ast_opt.c`, update `astfold_expr`, `astfold_stmt`, `astfold_pattern_negative`, `astfold_pattern_complex`, `astfold_pattern_keyword`, `astfold_pattern`, and `astfold_match_case`. Adds `astfold_match_case` and `astfold_pattern` functions for constant folding across all pattern expression node types. Adds `Match_kind` handling to `astfold_stmt`.

8. In `Python/compile.c`, update `stack_effect`, `compiler_visit_stmt`, `compiler.assignment_helper`, `compiler.unpack_helper`, `assignment_helper`, `unpack_helper`, `validate_keywords`, `compiler_visit_expr1`, `compiler.compiler_error`, `compiler_error`, `compiler_pattern`, `compiler.compiler_pattern`, `compiler_match`, and `compiler.compiler_match`. Adds `pattern_context` struct with `stores` (set of bound names) and `allow_irrefutable` flag. Adds `compiler_match` function that iterates over cases, sets `allow_irrefutable` based on guard presence and position, calls `compiler_pattern`, evaluates guards, and emits jumps to case bodies or the next case. Adds `compiler_pattern` dispatcher that routes to type-specific functions based on expression kind. Adds individual pattern compilation functions for all pattern types.

**Supporting changes:**

1. In `Include/internal/pycore_interp.h`, update `_is`. Adds `map_abc` and `seq_abc` fields to `PyInterpreterState` for caching `collections.abc.Mapping` and `collections.abc.Sequence`.

2. In `Lib/ast.py`, update `_Unparser`. Adds `Match`, `match_case`, `MatchAs`, and `MatchOr` to the `ast` module's Python-level API.

3. In `Python/pystate.c`, update `interpreter_clear`. Initializes and cleans up cached `map_abc` and `seq_abc` references on interpreter state.

4. In `Include/opcode.h`, apply the required changes. Defines new opcodes: `GET_LEN`, `MATCH_MAPPING`, `MATCH_SEQUENCE`, `MATCH_KEYS`, `COPY_DICT_WITHOUT_KEYS`, `MATCH_CLASS`.

5. In `Lib/opcode.py`, apply the required changes. Registers the new pattern matching opcodes in the Python-level opcode module.

6. In `Python/opcode_targets.h`, apply the required changes. Updates the computed goto dispatch table for the new opcodes.

7. In `Doc/library/dis.rst`, apply the required changes. Documents the new bytecode instructions for pattern matching.

8. In `Lib/importlib/_bootstrap_external.py`, apply the required changes. Updates the magic number for the new bytecodes added by pattern matching.

9. In `Python/importlib_external.h`, apply the required changes. Regenerated frozen importlib external module reflecting the magic number change.

10. Add `Misc/NEWS.d/next/Core and Builtins/2020-10-23-08-54-04.bpo-42128.SWmVEm.rst`. NEWS entry announcing pattern matching implementation.
#### Guards
If a guard is present on a case block, once the pattern or patterns in
the case block succeed, the expression in the guard is evaluated.  If
this raises an exception, the exception bubbles up.  Otherwise, if the
condition is "truthy" the case block is selected; if it is "falsy" the
case block is not selected.

Since guards are expressions they are allowed to have side effects.
Guard evaluation must proceed from the first to the last case block,
one at a time, skipping case blocks whose pattern(s) don't all
succeed.  (I.e., even if determining whether those patterns succeed
may happen out of order, guard evaluation must happen in order.)
Guard evaluation must stop once a case block is selected.


### Implementation Guidance

1. In `Python/compile.c`, apply the required changes. If the guard is falsy, control jumps to the next case block. If the guard is truthy, the case body executes and then jumps to the end of the match statement. This ensures guards are evaluated in order and only after their associated pattern succeeds.
#### Irrefutable case blocks
A pattern is considered irrefutable if we can prove from its syntax
alone that it will always succeed.  In particular, capture patterns
and wildcard patterns are irrefutable, and so are AS patterns whose
left-hand side is irrefutable, OR patterns containing at least
one irrefutable pattern, and parenthesized irrefutable patterns.

A case block is considered irrefutable if it has no guard and its
pattern is irrefutable.

A match statement may have at most one irrefutable case block, and it
must be last.


### Implementation Guidance

1. In `Python/compile.c`, apply the required changes. Adds `allow_irrefutable` field to `pattern_context`. `compiler_pattern_capture` (the relevant section) and `compiler_pattern_wildcard` (the relevant section) check this flag and raise `SyntaxError` if an irrefutable pattern appears in a non-final unguarded case. `compiler_pattern_or` (the relevant section) propagates `allow_irrefutable` to the last alternative only. `compiler_pattern_subpattern` (the relevant section) temporarily enables `allow_irrefutable` for sub-positions where irrefutable patterns are valid.
### Patterns
The top-level syntax for patterns is as follows:

```
patterns: open_sequence_pattern | pattern
pattern: as_pattern | or_pattern
as_pattern: or_pattern 'as' capture_pattern
or_pattern: '|'.closed_pattern+
closed_pattern:
    | literal_pattern
    | capture_pattern
    | wildcard_pattern
    | value_pattern
    | group_pattern
    | sequence_pattern
    | mapping_pattern
    | class_pattern
```
#### AS Patterns
Syntax:

```
as_pattern: or_pattern 'as' capture_pattern
```
(Note: the name on the right may not be `_`.)

An AS pattern matches the OR pattern on the left of the `as`
keyword against the subject.  If this fails, the AS pattern fails.
Otherwise, the AS pattern binds the subject to the name on the right
of the `as` keyword and succeeds.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `as_pattern: or_pattern 'as' capture_pattern` production that lets the parser recognize `<pattern> as <name>` syntax described by this section.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for `Grammar/python.gram` so the AS-pattern production is actually accepted at runtime.

3. In `Parser/Python.asdl`, apply the required changes. Declares the `MatchAs(expr pattern, identifier name)` AST node that the AS-pattern grammar production constructs.

4. In `Python/Python-ast.c`, apply the required changes. Generated AST machinery for the `MatchAs` node — the `MatchAs` constructor and `ast2obj_*` / `obj2ast_*` visitors used to materialize AS patterns in the AST.

5. In `Python/compile.c`, update `compiler_pattern_as` and `compiler.compiler_pattern_as`. `compiler_pattern_as` handles `MatchAs_kind` expressions. It compiles the inner OR pattern, and if the match succeeds, stores the subject value to the named variable. It verifies that the right-hand name is not `_` and delegates the inner pattern compilation to the existing pattern infrastructure.
#### OR Patterns
Syntax:

```
or_pattern: '|'.closed_pattern+
```
When two or more patterns are separated by vertical bars (`|`),
this is called an OR pattern.  (A single closed pattern is just that.)

Only the final subpattern may be irrefutable.

Each subpattern must bind the same set of names.

An OR pattern matches each of its subpatterns in turn to the subject,
until one succeeds.  The OR pattern is then deemed to succeed.
If none of the subpatterns succeed the OR pattern fails.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `or_pattern: '|'.closed_pattern+` production that captures the `|`-separated alternatives described by this section.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser implementing the OR-pattern production from `Grammar/python.gram`.

3. In `Parser/Python.asdl`, apply the required changes. Declares the `MatchOr(expr* patterns)` AST node that the OR-pattern grammar production builds.

4. In `Python/Python-ast.c`, apply the required changes. Generated AST machinery for the `MatchOr` node — the `MatchOr` constructor and `ast2obj_*` / `obj2ast_*` visitors used to materialize OR patterns in the AST.

5. In `Python/compile.c`, update `compiler_pattern_or` and `compiler.compiler_pattern_or`. `compiler_pattern_or` handles `MatchOr_kind` expressions. For each alternative in the OR pattern, it compiles the subpattern and jumps to a success label if it matches. After all alternatives fail, it falls through to failure. After any alternative succeeds, it validates that the set of bound names matches the first alternative's set. Only the final subpattern may be irrefutable per `allow_irrefutable` propagation.
#### Literal Patterns
Syntax:

```
literal_pattern:
    | signed_number
    | signed_number '+' NUMBER
    | signed_number '-' NUMBER
    | strings
    | 'None'
    | 'True'
    | 'False'
signed_number: NUMBER | '-' NUMBER
```
The rule `strings` and the token `NUMBER` are defined in the
standard Python grammar.

Triple-quoted strings are supported.  Raw strings and byte strings
are supported.  F-strings are not supported.

The forms `signed_number '+' NUMBER` and ``signed_number '-'
NUMBER`` are only permitted to express complex numbers; they require a
real number on the left and an imaginary number on the right.

A literal pattern succeeds if the subject value compares equal to the
value expressed by the literal, using the following comparisons rules:

- Numbers and strings are compared using the `==` operator.

- The singleton literals `None`, `True` and `False` are compared
  using the `is` operator.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `literal_pattern` and `signed_number` productions (numbers, signed numbers, complex `signed_number '+'/'-' NUMBER` forms, strings, and the `None`/`True`/`False` singletons) so the parser recognizes literal patterns as defined by this section.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser implementing the literal-pattern productions from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_literal` and `compiler.compiler_pattern_literal`. `compiler_pattern_literal` handles literal pattern nodes. For `None`, `True`, and `False`, it emits `IS_OP` for identity comparison. For numeric and string literals (including complex number expressions), it emits `COMPARE_OP` with `==` semantics. The function handles `BinOp_kind` for complex number literals (real +/- imaginary) and `UnaryOp_kind` for negated numbers.
#### Capture Patterns
Syntax:

```
capture_pattern: !"_" NAME
```
The single underscore (`_`) is not a capture pattern (this is what
`!"_"` expresses).  It is treated as a `wildcard pattern`_.

A capture pattern always succeeds.  It binds the subject value to the
name using the scoping rules for name binding established for the
walrus operator in PEP 572.  (Summary: the name becomes a local
variable in the closest containing function scope unless there's an
applicable `nonlocal` or `global` statement.)

In a given pattern, a given name may be bound only once.  This
disallows for example `case x, x: ...` but allows ``case [x] | x:
...``.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `capture_pattern:!"_" NAME` production so a bare name (other than the wildcard `_`) is recognized as a capture pattern at the grammar level.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the capture-pattern production from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_capture`, `compiler.compiler_pattern_capture`, `pattern_helper_store_name`, and `compiler.pattern_helper_store_name`. `compiler_pattern_capture` handles capture pattern nodes. It checks `allow_irrefutable` (since captures are irrefutable), verifies that the name is not already in the pattern context's `stores` set (raising `SyntaxError` for duplicate bindings like `case x, x:`), adds the name to `stores`, and emits via `pattern_helper_store_name` a `STORE_NAME`/`STORE_FAST` instruction to bind the subject to the captured name.

**Supporting changes:**

1. In `Include/symtable.h`, apply the required changes. `in_pattern` symbol-table flag supports capture-pattern name binding.

2. In `Python/symtable.c`, apply the required changes. `symtable_visit_match_case` records name bindings used by capture patterns.
#### Wildcard Pattern
Syntax:

```
wildcard_pattern: "_"
```
A wildcard pattern always succeeds.  It binds no name.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `wildcard_pattern: "_"` production so the lone underscore is recognized at the grammar level as the wildcard pattern (and not as a capture).

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the wildcard-pattern production from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_wildcard` and `compiler.compiler_pattern_wildcard`. `compiler_pattern_wildcard` handles the `_` wildcard pattern. It checks `allow_irrefutable` (since wildcards are irrefutable) and emits no additional instructions -- the pattern always succeeds and no name binding occurs.

**Supporting changes:**

1. In `Include/symtable.h`, apply the required changes. `in_pattern` symbol-table flag also governs the wildcard `_` suppression.

2. In `Python/symtable.c`, apply the required changes. `symtable_visit_match_case` suppresses `_` as a local variable in patterns.
#### Value Patterns
Syntax:

```
value_pattern: attr
attr: name_or_attr '.' NAME
name_or_attr: attr | NAME
```
The dotted name in the pattern is looked up using the standard Python
name resolution rules.  However, when the same value pattern occurs
multiple times in the same match statement, the interpreter may cache
the first value found and reuse it, rather than repeat the same
lookup.  (To clarify, this cache is strictly tied to a given execution
of a given match statement.)

The pattern succeeds if the value found thus compares equal to the
subject value (using the `==` operator).


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `value_pattern: attr` / `attr: name_or_attr '.' NAME` / `name_or_attr: attr | NAME` productions so dotted names like `Color.RED` are recognized as value patterns.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the value-pattern productions from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_value` and `compiler.compiler_pattern_value`. `compiler_pattern_value` handles value pattern nodes (dotted names like `Color.RED`). It loads the first name component, then emits `LOAD_ATTR` for each subsequent dotted component, and finally emits `COMPARE_OP` with `==` to compare the resolved value against the subject.
#### Group Patterns
Syntax:

```
group_pattern: '(' pattern ')'
```
(For the syntax of `pattern`, see Patterns above.  Note that it
contains no comma -- a parenthesized series of items with at least one
comma is a sequence pattern, as is `()`.)

A parenthesized pattern has no additional syntax.  It allows users to
add parentheses around patterns to emphasize the intended grouping.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `group_pattern: '(' pattern ')'` production so parenthesized patterns are recognized as a grouping construct that simply yields the inner pattern.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the group-pattern production from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_subpattern` and `compiler.compiler_pattern_subpattern`. Group patterns are desugared at the grammar level into their inner pattern. The `compiler_pattern_subpattern` helper temporarily enables `allow_irrefutable` for sub-positions, then delegates to `compiler_pattern` for the inner pattern. No dedicated `compiler_pattern_group` function is needed since the AST does not distinguish group patterns from their contents.
#### Sequence Patterns
Syntax:

```
sequence_pattern:
  | '[' [maybe_sequence_pattern] ']'
  | '(' [open_sequence_pattern] ')'
open_sequence_pattern: maybe_star_pattern ',' [maybe_sequence_pattern]
maybe_sequence_pattern: ','.maybe_star_pattern+ ','?
maybe_star_pattern: star_pattern | pattern
star_pattern: '*' (capture_pattern | wildcard_pattern)
```
(Note that a single parenthesized pattern without a trailing comma is
a group pattern, not a sequence pattern.  However a single pattern
enclosed in `[...]` is still a sequence pattern.)

There is no semantic difference between a sequence pattern using
`[...]`, a sequence pattern using `(...)`, and an open sequence
pattern.

A sequence pattern may contain at most one star subpattern.  The star
subpattern may occur in any position.  If no star subpattern is
present, the sequence pattern is a fixed-length sequence pattern;
otherwise it is a variable-length sequence pattern.

For a sequence pattern to succeed the subject must be a sequence,
where being a sequence is defined as its class being one of the following:

- a class that inherits from `collections.abc.Sequence`
- a Python class that has been registered as a `collections.abc.Sequence`
- a builtin class that has its `Py_TPFLAGS_SEQUENCE` bit set
- a class that inherits from any of the above (including classes defined *before* a
  parent's `Sequence` registration)

The following standard library classes will have their `Py_TPFLAGS_SEQUENCE`
bit set:

- `array.array`
- `collections.deque`
- `list`
- `memoryview`
- `range`
- `tuple`

> **Note:** Although `str`, `bytes`, and `bytearray` are usually considered sequences, they are not included in the above list and do not match sequence patterns.
A fixed-length sequence pattern fails if the length of the subject
sequence is not equal to the number of subpatterns.

A variable-length sequence pattern fails if the length of the subject
sequence is less than the number of non-star subpatterns.

The length of the subject sequence is obtained using the builtin
`len()` function (i.e., via the `__len__` protocol).  However, the
interpreter may cache this value in a similar manner as described for
value patterns.

A fixed-length sequence pattern matches the subpatterns to
corresponding items of the subject sequence, from left to right.
Matching stops (with a failure) as soon as a subpattern fails.  If all
subpatterns succeed in matching their corresponding item, the sequence
pattern succeeds.

A variable-length sequence pattern first matches the leading non-star
subpatterns to the corresponding items of the subject sequence, as for
a fixed-length sequence.  If this succeeds, the star subpattern
matches a list formed of the remaining subject items, with items
removed from the end corresponding to the non-star subpatterns
following the star subpattern.  The remaining non-star subpatterns are
then matched to the corresponding subject items, as for a fixed-length
sequence.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `sequence_pattern`, `open_sequence_pattern`, `maybe_sequence_pattern`, `maybe_star_pattern`, and `star_pattern` productions so the parser accepts `[...]`/`(...)` sequence patterns with at most one `*name`/`*_` star subpattern.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the sequence-pattern productions from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_sequence`, `compiler.compiler_pattern_sequence`, `pattern_helper_sequence_unpack`, `compiler.pattern_helper_sequence_unpack`, `pattern_helper_sequence_subscr`, and `compiler.pattern_helper_sequence_subscr`. `compiler_pattern_sequence` (plus `pattern_helper_sequence_unpack` / `pattern_helper_sequence_subscr`) emits `MATCH_SEQUENCE` to check if the subject is a sequence, `GET_LEN` to obtain the length, a length comparison (equality for fixed-length, minimum for variable-length), and then matches each subpattern against the corresponding item using subscript access. For star patterns, it constructs a list from the remaining items.

4. In `Python/ceval.c`, apply the required changes. Implements the `MATCH_SEQUENCE` opcode that checks if the subject is a `collections.abc.Sequence` (with fast path for list/tuple subclasses, and exclusion of `str`/`bytes`/`bytearray`). Implements the `GET_LEN` opcode that pushes `len(TOS)` onto the stack. Lazily imports and caches `_collections_abc.Sequence` on the interpreter state.

**Supporting changes:**

1. In `Include/internal/pycore_interp.h`, apply the required changes. `seq_abc` cache field on `PyInterpreterState` supports sequence-pattern matching.

2. In `Include/opcode.h`, apply the required changes. Defines `MATCH_SEQUENCE` and `GET_LEN` opcodes used by sequence patterns.

3. In `Lib/opcode.py`, apply the required changes. Registers the sequence-pattern opcodes in the Python-level opcode module.

4. In `Python/opcode_targets.h`, apply the required changes. Adds dispatch table entries for the sequence-pattern opcodes.

5. In `Python/pystate.c`, apply the required changes. Cleans up the `seq_abc` cache on interpreter state.
#### Mapping Patterns
Syntax:

```
mapping_pattern: '{' [items_pattern] '}'
items_pattern: ','.key_value_pattern+ ','?
key_value_pattern:
    | (literal_pattern | value_pattern) ':' pattern
    | double_star_pattern
double_star_pattern: '**' capture_pattern
```
(Note that `**_` is disallowed by this syntax.)

A mapping pattern may contain at most one double star pattern,
and it must be last.

A mapping pattern may not contain duplicate key values.
(If all key patterns are literal patterns this is considered a
syntax error; otherwise this is a runtime error and will
raise `ValueError`.)

For a mapping pattern to succeed the subject must be a mapping,
where being a mapping is defined as its class being one of the following:

- a class that inherits from `collections.abc.Mapping`
- a Python class that has been registered as a `collections.abc.Mapping`
- a builtin class that has its `Py_TPFLAGS_MAPPING` bit set
- a class that inherits from any of the above  (including classes defined *before* a
  parent's `Mapping` registration)

The standard library classes `dict` and `mappingproxy` will have their `Py_TPFLAGS_MAPPING`
bit set.

A mapping pattern succeeds if every key given in the mapping pattern
is present in the subject mapping, and the pattern for
each key matches the corresponding item of the subject mapping. Keys
are always compared with the `==` operator.  If a ``'**'
NAME` form is present, that name is bound to a `dict`` containing
remaining key-value pairs from the subject mapping.

If duplicate keys are detected in the mapping pattern, the pattern is
considered invalid, and a `ValueError` is raised.

Key-value pairs are matched using the two-argument form of the
subject's `get()` method.  As a consequence, matched key-value pairs
must already be present in the mapping, and not created on-the-fly by
`__missing__` or `__getitem__`.  For example,
`collections.defaultdict` instances will only be matched by patterns
with keys that were already present when the match statement was
entered.


### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `mapping_pattern`, `items_pattern`, `key_value_pattern`, and `double_star_pattern` productions so the parser accepts `{key: pattern,..., **rest}` mapping patterns.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the mapping-pattern productions from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_mapping` and `compiler.compiler_pattern_mapping`. `compiler_pattern_mapping` emits `MATCH_MAPPING` to check if the subject is a mapping, `MATCH_KEYS` with a tuple of key patterns to extract corresponding values, and then matches each value against its subpattern. For double-star patterns, it emits `COPY_DICT_WITHOUT_KEYS` to capture the remaining key-value pairs.

4. In `Python/ceval.c`, update `match_keys`. Implements the `MATCH_MAPPING` opcode that checks if the subject is a `collections.abc.Mapping` (with fast path for dicts). `match_keys` uses the two-argument `get` method to look up keys and detect missing/duplicate keys. Implements `COPY_DICT_WITHOUT_KEYS` that creates a new dict containing all key-value pairs except the matched keys. Lazily imports and caches `_collections_abc.Mapping` on the interpreter state.

**Supporting changes:**

1. In `Include/internal/pycore_interp.h`, apply the required changes. `map_abc` cache field on `PyInterpreterState` supports mapping-pattern matching.

2. In `Include/opcode.h`, apply the required changes. Defines `MATCH_MAPPING`, `MATCH_KEYS`, and `COPY_DICT_WITHOUT_KEYS` opcodes used by mapping patterns.

3. In `Lib/opcode.py`, apply the required changes. Registers the mapping-pattern opcodes in the Python-level opcode module.

4. In `Python/opcode_targets.h`, apply the required changes. Adds dispatch table entries for the mapping-pattern opcodes.

5. In `Python/pystate.c`, apply the required changes. Cleans up the `map_abc` cache on interpreter state.
#### Class Patterns
Syntax:

```
class_pattern:
    | name_or_attr '(' [pattern_arguments ','?] ')'
pattern_arguments:
    | positional_patterns [',' keyword_patterns]
    | keyword_patterns
positional_patterns: ','.pattern+
keyword_patterns: ','.keyword_pattern+
keyword_pattern: NAME '=' pattern
```
A class pattern may not repeat the same keyword multiple times.

If `name_or_attr` is not an instance of the builtin `type`,
`TypeError` is raised.

A class pattern fails if the subject is not an instance of `name_or_attr`.
This is tested using `isinstance()`.

If no arguments are present, the pattern succeeds if the `isinstance()`
check succeeds.  Otherwise:

- If only keyword patterns are present, they are processed as follows,
  one by one:

  - The keyword is looked up as an attribute on the subject.

    - If this raises an exception other than `AttributeError`,
      the exception bubbles up.

    - If this raises `AttributeError` the class pattern fails.

    - Otherwise, the subpattern associated with the keyword is matched
      against the attribute value.  If this fails, the class pattern fails.
      If it succeeds, the match proceeds to the next keyword.

  - If all keyword patterns succeed, the class pattern as a whole succeeds.

- If any positional patterns are present, they are converted to keyword
  patterns (see below) and treated as additional keyword patterns,
  preceding the syntactic keyword patterns (if any).

Positional patterns are converted to keyword patterns using the
`__match_args__` attribute on the class designated by `name_or_attr`,
as follows:

- For a number of built-in types (specified below),
  a single positional subpattern is accepted which will match
  the entire subject. (Keyword patterns work as for other types here.)
- The equivalent of `getattr(cls, "__match_args__", ()))` is called.
- If this raises an exception the exception bubbles up.
- If the returned value is not a tuple, the conversion fails
  and `TypeError` is raised.
- If there are more positional patterns than the length of
  `__match_args__` (as obtained using `len()`), `TypeError` is raised.
- Otherwise, positional pattern `i` is converted to a keyword pattern
  using `__match_args__[i]` as the keyword,
  provided it the latter is a string;
  if it is not, `TypeError` is raised.
- For duplicate keywords, `TypeError` is raised.

Once the positional patterns have been converted to keyword patterns,
the match proceeds as if there were only keyword patterns.

As mentioned above, for the following built-in types the handling of
positional subpatterns is different:
`bool`, `bytearray`, `bytes`, `dict`, `float`,
`frozenset`, `int`, `list`, `set`, `str`, and `tuple`.

This behavior is roughly equivalent to the following:

```
class C:
    __match_args__ = ("__match_self_prop__",)
    @property
    def __match_self_prop__(self):
        return self
```

### Implementation Guidance

1. In `Grammar/python.gram`, apply the required changes. Adds the `class_pattern`, `pattern_arguments`, `positional_patterns`, `keyword_patterns`, and `keyword_pattern` productions so the parser accepts `Cls(positional, kw=pattern)` class patterns described by this section.

2. In `Parser/parser.c`, apply the required changes. Regenerated parser for the class-pattern productions from `Grammar/python.gram`.

3. In `Python/compile.c`, update `compiler_pattern_class` and `compiler.compiler_pattern_class`. `compiler_pattern_class` emits `MATCH_CLASS` with the positional pattern count as its oparg and the keyword names as a tuple constant. It compiles the class name (possibly dotted), pushes the keyword names tuple, and then matches each returned attribute against its corresponding subpattern.

4. In `Python/ceval.c`, update `match_class` and `match_class_attr`. Implements the `MATCH_CLASS` opcode via the `match_class` helper (with `match_class_attr` for per-attribute lookup). It performs `isinstance` check, resolves positional patterns via `__match_args__`, handles special built-in types via `_Py_TPFLAGS_MATCH_SELF` (where a single positional subpattern matches the subject itself), looks up keyword attributes, validates against duplicate keywords, and returns a tuple of matched attributes on success.

5. In `Include/object.h`, apply the required changes. Defines the `_Py_TPFLAGS_MATCH_SELF` flag (bit 22) that marks built-in types whose single positional subpattern matches against the subject itself rather than a mapped attribute.

6. In `Objects/typeobject.c`, update `inherit_special`. Adds inheritance of `_Py_TPFLAGS_MATCH_SELF` in `inherit_special`, so subclasses of built-in types with this flag also get the special positional pattern behavior.

7. In `Objects/bytearrayobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyByteArray_Type.tp_flags`, placing `bytearray` in the explicit list of built-in types this section calls out as accepting a single self-matching positional subpattern.

8. In `Objects/bytesobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyBytes_Type.tp_flags`, opting `bytes` into the self-matching positional subpattern behavior the section enumerates.

9. In `Objects/dictobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyDict_Type.tp_flags`, opting `dict` into the self-matching positional subpattern behavior.

10. In `Objects/floatobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyFloat_Type.tp_flags`, opting `float` into the self-matching positional subpattern behavior.

11. In `Objects/listobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyList_Type.tp_flags`, opting `list` into the self-matching positional subpattern behavior.

12. In `Objects/longobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyLong_Type.tp_flags`, opting `int` (and `bool` via flag inheritance) into the self-matching positional subpattern behavior.

13. In `Objects/setobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to both `PySet_Type.tp_flags` and `PyFrozenSet_Type.tp_flags`, opting `set` and `frozenset` into the self-matching positional subpattern behavior.

14. In `Objects/tupleobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyTuple_Type.tp_flags`, opting `tuple` into the self-matching positional subpattern behavior.

15. In `Objects/unicodeobject.c`, apply the required changes. Adds `_Py_TPFLAGS_MATCH_SELF` to `PyUnicode_Type.tp_flags`, opting `str` into the self-matching positional subpattern behavior.

**Supporting changes:**

1. In `Include/opcode.h`, apply the required changes. Defines the `MATCH_CLASS` opcode used by class patterns.

2. In `Lib/opcode.py`, apply the required changes. Registers the class-pattern opcode in the Python-level opcode module.

3. In `Python/opcode_targets.h`, apply the required changes. Adds dispatch table entry for the `MATCH_CLASS` opcode.
## Side Effects and Undefined Behavior
The only side-effect produced explicitly by the matching process is
the binding of names.  However, the process relies on attribute
access, instance checks, `len()`, equality and item access on the
subject and some of its components.  It also evaluates value
patterns and the class name of class patterns.  While none of those
typically create any side-effects, in theory they could.  This
proposal intentionally leaves out any specification of what methods
are called or how many times.  This behavior is therefore undefined
and user code should not rely on it.

Another undefined behavior is the binding of variables by capture
patterns that are followed (in the same case block) by another pattern
that fails.  These may happen earlier or later depending on the
implementation strategy, the only constraint being that capture
variables must be set before guards that use them explicitly are
evaluated.  If a guard consists of an `and` clause, evaluation of
the operands may even be interspersed with pattern matching, as long
as left-to-right evaluation order is maintained.

## The Standard Library
To facilitate the use of pattern matching, several changes will be
made to the standard library:

- Namedtuples and dataclasses will have auto-generated
  `__match_args__`.

- For dataclasses the order of attributes in the generated
  `__match_args__` will be the same as the order of corresponding
  arguments in the generated `__init__()` method.  This includes the
  situations where attributes are inherited from a superclass.  Fields
  with `init=False` are excluded from `__match_args__`.

In addition, a systematic effort will be put into going through
existing standard library classes and adding `__match_args__` where
it looks beneficial.  As part of this the `ast` module's node classes each
gain an auto-generated `__match_args__` that mirrors the node's existing
`_fields` tuple — one is produced for every node type — so that AST nodes
can themselves be matched positionally in class patterns.


### Implementation Guidance

1. In `Lib/collections/__init__.py`, update `namedtuple`. Adds `'__match_args__': field_names` to the namedtuple class dict, setting `__match_args__` to the tuple of field names so that namedtuples support positional pattern matching in class patterns.

2. In `Lib/dataclasses.py`, update `_process_class`. Adds `__match_args__` generation in `_process_class`. Sets `__match_args__` to a tuple of field names for fields with `init=True`, preserving the same order as `__init__` parameters. Only adds `__match_args__` if the class does not already define it in its `__dict__`.
## Appendix A -- Full Grammar
Here is the full grammar for `match_stmt`.  This is an additional
alternative for `compound_stmt`.  Remember that `match` and
`case` are soft keywords, i.e. they are not reserved words in other
grammatical contexts (including at the start of a line if there is no
colon where expected).  By convention, hard keywords use single quotes
while soft keywords use double quotes.

Other notation used beyond standard EBNF:

- `SEP.RULE+` is shorthand for `RULE (SEP RULE)*`
- `!RULE` is a negative lookahead assertion

```
match_stmt: "match" subject_expr ':' NEWLINE INDENT case_block+ DEDENT
subject_expr:
    | star_named_expression ',' [star_named_expressions]
    | named_expression
case_block: "case" patterns [guard] ':' block
guard: 'if' named_expression

patterns: open_sequence_pattern | pattern
pattern: as_pattern | or_pattern
as_pattern: or_pattern 'as' capture_pattern
or_pattern: '|'.closed_pattern+
closed_pattern:
    | literal_pattern
    | capture_pattern
    | wildcard_pattern
    | value_pattern
    | group_pattern
    | sequence_pattern
    | mapping_pattern
    | class_pattern

literal_pattern:
    | signed_number !('+' | '-')
    | signed_number '+' NUMBER
    | signed_number '-' NUMBER
    | strings
    | 'None'
    | 'True'
    | 'False'
signed_number: NUMBER | '-' NUMBER

capture_pattern: !"_" NAME !('.' | '(' | '=')

wildcard_pattern: "_"

value_pattern: attr !('.' | '(' | '=')
attr: name_or_attr '.' NAME
name_or_attr: attr | NAME

group_pattern: '(' pattern ')'

sequence_pattern:
  | '[' [maybe_sequence_pattern] ']'
  | '(' [open_sequence_pattern] ')'
open_sequence_pattern: maybe_star_pattern ',' [maybe_sequence_pattern]
maybe_sequence_pattern: ','.maybe_star_pattern+ ','?
maybe_star_pattern: star_pattern | pattern
star_pattern: '*' (capture_pattern | wildcard_pattern)

mapping_pattern: '{' [items_pattern] '}'
items_pattern: ','.key_value_pattern+ ','?
key_value_pattern:
    | (literal_pattern | value_pattern) ':' pattern
    | double_star_pattern
double_star_pattern: '**' capture_pattern

class_pattern:
    | name_or_attr '(' [pattern_arguments ','?] ')'
pattern_arguments:
    | positional_patterns [',' keyword_patterns]
    | keyword_patterns
positional_patterns: ','.pattern+
keyword_patterns: ','.keyword_pattern+
keyword_pattern: NAME '=' pattern
```
