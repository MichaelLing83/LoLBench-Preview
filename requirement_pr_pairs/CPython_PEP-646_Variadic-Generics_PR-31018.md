# CPython - PEP 646: Variadic Generics

**PR:** https://github.com/python/cpython/pull/31018
**Requirement Doc:** https://peps.python.org/pep-0646/

## Matching Statistics
- **Requirement Doc Coverage:** 2/2 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 5/12 files mapped (41.7%) + 7/12 files associated (58.3%) = 12/12 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 646: Variadic Generics | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Acceptance | No | N/A | process |
| 4 | Motivation | No | N/A | contextual |
| 5 | Summary Examples | No | N/A | knowledge |
| 6 | Specification | No | N/A | knowledge |
| 7 | Specification > Type Variable Tuples | No | N/A | knowledge |
| 8 | Specification > Type Variable Tuples > Using Type Variable Tuples in Generic Classes | No | N/A | knowledge |
| 9 | Specification > Type Variable Tuples > Using Type Variable Tuples in Functions | No | N/A | knowledge |
| 10 | Specification > Type Variable Tuples > Type Variable Tuples Must Always be Unpacked | No | N/A | knowledge |
| 11 | Specification > Type Variable Tuples > `Unpack` for Backwards Compatibility | No | N/A | knowledge |
| 12 | Specification > Type Variable Tuples > Variance, Type Constraints and Type Bounds: Not (Yet) Supported | No | N/A | contextual |
| 13 | Specification > Type Variable Tuples > Type Variable Tuple Equality | No | N/A | knowledge |
| 14 | Specification > Type Variable Tuples > Multiple Type Variable Tuples: Not Allowed | No | N/A | knowledge |
| 15 | Specification > Type Concatenation | No | N/A | knowledge |
| 16 | Specification > Unpacking Tuple Types | No | N/A | knowledge |
| 17 | Specification > Unpacking Tuple Types > Unpacking Concrete Tuple Types | No | N/A | knowledge |
| 18 | Specification > Unpacking Tuple Types > Unpacking Unbounded Tuple Types | No | N/A | knowledge |
| 19 | Specification > Unpacking Tuple Types > Multiple Unpackings in a Tuple: Not Allowed | No | N/A | knowledge |
| 20 | Specification > `*args` as a Type Variable Tuple | No | N/A | knowledge |
| 21 | Specification > Type Variable Tuples with `Callable` | No | N/A | knowledge |
| 22 | Specification > Behaviour when Type Parameters are not Specified | No | N/A | knowledge |
| 23 | Specification > Aliases | No | N/A | knowledge |
| 24 | Specification > Substitution in Aliases | No | N/A | knowledge |
| 25 | Specification > Substitution in Aliases > Type Arguments can be Variadic | No | N/A | knowledge |
| 26 | Specification > Substitution in Aliases > Variadic Arguments Require Variadic Aliases | No | N/A | knowledge |
| 27 | Specification > Substitution in Aliases > Aliases with Both TypeVars and TypeVarTuples | No | N/A | knowledge |
| 28 | Specification > Substitution in Aliases > Splitting Arbitrary-Length Tuples | No | N/A | knowledge |
| 29 | Specification > Substitution in Aliases > TypeVarTuples Cannot be Split | No | N/A | knowledge |
| 30 | Specification > Overloads for Accessing Individual Types | No | N/A | knowledge |
| 31 | Rationale and Rejected Ideas | No | N/A | contextual |
| 32 | Rationale and Rejected Ideas > Shape Arithmetic | No | N/A | contextual |
| 33 | Rationale and Rejected Ideas > Supporting Variadicity Through Aliases | No | N/A | contextual |
| 34 | Rationale and Rejected Ideas > Construction of `TypeVarTuple` | No | N/A | contextual |
| 35 | Rationale and Rejected Ideas > Unspecified Type Parameters: Tuple vs TypeVarTuple | No | N/A | contextual |
| 36 | Alternatives | No | N/A | contextual |
| 37 | Grammar Changes | No | N/A | knowledge |
| 38 | Grammar Changes > Change 1: Star Expressions in Indexes | Yes | Yes | implementation |
| 39 | Grammar Changes > Change 1: Star Expressions in Indexes > TypeVarTuple Implementation | No | N/A | knowledge |
| 40 | Grammar Changes > Change 1: Star Expressions in Indexes > Implications | No | N/A | contextual |
| 41 | Grammar Changes > Change 2: `*args` as a TypeVarTuple | Yes | Yes | implementation |
| 42 | Grammar Changes > Change 2: `*args` as a TypeVarTuple > Implications | No | N/A | contextual |
| 43 | Grammar Changes > Alternatives (Why Not Just Use `Unpack`?) | No | N/A | contextual |
| 44 | Backwards Compatibility | No | N/A | contextual |
| 45 | Reference Implementation | No | N/A | contextual |
| 46 | Appendix A: Shape Typing Use Cases | No | N/A | contextual |
| 47 | Appendix A: Shape Typing Use Cases > Use Case 1: Specifying Shape Values | No | N/A | contextual |
| 48 | Appendix A: Shape Typing Use Cases > Use Case 2: Specifying Shape Semantics | No | N/A | contextual |
| 49 | Appendix A: Shape Typing Use Cases > Discussion | No | N/A | contextual |
| 50 | Appendix A: Shape Typing Use Cases > Why Not Both? | No | N/A | contextual |
| 51 | Appendix B: Shaped Types vs Named Axes | No | N/A | contextual |
| 52 | Footnotes | No | N/A | process |
| 53 | Endorsements | No | N/A | contextual |
| 54 | Acknowledgements | No | N/A | process |
| 55 | Resources | No | N/A | process |
| 56 | References | No | N/A | process |
| 57 | Copyright | No | N/A | process |
| 58 | Linked Issue #193 — Allow variadic generics | No | N/A | knowledge |
| 59 | Linked Issue #24527 — bpo-43224: Initial implementation of PEP 646 in typing.py | No | N/A | knowledge |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Grammar/python.gram` | source | Section 38, Section 41 | — |
| 2 | `Lib/ast.py` | source | Section 38 | — |
| 3 | `Lib/test/test_ast.py` | test | — | Section 38 |
| 4 | `Lib/test/test_future.py` | test | — | Section 38, Section 41 |
| 5 | `Lib/test/test_pep646_syntax.py` | test | — | Section 38, Section 41 |
| 6 | `Lib/test/test_syntax.py` | test | — | Section 38 |
| 7 | `Lib/test/test_unparse.py` | test | — | Section 38 |
| 8 | `Lib/typing.py` | source | Section 41 | — |
| 9 | `Misc/NEWS.d/next/Core and Builtins/2022-01-20-16-48-09.bpo-43224.WDihrT.rst` | documentation | — | Section 38 |
| 10 | `Parser/parser.c` | generated | — | Section 38, Section 41 |
| 11 | `Python/ast_unparse.c` | source | Section 38 | — |
| 12 | `Python/compile.c` | source | Section 41 | — |

