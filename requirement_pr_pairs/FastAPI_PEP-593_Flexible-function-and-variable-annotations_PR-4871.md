# FastAPI - PEP 593: Flexible Function and Variable Annotations

**PR:** https://github.com/fastapi/fastapi/pull/4871
**Requirement Doc:** PEP 593 Flexible function and variable annotations

## Matching Statistics
- **Requirement Doc Coverage:** 2/2 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 3/24 files mapped (12.5%) + 21/24 files associated (87.5%) = 24/24 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 593: Flexible function and variable annotations | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Rationale | No | N/A | knowledge |
| 5 | Motivating examples | No | N/A | contextual |
| 6 | Combining runtime and static uses of annotations | No | N/A | contextual |
| 7 | Lowering barriers to developing new typing constructs | No | N/A | contextual |
| 8 | Specification | No | N/A | knowledge |
| 9 | Specification > Syntax | Yes | Yes | implementation |
| 10 | Specification > Consuming annotations | Yes | Yes | implementation |
| 11 | Interaction with `get_type_hints()` | No | N/A | knowledge |
| 12 | Aliases & Concerns over verbosity | No | N/A | knowledge |
| 13 | Rejected ideas | No | N/A | contextual |
| 14 | Copyright | No | N/A | process |
| 15 | Linked PEP 484 — Type Hints | No | N/A | knowledge |
| 16 | Linked PEP 484 — Type Hints > Abstract | No | N/A | knowledge |
| 17 | Linked PEP 484 — Type Hints > Rationale and Goals | No | N/A | contextual |
| 18 | Linked PEP 484 — Type Hints > Rationale and Goals > Non-goals | No | N/A | contextual |
| 19 | Linked PEP 484 — Type Hints > The meaning of annotations | No | N/A | knowledge |
| 20 | Linked PEP 484 — Type Hints > Type Definition Syntax | No | N/A | knowledge |
| 21 | Linked PEP 484 — Type Hints > Type Definition Syntax > Acceptable type hints | No | N/A | knowledge |
| 22 | Linked PEP 3107 — Function Annotations | No | N/A | knowledge |
| 23 | Linked PEP 3107 — Function Annotations > Abstract | No | N/A | knowledge |
| 24 | Linked PEP 3107 — Function Annotations > Rationale | No | N/A | contextual |
| 25 | Linked PEP 3107 — Function Annotations > Fundamentals of Function Annotations | No | N/A | knowledge |
| 26 | Linked PEP 3107 — Function Annotations > Syntax | No | N/A | knowledge |
| 27 | Linked PEP 3107 — Function Annotations > Syntax > Parameters | No | N/A | knowledge |
| 28 | Linked PEP 3107 — Function Annotations > Syntax > Return Values | No | N/A | knowledge |
| 29 | Linked PEP 3107 — Function Annotations > Syntax > Lambda | No | N/A | knowledge |
| 30 | Linked PEP 3107 — Function Annotations > Accessing Function Annotations | No | N/A | knowledge |
| 31 | Linked Issue #600 — Add support for external annotations in the typing module | No | N/A | contextual |
| 32 | Linked Issue #600 — Add support for external annotations in the typing module > Motivating examples | No | N/A | contextual |
| 33 | Linked Issue #600 — Add support for external annotations in the typing module > Motivating examples > READING binary data | No | N/A | contextual |
| 34 | Linked Issue #600 — Add support for external annotations in the typing module > Motivating examples > dataclasses | No | N/A | contextual |
| 35 | Linked Issue #600 — Add support for external annotations in the typing module > Motivating examples > lowering barriers to developing new types | No | N/A | contextual |
| 36 | Linked Issue #600 — Add support for external annotations in the typing module > Details of proposed changes to `typing` | No | N/A | knowledge |
| 37 | Linked Issue #600 — Add support for external annotations in the typing module > Details of proposed changes to `typing` > Syntax | No | N/A | knowledge |
| 38 | Linked Issue #600 — Add support for external annotations in the typing module > Details of proposed changes to `typing` > consuming annotations | No | N/A | knowledge |
| 39 | Linked Issue #600 — Add support for external annotations in the typing module > Details of proposed changes to `typing` > related bugs | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `docs_src/annotated/tutorial001.py` | documentation | — | Section 9 |
| 2 | `docs_src/annotated/tutorial001_py39.py` | documentation | — | Section 9 |
| 3 | `docs_src/annotated/tutorial002.py` | documentation | — | Section 9 |
| 4 | `docs_src/annotated/tutorial002_py39.py` | documentation | — | Section 9 |
| 5 | `docs_src/annotated/tutorial003.py` | documentation | — | Section 9 |
| 6 | `docs_src/annotated/tutorial003_py39.py` | documentation | — | Section 9 |
| 7 | `fastapi/dependencies/utils.py` | source | Section 9, Section 10 | — |
| 8 | `fastapi/param_functions.py` | source | Section 9 | — |
| 9 | `fastapi/params.py` | source | Section 9 | — |
| 10 | `fastapi/utils.py` | source | — | Section 9 |
| 11 | `tests/main.py` | test | — | Section 9 |
| 12 | `tests/test_ambiguous_params.py` | test | — | Section 9 |
| 13 | `tests/test_annotated.py` | test | — | Section 9 |
| 14 | `tests/test_application.py` | test | — | Section 9 |
| 15 | `tests/test_params_repr.py` | test | — | Section 9 |
| 16 | `tests/test_path.py` | test | — | Section 9 |
| 17 | `tests/test_tutorial/test_annotated/__init__.py` | test | — | Section 9 |
| 18 | `tests/test_tutorial/test_annotated/test_tutorial001.py` | test | — | Section 9 |
| 19 | `tests/test_tutorial/test_annotated/test_tutorial001_py39.py` | test | — | Section 9 |
| 20 | `tests/test_tutorial/test_annotated/test_tutorial002.py` | test | — | Section 9 |
| 21 | `tests/test_tutorial/test_annotated/test_tutorial002_py39.py` | test | — | Section 9 |
| 22 | `tests/test_tutorial/test_annotated/test_tutorial003.py` | test | — | Section 9 |
| 23 | `tests/test_tutorial/test_annotated/test_tutorial003_py39.py` | test | — | Section 9 |
| 24 | `tests/test_tutorial/test_dataclasses/__init__.py` | test | — | Section 9 |

