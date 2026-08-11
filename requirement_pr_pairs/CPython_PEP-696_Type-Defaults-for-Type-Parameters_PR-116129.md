# CPython - PEP 696: Type Defaults for Type Parameters

**PR:** https://github.com/python/cpython/pull/116129
**Requirement Doc:** https://peps.python.org/pep-0696/

## Matching Statistics
- **Requirement Doc Coverage:** 7/7 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 12/28 files mapped (42.9%) + 16/28 files associated (57.1%) = 28/28 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 696: Type Defaults for Type Parameters | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Specification | No | N/A | knowledge |
| 5 | Specification > Default Ordering and Subscription Rules | Yes | Yes | implementation |
| 6 | Specification > `ParamSpec` Defaults | Yes | Yes | implementation |
| 7 | Specification > `TypeVarTuple` Defaults | Yes | Yes | implementation |
| 8 | Specification > Using Another Type Parameter as `default` | Yes | Yes | implementation |
| 9 | Specification > Using Another Type Parameter as `default` > Scoping Rules | No | N/A | knowledge |
| 10 | Specification > Using Another Type Parameter as `default` > Bound Rules | No | N/A | knowledge |
| 11 | Specification > Using Another Type Parameter as `default` > Constraint Rules | No | N/A | knowledge |
| 12 | Specification > Using Another Type Parameter as `default` > Type Parameters as Parameters to Generics | No | N/A | knowledge |
| 13 | Specification > Using Another Type Parameter as `default` > Specialisation Rules | No | N/A | knowledge |
| 14 | Specification > `Generic` `TypeAlias`\ es | No | N/A | knowledge |
| 15 | Specification > Subclassing | No | N/A | knowledge |
| 16 | Specification > Using `bound` and `default` | No | N/A | knowledge |
| 17 | Specification > Constraints | No | N/A | knowledge |
| 18 | Specification > Function Defaults | No | N/A | knowledge |
| 19 | Specification > Defaults following `TypeVarTuple` | Yes | Yes | implementation |
| 20 | Specification > Subtyping | No | N/A | knowledge |
| 21 | Specification > `TypeVarTuple`\ s as Defaults | No | N/A | knowledge |
| 22 | Binding rules | No | N/A | contextual |
| 23 | Implementation | Yes | Yes | implementation |
| 24 | Implementation > Grammar changes | Yes | Yes | implementation |
| 25 | Rejected Alternatives | No | N/A | contextual |
| 26 | Rejected Alternatives > Allowing the Type Parameters Defaults to Be Passed to `type.__new__`'s `**kwargs` | No | N/A | knowledge |
| 27 | Rejected Alternatives > Allowing Non-defaults to Follow Defaults | No | N/A | knowledge |
| 28 | Rejected Alternatives > Having `default` Implicitly Be `bound` | No | N/A | knowledge |
| 29 | Rejected Alternatives > Allowing Type Parameters With Defaults To Be Used in Function Signatures | No | N/A | knowledge |
| 30 | Rejected Alternatives > Allowing Type Parameters from Outer Scopes in `default` | No | N/A | knowledge |
| 31 | Acknowledgements | No | N/A | process |
| 32 | Copyright | No | N/A | process |
| 33 | Linked Issue #975 — Allow Generator type annotation to have one argument. | No | N/A | contextual |
| 34 | Linked Issue #159 — `builtins.slice` should be generic | No | N/A | contextual |
| 35 | Linked Issue #548 — Higher-Kinded TypeVars | No | N/A | contextual |
| 36 | Linked Issue #813 — [Feature Request] TypeVar variance definition alias | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/ast.rst` | documentation | — | Section 24 |
| 2 | `Doc/library/typing.rst` | documentation | — | Section 23 |
| 3 | `Doc/reference/compound_stmts.rst` | documentation | — | Section 24 |
| 4 | `Doc/reference/executionmodel.rst` | documentation | — | Section 24 |
| 5 | `Doc/whatsnew/3.13.rst` | documentation | — | Section 23 |
| 6 | `Grammar/python.gram` | source | Section 19, Section 24 | — |
| 7 | `Include/internal/pycore_ast.h` | generated | — | Section 24 |
| 8 | `Include/internal/pycore_ast_state.h` | generated | — | Section 24 |
| 9 | `Include/internal/pycore_intrinsics.h` | source | Section 24 | — |
| 10 | `Include/internal/pycore_typevarobject.h` | source | Section 23 | — |
| 11 | `Lib/ast.py` | source | Section 24 | — |
| 12 | `Lib/test/test_ast.py` | test | — | Section 24 |
| 13 | `Lib/test/test_type_params.py` | test | — | Section 5, Section 8, Section 19, Section 23, Section 24 |
| 14 | `Lib/test/test_typing.py` | test | — | Section 5, Section 6, Section 7, Section 23 |
| 15 | `Lib/test/test_unparse.py` | test | — | Section 24 |
| 16 | `Lib/typing.py` | source | Section 5, Section 6, Section 7 | — |
| 17 | `Misc/NEWS.d/next/Core and Builtins/2024-02-29-18-55-45.gh-issue-116129.wsFnIq.rst` | documentation | — | Section 23 |
| 18 | `Modules/_typingmodule.c` | source | Section 23 | — |
| 19 | `Objects/clinic/typevarobject.c.h` | generated | — | Section 23 |
| 20 | `Objects/typevarobject.c` | source | Section 6, Section 7, Section 8, Section 23 | — |
| 21 | `Parser/Python.asdl` | source | Section 24 | — |
| 22 | `Parser/parser.c` | generated | — | Section 24 |
| 23 | `Python/Python-ast.c` | generated | — | Section 24 |
| 24 | `Python/ast.c` | source | Section 24 | — |
| 25 | `Python/compile.c` | source | Section 8, Section 19, Section 24 | — |
| 26 | `Python/intrinsics.c` | source | Section 24 | — |
| 27 | `Python/symtable.c` | source | Section 24 | — |
| 28 | `Tools/c-analyzer/cpython/globals-to-fix.tsv` | data | — | Section 24 |