---

## Section 38: Change 1: Star Expressions in Indexes
*Path: Grammar Changes > Change 1: Star Expressions in Indexes*
*Classification: Implementable*

> The first grammar change enables use of star expressions in index operations (that is,
> within square brackets), necessary to support star-unpacking of TypeVarTuples:
>
> ```
> DType = TypeVar('DType')
> Shape = TypeVarTuple('Shape')
> class Array(Generic[DType, *Shape]):
>     ...
> ```
> Before:
>
> ```
> slices:
>     | slice !','
>     | ','.slice+ [',']
> ```
> After:
>
> ```
> slices:
>     | slice !','
>     | ','.(slice | starred_expression)+ [',']
> ```
> As with star-unpacking in other contexts, the star operator calls `__iter__`
> on the callee, and adds the contents of the resulting iterator to the argument
> passed to `__getitem__`. For example, if we do `foo[a, *b, c]`, and
> `b.__iter__` produces an iterator yielding `d` and `e`,
> `foo.__getitem__` would receive `(a, d, e, c)`.
>
> To put it another way, note that `x[..., *a, ...]` produces the same result
> as `x[(..., *a, ...)]` (with any slices `i:j` in `...` replaced with
> `slice(i, j)`, with the one edge case that `x[*a]` becomes `x[(*a,)]`).