---

## Section 9: Syntax
*Path: Specification > Syntax*
*Classification: Implementable*

> `Annotated` is parameterized with a type and an arbitrary list of
> Python values that represent the annotations. Here are the specific
> details of the syntax:
>
> * The first argument to `Annotated` must be a valid type
>
> * Multiple type annotations are supported (`Annotated` supports variadic
>   arguments):
>
> ```
> Annotated[int, ValueRange(3, 10), ctype("char")]
> ```
> * `Annotated` must be called with at least two arguments (
>   `Annotated[int]` is not valid)
>
> * The order of the annotations is preserved and matters for equality
>   checks:
>
> ```
> Annotated[int, ValueRange(3, 10), ctype("char")] != Annotated[
>     int, ctype("char"), ValueRange(3, 10)
> ]
> ```
> * Nested `Annotated` types are flattened, with metadata ordered
>   starting with the innermost annotation:
>
> ```
> Annotated[Annotated[int, ValueRange(3, 10)], ctype("char")] == Annotated[
>     int, ValueRange(3, 10), ctype("char")
> ]
> ```
> * Duplicated annotations are not removed:
>
> ```
> Annotated[int, ValueRange(3, 10)] != Annotated[
>     int, ValueRange(3, 10), ValueRange(3, 10)
> ]
> ```
> * `Annotated` can be used with nested and generic aliases:
>
> ```
> Typevar T = ...
> Vec = Annotated[List[Tuple[T, T]], MaxLen(10)]
> V = Vec[int]
>
> V == Annotated[List[Tuple[int, int]], MaxLen(10)]
> ```

#### Requirement Summary
`Annotated` is parameterized with a type and an arbitrary list of Python values that represent annotations. The first argument must be a valid type, at least two arguments are required, the order of annotations is preserved and matters for equality checks, nested `Annotated` types are flattened with metadata ordered starting with the innermost annotation, duplicated annotations are not removed, and `Annotated` can be used with nested and generic aliases.

