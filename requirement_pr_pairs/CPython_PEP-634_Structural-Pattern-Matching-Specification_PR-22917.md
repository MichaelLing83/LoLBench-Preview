# CPython - PEP 634: Structural Pattern Matching: Specification

**PR:** https://github.com/python/cpython/pull/22917
**Requirement Doc:** https://peps.python.org/pep-0634/

## Matching Statistics
- **Requirement Doc Coverage:** 15/15 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 25/43 files mapped (58.1%) + 18/43 files associated (41.9%) = 43/43 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 634: Structural Pattern Matching: Specification | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Syntax and Semantics | No | N/A | knowledge |
| 4 | Syntax and Semantics > Overview and Terminology | No | N/A | knowledge |
| 5 | Syntax and Semantics > The Match Statement | Yes | Yes | implementation |
| 6 | Syntax and Semantics > The Match Statement > Match Semantics | Yes | Yes | implementation |
| 7 | Syntax and Semantics > The Match Statement > Guards | Yes | Yes | implementation |
| 8 | Syntax and Semantics > The Match Statement > Irrefutable case blocks | Yes | Yes | implementation |
| 9 | Syntax and Semantics > Patterns | No | N/A | knowledge |
| 10 | Syntax and Semantics > Patterns > AS Patterns | Yes | Yes | implementation |
| 11 | Syntax and Semantics > Patterns > OR Patterns | Yes | Yes | implementation |
| 12 | Syntax and Semantics > Patterns > Literal Patterns | Yes | Yes | implementation |
| 13 | Syntax and Semantics > Patterns > Capture Patterns | Yes | Yes | implementation |
| 14 | Syntax and Semantics > Patterns > Wildcard Pattern | Yes | Yes | implementation |
| 15 | Syntax and Semantics > Patterns > Value Patterns | Yes | Yes | implementation |
| 16 | Syntax and Semantics > Patterns > Group Patterns | Yes | Yes | implementation |
| 17 | Syntax and Semantics > Patterns > Sequence Patterns | Yes | Yes | implementation |
| 18 | Syntax and Semantics > Patterns > Mapping Patterns | Yes | Yes | implementation |
| 19 | Syntax and Semantics > Patterns > Class Patterns | Yes | Yes | implementation |
| 20 | Side Effects and Undefined Behavior | No | N/A | contextual |
| 21 | The Standard Library | Yes | Yes | implementation |
| 22 | Appendix A -- Full Grammar | No | N/A | contextual |
| 23 | Copyright | No | N/A | process |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/dis.rst` | documentation | — | Section 6 |
| 2 | `Doc/tools/susp-ignored.csv` | documentation | — | Section 5 |
| 3 | `Grammar/python.gram` | source | Section 5, Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18, Section 19 | — |
| 4 | `Include/Python-ast.h` | source | Section 6 | — |
| 5 | `Include/internal/pycore_ast.h` | generated | Section 6 | — |
| 6 | `Include/internal/pycore_interp.h` | source | — | Section 6, Section 17, Section 18 |
| 7 | `Include/object.h` | source | Section 19 | — |
| 8 | `Include/opcode.h` | generated | — | Section 6, Section 17, Section 18, Section 19 |
| 9 | `Include/symtable.h` | source | — | Section 5, Section 13, Section 14 |
| 10 | `Lib/ast.py` | source | — | Section 6 |
| 11 | `Lib/collections/__init__.py` | source | Section 21 | — |
| 12 | `Lib/dataclasses.py` | source | Section 21 | — |
| 13 | `Lib/importlib/_bootstrap_external.py` | generated | — | Section 6 |
| 14 | `Lib/keyword.py` | source | Section 5 | — |
| 15 | `Lib/opcode.py` | source | — | Section 6, Section 17, Section 18, Section 19 |
| 16 | `Lib/test/libregrtest/pgo.py` | test | — | Section 6 |
| 17 | `Lib/test/test_ast.py` | test | — | Section 6 |
| 18 | `Lib/test/test_collections.py` | test | — | Section 21 |
| 19 | `Lib/test/test_dataclasses.py` | test | — | Section 21 |
| 20 | `Lib/test/test_patma.py` | test | — | Section 6, Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18, Section 19 |
| 21 | `Misc/NEWS.d/next/Core and Builtins/2020-10-23-08-54-04.bpo-42128.SWmVEm.rst` | documentation | — | Section 6 |
| 22 | `Objects/bytearrayobject.c` | source | Section 19 | — |
| 23 | `Objects/bytesobject.c` | source | Section 19 | — |
| 24 | `Objects/dictobject.c` | source | Section 19 | — |
| 25 | `Objects/floatobject.c` | source | Section 19 | — |
| 26 | `Objects/listobject.c` | source | Section 19 | — |
| 27 | `Objects/longobject.c` | source | Section 19 | — |
| 28 | `Objects/setobject.c` | source | Section 19 | — |
| 29 | `Objects/tupleobject.c` | source | Section 19 | — |
| 30 | `Objects/typeobject.c` | source | Section 19 | — |
| 31 | `Objects/unicodeobject.c` | source | Section 19 | — |
| 32 | `Parser/Python.asdl` | source | Section 6, Section 10, Section 11 | — |
| 33 | `Parser/asdl_c.py` | source | Section 6 | — |
| 34 | `Parser/parser.c` | generated | Section 5, Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18, Section 19 | — |
| 35 | `Python/Python-ast.c` | generated | Section 6, Section 10, Section 11 | — |
| 36 | `Python/ast.c` | source | Section 6 | — |
| 37 | `Python/ast_opt.c` | source | Section 6 | — |
| 38 | `Python/ceval.c` | source | Section 17, Section 18, Section 19 | — |
| 39 | `Python/compile.c` | source | Section 6, Section 7, Section 8, Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18, Section 19 | — |
| 40 | `Python/importlib_external.h` | source | — | Section 6 |
| 41 | `Python/opcode_targets.h` | generated | — | Section 6, Section 17, Section 18, Section 19 |
| 42 | `Python/pystate.c` | source | — | Section 6, Section 17, Section 18 |
| 43 | `Python/symtable.c` | source | — | Section 5, Section 13, Section 14 |

---

## Section 5: The Match Statement
*Path: Syntax and Semantics > The Match Statement*
*Classification: Implementable*

> Syntax:
>
> ```
> match_stmt: "match" subject_expr ':' NEWLINE INDENT case_block+ DEDENT
> subject_expr:
>     | star_named_expression ',' star_named_expressions?
>     | named_expression
> case_block: "case" patterns [guard] ':' block
> guard: 'if' named_expression
> ```
> The rules `star_named_expression`, `star_named_expressions`,
> `named_expression` and `block` are part of the [standard Python grammar](https://docs.python.org/3.10/reference/grammar.html).
>
> The rule `patterns` is specified below.
>
> For context, `match_stmt` is a new alternative for
> `compound_statement`:
>
> ```
> compound_statement:
>     | if_stmt
>     ...
>     | match_stmt
> ```
> The `match` and `case` keywords are soft keywords, i.e. they are
> not reserved words in other grammatical contexts (including at the
> start of a line if there is no colon where expected).  This implies
> that they are recognized as keywords when part of a match
> statement or case block only, and are allowed to be used in all
> other contexts as variable or argument names.

#### Requirement Summary
This section specifies the match statement grammar (match_stmt, subject_expr, case_block, guard rules) and defines `match` and `case` as soft keywords. The PR adds the match_stmt grammar rule with all pattern sub-rules to `python.gram`, regenerates the C parser, and registers `match`, `case`, and `_` as soft keywords.

**File proportion:** 3/43 files mapped (7.0%) + 3/43 files associated (7.0%) = 6/43 accounted (14.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Lib/keyword.py` | Modified | +3 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds `match_stmt` as a new alternative for `compound_stmt`. Defines the full grammar for `match_stmt`, `subject_expr`, `case_block`, and `guard` rules. Defines rules for `patterns`, `pattern`, `as_pattern`, `or_pattern`, and `closed_pattern` (which covers `literal_pattern`, `capture_pattern`, `wildcard_pattern`, `value_pattern`, `group_pattern`, `sequence_pattern`, `mapping_pattern`, and `class_pattern`), along with all their sub-rules. Each grammar rule includes C action code to construct the appropriate AST nodes.
- **`Parser/parser.c`**: Auto-generated parser code reflecting all grammar changes, implementing the PEG parser functions for each new grammar rule.
- **`Lib/keyword.py`**: Adds `'_'`, `'case'`, and `'match'` to the `softkwlist` list, registering them as soft keywords.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Doc/tools/susp-ignored.csv` | Modified | +1 / -0 | Suppresses documentation build warnings for the new soft keywords | — | — |
| `Include/symtable.h` | Modified | +1 / -0 | Adds `in_pattern` flag for symbol table tracking of pattern context | `symtable` | — |
| `Python/symtable.c` | Modified | +34 / -0 | Adds `symtable_visit_match_case` and handles name bindings in pattern context, including suppressing `_` as a local variable in patterns | `symtable` | `symtable_new`, `symtable_visit_stmt`, `symtable_visit_expr`, `symtable_visit_match_case`, `symtable.symtable_visit_match_case` |

---

## Section 6: Match Semantics
*Path: Syntax and Semantics > The Match Statement > Match Semantics*
*Classification: Implementable*

> The match statement first evaluates the subject expression.  If a
> comma is present a tuple is constructed using the standard rules.
>
> The resulting subject value is then used to select the first case
> block whose patterns succeeds matching it *and* whose guard condition
> (if present) is "truthy".  If no case blocks qualify the match
> statement is complete; otherwise, the block of the selected case block
> is executed.  The usual rules for executing a block nested inside a
> compound statement apply (e.g. an `if` statement).
>
> Name bindings made during a successful pattern match outlive the
> executed block and can be used after the match statement.
>
> During failed pattern matches, some subpatterns may succeed. For
> example, while matching the pattern `(0, x, 1)` with the value ``[0,
> 1, 2]`, the subpattern `x`` may succeed if the list elements are
> matched from left to right.  The implementation may choose to either
> make persistent bindings for those partial matches or not. User code
> including a match statement should not rely on the bindings being
> made for a failed match, but also shouldn't assume that variables are
> unchanged by a failed match.  This part of the behavior is left
> intentionally unspecified so different implementations can add
> optimizations, and to prevent introducing semantic restrictions that
> could limit the extensibility of this feature.
>
> The precise pattern binding rules vary per pattern type and are
> specified below.

#### Requirement Summary
This section specifies the core match statement semantics: evaluating the subject expression, iterating case blocks to find a matching pattern with a truthy guard, executing the matched block, and the scoping rules for name bindings. The PR adds Match/MatchAs/MatchOr/match_case AST node definitions, AST validation and constant folding, and the `compiler_match` function that orchestrates pattern compilation.

**File proportion:** 8/43 files mapped (18.6%) + 13/43 files associated (30.2%) = 21/43 accounted (48.8%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Parser/Python.asdl` | Modified | +8 / -0 | — | — |
| `Include/Python-ast.h` | Modified | +50 / -5 | `_match_case`, `_stmt`, `_expr` | — |
| `Include/internal/pycore_ast.h` | Modified | +10 / -0 | `ast_state` | — |
| `Parser/asdl_c.py` | Modified | +4 / -1 | `PyTypesVisitor` | — |
| `Python/Python-ast.c` | Modified | +467 / -2 | `ast_state` | `_PyAST_Fini`, `init_identifiers`, `make_type`, `add_ast_fields`, `init_types`, `Match`, `MatchAs`, `MatchOr`, `match_case`, `ast2obj_stmt`, `ast2obj_expr`, `ast2obj_match_case`, `ast_state.ast2obj_match_case`, `obj2ast_stmt`, `obj2ast_expr`, `obj2ast_match_case`, `ast_state.obj2ast_match_case`, `astmodule_exec` |
| `Python/ast.c` | Modified | +29 / -0 | — | `validate_expr`, `validate_pattern`, `validate_stmt` |
| `Python/ast_opt.c` | Modified | +130 / -0 | — | `astfold_expr`, `astfold_stmt`, `astfold_pattern_negative`, `astfold_pattern_complex`, `astfold_pattern_keyword`, `astfold_pattern`, `astfold_match_case` |
| `Python/compile.c` | Modified | +713 / -26 | `compiler` | `stack_effect`, `compiler_visit_stmt`, `compiler.assignment_helper`, `compiler.unpack_helper`, `assignment_helper`, `unpack_helper`, `validate_keywords`, `compiler_visit_expr1`, `compiler.compiler_error`, `compiler_error`, `compiler_pattern`, `compiler.compiler_pattern`, `compiler_match`, `compiler.compiler_match` |