#### Requirement Summary
This section specifies the first grammar change required by PEP 646: enabling star expressions in index operations (subscripts). The PR implements this by modifying the `slices` production rule in `Grammar/python.gram` to accept `starred_expression` alongside `slice`, updating the auto-generated `Parser/parser.c`, simplifying the `ast_unparse.c` subscript handling to accept starred elements within subscript tuples, and updating `Lib/ast.py` to allow starred elements in subscript tuple unparsing.

**File proportion:** 3/12 files mapped (25.0%) + 7/12 files associated (58.3%) = 10/12 accounted (83.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +8 / -1 | — | — |
| `Lib/ast.py` | Modified | +3 / -6 | `_Unparser` | `_Unparser.visit_Subscript` |
| `Python/ast_unparse.c` | Modified | +1 / -12 | — | `append_ast_subscript` |

#### Modification Summary
- **`Grammar/python.gram`**: Modifies the `slices` production rule from `','.slice+ [',']` to `','.(slice | starred_expression)+ [',']`, enabling star expressions (e.g., `*Shape`) inside index brackets as specified in the "After" grammar.
- **`Lib/ast.py`**: Renames `is_simple_tuple` to `is_non_empty_tuple` in `visit_Subscript` and removes the check that excluded starred elements from parenthesis-free tuple unparsing, since starred expressions are now valid within subscripts.
- **`Python/ast_unparse.c`**: Simplifies `append_ast_subscript` by removing the special-case logic that elevated precedence when starred elements appeared in subscript tuples, since starred expressions in subscripts are now standard.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +2465 / -2101 | Auto-regenerated from Grammar/python.gram | — | — |
| `Lib/test/test_ast.py` | Modified | +24 / -1 | Test file updated with AST round-trip cases for starred expressions in subscripts and function annotations | — | — |
| `Lib/test/test_future.py` | Modified | +38 / -3 | Test file includes future-annotation round-trip cases covering starred subscripts | — | — |
| `Lib/test/test_pep646_syntax.py` | Added | +326 / -0 | Test file added to verify runtime behavior of star-unpacking in index operations | — | — |
| `Lib/test/test_syntax.py` | Modified | +143 / -0 | Test file updated with syntax error cases for invalid star-unpacking in slices | — | — |
| `Lib/test/test_unparse.py` | Modified | +25 / -1 | Test file updated with unparse round-trip cases for starred expressions in subscripts | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2022-01-20-16-48-09.bpo-43224.WDihrT.rst` | Added | +1 / -0 | NEWS entry documenting the grammar changes for PEP 646 | — | — |

---

## Section 41: Change 2: `*args` as a TypeVarTuple
*Path: Grammar Changes > Change 2: `*args` as a TypeVarTuple*
*Classification: Implementable*

> The second change enables use of `*args: *Ts` in function definitions.
>
> Before:
>
> ```
> star_etc:
> | '*' param_no_default param_maybe_default* [kwds]
> | '*' ',' param_maybe_default+ [kwds]
> | kwds
> ```
> After:
>
> ```
> star_etc:
> | '*' param_no_default param_maybe_default* [kwds]
> | '*' param_no_default_star_annotation param_maybe_default* [kwds]  # New
> | '*' ',' param_maybe_default+ [kwds]
> | kwds
> ```
> Where:
>
> ```
> param_no_default_star_annotation:
> | param_star_annotation ',' TYPE_COMMENT?
> | param_star_annotation TYPE_COMMENT? &')'
>
> param_star_annotation: NAME star_annotation
>
> star_annotation: ':' star_expression
> ```
> We also need to deal with the `star_expression` that results from this
> construction. Normally, a `star_expression` occurs within the context
> of e.g. a list, so a `star_expression` is handled by essentially
> calling `iter()` on the starred object, and inserting the results
> of the resulting iterator into the list at the appropriate place. For
> `*args: *Ts`, however, we must process the `star_expression` in a
> different way.
>
> We do this by instead making a special case for the `star_expression`
> resulting from `*args: *Ts`, emitting code equivalent to
> `[annotation_value] = [*Ts]`. That is, we create an iterator from
> `Ts` by calling `Ts.__iter__`, fetch a single value from the iterator,
> verify that the iterator is exhausted, and set that value as the annotation
> value. This results in the unpacked `TypeVarTuple` being set directly
> as the runtime annotation for `*args`:
>
> ```
> >>> Ts = TypeVarTuple('Ts')
> >>> def foo(*args: *Ts): pass
> >>> foo.__annotations__
> {'args': *Ts}
> ## *Ts is the repr() of Ts._unpacked, an instance of UnpackedTypeVarTuple
> ```
> This allows the runtime annotation to be consistent with an AST representation
> that uses a `Starred` node for the annotations of `args` - in turn important
> for tools that rely on the AST such as mypy to correctly recognise the construction:
>
> ```
> >>> print(ast.dump(ast.parse('def foo(*args: *Ts): pass'), indent=2))
> Module(
>   body=[
>     FunctionDef(
>       name='foo',
>       args=arguments(
>         posonlyargs=[],
>         args=[],
>         vararg=arg(
>           arg='args',
>           annotation=Starred(
>             value=Name(id='Ts', ctx=Load()),
>             ctx=Load())),
>         kwonlyargs=[],
>         kw_defaults=[],
>         defaults=[]),
>       body=[
>         Pass()],
>       decorator_list=[])],
>   type_ignores=[])
> ```
> Note that the only scenario in which this grammar change allows `*Ts` to be
> used as a direct annotation (rather than being wrapped in e.g. `Tuple[*Ts]`)
> is `*args`. Other uses are still invalid:
>
> ```
> x: *Ts                 # Syntax error
> def foo(x: *Ts): pass  # Syntax error
> ```

#### Requirement Summary
This section specifies the second grammar change: enabling `*args: *Ts` in function definitions. The PR implements this by adding the `param_no_default_star_annotation`, `param_star_annotation`, and `star_annotation` production rules to `Grammar/python.gram`, implementing the compiler special-case in `Python/compile.c` to emit `UNPACK_SEQUENCE 1` for starred annotations on `*args`, and updating `Lib/typing.py` to handle `ForwardRef` arguments starting with `*` (for `from __future__ import annotations`).

**File proportion:** 3/12 files mapped (25.0%) + 3/12 files associated (25.0%) = 6/12 accounted (50.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +8 / -1 | — | — |
| `Lib/typing.py` | Modified | +10 / -1 | `ForwardRef` | `ForwardRef.__init__` |
| `Python/compile.c` | Modified | +12 / -2 | — | `compiler_visit_argannotation` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the new `star_etc` alternative `'*' param_no_default_star_annotation param_maybe_default* [kwds]` along with supporting rules `param_no_default_star_annotation`, `param_star_annotation`, and `star_annotation` as specified in the "After" grammar, enabling `*args: *Ts` syntax.
- **`Lib/typing.py`**: Updates `ForwardRef.__init__` to handle annotation strings starting with `*` (e.g., `'*Ts'` produced by `from __future__ import annotations`) by wrapping them as `(*Ts,)[0]` before compilation, enabling correct evaluation of forward references for variadic `*args` annotations.
- **`Python/compile.c`**: Adds a special case in `compiler_visit_argannotation` for `Starred` annotation nodes: when the annotation is a starred expression (i.e., `*args: *Ts`), it emits `UNPACK_SEQUENCE 1` to extract the single value from the iterator, implementing the `[annotation_value] = [*Ts]` semantics specified in the PEP.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_future.py` | Modified | +38 / -3 | Test file updated with annotation round-trip tests and type hints tests for `*args: *Ts` with `from __future__ import annotations` | — | — |
| `Lib/test/test_pep646_syntax.py` | Added | +326 / -0 | Test file doctest covers `*args: *b` runtime behavior in addition to starred subscripts | — | — |
| `Parser/parser.c` | Modified | +2465 / -2101 | Auto-regenerated parser reflects the `*args: *Ts` grammar rule additions | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