**File proportion:** 3/24 files mapped (12.5%) + 21/24 files associated (87.5%) = 24/24 accounted (100.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `fastapi/dependencies/utils.py` | Modified | +177 / -99 | — | `add_non_field_param_to_dependency`, `get_dependant`, `get_param_field`, `get_param_sub_dependant`, `is_body_param` |
| `fastapi/param_functions.py` | Modified | +1 / -1 | — | `Path` |
| `fastapi/params.py` | Modified | +5 / -4 | `File`, `Form`, `Path` | `File.__init__`, `Form.__init__`, `Path.__init__` |

#### Modification Summary
- **`fastapi/dependencies/utils.py`**: Core implementation of `Annotated` support in FastAPI's dependency injection system. Imports `Annotated` from `typing_extensions` and `get_args`/`get_origin` from `pydantic.typing`. Adds the `analyze_param` helper that unpacks `Annotated` syntax (its detailed scope is documented under Section 10, which covers how the consuming-annotations pattern is applied). Refactors `get_param_sub_dependant` to accept explicit `param_name` and `depends` arguments instead of the raw `inspect.Parameter`. Refactors `add_non_field_param_to_dependency` to accept `param_name` and `type_annotation` instead of the raw parameter. Extracts `is_body_param` as a separate function. The `get_dependant` loop now calls `analyze_param` for each parameter and dispatches based on the returned `(type_annotation, depends, param_field)` tuple. Together these refactors enable `Annotated[T, FieldInfo|Depends]` to coexist with default values, `Depends`, `Path`, `Query`, `Body`, `Form`, `File`, and other parameter syntactic positions.
- **`fastapi/params.py`**: Changes `Path.__init__` default from `Undefined` to `...` (Ellipsis) and adds `assert default is ..., "Path parameters cannot have a default value"` to enforce that path parameters never receive a non-ellipsis default. Changes `Form.__init__` and `File.__init__` defaults from required positional `default: Any` to `default: Any = Undefined`, making them compatible with `Annotated` usage where the default is set externally.
- **`fastapi/param_functions.py`**: Changes the `Path()` function's `default` parameter from `Undefined` to `...` (Ellipsis) to match the updated `params.Path` class.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `fastapi/utils.py` | Modified | +10 / -13 | Utility function changes required by the Annotated type handling refactor in dependencies/utils.py | — | `create_response_field` |
| `docs_src/annotated/tutorial001.py` | Added | +18 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `docs_src/annotated/tutorial001_py39.py` | Added | +17 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `docs_src/annotated/tutorial002.py` | Added | +21 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `docs_src/annotated/tutorial002_py39.py` | Added | +20 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `docs_src/annotated/tutorial003.py` | Added | +15 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `docs_src/annotated/tutorial003_py39.py` | Added | +16 / -0 | Tutorial example for Annotated parameter integration | — | — |
| `tests/main.py` | Modified | +1 / -6 | Tests for Annotated parameter handling | — | — |
| `tests/test_ambiguous_params.py` | Added | +66 / -0 | Tests for ambiguous/multiple FastAPI metadata cases | — | — |
| `tests/test_annotated.py` | Added | +226 / -0 | Main test coverage for Annotated parameter support | — | — |
| `tests/test_application.py` | Modified | +0 / -30 | Test adjustment after dependency behavior changes | — | — |
| `tests/test_params_repr.py` | Modified | +3 / -2 | Tests for parameter representation changes | — | — |
| `tests/test_path.py` | Modified | +0 / -1 | Tests for path default behavior | — | — |
| `tests/test_tutorial/test_annotated/__init__.py` | Added | +0 / -0 | Test package marker for annotated tutorial tests | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial001.py` | Added | +100 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial001_py39.py` | Added | +107 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial002.py` | Added | +100 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial002_py39.py` | Added | +107 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial003.py` | Added | +138 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_annotated/test_tutorial003_py39.py` | Added | +145 / -0 | Tutorial test support | — | — |
| `tests/test_tutorial/test_dataclasses/__init__.py` | Added | +0 / -0 | Test package marker | — | — |

---

## Section 10: Consuming annotations
*Path: Specification > Consuming annotations*
*Classification: Implementable*

> Ultimately, the responsibility of how to interpret the annotations (if
> at all) is the responsibility of the tool or library encountering the
> `Annotated` type. A tool or library encountering an `Annotated` type
> can scan through the annotations to determine if they are of interest
> (e.g., using `isinstance()`).
>
> **Unknown annotations:** When a tool or a library does not support
> annotations or encounters an unknown annotation it should just ignore it
> and treat annotated type as the underlying type. For example, when encountering
> an annotation that is not an instance of `struct2.ctype` to the annotations
> for name (e.g., `Annotated[str, 'foo', struct2.ctype("<10s")]`), the unpack
> method should ignore it.
>
> **Namespacing annotations:** Namespaces are not needed for annotations since
> the class used by the annotations acts as a namespace.
>
> **Multiple annotations:** It's up to the tool consuming the annotations
> to decide whether the client is allowed to have several annotations on
> one type and how to merge those annotations.
>
> Since the `Annotated` type allows you to put several annotations of
> the same (or different) type(s) on any node, the tools or libraries
> consuming those annotations are in charge of dealing with potential
> duplicates. For example, if you are doing value range analysis you might
> allow this:
>
> ```
> T1 = Annotated[int, ValueRange(-10, 5)]
> T2 = Annotated[T1, ValueRange(-20, 3)]
> ```
> Flattening nested annotations, this translates to:
>
> ```
> T2 = Annotated[int, ValueRange(-10, 5), ValueRange(-20, 3)]
> ```

#### Requirement Summary
The responsibility of how to interpret annotations is on the tool or library encountering the `Annotated` type. A tool can scan through annotations to determine if they are of interest (e.g., using `isinstance()`). Unknown annotations should be ignored and the annotated type treated as the underlying type. Namespaces are not needed since the annotation class acts as a namespace. It is up to the consuming tool to decide whether multiple annotations on one type are allowed and how to merge them.

**File proportion:** 1/24 files mapped (4.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `fastapi/dependencies/utils.py` | Modified | +177 / -99 | — | `analyze_param` |

#### Modification Summary
- **`fastapi/dependencies/utils.py`**: The `analyze_param` function implements the PEP 593 consuming-annotations pattern: it iterates over `annotated_args[1:]` and filters with `isinstance(arg, (FieldInfo, params.Depends))` to find FastAPI-relevant annotations, ignoring all others. Non-FastAPI annotations (e.g., `object()` instances or other arbitrary metadata) are silently skipped, treating the annotated type as its underlying base type -- exactly as PEP 593 prescribes for unknown annotations. The function enforces a single-FastAPI-annotation policy (`len(fastapi_annotations) <= 1`), which is FastAPI's chosen strategy for handling multiple annotations as allowed by the PEP.

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