#### Modification Summary
- **`Parser/Python.asdl`**: Adds `Match(expr subject, match_case* cases)` as a new statement kind. Adds `MatchAs(expr pattern, identifier name)` and `MatchOr(expr* patterns)` as new expression kinds. Adds `match_case = (expr pattern, expr? guard, stmt* body)` as a new type.
- **`Include/Python-ast.h`**: Adds the `match_case_ty` typedef and `asdl_match_case_seq` sequence type. Updates `_stmt_kind` and `_expr_kind` enums to include `Match_kind`, `MatchAs_kind`, and `MatchOr_kind`. Adds struct fields and constructor declarations for the new AST node types.
- **`Include/internal/pycore_ast.h`**: Adds `MatchAs_type`, `MatchOr_type`, `Match_type`, `__match_args__`, `cases`, and `guard` fields to the `ast_state` struct for the AST module's cached type objects and attribute name strings.
- **`Parser/asdl_c.py`**: Updates the ASDL-to-C code generator to emit `__match_args__` alongside `_fields` when creating AST type objects, and to set `__match_args__` as an empty tuple on the base AST type.
- **`Python/Python-ast.c`**: Implements constructors (`_Py_Match`, `_Py_match_case`, `_Py_MatchAs`, `_Py_MatchOr`), visitor functions (`ast2obj_*`, `obj2ast_*`), and initialization code for all new AST types. Adds `__match_args__` as an attribute on all AST node types.
- **`Python/ast.c`**: Adds `Match_kind` handling to `validate_stmt` that validates the subject expression, checks that `cases` is non-empty, and validates each case's pattern and optional guard. Adds `MatchAs_kind` and `MatchOr_kind` to `validate_expr`. Adds a `validate_pattern` stub function.
- **`Python/ast_opt.c`**: Adds `astfold_match_case` and `astfold_pattern` functions for constant folding across all pattern expression node types. Adds `Match_kind` handling to `astfold_stmt`.
- **`Python/compile.c`**: Adds `pattern_context` struct with `stores` (set of bound names) and `allow_irrefutable` flag. Adds `compiler_match` function that iterates over cases, sets `allow_irrefutable` based on guard presence and position, calls `compiler_pattern`, evaluates guards, and emits jumps to case bodies or the next case. Adds `compiler_pattern` dispatcher that routes to type-specific functions based on expression kind. Adds individual pattern compilation functions for all pattern types.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/internal/pycore_interp.h` | Modified | +4 / -1 | Adds `map_abc` and `seq_abc` fields to `PyInterpreterState` for caching `collections.abc.Mapping` and `collections.abc.Sequence` | `_is` | — |
| `Lib/ast.py` | Modified | +27 / -0 | Adds `Match`, `match_case`, `MatchAs`, and `MatchOr` to the `ast` module's Python-level API | `_Unparser` | — |
| `Python/pystate.c` | Modified | +2 / -0 | Initializes and cleans up cached `map_abc` and `seq_abc` references on interpreter state | — | `interpreter_clear` |
| `Include/opcode.h` | Modified | +6 / -0 | Defines new opcodes: `GET_LEN`, `MATCH_MAPPING`, `MATCH_SEQUENCE`, `MATCH_KEYS`, `COPY_DICT_WITHOUT_KEYS`, `MATCH_CLASS` | — | — |
| `Lib/opcode.py` | Modified | +10 / -12 | Registers the new pattern matching opcodes in the Python-level opcode module | — | — |
| `Python/opcode_targets.h` | Modified | +6 / -6 | Updates the computed goto dispatch table for the new opcodes | — | — |
| `Doc/library/dis.rst` | Modified | +56 / -0 | Documents the new bytecode instructions for pattern matching | — | — |
| `Lib/importlib/_bootstrap_external.py` | Modified | +2 / -1 | Updates the magic number for the new bytecodes added by pattern matching | — | — |
| `Python/importlib_external.h` | Modified | +109 / -109 | Regenerated frozen importlib external module reflecting the magic number change | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2020-10-23-08-54-04.bpo-42128.SWmVEm.rst` | Added | +1 / -0 | NEWS entry announcing pattern matching implementation | — | — |

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Comprehensive test suite for all pattern matching features |  |  | — | — |
| `Lib/test/test_ast.py` | Tests for new Match/MatchAs/MatchOr AST node types |  |  | — | — |
| `Lib/test/libregrtest/pgo.py` | Adds test_patma to PGO test list |  |  | — | — |
---