---

## Section 5: Default Ordering and Subscription Rules
*Path: Specification > Default Ordering and Subscription Rules*
*Classification: Implementable*

> The order for defaults should follow the standard function parameter
> rules, so a type parameter with no `default` cannot follow one with
> a `default` value. Doing so should ideally raise a `TypeError` in
> `typing._GenericAlias`/`types.GenericAlias`, and a type checker
> should flag this as an error.
>
> ```
> DefaultStrT = TypeVar("DefaultStrT", default=str)
> DefaultIntT = TypeVar("DefaultIntT", default=int)
> DefaultBoolT = TypeVar("DefaultBoolT", default=bool)
> T = TypeVar("T")
> T2 = TypeVar("T2")
>
> class NonDefaultFollowsDefault(Generic[DefaultStrT, T]): ...  # Invalid: non-default TypeVars cannot follow ones with defaults
>
> class NoNonDefaults(Generic[DefaultStrT, DefaultIntT]): ...
>
> (
>     NoNoneDefaults ==
>     NoNoneDefaults[str] ==
>     NoNoneDefaults[str, int]
> )  # All valid
>
> class OneDefault(Generic[T, DefaultBoolT]): ...
>
> OneDefault[float] == OneDefault[float, bool]  # Valid
> reveal_type(OneDefault)          # type is type[OneDefault[T, DefaultBoolT = bool]]
> reveal_type(OneDefault[float]()) # type is OneDefault[float, bool]
>
> class AllTheDefaults(Generic[T1, T2, DefaultStrT, DefaultIntT, DefaultBoolT]): ...
>
> reveal_type(AllTheDefaults)                  # type is type[AllTheDefaults[T1, T2, DefaultStrT = str, DefaultIntT = int, DefaultBoolT = bool]]
> reveal_type(AllTheDefaults[int, complex]())  # type is AllTheDefaults[int, complex, str, int, bool]
> AllTheDefaults[int]  # Invalid: expected 2 arguments to AllTheDefaults
> (
>     AllTheDefaults[int, complex] ==
>     AllTheDefaults[int, complex, str] ==
>     AllTheDefaults[int, complex, str, int] ==
>     AllTheDefaults[int, complex, str, int, bool]
> )  # All valid
> ```
> With the new Python 3.12 syntax for generics (introduced by PEP 695), this can
> be enforced at compile time:
>
> ```
> type Alias[DefaultT = int, T] = tuple[DefaultT, T]  # SyntaxError: non-default TypeVars cannot follow ones with defaults
>
> def generic_func[DefaultT = int, T](x: DefaultT, y: T) -> None: ...  # SyntaxError: non-default TypeVars cannot follow ones with defaults
>
> class GenericClass[DefaultT = int, T]: ...  # SyntaxError: non-default TypeVars cannot follow ones with defaults
> ```