## Section 7: Guards
*Path: Syntax and Semantics > The Match Statement > Guards*
*Classification: Implementable*

> If a guard is present on a case block, once the pattern or patterns in
> the case block succeed, the expression in the guard is evaluated.  If
> this raises an exception, the exception bubbles up.  Otherwise, if the
> condition is "truthy" the case block is selected; if it is "falsy" the
> case block is not selected.
>
> Since guards are expressions they are allowed to have side effects.
> Guard evaluation must proceed from the first to the last case block,
> one at a time, skipping case blocks whose pattern(s) don't all
> succeed.  (I.e., even if determining whether those patterns succeed
> may happen out of order, guard evaluation must happen in order.)
> Guard evaluation must stop once a case block is selected.

#### Requirement Summary
This section specifies guard evaluation semantics: guards are evaluated after a pattern matches, exceptions propagate, truthy guards select the case block, and evaluation order is first-to-last. The PR implements this in `compiler_match` via `compiler_jump_if` calls that emit conditional jumps after successful pattern matches.

**File proportion:** 1/43 files mapped (2.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/compile.c` | Modified | +713 / -26 | — | — |

#### Modification Summary
- **`Python/compile.c`**: Within `compiler_match` (owned by Section 6), after a pattern succeeds, the guard expression (if present) is compiled using `compiler_jump_if`. If the guard is falsy, control jumps to the next case block. If the guard is truthy, the case body executes and then jumps to the end of the match statement. This ensures guards are evaluated in order and only after their associated pattern succeeds.

---

## Section 8: Irrefutable case blocks
*Path: Syntax and Semantics > The Match Statement > Irrefutable case blocks*
*Classification: Implementable*

> A pattern is considered irrefutable if we can prove from its syntax
> alone that it will always succeed.  In particular, capture patterns
> and wildcard patterns are irrefutable, and so are AS patterns whose
> left-hand side is irrefutable, OR patterns containing at least
> one irrefutable pattern, and parenthesized irrefutable patterns.
>
> A case block is considered irrefutable if it has no guard and its
> pattern is irrefutable.
>
> A match statement may have at most one irrefutable case block, and it
> must be last.

#### Requirement Summary
This section specifies irrefutability constraints: irrefutable patterns (capture, wildcard, certain AS/OR patterns) are identified syntactically, and a match statement may have at most one irrefutable case block which must be last. The PR implements this via the `allow_irrefutable` flag in `pattern_context`, which is checked by `compiler_pattern_capture` and `compiler_pattern_wildcard` to raise `SyntaxError` for misplaced irrefutable patterns.

**File proportion:** 1/43 files mapped (2.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/compile.c` | Modified | +713 / -26 | — | — |

#### Modification Summary
- **`Python/compile.c`**: Adds `allow_irrefutable` field to `pattern_context`. In `compiler_match` (owned by Section 6), sets `allow_irrefutable` to true only if the case has a guard or is the last case. `compiler_pattern_capture` (Section 13) and `compiler_pattern_wildcard` (Section 14) check this flag and raise `SyntaxError` if an irrefutable pattern appears in a non-final unguarded case. `compiler_pattern_or` (Section 11) propagates `allow_irrefutable` to the last alternative only. `compiler_pattern_subpattern` (Section 16) temporarily enables `allow_irrefutable` for sub-positions where irrefutable patterns are valid.

---

## Section 10: AS Patterns
*Path: Syntax and Semantics > Patterns > AS Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> as_pattern: or_pattern 'as' capture_pattern
> ```
> (Note: the name on the right may not be `_`.)
>
> An AS pattern matches the OR pattern on the left of the `as`
> keyword against the subject.  If this fails, the AS pattern fails.
> Otherwise, the AS pattern binds the subject to the name on the right
> of the `as` keyword and succeeds.

#### Requirement Summary
This section specifies AS pattern semantics: match the inner pattern, and on success bind the subject to the given name. The PR implements `compiler_pattern_as` in `compile.c` which compiles the inner pattern first, then emits a name store for the binding on success.

**File proportion:** 5/43 files mapped (11.6%) + 1/43 files associated (2.3%) = 6/43 accounted (14.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Parser/Python.asdl` | Modified | +8 / -0 | — | — |
| `Python/Python-ast.c` | Modified | +467 / -2 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_as`, `compiler.compiler_pattern_as` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `as_pattern: or_pattern 'as' capture_pattern` production that lets the parser recognize `<pattern> as <name>` syntax described by this section.
- **`Parser/parser.c`**: Regenerated parser for `Grammar/python.gram` so the AS-pattern production is actually accepted at runtime.
- **`Parser/Python.asdl`**: Declares the `MatchAs(expr pattern, identifier name)` AST node that the AS-pattern grammar production constructs.
- **`Python/Python-ast.c`**: Generated AST machinery for the `MatchAs` node — the `MatchAs` constructor and `ast2obj_*` / `obj2ast_*` visitors used to materialize AS patterns in the AST.
- **`Python/compile.c`**: `compiler_pattern_as` handles `MatchAs_kind` expressions. It compiles the inner OR pattern, and if the match succeeds, stores the subject value to the named variable. It verifies that the right-hand name is not `_` and delegates the inner pattern compilation to the existing pattern infrastructure.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers AS pattern behavior | — | — |

---

## Section 11: OR Patterns
*Path: Syntax and Semantics > Patterns > OR Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> or_pattern: '|'.closed_pattern+
> ```
> When two or more patterns are separated by vertical bars (`|`),
> this is called an OR pattern.  (A single closed pattern is just that.)
>
> Only the final subpattern may be irrefutable.
>
> Each subpattern must bind the same set of names.
>
> An OR pattern matches each of its subpatterns in turn to the subject,
> until one succeeds.  The OR pattern is then deemed to succeed.
> If none of the subpatterns succeed the OR pattern fails.

#### Requirement Summary
This section specifies OR pattern semantics: try each subpattern in order, succeed on the first match, and enforce that all alternatives bind the same set of names. The PR implements `compiler_pattern_or` in `compile.c` which tries each alternative, validates consistent name bindings across alternatives, and only allows the last alternative to be irrefutable.

**File proportion:** 5/43 files mapped (11.6%) + 1/43 files associated (2.3%) = 6/43 accounted (14.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Parser/Python.asdl` | Modified | +8 / -0 | — | — |
| `Python/Python-ast.c` | Modified | +467 / -2 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_or`, `compiler.compiler_pattern_or` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `or_pattern: '|'.closed_pattern+` production that captures the `|`-separated alternatives described by this section.
- **`Parser/parser.c`**: Regenerated parser implementing the OR-pattern production from `Grammar/python.gram`.
- **`Parser/Python.asdl`**: Declares the `MatchOr(expr* patterns)` AST node that the OR-pattern grammar production builds.
- **`Python/Python-ast.c`**: Generated AST machinery for the `MatchOr` node — the `MatchOr` constructor and `ast2obj_*` / `obj2ast_*` visitors used to materialize OR patterns in the AST.
- **`Python/compile.c`**: `compiler_pattern_or` handles `MatchOr_kind` expressions. For each alternative in the OR pattern, it compiles the subpattern and jumps to a success label if it matches. After all alternatives fail, it falls through to failure. After any alternative succeeds, it validates that the set of bound names matches the first alternative's set. Only the final subpattern may be irrefutable per `allow_irrefutable` propagation.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers OR pattern behavior | — | — |

---

## Section 12: Literal Patterns
*Path: Syntax and Semantics > Patterns > Literal Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> literal_pattern:
>     | signed_number
>     | signed_number '+' NUMBER
>     | signed_number '-' NUMBER
>     | strings
>     | 'None'
>     | 'True'
>     | 'False'
> signed_number: NUMBER | '-' NUMBER
> ```
> The rule `strings` and the token `NUMBER` are defined in the
> standard Python grammar.
>
> Triple-quoted strings are supported.  Raw strings and byte strings
> are supported.  F-strings are not supported.
>
> The forms `signed_number '+' NUMBER` and ``signed_number '-'
> NUMBER`` are only permitted to express complex numbers; they require a
> real number on the left and an imaginary number on the right.
>
> A literal pattern succeeds if the subject value compares equal to the
> value expressed by the literal, using the following comparisons rules:
>
> - Numbers and strings are compared using the `==` operator.
>
> - The singleton literals `None`, `True` and `False` are compared
>   using the `is` operator.

#### Requirement Summary
This section specifies literal pattern semantics: numbers and strings are compared with `==`, while `None`, `True`, and `False` use `is`. Complex number literals are supported via `signed_number +/- NUMBER` syntax. The PR implements `compiler_pattern_literal` in `compile.c` which emits equality comparisons for numeric/string literals and identity comparisons for singletons.

**File proportion:** 3/43 files mapped (7.0%) + 1/43 files associated (2.3%) = 4/43 accounted (9.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_literal`, `compiler.compiler_pattern_literal` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `literal_pattern` and `signed_number` productions (numbers, signed numbers, complex `signed_number '+'/'-' NUMBER` forms, strings, and the `None`/`True`/`False` singletons) so the parser recognizes literal patterns as defined by this section.
- **`Parser/parser.c`**: Regenerated parser implementing the literal-pattern productions from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_literal` handles literal pattern nodes. For `None`, `True`, and `False`, it emits `IS_OP` for identity comparison. For numeric and string literals (including complex number expressions), it emits `COMPARE_OP` with `==` semantics. The function handles `BinOp_kind` for complex number literals (real +/- imaginary) and `UnaryOp_kind` for negated numbers.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers literal pattern behavior | — | — |

---

## Section 13: Capture Patterns
*Path: Syntax and Semantics > Patterns > Capture Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> capture_pattern: !"_" NAME
> ```
> The single underscore (`_`) is not a capture pattern (this is what
> `!"_"` expresses).  It is treated as a `wildcard pattern`_.
>
> A capture pattern always succeeds.  It binds the subject value to the
> name using the scoping rules for name binding established for the
> walrus operator in PEP 572.  (Summary: the name becomes a local
> variable in the closest containing function scope unless there's an
> applicable `nonlocal` or `global` statement.)
>
> In a given pattern, a given name may be bound only once.  This
> disallows for example `case x, x: ...` but allows ``case [x] | x:
> ...``.

#### Requirement Summary
This section specifies capture pattern semantics: always succeeds, binds the subject to the named variable (excluding `_`), and enforces single-binding of each name within a pattern. The PR implements `compiler_pattern_capture` in `compile.c` which stores the subject to the name, checks for duplicate name bindings, and verifies irrefutability constraints.

**File proportion:** 3/43 files mapped (7.0%) + 3/43 files associated (7.0%) = 6/43 accounted (14.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_capture`, `compiler.compiler_pattern_capture`, `pattern_helper_store_name`, `compiler.pattern_helper_store_name` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `capture_pattern: !"_" NAME` production so a bare name (other than the wildcard `_`) is recognized as a capture pattern at the grammar level.
- **`Parser/parser.c`**: Regenerated parser for the capture-pattern production from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_capture` handles capture pattern nodes. It checks `allow_irrefutable` (since captures are irrefutable), verifies that the name is not already in the pattern context's `stores` set (raising `SyntaxError` for duplicate bindings like `case x, x:`), adds the name to `stores`, and emits via `pattern_helper_store_name` a `STORE_NAME`/`STORE_FAST` instruction to bind the subject to the captured name.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/symtable.h` | Modified | +1 / -0 | `in_pattern` symbol-table flag supports capture-pattern name binding | — | — |
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers capture pattern behavior | — | — |
| `Python/symtable.c` | Modified | +34 / -0 | `symtable_visit_match_case` records name bindings used by capture patterns | — | — |

---

## Section 14: Wildcard Pattern
*Path: Syntax and Semantics > Patterns > Wildcard Pattern*
*Classification: Implementable*

> Syntax:
>
> ```
> wildcard_pattern: "_"
> ```
> A wildcard pattern always succeeds.  It binds no name.

#### Requirement Summary
This section specifies wildcard pattern semantics: always succeeds and binds no name. The PR implements `compiler_pattern_wildcard` in `compile.c` which simply succeeds without emitting any binding instructions, and checks irrefutability constraints.

**File proportion:** 3/43 files mapped (7.0%) + 3/43 files associated (7.0%) = 6/43 accounted (14.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_wildcard`, `compiler.compiler_pattern_wildcard` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `wildcard_pattern: "_"` production so the lone underscore is recognized at the grammar level as the wildcard pattern (and not as a capture).
- **`Parser/parser.c`**: Regenerated parser for the wildcard-pattern production from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_wildcard` handles the `_` wildcard pattern. It checks `allow_irrefutable` (since wildcards are irrefutable) and emits no additional instructions -- the pattern always succeeds and no name binding occurs.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/symtable.h` | Modified | +1 / -0 | `in_pattern` symbol-table flag also governs the wildcard `_` suppression | — | — |
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers wildcard pattern behavior | — | — |
| `Python/symtable.c` | Modified | +34 / -0 | `symtable_visit_match_case` suppresses `_` as a local variable in patterns | — | — |

---

## Section 15: Value Patterns
*Path: Syntax and Semantics > Patterns > Value Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> value_pattern: attr
> attr: name_or_attr '.' NAME
> name_or_attr: attr | NAME
> ```
> The dotted name in the pattern is looked up using the standard Python
> name resolution rules.  However, when the same value pattern occurs
> multiple times in the same match statement, the interpreter may cache
> the first value found and reuse it, rather than repeat the same
> lookup.  (To clarify, this cache is strictly tied to a given execution
> of a given match statement.)
>
> The pattern succeeds if the value found thus compares equal to the
> subject value (using the `==` operator).

#### Requirement Summary
This section specifies value pattern semantics: look up the dotted name using standard name resolution and compare against the subject with `==`. The PR implements `compiler_pattern_value` in `compile.c` which loads each component of the dotted name via attribute access and emits an equality comparison.

**File proportion:** 3/43 files mapped (7.0%) + 1/43 files associated (2.3%) = 4/43 accounted (9.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_value`, `compiler.compiler_pattern_value` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `value_pattern: attr` / `attr: name_or_attr '.' NAME` / `name_or_attr: attr | NAME` productions so dotted names like `Color.RED` are recognized as value patterns.
- **`Parser/parser.c`**: Regenerated parser for the value-pattern productions from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_value` handles value pattern nodes (dotted names like `Color.RED`). It loads the first name component, then emits `LOAD_ATTR` for each subsequent dotted component, and finally emits `COMPARE_OP` with `==` to compare the resolved value against the subject.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers value pattern behavior | — | — |

---

## Section 16: Group Patterns
*Path: Syntax and Semantics > Patterns > Group Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> group_pattern: '(' pattern ')'
> ```
> (For the syntax of `pattern`, see Patterns above.  Note that it
> contains no comma -- a parenthesized series of items with at least one
> comma is a sequence pattern, as is `()`.)
>
> A parenthesized pattern has no additional syntax.  It allows users to
> add parentheses around patterns to emphasize the intended grouping.

#### Requirement Summary
This section specifies group pattern semantics: a parenthesized pattern is purely syntactic grouping with no additional semantics. The PR handles this at the grammar/parser level where `group_pattern` simply unwraps to the inner pattern, and in the compiler via `compiler_pattern_subpattern` which recursively compiles the inner pattern.

**File proportion:** 3/43 files mapped (7.0%) + 1/43 files associated (2.3%) = 4/43 accounted (9.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_subpattern`, `compiler.compiler_pattern_subpattern` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `group_pattern: '(' pattern ')'` production so parenthesized patterns are recognized as a grouping construct that simply yields the inner pattern.
- **`Parser/parser.c`**: Regenerated parser for the group-pattern production from `Grammar/python.gram`.
- **`Python/compile.c`**: Group patterns are desugared at the grammar level into their inner pattern. The `compiler_pattern_subpattern` helper temporarily enables `allow_irrefutable` for sub-positions, then delegates to `compiler_pattern` for the inner pattern. No dedicated `compiler_pattern_group` function is needed since the AST does not distinguish group patterns from their contents.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers group pattern behavior | — | — |

---

## Section 17: Sequence Patterns
*Path: Syntax and Semantics > Patterns > Sequence Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> sequence_pattern:
>   | '[' [maybe_sequence_pattern] ']'
>   | '(' [open_sequence_pattern] ')'
> open_sequence_pattern: maybe_star_pattern ',' [maybe_sequence_pattern]
> maybe_sequence_pattern: ','.maybe_star_pattern+ ','?
> maybe_star_pattern: star_pattern | pattern
> star_pattern: '*' (capture_pattern | wildcard_pattern)
> ```
> (Note that a single parenthesized pattern without a trailing comma is
> a group pattern, not a sequence pattern.  However a single pattern
> enclosed in `[...]` is still a sequence pattern.)
>
> There is no semantic difference between a sequence pattern using
> `[...]`, a sequence pattern using `(...)`, and an open sequence
> pattern.
>
> A sequence pattern may contain at most one star subpattern.  The star
> subpattern may occur in any position.  If no star subpattern is
> present, the sequence pattern is a fixed-length sequence pattern;
> otherwise it is a variable-length sequence pattern.
>
> For a sequence pattern to succeed the subject must be a sequence,
> where being a sequence is defined as its class being one of the following:
>
> - a class that inherits from `collections.abc.Sequence`
> - a Python class that has been registered as a `collections.abc.Sequence`
> - a builtin class that has its `Py_TPFLAGS_SEQUENCE` bit set
> - a class that inherits from any of the above (including classes defined *before* a
>   parent's `Sequence` registration)
>
> The following standard library classes will have their `Py_TPFLAGS_SEQUENCE`
> bit set:
>
> - `array.array`
> - `collections.deque`
> - `list`
> - `memoryview`
> - `range`
> - `tuple`
>
> > **Note:** Although `str`, `bytes`, and `bytearray` are usually considered sequences, they are not included in the above list and do not match sequence patterns.
> A fixed-length sequence pattern fails if the length of the subject
> sequence is not equal to the number of subpatterns.
>
> A variable-length sequence pattern fails if the length of the subject
> sequence is less than the number of non-star subpatterns.
>
> The length of the subject sequence is obtained using the builtin
> `len()` function (i.e., via the `__len__` protocol).  However, the
> interpreter may cache this value in a similar manner as described for
> value patterns.
>
> A fixed-length sequence pattern matches the subpatterns to
> corresponding items of the subject sequence, from left to right.
> Matching stops (with a failure) as soon as a subpattern fails.  If all
> subpatterns succeed in matching their corresponding item, the sequence
> pattern succeeds.
>
> A variable-length sequence pattern first matches the leading non-star
> subpatterns to the corresponding items of the subject sequence, as for
> a fixed-length sequence.  If this succeeds, the star subpattern
> matches a list formed of the remaining subject items, with items
> removed from the end corresponding to the non-star subpatterns
> following the star subpattern.  The remaining non-star subpatterns are
> then matched to the corresponding subject items, as for a fixed-length
> sequence.

#### Requirement Summary
This section specifies sequence pattern semantics: the subject must be a sequence (via `collections.abc.Sequence` or `Py_TPFLAGS_SEQUENCE`), `str`/`bytes`/`bytearray` are excluded, length is checked via `len()`, and subpatterns are matched left-to-right with star pattern support. The PR implements `compiler_pattern_sequence` in `compile.c` and the `MATCH_SEQUENCE`/`GET_LEN` opcodes in `ceval.c`.

**File proportion:** 4/43 files mapped (9.3%) + 6/43 files associated (14.0%) = 10/43 accounted (23.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_sequence`, `compiler.compiler_pattern_sequence`, `pattern_helper_sequence_unpack`, `compiler.pattern_helper_sequence_unpack`, `pattern_helper_sequence_subscr`, `compiler.pattern_helper_sequence_subscr` |
| `Python/ceval.c` | Modified | +382 / -0 | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `sequence_pattern`, `open_sequence_pattern`, `maybe_sequence_pattern`, `maybe_star_pattern`, and `star_pattern` productions so the parser accepts `[...]`/`(...)` sequence patterns with at most one `*name`/`*_` star subpattern.
- **`Parser/parser.c`**: Regenerated parser for the sequence-pattern productions from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_sequence` (plus `pattern_helper_sequence_unpack` / `pattern_helper_sequence_subscr`) emits `MATCH_SEQUENCE` to check if the subject is a sequence, `GET_LEN` to obtain the length, a length comparison (equality for fixed-length, minimum for variable-length), and then matches each subpattern against the corresponding item using subscript access. For star patterns, it constructs a list from the remaining items.
- **`Python/ceval.c`**: Implements the `MATCH_SEQUENCE` opcode that checks if the subject is a `collections.abc.Sequence` (with fast path for list/tuple subclasses, and exclusion of `str`/`bytes`/`bytearray`). Implements the `GET_LEN` opcode that pushes `len(TOS)` onto the stack. Lazily imports and caches `_collections_abc.Sequence` on the interpreter state.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/internal/pycore_interp.h` | Modified | +4 / -1 | `seq_abc` cache field on `PyInterpreterState` supports sequence-pattern matching | — | — |
| `Include/opcode.h` | Modified | +6 / -0 | Defines `MATCH_SEQUENCE` and `GET_LEN` opcodes used by sequence patterns | — | — |
| `Lib/opcode.py` | Modified | +10 / -12 | Registers the sequence-pattern opcodes in the Python-level opcode module | — | — |
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers sequence pattern behavior | — | — |
| `Python/opcode_targets.h` | Modified | +6 / -6 | Adds dispatch table entries for the sequence-pattern opcodes | — | — |
| `Python/pystate.c` | Modified | +2 / -0 | Cleans up the `seq_abc` cache on interpreter state | — | — |

---

## Section 18: Mapping Patterns
*Path: Syntax and Semantics > Patterns > Mapping Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> mapping_pattern: '{' [items_pattern] '}'
> items_pattern: ','.key_value_pattern+ ','?
> key_value_pattern:
>     | (literal_pattern | value_pattern) ':' pattern
>     | double_star_pattern
> double_star_pattern: '**' capture_pattern
> ```
> (Note that `**_` is disallowed by this syntax.)
>
> A mapping pattern may contain at most one double star pattern,
> and it must be last.
>
> A mapping pattern may not contain duplicate key values.
> (If all key patterns are literal patterns this is considered a
> syntax error; otherwise this is a runtime error and will
> raise `ValueError`.)
>
> For a mapping pattern to succeed the subject must be a mapping,
> where being a mapping is defined as its class being one of the following:
>
> - a class that inherits from `collections.abc.Mapping`
> - a Python class that has been registered as a `collections.abc.Mapping`
> - a builtin class that has its `Py_TPFLAGS_MAPPING` bit set
> - a class that inherits from any of the above  (including classes defined *before* a
>   parent's `Mapping` registration)
>
> The standard library classes `dict` and `mappingproxy` will have their `Py_TPFLAGS_MAPPING`
> bit set.
>
> A mapping pattern succeeds if every key given in the mapping pattern
> is present in the subject mapping, and the pattern for
> each key matches the corresponding item of the subject mapping. Keys
> are always compared with the `==` operator.  If a ``'**'
> NAME` form is present, that name is bound to a `dict`` containing
> remaining key-value pairs from the subject mapping.
>
> If duplicate keys are detected in the mapping pattern, the pattern is
> considered invalid, and a `ValueError` is raised.
>
> Key-value pairs are matched using the two-argument form of the
> subject's `get()` method.  As a consequence, matched key-value pairs
> must already be present in the mapping, and not created on-the-fly by
> `__missing__` or `__getitem__`.  For example,
> `collections.defaultdict` instances will only be matched by patterns
> with keys that were already present when the match statement was
> entered.

#### Requirement Summary
This section specifies mapping pattern semantics: the subject must be a mapping (via `collections.abc.Mapping` or `Py_TPFLAGS_MAPPING`), keys are looked up via `get()`, duplicate keys raise errors, and `**name` captures remaining key-value pairs. The PR implements `compiler_pattern_mapping` in `compile.c` and the `MATCH_MAPPING`, `MATCH_KEYS`, and `COPY_DICT_WITHOUT_KEYS` opcodes in `ceval.c`.

**File proportion:** 4/43 files mapped (9.3%) + 6/43 files associated (14.0%) = 10/43 accounted (23.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_mapping`, `compiler.compiler_pattern_mapping` |
| `Python/ceval.c` | Modified | +382 / -0 | — | `match_keys` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `mapping_pattern`, `items_pattern`, `key_value_pattern`, and `double_star_pattern` productions so the parser accepts `{key: pattern, ..., **rest}` mapping patterns.
- **`Parser/parser.c`**: Regenerated parser for the mapping-pattern productions from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_mapping` emits `MATCH_MAPPING` to check if the subject is a mapping, `MATCH_KEYS` with a tuple of key patterns to extract corresponding values, and then matches each value against its subpattern. For double-star patterns, it emits `COPY_DICT_WITHOUT_KEYS` to capture the remaining key-value pairs.
- **`Python/ceval.c`**: Implements the `MATCH_MAPPING` opcode that checks if the subject is a `collections.abc.Mapping` (with fast path for dicts). `match_keys` uses the two-argument `get()` method to look up keys and detect missing/duplicate keys. Implements `COPY_DICT_WITHOUT_KEYS` that creates a new dict containing all key-value pairs except the matched keys. Lazily imports and caches `_collections_abc.Mapping` on the interpreter state.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/internal/pycore_interp.h` | Modified | +4 / -1 | `map_abc` cache field on `PyInterpreterState` supports mapping-pattern matching | — | — |
| `Include/opcode.h` | Modified | +6 / -0 | Defines `MATCH_MAPPING`, `MATCH_KEYS`, and `COPY_DICT_WITHOUT_KEYS` opcodes used by mapping patterns | — | — |
| `Lib/opcode.py` | Modified | +10 / -12 | Registers the mapping-pattern opcodes in the Python-level opcode module | — | — |
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers mapping pattern behavior | — | — |
| `Python/opcode_targets.h` | Modified | +6 / -6 | Adds dispatch table entries for the mapping-pattern opcodes | — | — |
| `Python/pystate.c` | Modified | +2 / -0 | Cleans up the `map_abc` cache on interpreter state | — | — |

---

## Section 19: Class Patterns
*Path: Syntax and Semantics > Patterns > Class Patterns*
*Classification: Implementable*

> Syntax:
>
> ```
> class_pattern:
>     | name_or_attr '(' [pattern_arguments ','?] ')'
> pattern_arguments:
>     | positional_patterns [',' keyword_patterns]
>     | keyword_patterns
> positional_patterns: ','.pattern+
> keyword_patterns: ','.keyword_pattern+
> keyword_pattern: NAME '=' pattern
> ```
> A class pattern may not repeat the same keyword multiple times.
>
> If `name_or_attr` is not an instance of the builtin `type`,
> `TypeError` is raised.
>
> A class pattern fails if the subject is not an instance of `name_or_attr`.
> This is tested using `isinstance()`.
>
> If no arguments are present, the pattern succeeds if the `isinstance()`
> check succeeds.  Otherwise:
>
> - If only keyword patterns are present, they are processed as follows,
>   one by one:
>
>   - The keyword is looked up as an attribute on the subject.
>
>     - If this raises an exception other than `AttributeError`,
>       the exception bubbles up.
>
>     - If this raises `AttributeError` the class pattern fails.
>
>     - Otherwise, the subpattern associated with the keyword is matched
>       against the attribute value.  If this fails, the class pattern fails.
>       If it succeeds, the match proceeds to the next keyword.
>
>   - If all keyword patterns succeed, the class pattern as a whole succeeds.
>
> - If any positional patterns are present, they are converted to keyword
>   patterns (see below) and treated as additional keyword patterns,
>   preceding the syntactic keyword patterns (if any).
>
> Positional patterns are converted to keyword patterns using the
> `__match_args__` attribute on the class designated by `name_or_attr`,
> as follows:
>
> - For a number of built-in types (specified below),
>   a single positional subpattern is accepted which will match
>   the entire subject. (Keyword patterns work as for other types here.)
> - The equivalent of `getattr(cls, "__match_args__", ()))` is called.
> - If this raises an exception the exception bubbles up.
> - If the returned value is not a tuple, the conversion fails
>   and `TypeError` is raised.
> - If there are more positional patterns than the length of
>   `__match_args__` (as obtained using `len()`), `TypeError` is raised.
> - Otherwise, positional pattern `i` is converted to a keyword pattern
>   using `__match_args__[i]` as the keyword,
>   provided it the latter is a string;
>   if it is not, `TypeError` is raised.
> - For duplicate keywords, `TypeError` is raised.
>
> Once the positional patterns have been converted to keyword patterns,
> the match proceeds as if there were only keyword patterns.
>
> As mentioned above, for the following built-in types the handling of
> positional subpatterns is different:
> `bool`, `bytearray`, `bytes`, `dict`, `float`,
> `frozenset`, `int`, `list`, `set`, `str`, and `tuple`.
>
> This behavior is roughly equivalent to the following:
>
> ```
> class C:
>     __match_args__ = ("__match_self_prop__",)
>     @property
>     def __match_self_prop__(self):
>         return self
> ```

#### Requirement Summary
This section specifies class pattern semantics: `isinstance()` check, keyword attribute lookup, positional-to-keyword conversion via `__match_args__`, and special handling for built-in types that match a single positional subpattern against the subject itself. The PR implements `compiler_pattern_class` in `compile.c`, the `MATCH_CLASS` opcode in `ceval.c`, the `_Py_TPFLAGS_MATCH_SELF` flag in `object.h`, and sets this flag on built-in types.

**File proportion:** 15/43 files mapped (34.9%) + 4/43 files associated (9.3%) = 19/43 accounted (44.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +110 / -1 | — | — |
| `Parser/parser.c` | Modified | +11135 / -7806 | — | — |
| `Python/compile.c` | Modified | +713 / -26 | — | `compiler_pattern_class`, `compiler.compiler_pattern_class` |
| `Python/ceval.c` | Modified | +382 / -0 | — | `match_class`, `match_class_attr` |
| `Include/object.h` | Modified | +5 / -0 | — | — |
| `Objects/typeobject.c` | Modified | +4 / -0 | — | `inherit_special` |
| `Objects/bytearrayobject.c` | Modified | +2 / -1 | — | — |
| `Objects/bytesobject.c` | Modified | +2 / -1 | — | — |
| `Objects/dictobject.c` | Modified | +2 / -1 | — | — |
| `Objects/floatobject.c` | Modified | +2 / -1 | — | — |
| `Objects/listobject.c` | Modified | +2 / -1 | — | — |
| `Objects/longobject.c` | Modified | +2 / -1 | — | — |
| `Objects/setobject.c` | Modified | +4 / -3 | — | — |
| `Objects/tupleobject.c` | Modified | +2 / -1 | — | — |
| `Objects/unicodeobject.c` | Modified | +2 / -1 | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `class_pattern`, `pattern_arguments`, `positional_patterns`, `keyword_patterns`, and `keyword_pattern` productions so the parser accepts `Cls(positional, kw=pattern)` class patterns described by this section.
- **`Parser/parser.c`**: Regenerated parser for the class-pattern productions from `Grammar/python.gram`.
- **`Python/compile.c`**: `compiler_pattern_class` emits `MATCH_CLASS` with the positional pattern count as its oparg and the keyword names as a tuple constant. It compiles the class name (possibly dotted), pushes the keyword names tuple, and then matches each returned attribute against its corresponding subpattern.
- **`Python/ceval.c`**: Implements the `MATCH_CLASS` opcode via the `match_class` helper (with `match_class_attr` for per-attribute lookup). It performs `isinstance()` check, resolves positional patterns via `__match_args__`, handles special built-in types via `_Py_TPFLAGS_MATCH_SELF` (where a single positional subpattern matches the subject itself), looks up keyword attributes, validates against duplicate keywords, and returns a tuple of matched attributes on success.
- **`Include/object.h`**: Defines the `_Py_TPFLAGS_MATCH_SELF` flag (bit 22) that marks built-in types whose single positional subpattern matches against the subject itself rather than a mapped attribute.
- **`Objects/typeobject.c`**: Adds inheritance of `_Py_TPFLAGS_MATCH_SELF` in `inherit_special`, so subclasses of built-in types with this flag also get the special positional pattern behavior.
- **`Objects/bytearrayobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyByteArray_Type.tp_flags`, placing `bytearray` in the explicit list of built-in types this section calls out as accepting a single self-matching positional subpattern.
- **`Objects/bytesobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyBytes_Type.tp_flags`, opting `bytes` into the self-matching positional subpattern behavior the section enumerates.
- **`Objects/dictobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyDict_Type.tp_flags`, opting `dict` into the self-matching positional subpattern behavior.
- **`Objects/floatobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyFloat_Type.tp_flags`, opting `float` into the self-matching positional subpattern behavior.
- **`Objects/listobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyList_Type.tp_flags`, opting `list` into the self-matching positional subpattern behavior.
- **`Objects/longobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyLong_Type.tp_flags`, opting `int` (and `bool` via flag inheritance) into the self-matching positional subpattern behavior.
- **`Objects/setobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to both `PySet_Type.tp_flags` and `PyFrozenSet_Type.tp_flags`, opting `set` and `frozenset` into the self-matching positional subpattern behavior.
- **`Objects/tupleobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyTuple_Type.tp_flags`, opting `tuple` into the self-matching positional subpattern behavior.
- **`Objects/unicodeobject.c`**: Adds `_Py_TPFLAGS_MATCH_SELF` to `PyUnicode_Type.tp_flags`, opting `str` into the self-matching positional subpattern behavior.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/opcode.h` | Modified | +6 / -0 | Defines the `MATCH_CLASS` opcode used by class patterns | — | — |
| `Lib/opcode.py` | Modified | +10 / -12 | Registers the class-pattern opcode in the Python-level opcode module | — | — |
| `Lib/test/test_patma.py` | Modified | — | Comprehensive pattern-matching suite covers class pattern behavior | — | — |
| `Python/opcode_targets.h` | Modified | +6 / -6 | Adds dispatch table entry for the `MATCH_CLASS` opcode | — | — |

---

## Section 21: The Standard Library
*Path: The Standard Library*
*Classification: Implementable*

> To facilitate the use of pattern matching, several changes will be
> made to the standard library:
>
> - Namedtuples and dataclasses will have auto-generated
>   `__match_args__`.
>
> - For dataclasses the order of attributes in the generated
>   `__match_args__` will be the same as the order of corresponding
>   arguments in the generated `__init__()` method.  This includes the
>   situations where attributes are inherited from a superclass.  Fields
>   with `init=False` are excluded from `__match_args__`.
>
> In addition, a systematic effort will be put into going through
> existing standard library classes and adding `__match_args__` where
> it looks beneficial.

#### Requirement Summary
This section specifies that namedtuples and dataclasses should auto-generate `__match_args__`, with dataclass field ordering matching `__init__()` parameter order and excluding `init=False` fields. The PR adds `__match_args__` generation to both namedtuples and dataclasses.

**File proportion:** 2/43 files mapped (4.7%) + 2/43 files associated (4.7%) = 4/43 accounted (9.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/collections/__init__.py` | Modified | +1 / -0 | — | `namedtuple` |
| `Lib/dataclasses.py` | Modified | +12 / -0 | — | `_process_class` |

#### Modification Summary
- **`Lib/collections/__init__.py`**: Adds `'__match_args__': field_names` to the namedtuple class dict, setting `__match_args__` to the tuple of field names so that namedtuples support positional pattern matching in class patterns.
- **`Lib/dataclasses.py`**: Adds `__match_args__` generation in `_process_class`. Sets `__match_args__` to a tuple of field names for fields with `init=True`, preserving the same order as `__init__()` parameters. Only adds `__match_args__` if the class does not already define it in its `__dict__`.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_collections.py` | Modified | +4 / -0 | Tests `__match_args__` on namedtuples | — | — |
| `Lib/test/test_dataclasses.py` | Modified | +16 / -0 | Tests `__match_args__` on dataclasses including field ordering and `init=False` exclusion | — | — |

---

## Unmapped Requirement Sections

*All implementable sections are mapped.*

## Unmapped PR Files

*All PR files are accounted for.*