#### Requirement Summary
Type parameters without defaults cannot follow type parameters with defaults. At runtime `_collect_parameters()` must raise `TypeError` for this ordering violation, and `_check_generic_specialization()` must allow omitting arguments for parameters that have defaults. The PEP 695 syntax must enforce this at compile time as a `SyntaxError`.

**File proportion:** 1/28 files mapped (3.6%) + 2/28 files associated (7.1%) = 3/28 accounted (10.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/typing.py` | Modified | +71 / -24 | `_GenericAlias`, `_SpecialGenericAlias` | `_collect_parameters`, `_check_generic_specialization`, `_generic_class_getitem`, `_GenericAlias.__getitem__`, `_SpecialGenericAlias.__getitem__` |

#### Modification Summary
- **`Lib/typing.py`**: Adds ordering validation in `_collect_parameters()` that raises `TypeError` when a non-default type parameter follows one with a default, or when a defaulted `TypeVar` follows a `TypeVarTuple`. Rewrites `_check_generic` as `_check_generic_specialization()` to allow fewer arguments than parameters when the remaining parameters have defaults. `_generic_class_getitem` (parameter renamed `params` → `args`) and the `_GenericAlias.__getitem__` / `_SpecialGenericAlias.__getitem__` entry points route subscription through the new default-aware checks.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_typing.py` | Modified | +189 / -1 | Tests for ordering enforcement, subscription with defaults, specialization of TypeVar/ParamSpec/TypeVarTuple defaults, and NoDefault sentinel | — | — |
| `Lib/test/test_type_params.py` | Modified | +113 / -1 | Tests subscription default-ordering rules via the PEP 695 syntax (`class Foo[T = str]: ...`) for ordering errors and default-aware specialisation | — | — |

---

## Section 6: `ParamSpec` Defaults
*Path: Specification > `ParamSpec` Defaults*
*Classification: Implementable*

> `ParamSpec` defaults are defined using the same syntax as
> `TypeVar` \ s but use a `list` of types or an ellipsis
> literal "`...`" or another in-scope `ParamSpec` (see `Scoping Rules`_).
>
> ```
> DefaultP = ParamSpec("DefaultP", default=[str, int])
>
> class Foo(Generic[DefaultP]): ...
>
> reveal_type(Foo)                  # type is type[Foo[DefaultP = [str, int]]]
> reveal_type(Foo())                # type is Foo[[str, int]]
> reveal_type(Foo[[bool, bool]]())  # type is Foo[[bool, bool]]
> ```

#### Requirement Summary
`ParamSpec` must accept a `default` keyword argument (a list of types, an ellipsis literal, or another in-scope `ParamSpec`). The `__default__` attribute and `has_default()` method must work for `ParamSpec` instances. The C-level `paramspecobject` struct must include a `default_value` field, and the Python-level `ParamSpec` class must expose the `__default__` property with lazy evaluation support.

**File proportion:** 2/28 files mapped (7.1%) + 1/28 files associated (3.6%) = 3/28 accounted (10.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/typevarobject.c` | Modified | +313 / -14 | — | `paramspec_default`, `paramspec_has_default_impl`, `paramspec_new_impl`, `paramspec_alloc`, `paramspec_dealloc`, `paramspec_traverse`, `paramspec_clear`, `_Py_make_paramspec` |
| `Lib/typing.py` | Modified | +71 / -24 | — | `_paramspec_prepare_subst` |

#### Modification Summary
- **`Objects/typevarobject.c`**: Implements the `paramspecobject` C struct with a `default_value` field and an `evaluate_default` callback for lazy evaluation. `paramspec_default`/`paramspec_has_default_impl` expose `__default__` and `has_default()`; `paramspec_new_impl`/`paramspec_alloc` (with `paramspec_dealloc`/`paramspec_traverse`/`paramspec_clear` lifecycle hooks and the `_Py_make_paramspec` helper) accept the `default` keyword argument via Argument Clinic and own the default field.
- **`Lib/typing.py`**: `_paramspec_prepare_subst` fills in default values for the pure-Python `ParamSpec` when type arguments are missing during generic subscription.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_typing.py` | Modified | +189 / -1 | Tests `ParamSpec` `default`/`__default__`/`has_default()` and ParamSpec substitution with defaults | — | — |

---

## Section 7: `TypeVarTuple` Defaults
*Path: Specification > `TypeVarTuple` Defaults*
*Classification: Implementable*

> `TypeVarTuple` defaults are defined using the same syntax as
> `TypeVar` \ s but use an unpacked tuple of types instead of a single type
> or another in-scope `TypeVarTuple` (see `Scoping Rules`_).
>
> ```
> DefaultTs = TypeVarTuple("DefaultTs", default=Unpack[tuple[str, int]])
>
> class Foo(Generic[*DefaultTs]): ...
>
> reveal_type(Foo)               # type is type[Foo[DefaultTs = *tuple[str, int]]]
> reveal_type(Foo())             # type is Foo[str, int]
> reveal_type(Foo[int, bool]())  # type is Foo[int, bool]
> ```

#### Requirement Summary
`TypeVarTuple` must accept a `default` keyword argument (an unpacked tuple of types or another in-scope `TypeVarTuple`). The `__default__` attribute and `has_default()` method must work for `TypeVarTuple` instances. The C-level `typevartupleobject` struct must include a `default_value` field, and the Python-level `TypeVarTuple` class must expose the `__default__` property with lazy evaluation support.

**File proportion:** 2/28 files mapped (7.1%) + 1/28 files associated (3.6%) = 3/28 accounted (10.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/typevarobject.c` | Modified | +313 / -14 | — | `typevartuple_default`, `typevartuple_has_default_impl`, `typevartuple_impl`, `typevartuple_alloc`, `typevartuple_dealloc`, `typevartuple_traverse`, `typevartuple_clear`, `_Py_make_typevartuple` |
| `Lib/typing.py` | Modified | +71 / -24 | — | `_typevartuple_prepare_subst` |

#### Modification Summary
- **`Objects/typevarobject.c`**: Implements the `typevartupleobject` C struct with a `default_value` field and an `evaluate_default` callback for lazy evaluation. `typevartuple_default`/`typevartuple_has_default_impl` expose `__default__` and `has_default()`; `typevartuple_impl`/`typevartuple_alloc` (with `typevartuple_dealloc`/`typevartuple_traverse`/`typevartuple_clear` lifecycle and the `_Py_make_typevartuple` helper) accept the `default` keyword via Argument Clinic and own the default field.
- **`Lib/typing.py`**: `_typevartuple_prepare_subst` fills in default values for the pure-Python `TypeVarTuple` when type arguments are missing during generic subscription.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_typing.py` | Modified | +189 / -1 | Tests `TypeVarTuple` `default`/`__default__`/`has_default()` and TypeVarTuple substitution with defaults | — | — |

---

## Section 8: Using Another Type Parameter as `default`
*Path: Specification > Using Another Type Parameter as `default`*
*Classification: Implementable*

> This allows for a value to be used again when the type parameter to a
> generic is missing but another type parameter is specified.
>
> To use another type parameter as a default the `default` and the
> type parameter must be the same type (a `TypeVar`'s default must be
> a `TypeVar`, etc.).
>
> [This could be used on builtins.slice](https://github.com/python/typing/issues/159)
> where the `start` parameter should default to `int`, `stop`
> default to the type of `start` and step default to `int | None`.
>
> ```
> StartT = TypeVar("StartT", default=int)
> StopT = TypeVar("StopT", default=StartT)
> StepT = TypeVar("StepT", default=int | None)
>
> class slice(Generic[StartT, StopT, StepT]): ...
>
> reveal_type(slice)  # type is type[slice[StartT = int, StopT = StartT, StepT = int | None]]
> reveal_type(slice())                        # type is slice[int, int, int | None]
> reveal_type(slice[str]())                   # type is slice[str, str, int | None]
> reveal_type(slice[str, bool, timedelta]())  # type is slice[str, bool, timedelta]
>
> T2 = TypeVar("T2", default=DefaultStrT)
>
> class Foo(Generic[DefaultStrT, T2]):
>     def __init__(self, a: DefaultStrT, b: T2) -> None: ...
>
> reveal_type(Foo(1, ""))  # type is Foo[int, str]
> Foo[int](1, "")          # Invalid: Foo[int, str] cannot be assigned to self: Foo[int, int] in Foo.__init__
> Foo[int]("", 1)          # Invalid: Foo[str, int] cannot be assigned to self: Foo[int, int] in Foo.__init__
> ```
> When using a type parameter as the default to another type parameter, the
> following rules apply, where `T1` is the default for `T2`.

#### Requirement Summary
When one type parameter is used as the `default` of another, the default must be lazily evaluated so that the referenced type parameter is resolved at subscription time rather than at definition time. The C-level `_Py_set_typeparam_default` function must support setting a lazily-evaluated callback that resolves cross-referenced defaults. The compiler must generate bytecode that wraps such defaults in annotation scopes for deferred evaluation.

**File proportion:** 2/28 files mapped (7.1%) + 1/28 files associated (3.6%) = 3/28 accounted (10.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/typevarobject.c` | Modified | +313 / -14 | — | `_Py_set_typeparam_default`, `typevar_default` |
| `Python/compile.c` | Modified | +75 / -14 | `compiler` | `compiler_type_param_bound_or_default`, `compiler.compiler_type_param_bound_or_default` |

#### Modification Summary
- **`Objects/typevarobject.c`**: Implements `_Py_set_typeparam_default()` which stores a callable for lazy evaluation of type parameter defaults. The `typevar_default`, `paramspec_default`, and `typevartuple_default` getters on `TypeVar`, `ParamSpec`, and `TypeVarTuple` invoke this callable on first access, caching the result. This mechanism enables cross-referenced defaults (e.g., `StopT = TypeVar("StopT", default=StartT)`) to be resolved in the correct scope.
- **`Python/compile.c`**: Generates bytecode that compiles type parameter default expressions in their own annotation scopes via `compiler_type_param_bound_or_default()`. When a default is present, emits `CALL_INTRINSIC_2 INTRINSIC_SET_TYPEPARAM_DEFAULT` from `compiler_type_params` to attach the lazy evaluation callback to the type parameter object.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_params.py` | Modified | +113 / -1 | Tests lazy evaluation of cross-referenced type-parameter defaults (e.g., `StopT = TypeVar("StopT", default=StartT)`) | — | — |

---

## Section 19: Defaults following `TypeVarTuple`
*Path: Specification > Defaults following `TypeVarTuple`*
*Classification: Implementable*

> A `TypeVar` that immediately follows a `TypeVarTuple` is not allowed
> to have a default, because it would be ambiguous whether a type argument
> should be bound to the `TypeVarTuple` or the defaulted `TypeVar`.
>
> ```
> Ts = TypeVarTuple("Ts")
> T = TypeVar("T", default=bool)
>
> class Foo(Generic[Ts, T]): ...  # Type checker error
>
> ## Could be reasonably interpreted as either Ts = (int, str, float), T = bool
> ## or Ts = (int, str), T = float
> Foo[int, str, float]
> ```

#### Requirement Summary
A `TypeVar` with a default must not immediately follow a `TypeVarTuple` in PEP 695 syntax, as this creates ambiguity during subscription. The compiler must raise a `SyntaxError` for this case. A `ParamSpec` with a default following a `TypeVarTuple` is permitted since there is no ambiguity. The grammar must support the syntax that enables this error detection.

**File proportion:** 2/28 files mapped (7.1%) + 1/28 files associated (3.6%) = 3/28 accounted (10.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/compile.c` | Modified | +75 / -14 | — | `compiler_type_params` |
| `Grammar/python.gram` | Modified | +7 / -3 | — | — |

#### Modification Summary
- **`Python/compile.c`**: `compiler_type_params` tracks whether the previous type parameter was a `TypeVarTuple` (`seen_typevartuplestar`) and whether a default has been seen (`seen_default`). When a `TypeVar` with a default immediately follows a `TypeVarTuple`, emits `SyntaxError: TypeVars with defaults cannot immediately follow TypeVarTuple`. This enforcement occurs during compilation of type parameter lists.
- **`Grammar/python.gram`**: Adds `type_param_default` and `type_param_starred_default` productions to the grammar, enabling the parser to recognize default values on all type parameter kinds. This grammar structure is what allows the compiler to detect and reject the invalid TypeVar-after-TypeVarTuple-with-default pattern.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_params.py` | Modified | +113 / -1 | Tests the `SyntaxError` raised when a `TypeVar` with a default immediately follows a `TypeVarTuple` | — | — |

---

## Section 23: Implementation
*Path: Implementation*
*Classification: Implementable*

> At runtime, this would involve the following changes to the `typing`
> module.
>
> - The classes `TypeVar`, `ParamSpec`, and `TypeVarTuple` should
>   expose the type passed to `default`. This would be available as
>   a `__default__` attribute, which would be `None` if no argument
>   is passed and `NoneType` if `default=None`.
>
> The following changes would be required to both `GenericAlias`\ es:
>
> -  logic to determine the defaults required for a subscription.
> -  ideally, logic to determine if subscription (like
>    `Generic[T, DefaultT]`) would be valid.
>
> The grammar for type parameter lists would need to be updated to
> allow defaults; see below.
>
> A reference implementation of the runtime changes can be found at
> https://github.com/Gobot1234/cpython/tree/pep-696
>
> A reference implementation of the type checker can be found at
> https://github.com/Gobot1234/mypy/tree/TypeVar-defaults
>
> Pyright currently supports this functionality.

#### Requirement Summary
At runtime, `TypeVar`, `ParamSpec`, and `TypeVarTuple` must expose a `__default__` attribute containing the default type (or a sentinel when no default is provided). A `NoDefault` sentinel object must be introduced. Each type parameter class must also provide a `has_default()` method. The `default` keyword argument must be accepted by all three constructors.

**File proportion:** 3/28 files mapped (10.7%) + 6/28 files associated (21.4%) = 9/28 accounted (32.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_typevarobject.h` | Modified | +2 / -0 | — | — |
| `Modules/_typingmodule.c` | Modified | +3 / -0 | — | `_typing_exec` |
| `Objects/typevarobject.c` | Modified | +313 / -14 | — | `NoDefault_repr`, `NoDefault_reduce`, `nodefault_new`, `nodefault_dealloc`, `typevar_dealloc`, `typevar_traverse`, `typevar_clear`, `typevar_alloc`, `typevar_new_impl`, `typevar_typing_prepare_subst_impl`, `typevar_has_default_impl`, `_Py_make_typevar` |

#### Modification Summary
- **`Include/internal/pycore_typevarobject.h`**: Declares `_Py_set_typeparam_default()` function and `_Py_NoDefaultStruct` global for the `NoDefault` singleton.
- **`Modules/_typingmodule.c`**: `_typing_exec` exports the `NoDefault` singleton object to the `_typing` C extension module.
- **`Objects/typevarobject.c`**: Implements the `NoDefault` sentinel type (`NoDefault_repr`, `NoDefault_reduce`, `nodefault_new`, `nodefault_dealloc`) and singleton (`_Py_NoDefaultStruct`). Adds `default_value` and `evaluate_default` fields to the `typevarobject` C struct: `typevar_alloc` allocates the field, `typevar_dealloc`/`typevar_traverse`/`typevar_clear` manage its GC lifetime, `typevar_new_impl` (with the `_Py_make_typevar` helper) accepts the `default` keyword via Argument Clinic, `typevar_has_default_impl` exposes `has_default()`, and `typevar_typing_prepare_subst_impl` implements `__typing_prepare_subst__` to fill in defaults during subscription.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Objects/clinic/typevarobject.c.h` | Modified | +137 / -33 | Regenerated Argument Clinic output for `TypeVar.__new__`, `ParamSpec.__new__`, and `TypeVarTuple.__new__` accepting the new `default` keyword; generated artifact, not direct implementation | — | — |
| `Lib/test/test_type_params.py` | Modified | +113 / -1 | Tests `TypeVar.__default__`/`has_default()` exposure, the `NoDefault` sentinel, and `default` keyword acceptance — Section 22's runtime API surface | — | — |
| `Lib/test/test_typing.py` | Modified | +189 / -1 | Tests `__default__`/`has_default()` and the `NoDefault` sentinel via the public `typing` API | — | — |
| `Doc/library/typing.rst` | Modified | +79 / -3 | Reference documentation for the new `__default__`/`has_default()` API and `NoDefault` sentinel; PEP 696 does not specify documentation deliverables | — | — |
| `Doc/whatsnew/3.13.rst` | Modified | +6 / -0 | Release-notes documentation for the PEP 696 feature; doc-only support | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2024-02-29-18-55-45.gh-issue-116129.wsFnIq.rst` | Added | +2 / -0 | NEWS entry for the feature; doc-only support | — | — |

---

## Section 24: Grammar changes
*Path: Implementation > Grammar changes*
*Classification: Implementable*

> The syntax added in PEP 695 will be extended to introduce a way
> to specify defaults for type parameters using the "=" operator inside
> of the square brackets like so:
>
> ```
> ## TypeVars
> class Foo[T = str]: ...
>
> ## ParamSpecs
> class Baz[**P = [int, str]]: ...
>
> ## TypeVarTuples
> class Qux[*Ts = *tuple[int, bool]]: ...
>
> ## TypeAliases
> type Foo[T, U = str] = Bar[T, U]
> type Baz[**P = [int, str]] = Spam[**P]
> type Qux[*Ts = *tuple[str]] = Ham[*Ts]
> type Rab[U, T = str] = Bar[T, U]
> ```
> `Similarly to the bound for a type parameter <695-scoping-behavior>`,
> defaults should be lazily evaluated, with the same scoping rules to
> avoid the unnecessary usage of quotes around them.
>
> This functionality was included in the initial draft of PEP 695 but
> was removed due to scope creep.
>
> The following changes would be made to the grammar:
>
> ```
> type_param:
>     | a=NAME b=[type_param_bound] d=[type_param_default]
>     | a=NAME c=[type_param_constraint] d=[type_param_default]
>     | '*' a=NAME d=[type_param_default]
>     | '**' a=NAME d=[type_param_default]
>
> type_param_default:
>     | '=' e=expression
>     | '=' e=starred_expression
> ```
> The compiler would enforce that type parameters without defaults cannot
> follow type parameters with defaults and that `TypeVar`\ s with defaults
> cannot immediately follow `TypeVarTuple`\ s.

#### Requirement Summary
The PEP 695 type parameter syntax is extended with `= expression` for specifying defaults. The grammar adds `type_param_default` and `type_param_starred_default` productions. The AST gains `default_value` fields on `TypeVar`, `ParamSpec`, and `TypeVarTuple` nodes. Defaults are lazily evaluated in annotation scopes. The compiler enforces that non-default type parameters cannot follow defaulted ones.

**File proportion:** 8/28 files mapped (28.6%) + 11/28 files associated (39.3%) = 19/28 accounted (67.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +7 / -3 | — | — |
| `Include/internal/pycore_intrinsics.h` | Modified | +2 / -1 | — | — |
| `Lib/ast.py` | Modified | +9 / -0 | `_Unparser` | `_Unparser.visit_TypeVar`, `_Unparser.visit_TypeVarTuple`, `_Unparser.visit_ParamSpec` |
| `Parser/Python.asdl` | Modified | +3 / -3 | — | — |
| `Python/ast.c` | Modified | +9 / -3 | — | `validate_typeparam` |
| `Python/compile.c` | Modified | +75 / -14 | — | — |
| `Python/intrinsics.c` | Modified | +1 / -0 | — | — |
| `Python/symtable.c` | Modified | +44 / -15 | `symtable` | `symtable_visit_type_param_bound_or_default`, `symtable.symtable_visit_type_param_bound_or_default`, `symtable_visit_type_param` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds `type_param_default` (`'=' expression`) and `type_param_starred_default` (`'=' star_expression`) productions with `CHECK_VERSION(13, ...)` guards. Updates `type_param` alternatives so `TypeVar` gains an optional `[type_param_default]`, `TypeVarTuple` gains an optional `[type_param_starred_default]`, and `ParamSpec` gains an optional `[type_param_default]`.
- **`Include/internal/pycore_intrinsics.h`**: Defines `INTRINSIC_SET_TYPEPARAM_DEFAULT` (value 5) and bumps `MAX_INTRINSIC_2` from 4 to 5.
- **`Lib/ast.py`**: Extends the AST unparser via `_Unparser.visit_TypeVar`, `_Unparser.visit_TypeVarTuple`, and `_Unparser.visit_ParamSpec` to emit `= <default>` after type parameter names/bounds.
- **`Parser/Python.asdl`**: Adds `expr? default_value` field to all three type parameter AST node types: `TypeVar`, `ParamSpec`, and `TypeVarTuple`.
- **`Python/ast.c`**: `validate_typeparam` validates `default_value` expressions on `TypeVar`, `ParamSpec`, and `TypeVarTuple` AST nodes — direct AST-validation contribution to the grammar-change requirement.
- **`Python/compile.c`**: The compile-side default-handling is implemented by `compiler_type_param_bound_or_default` (owned by Section 8) and `compiler_type_params` (owned by Section 19); this Section 24 row carries `—` to preserve `(file, class, function)` uniqueness. The contribution here is the grammar-change narrative that ties those compile-side scopes to the new `type_param_default` production.
- **`Python/intrinsics.c`**: Registers `_Py_set_typeparam_default` as the handler for `INTRINSIC_SET_TYPEPARAM_DEFAULT`.
- **`Python/symtable.c`**: `symtable_visit_type_param_bound_or_default` (extracted helper, exposed as both module-level and `symtable.symtable_visit_type_param_bound_or_default`) handles default-value scoping; `symtable_visit_type_param` visits `default_value` for TypeVar, ParamSpec, and TypeVarTuple with unique symtable keys — direct default-expression scoping for the grammar change.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +548 / -443 | Regenerated parser tables for the `type_param_default`/`type_param_starred_default` productions; generated artifact, not direct implementation | — | — |
| `Tools/c-analyzer/cpython/globals-to-fix.tsv` | Modified | +2 / -0 | Analyzer metadata for the new `_Py_NoDefaultStruct` and `_PyNoDefault_Type` globals; consistency-only support | — | — |
| `Doc/library/ast.rst` | Modified | +38 / -14 | Reference documentation for the new `default_value` AST field on `TypeVar`/`ParamSpec`/`TypeVarTuple`; PEP 696 does not specify documentation deliverables | — | — |
| `Doc/reference/compound_stmts.rst` | Modified | +23 / -8 | Documents the grammar/syntax change; doc-only support | — | — |
| `Doc/reference/executionmodel.rst` | Modified | +6 / -2 | Documents annotation-scope behavior for defaults; doc-only support | — | — |
| `Include/internal/pycore_ast.h` | Modified | +12 / -8 | Regenerated from ASDL; adds `default_value` field to C AST structs | — | — |
| `Include/internal/pycore_ast_state.h` | Modified | +1 / -0 | Regenerated from ASDL; adds `default_value` identifier to AST state | — | — |
| `Lib/test/test_ast.py` | Modified | +30 / -12 | Tests parsing of type parameter defaults and feature version gating | — | — |
| `Lib/test/test_type_params.py` | Modified | +113 / -1 | Tests default values on functions, classes, type aliases; lazy evaluation; ordering errors; symtable key regression | — | — |
| `Lib/test/test_unparse.py` | Modified | +42 / -0 | Tests round-trip unparsing of type parameter defaults | — | — |
| `Python/Python-ast.c` | Modified | +157 / -21 | Regenerated from ASDL; adds `default_value` handling to AST construction, marshalling, and annotation code | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
