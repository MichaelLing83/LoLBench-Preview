# CPython - PEP-695: Type Parameter Syntax

**PR:** https://github.com/python/cpython/pull/103764
**Requirement Doc:** https://peps.python.org/pep-0695/

## Matching Statistics
- **Requirement Doc Coverage:** 15/15 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 23/56 files mapped (41.1%) + 33/56 files associated (58.9%) = 56/56 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | Abstract | No | N/A | knowledge |
| 2 | Motivation | No | N/A | contextual |
| 3 | Motivation > Points of Confusion | No | N/A | knowledge |
| 4 | Summary Examples | No | N/A | contextual |
| 5 | Specification | No | N/A | knowledge |
| 6 | Specification > Type Parameter Declarations | Yes | Yes | implementation |
| 7 | Specification > Upper Bound Specification | Yes | Yes | implementation |
| 8 | Specification > Constrained Type Specification | Yes | Yes | implementation |
| 9 | Specification > Runtime Representation of Bounds and Constraints | Yes | Yes | implementation |
| 10 | Specification > Generic Type Alias | Yes | Yes | implementation |
| 11 | Specification > Runtime Type Alias Class | Yes | Yes | implementation |
| 12 | Specification > Type Parameter Scopes | Yes | Yes | implementation |
| 13 | Specification > Accessing Type Parameters at Runtime | Yes | Yes | implementation |
| 14 | Specification > Variance Inference | No | N/A | knowledge |
| 15 | Specification > Auto Variance For TypeVar | Yes | Yes | implementation |
| 16 | Specification > Compatibility with Traditional TypeVars | Yes | Yes | implementation |
| 17 | Runtime Implementation | No | N/A | knowledge |
| 18 | Runtime Implementation > Grammar Changes | Yes | Yes | implementation |
| 19 | Runtime Implementation > AST Changes | Yes | Yes | implementation |
| 20 | Runtime Implementation > Lazy Evaluation | Yes | Yes | implementation |
| 21 | Runtime Implementation > Scoping Behavior | Yes | Yes | implementation |
| 22 | Runtime Implementation > Library Changes | Yes | Yes | implementation |
| 23 | Reference Implementation | No | N/A | process |
| 24 | Rejected Ideas | No | N/A | contextual |
| 25 | Rejected Ideas > Prefix Clause | No | N/A | knowledge |
| 26 | Rejected Ideas > Angle Brackets | No | N/A | knowledge |
| 27 | Rejected Ideas > Bounds Syntax | No | N/A | contextual |
| 28 | Rejected Ideas > Explicit Variance | No | N/A | knowledge |
| 29 | Rejected Ideas > Name Mangling | No | N/A | knowledge |
| 30 | Appendix A: Survey of Type Parameter Syntax | No | N/A | process |
| 31 | Appendix A: Survey of Type Parameter Syntax > C++ | No | N/A | contextual |
| 32 | Appendix A: Survey of Type Parameter Syntax > Java | No | N/A | contextual |
| 33 | Appendix A: Survey of Type Parameter Syntax > TypeScript | No | N/A | contextual |
| 34 | Appendix A: Survey of Type Parameter Syntax > Scala | No | N/A | contextual |
| 35 | Appendix A: Survey of Type Parameter Syntax > Swift | No | N/A | contextual |
| 36 | Appendix A: Survey of Type Parameter Syntax > Rust | No | N/A | contextual |
| 37 | Appendix A: Survey of Type Parameter Syntax > Kotlin | No | N/A | contextual |
| 38 | Appendix A: Survey of Type Parameter Syntax > Julia | No | N/A | contextual |
| 39 | Appendix A: Survey of Type Parameter Syntax > Dart | No | N/A | contextual |
| 40 | Appendix A: Survey of Type Parameter Syntax > Summary | No | N/A | knowledge |
| 41 | Acknowledgements | No | N/A | process |
| 42 | Copyright | No | N/A | process |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/ast.rst` | documentation | — | Section 19 |
| 2 | `Grammar/python.gram` | source | Section 6, Section 10, Section 18 | — |
| 3 | `Include/cpython/funcobject.h` | source | Section 13 | — |
| 4 | `Include/internal/pycore_ast.h` | generated | — | Section 19 |
| 5 | `Include/internal/pycore_ast_state.h` | generated | — | Section 19 |
| 6 | `Include/internal/pycore_function.h` | source | Section 13 | — |
| 7 | `Include/internal/pycore_global_objects.h` | source | — | Section 22 |
| 8 | `Include/internal/pycore_global_objects_fini_generated.h` | generated | — | Section 22 |
| 9 | `Include/internal/pycore_global_strings.h` | generated | — | Section 22 |
| 10 | `Include/internal/pycore_intrinsics.h` | source | Section 20 | — |
| 11 | `Include/internal/pycore_opcode.h` | generated | — | Section 20 |
| 12 | `Include/internal/pycore_runtime_init_generated.h` | generated | — | Section 22 |
| 13 | `Include/internal/pycore_symtable.h` | source | Section 6, Section 12 | — |
| 14 | `Include/internal/pycore_typevarobject.h` | source | Section 7, Section 8 | — |
| 15 | `Include/internal/pycore_unicodeobject_generated.h` | generated | — | Section 22 |
| 16 | `Include/opcode.h` | generated | — | Section 20 |
| 17 | `Lib/ast.py` | source | Section 19 | — |
| 18 | `Lib/importlib/_bootstrap_external.py` | source | — | Section 18 |
| 19 | `Lib/keyword.py` | source | Section 10, Section 18 | — |
| 20 | `Lib/opcode.py` | source | — | Section 20, Section 21 |
| 21 | `Lib/test/support/__init__.py` | test | — | Section 6 |
| 22 | `Lib/test/test_ast.py` | test | — | Section 19 |
| 23 | `Lib/test/test_keyword.py` | test | — | Section 18 |
| 24 | `Lib/test/test_sys.py` | test | — | Section 22 |
| 25 | `Lib/test/test_type_aliases.py` | test | — | Section 10, Section 11, Section 20, Section 21 |
| 26 | `Lib/test/test_type_params.py` | test | — | Section 6, Section 7, Section 8, Section 9, Section 10, Section 11, Section 12, Section 13, Section 20, Section 21 |
| 27 | `Lib/test/test_typing.py` | test | — | Section 15 |
| 28 | `Lib/typing.py` | source | Section 11, Section 15, Section 16, Section 22 | — |
| 29 | `Makefile.pre.in` | build | — | Section 22 |
| 30 | `Misc/NEWS.d/next/Core and Builtins/2023-04-25-08-43-11.gh-issue-103763.ZLBZk1.rst` | documentation | — | Section 6 |
| 31 | `Modules/Setup.bootstrap.in` | build | — | Section 22 |
| 32 | `Modules/Setup.stdlib.in` | build | — | Section 22 |
| 33 | `Modules/_typingmodule.c` | source | Section 22 | — |
| 34 | `Objects/clinic/typevarobject.c.h` | generated | — | Section 7, Section 8 |
| 35 | `Objects/funcobject.c` | source | Section 13 | — |
| 36 | `Objects/object.c` | source | Section 22 | — |
| 37 | `Objects/typeobject.c` | source | Section 13, Section 22 | — |
| 38 | `Objects/typevarobject.c` | source | Section 7, Section 8, Section 9, Section 10, Section 11, Section 13, Section 15, Section 20, Section 22 | — |
| 39 | `Objects/unionobject.c` | source | Section 22 | — |
| 40 | `PCbuild/_freeze_module.vcxproj` | build | — | Section 22 |
| 41 | `PCbuild/pythoncore.vcxproj` | build | — | Section 22 |
| 42 | `PCbuild/pythoncore.vcxproj.filters` | build | — | Section 22 |
| 43 | `Parser/Python.asdl` | source | Section 6, Section 10, Section 18 | — |
| 44 | `Parser/action_helpers.c` | source | Section 6, Section 18 | — |
| 45 | `Parser/parser.c` | generated | — | Section 6, Section 10, Section 18 |
| 46 | `Python/Python-ast.c` | generated | — | Section 19 |
| 47 | `Python/ast.c` | source | Section 19 | — |
| 48 | `Python/ast_opt.c` | source | Section 19 | — |
| 49 | `Python/bytecodes.c` | source | Section 20 | — |
| 50 | `Python/compile.c` | source | Section 6, Section 10, Section 12, Section 13, Section 20, Section 21 | — |
| 51 | `Python/generated_cases.c.h` | generated | — | Section 20 |
| 52 | `Python/intrinsics.c` | source | Section 20 | — |
| 53 | `Python/opcode_metadata.h` | generated | — | Section 20 |
| 54 | `Python/opcode_targets.h` | generated | — | Section 20 |
| 55 | `Python/pylifecycle.c` | source | — | Section 22 |
| 56 | `Python/symtable.c` | source | Section 6, Section 12, Section 13, Section 21 | — |

---

## Section 6: Type Parameter Declarations
*Path: Specification > Type Parameter Declarations*
*Classification: Implementable*

> Here is a new syntax for declaring type parameters for generic
> classes, functions, and type aliases. The syntax adds support for
> a comma-delimited list of type parameters in square brackets after
> the name of the class, function, or type alias.
>
> Simple (non-variadic) type variables are declared with an unadorned name.
> Variadic type variables are preceded by `*` (see PEP 646 for details).
> Parameter specifications are preceded by `**` (see PEP 612 for details).
>
> ```
> ## This generic class is parameterized by a TypeVar T, a
> ## TypeVarTuple Ts, and a ParamSpec P.
> class ChildClass[T, *Ts, **P]: ...
> ```
> There is no need to include `Generic` as a base class. Its inclusion as
> a base class is implied by the presence of type parameters, and it will
> automatically be included in the `__mro__` and `__orig_bases__` attributes
> for the class. The explicit use of a `Generic` base class will result in a
> runtime error.
>
> ```
> class ClassA[T](Generic[T]): ...  # Runtime error
> ```
> A `Protocol` base class with type arguments may generate a runtime
> error. Type checkers should generate an error in this case because
> the use of type arguments is not needed, and the order of type parameters
> for the class are no longer dictated by their order in the `Protocol`
> base class.
>
> ```
> class ClassA[S, T](Protocol): ... # OK
>
> class ClassB[S, T](Protocol[S, T]): ... # Recommended type checker error
> ```
> Type parameter names within a generic class, function, or type alias must be
> unique within that same class, function, or type alias. A duplicate name
> generates a syntax error at compile time. This is consistent with the
> requirement that parameter names within a function signature must be unique.
>
> ```
> class ClassA[T, *T]: ... # Syntax Error
>
> def func1[T, **T](): ... # Syntax Error
> ```
> Class type parameter names are mangled if they begin with a double
> underscore, to avoid complicating the name lookup mechanism for names used
> within the class. However, the `__name__` attribute of the type parameter
> will hold the non-mangled name.

#### Requirement Summary
Here is a new syntax for declaring type parameters for generic classes, functions, and type aliases. The syntax adds support for a comma-delimited list of type parameters in square brackets after the name of the class, function, or type alias.


**File proportion:** 6/56 files mapped (10.7%) + 4/56 files associated (7.1%) = 10/56 accounted (17.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +40 / -6 | — | — |
| `Include/internal/pycore_symtable.h` | Modified | +18 / -3 | `_symtable_entry` | — |
| `Parser/Python.asdl` | Modified | +9 / -2 | — | — |
| `Parser/action_helpers.c` | Modified | +7 / -4 | — | `_PyPegen_function_def_decorators`, `_PyPegen_class_def_decorators` |
| `Python/compile.c` | Modified | +520 / -103 | `compiler_unit`, `compiler` | `compiler.compiler_function`, `compiler.compiler_function_body`, `compiler.compiler_class`, `compiler.compiler_class_body`, `compiler_function`, `compiler_function_body`, `compiler_class`, `compiler_class_body`, `compiler_set_type_params_in_class`, `compiler.compiler_set_type_params_in_class`, `compiler_return`, `compiler_visit_stmt`, `compiler_visit_expr1`, `push_inlined_comprehension_state`, `instr_sequence_next_inst`, `compute_code_flags` |
| `Python/symtable.c` | Modified | +329 / -26 | `symtable` | `ste_new`, `_PyST_IsFunctionLike`, `symtable_add_def_helper`, `symtable_visit_stmt`, `symtable_visit_expr`, `symtable_analyze`, `symtable_extend_namedexpr_scope`, `symtable_raise_if_annotation_block`, `has_kwonlydefaults` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the new `type_params` rule that captures the bracketed `[T, *Ts, **P]` declaration syntax attached to `def`, `class`, and `type` statements.
- **`Include/internal/pycore_symtable.h`**: Extends `_symtable_entry` with the flags/fields that mark a block as a type-parameter block so the symtable analyzer can recognize declared type parameters when blocks are entered.
- **`Parser/Python.asdl`**: Adds the `typeparam` sum type (`TypeVar`/`ParamSpec`/`TypeVarTuple`) and the `type_params` field on `FunctionDef`/`AsyncFunctionDef`/`ClassDef`/`TypeAlias` AST nodes that capture the declared parameters.
- **`Parser/action_helpers.c`**: Updates the parser helpers `_PyPegen_function_def_decorators` and `_PyPegen_class_def_decorators` to thread the new `type_params` list through to the produced AST node.
- **`Python/compile.c`**: Emits code for declarations carrying type parameters. The `compiler.compiler_function` / `compiler.compiler_function_body` methods (and their `compiler_function`/`compiler_function_body` helpers) extend function compilation to wrap a function in a type-parameter block when one is declared; `compiler.compiler_class` / `compiler.compiler_class_body` and `compiler_set_type_params_in_class` do the same for generic classes; `compiler_return`/`compiler_visit_stmt`/`compiler_visit_expr1`/`push_inlined_comprehension_state`/`instr_sequence_next_inst`/`compute_code_flags` are the supporting compile-pipeline tweaks the declaration path needs.
- **`Python/symtable.c`**: Recognizes the new declarations during symbol-table construction. `symtable_visit_stmt` and `symtable_visit_expr` dispatch on the new AST shapes, `symtable_add_def_helper`/`_PyST_IsFunctionLike`/`ste_new` extend block/symbol bookkeeping to model type-parameter holders, and `symtable_analyze`/`symtable_extend_namedexpr_scope`/`symtable_raise_if_annotation_block`/`has_kwonlydefaults` adapt analysis to the additional type-parameter block layer.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +2690 / -2091 | Generated parser tables from `Grammar/python.gram` recognising the new `type_params` production on `def`, `class`, and `type` statements | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2023-04-25-08-43-11.gh-issue-103763.ZLBZk1.rst` | Added | +23 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Lib/test/support/__init__.py` | Modified | — | Supporting change for the implementation | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests for section implementation | — | — |

---

## Section 7: Upper Bound Specification
*Path: Specification > Upper Bound Specification*
*Classification: Implementable*

> For a non-variadic type parameter, an "upper bound" type can be specified
> through the use of a type annotation expression. If an upper bound is
> not specified, the upper bound is assumed to be `object`.
>
> ```
> class ClassA[T: str]: ...
> ```
> The specified upper bound type must use an expression form that is allowed in
> type annotations. More complex expression forms should be flagged
> as an error by a type checker. Quoted forward references are allowed.
>
> The specified upper bound type must be concrete. An attempt to use a generic
> type should be flagged as an error by a type checker. This is consistent with
> the existing rules enforced by type checkers for a `TypeVar` constructor call.
>
> ```
> class ClassA[T: dict[str, int]]: ...  # OK
>
> class ClassB[T: "ForwardReference"]: ...  # OK
>
> class ClassC[V]:
>     class ClassD[T: dict[str, V]]: ...  # Type checker error: generic type
>
> class ClassE[T: [str, int]]: ...  # Type checker error: illegal expression form
> ```

#### Requirement Summary
For a non-variadic type parameter, an "upper bound" type can be specified through the use of a type annotation expression. If an upper bound is not specified, the upper bound is assumed to be `object`.


**File proportion:** 2/56 files mapped (3.6%) + 2/56 files associated (3.6%) = 4/56 accounted (7.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_typevarobject.h` | Added | +22 / -0 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | `Generic` | `typevar_bound` |


#### Modification Summary
- **`Include/internal/pycore_typevarobject.h`**: Declares the C TypeVar runtime helpers used by the upper-bound `T: bound` syntax, including the constructors and bound accessors invoked by the compiler/intrinsic for new-style type parameters.
- **`Objects/typevarobject.c`**: Implements TypeVar's `__bound__` descriptor and lazy bound evaluation (`typevar_bound` and supporting helpers) used by `T: bound` syntax; the bound expression is stored as a callable and resolved on first access.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Objects/clinic/typevarobject.c.h` | Added | +786 / -0 | Generated Argument Clinic output for the TypeVar/ParamSpec/TypeVarTuple/TypeAlias C APIs that exposes the `bound=` keyword to Python callers | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests covering upper-bound declaration and runtime bound access | — | — |

---

## Section 8: Constrained Type Specification
*Path: Specification > Constrained Type Specification*
*Classification: Implementable*

> PEP 484 introduced the concept of a "constrained type variable" which is
> constrained to a set of two or more types. The new syntax supports this type
> of constraint through the use of a literal tuple expression that contains
> two or more types.
>
> ```
> class ClassA[AnyStr: (str, bytes)]: ...  # OK
>
> class ClassB[T: ("ForwardReference", bytes)]: ...  # OK
>
> class ClassC[T: ()]: ...  # Type checker error: two or more types required
>
> class ClassD[T: (str, )]: ...  # Type checker error: two or more types required
>
> t1 = (bytes, str)
> class ClassE[T: t1]: ...  # Type checker error: literal tuple expression required
> ```
> If the specified type is not a tuple expression or the tuple expression includes
> complex expression forms that are not allowed in a type annotation, a type
> checker should generate an error. Quoted forward references are allowed.
>
> ```
> class ClassF[T: (3, bytes)]: ...  # Type checker error: invalid expression form
> ```
> The specified constrained types must be concrete. An attempt to use a generic
> type should be flagged as an error by a type checker. This is consistent with
> the existing rules enforced by type checkers for a `TypeVar` constructor call.
>
> ```
> class ClassG[T: (list[S], str)]: ...  # Type checker error: generic type
> ```

#### Requirement Summary
:pep:`484` introduced the concept of a "constrained type variable" which is constrained to a set of two or more types. The new syntax supports this type of constraint through the use of a literal tuple expression that contains.


**File proportion:** 2/56 files mapped (3.6%) + 2/56 files associated (3.6%) = 4/56 accounted (7.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_typevarobject.h` | Added | +22 / -0 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typevar_constraints` |


#### Modification Summary
- **`Include/internal/pycore_typevarobject.h`**: Declares the TypeVar helpers used by tuple-form constraints `T: (X, Y)`, including the constructor that accepts a constraints sequence and the constraints accessor invoked from the compiler/intrinsic.
- **`Objects/typevarobject.c`**: Implements `__constraints__` lazy evaluation via `typevar_constraints`, which materializes the tuple of constraint types on first access for TypeVars built from the new tuple constraint syntax.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Objects/clinic/typevarobject.c.h` | Added | +786 / -0 | Generated Argument Clinic output exposing the `constraints=` keyword to the TypeVar/ParamSpec C APIs | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests covering tuple-form constraint declaration and runtime constraint access | — | — |

---

## Section 9: Runtime Representation of Bounds and Constraints
*Path: Specification > Runtime Representation of Bounds and Constraints*
*Classification: Implementable*

> The upper bounds and constraints of `TypeVar` objects are accessible at
> runtime through the `__bound__` and `__constraints__` attributes.
> For `TypeVar` objects defined through the new syntax, these attributes
> become lazily evaluated, as discussed under `Lazy Evaluation`_ below.

#### Requirement Summary
The upper bounds and constraints of `TypeVar` objects are accessible at runtime through the `__bound__` and `__constraints__` attributes. For `TypeVar` objects defined through the new syntax, these attributes.


**File proportion:** 1/56 files mapped (1.8%) + 1/56 files associated (1.8%) = 2/56 accounted (3.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typevar_alloc`, `typevar_dealloc`, `typevar_traverse`, `typevar_clear`, `typevar_typing_subst_impl`, `typevar_reduce_impl`, `typevar_mro_entries`, `type_check`, `caller` |

#### Modification Summary
- **`Objects/typevarobject.c`**: Implements the C `TypeVar` object that materializes the runtime representation of bounds and constraints. `typevar_alloc` constructs a TypeVar with its (possibly lazy) bound and constraints, `typevar_dealloc`/`typevar_traverse`/`typevar_clear` manage its lifecycle and GC, `typevar_typing_subst_impl` and `typevar_reduce_impl` expose substitution and pickling, `typevar_mro_entries` integrates the TypeVar with generic base resolution, and the helpers `type_check`/`caller` support evaluating bound/constraint expressions used by the runtime representation.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_params.py` | Added | — | Tests runtime `__bound__`/`__constraints__` representation behavior | — | — |

---

## Section 10: Generic Type Alias
*Path: Specification > Generic Type Alias*
*Classification: Implementable*

> We propose to introduce a new statement for declaring type aliases. Similar
> to `class` and `def` statements, a `type` statement defines a scope
> for type parameters.
>
> ```
> ## A non-generic type alias
> type IntOrStr = int | str
>
> ## A generic type alias
> type ListOrSet[T] = list[T] | set[T]
> ```
> Type aliases can refer to themselves without the use of quotes.
>
> ```
> ## A type alias that includes a forward reference
> type AnimalOrVegetable = Animal | "Vegetable"
>
> ## A generic self-referential type alias
> type RecursiveList[T] = T | list[RecursiveList[T]]
> ```
> The `type` keyword is a new soft keyword. It is interpreted as a keyword
> only in this part of the grammar. In all other locations, it is assumed to
> be an identifier name.
>
> Type parameters declared as part of a generic type alias are valid only
> when evaluating the right-hand side of the type alias.
>
> As with `typing.TypeAlias`, type checkers should restrict the right-hand
> expression to expression forms that are allowed within type annotations.
> The use of more complex expression forms (call expressions, ternary operators,
> arithmetic operators, comparison operators, etc.) should be flagged as an
> error.
>
> Type alias expressions are not allowed to use traditional type variables (i.e.
> those allocated with an explicit `TypeVar` constructor call). Type checkers
> should generate an error in this case.
>
> ```
> T = TypeVar("T")
> type MyList = list[T]  # Type checker error: traditional type variable usage
> ```
> We propose to deprecate the existing `typing.TypeAlias` introduced in
> PEP 613. The new syntax eliminates its need entirely.

#### Requirement Summary
We propose to introduce a new statement for declaring type aliases. Similar to `class` and `def` statements, a `type` statement defines a scope for type parameters.


**File proportion:** 5/56 files mapped (8.9%) + 3/56 files associated (5.4%) = 8/56 accounted (14.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +40 / -6 | — | — |
| `Lib/keyword.py` | Modified | +2 / -1 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typealias_new_impl`, `typealias_subscript`, `_Py_make_typealias` |
| `Parser/Python.asdl` | Modified | +9 / -2 | — | — |
| `Python/compile.c` | Modified | +520 / -103 | — | `compiler_typealias`, `compiler_typealias_body`, `compiler.compiler_typealias`, `compiler.compiler_typealias_body` |


#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +2690 / -2091 | Generated parser tables include the `type_alias` production for the new `type Alias[T] = ...` statement | — | — |
| `Lib/test/test_type_aliases.py` | Added | — | Tests for section implementation | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests covering generic type alias declaration with the new `type Alias[T] = ...` statement | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `type Alias[T] = value` statement production (the `type_alias` rule) to the grammar so the parser accepts the new generic-type-alias syntax.
- **`Lib/keyword.py`**: Registers `type` as a soft keyword so the lexer can recognize the `type Alias = ...` statement without breaking existing identifier usage.
- **`Objects/typevarobject.c`**: Provides the C-level constructor for the new generic type alias statement: `typealias_new_impl` builds a `TypeAliasType` with the supplied name/type parameters/value, `_Py_make_typealias` is the intrinsic entry point invoked by the compiler-emitted bytecode, and `typealias_subscript` implements `Alias[T]` subscription that yields a parameterized alias.
- **`Parser/Python.asdl`**: Declares the `TypeAlias` AST statement node holding the alias name, type parameters, and value expression that the grammar produces.
- **`Python/compile.c`**: Implements `compiler_typealias` and `compiler_typealias_body` (as both top-level functions and `compiler.compiler_typealias`/`compiler.compiler_typealias_body` methods), which emit bytecode that (i) opens a dedicated type-parameter block, (ii) builds the type parameters, (iii) lazily wraps the value expression, and (iv) calls the `_Py_make_typealias` intrinsic to create the `TypeAliasType` for the new `type` statement.

---

## Section 11: Runtime Type Alias Class
*Path: Specification > Runtime Type Alias Class*
*Classification: Implementable*

> At runtime, a `type` statement will generate an instance of
> `typing.TypeAliasType`. This class represents the type. Its attributes
> include:
>
> * `__name__` is a str representing the name of the type alias
> * `__type_params__` is a tuple of `TypeVar`, `TypeVarTuple`, or
>   `ParamSpec` objects that parameterize the type alias if it is generic
> * `__value__` is the evaluated value of the type alias
>
> All of these attributes are read-only.
>
> The value of the type alias is evaluated lazily (see `Lazy Evaluation`_ below).

#### Requirement Summary
At runtime, a `type` statement will generate an instance of `typing.TypeAliasType`. This class represents the type.


**File proportion:** 2/56 files mapped (3.6%) + 2/56 files associated (3.6%) = 4/56 accounted (7.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/typing.py` | Modified | +170 / -421 | `_BoundVarianceMixin`, `TypeVar`, `TypeVarTuple`, `ParamSpecArgs`, `ParamSpecKwargs`, `ParamSpec`, `Generic`, `NamedTupleMeta` | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typealias_dealloc`, `typealias_traverse`, `typealias_clear`, `typealias_alloc`, `typealias_repr`, `typealias_value`, `typealias_get_value`, `typealias_parameters`, `typealias_reduce_impl` |


#### Modification Summary
- **`Lib/typing.py`**: Re-exports the new `TypeAliasType` runtime class implemented in C and migrates the Python-side TypeVar/TypeVarTuple/ParamSpec/Generic skeleton classes to delegate to the C runtime, ensuring user code that imports the runtime type alias class from `typing` continues to work.
- **`Objects/typevarobject.c`**: Implements the `TypeAliasType` runtime class itself. `typealias_alloc`/`typealias_dealloc`/`typealias_traverse`/`typealias_clear` manage the instance lifecycle and GC; `typealias_repr` formats the alias's printable representation; `typealias_value` and `typealias_get_value` implement the lazily-evaluated `__value__` property that materializes the aliased type on first access; `typealias_parameters` exposes `__parameters__`; and `typealias_reduce_impl` provides the pickling reducer for the runtime class.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_aliases.py` | Added | — | Tests `TypeAliasType` runtime class behavior (`__name__`, `__value__`, `__type_params__`) | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests type-parameter exposure on the new `TypeAliasType` runtime class | — | — |

---

## Section 12: Type Parameter Scopes
*Path: Specification > Type Parameter Scopes*
*Classification: Implementable*

> When the new syntax is used, a new lexical scope is introduced, and this scope
> includes the type parameters. Type parameters can be accessed by name
> within inner scopes. As with other symbols in Python, an inner scope can
> define its own symbol that overrides an outer-scope symbol of the same name.
> This section provides a verbal description of the new scoping rules.
> The `Scoping Behavior`_ section below specifies the behavior in terms
> of a translation to near-equivalent existing Python code.
>
> Type parameters are visible to other
> type parameters declared elsewhere in the list. This allows type parameters
> to use other type parameters within their definition. While there is currently
> no use for this capability, it preserves the ability in the future to support
> upper bound expressions or type argument defaults that depend on earlier
> type parameters.
>
> A compiler error or runtime exception is generated if the definition of an
> earlier type parameter references a later type parameter even if the name is
> defined in an outer scope.
>
> ```
> ## The following generates no compiler error, but a type checker
> ## should generate an error because an upper bound type must be concrete,
> ## and `Sequence[S]` is generic. Future extensions to the type system may
> ## eliminate this limitation.
> class ClassA[S, T: Sequence[S]]: ...
>
> ## The following generates no compiler error, because the bound for `S`
> ## is lazily evaluated. However, type checkers should generate an error.
> class ClassB[S: Sequence[T], T]: ...
> ```
> A type parameter declared as part of a generic class is valid within the
> class body and inner scopes contained therein. Type parameters are also
> accessible when evaluating the argument list (base classes and any keyword
> arguments) that comprise the class definition. This allows base classes
> to be parameterized by these type parameters. Type parameters are not
> accessible outside of the class body, including class decorators.
>
> ```
> class ClassA[T](BaseClass[T], param = Foo[T]): ...  # OK
>
> print(T)  # Runtime error: 'T' is not defined
>
> @dec(Foo[T])  # Runtime error: 'T' is not defined
> class ClassA[T]: ...
> ```
> A type parameter declared as part of a generic function is valid within
> the function body and any scopes contained therein. It is also valid within
> parameter and return type annotations. Default argument values for function
> parameters are evaluated outside of this scope, so type parameters are
> not accessible in default value expressions. Likewise, type parameters are not
> in scope for function decorators.
>
> ```
> def func1[T](a: T) -> T: ...  # OK
>
> print(T)  # Runtime error: 'T' is not defined
>
> def func2[T](a = list[T]): ...  # Runtime error: 'T' is not defined
>
> @dec(list[T])  # Runtime error: 'T' is not defined
> def func3[T](): ...
> ```
> A type parameter declared as part of a generic type alias is valid within
> the type alias expression.
>
> ```
> type Alias1[K, V] = Mapping[K, V] | Sequence[K]
> ```
> Type parameter symbols defined in outer scopes cannot be bound with
> `nonlocal` statements in inner scopes.
>
> ```
> S = 0
>
> def outer1[S]():
>     S = 1
>     T = 1
>
>     def outer2[T]():
>
>         def inner1():
>             nonlocal S  # OK because it binds variable S from outer1
>             nonlocal T  # Syntax error: nonlocal binding not allowed for type parameter
>
>         def inner2():
>             global S  # OK because it binds variable S from global scope
> ```
> The lexical scope introduced by the new type parameter syntax is unlike
> traditional scopes introduced by a `def` or `class` statement. A type
> parameter scope acts more like a temporary "overlay" to the containing scope.
> The only new symbols contained
> within its symbol table are the type parameters defined using the new syntax.
> References to all other symbols are treated as though they were found within
> the containing scope. This allows base class lists (in class definitions) and
> type annotation expressions (in function definitions) to reference symbols
> defined in the containing scope.
>
> ```
> class Outer:
>     class Private:
>         pass
>
>     # If the type parameter scope was like a traditional scope,
>     # the base class 'Private' would not be accessible here.
>     class Inner[T](Private, Sequence[T]):
>         pass
>
>     # Likewise, 'Inner' would not be available in these type annotations.
>     def method1[T](self, a: Inner[T]) -> Inner[T]:
>         return a
> ```
> The compiler allows inner scopes to define a local symbol that overrides an
> outer-scoped type parameter.
>
> Consistent with the scoping rules defined in PEP 484, type checkers should
> generate an error if inner-scoped generic classes, functions, or type aliases
> reuse the same type parameter name as an outer scope.
>
> ```
> T = 0
>
> @decorator(T)  # Argument expression `T` evaluates to 0
> class ClassA[T](Sequence[T]):
>     T = 1
>
>     # All methods below should result in a type checker error
>     # "type parameter 'T' already in use" because they are using the
>     # type parameter 'T', which is already in use by the outer scope
>     # 'ClassA'.
>     def method1[T](self):
>         ...
>
>     def method2[T](self, x = T):  # Parameter 'x' gets default value of 1
>         ...
>
>     def method3[T](self, x: T):  # Parameter 'x' has type T (scoped to method3)
>         ...
> ```
> Symbols referenced in inner scopes are resolved using existing rules except
> that type parameter scopes are also considered during name resolution.
>
> ```
> T = 0
>
> ## T refers to the global variable
> print(T)  # Prints 0
>
> class Outer[T]:
>     T = 1
>
>     # T refers to the local variable scoped to class 'Outer'
>     print(T)  # Prints 1
>
>     class Inner1:
>         T = 2
>
>         # T refers to the local type variable within 'Inner1'
>         print(T)  # Prints 2
>
>         def inner_method(self):
>             # T refers to the type parameter scoped to class 'Outer';
>             # If 'Outer' did not use the new type parameter syntax,
>             # this would instead refer to the global variable 'T'
>             print(T)  # Prints 'T'
>
>     def outer_method(self):
>         T = 3
>
>         # T refers to the local variable within 'outer_method'
>         print(T)  # Prints 3
>
>         def inner_func():
>             # T refers to the variable captured from 'outer_method'
>             print(T)  # Prints 3
> ```
> When the new type parameter syntax is used for a generic class, assignment
> expressions are not allowed within the argument list for the class definition.
> Likewise, with functions that use the new type parameter syntax, assignment
> expressions are not allowed within parameter or return type annotations, nor
> are they allowed within the expression that defines a type alias, or within
> the bounds and constraints of a `TypeVar`. Similarly, `yield`, `yield from`,
> and `await` expressions are disallowed in these contexts.
>
> This restriction is necessary because expressions evaluated within the
> new lexical scope should not introduce symbols within that scope other than
> the defined type parameters, and should not affect whether the enclosing function
> is a generator or coroutine.
>
> ```
> class ClassA[T]((x := Sequence[T])): ...  # Syntax error: assignment expression not allowed
>
> def func1[T](val: (x := int)): ...  # Syntax error: assignment expression not allowed
>
> def func2[T]() -> (x := Sequence[T]): ...  # Syntax error: assignment expression not allowed
>
> type Alias1[T] = (x := list[T])  # Syntax error: assignment expression not allowed
> ```

#### Requirement Summary
When the new syntax is used, a new lexical scope is introduced, and this scope includes the type parameters. Type parameters can be accessed by name within inner scopes.


**File proportion:** 3/56 files mapped (5.4%) + 1/56 files associated (1.8%) = 4/56 accounted (7.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_symtable.h` | Modified | +18 / -3 | — | — |
| `Python/compile.c` | Modified | +520 / -103 | — | `compiler_type_params`, `compiler.compiler_type_params`, `compiler_set_qualname`, `compiler_unit.compiler_set_qualname`, `compiler_enter_scope` |
| `Python/symtable.c` | Modified | +329 / -26 | — | `symtable_enter_typeparam_block`, `symtable.symtable_enter_typeparam_block`, `symtable_visit_typeparam`, `symtable.symtable_visit_typeparam` |


#### Modification Summary
- **`Include/internal/pycore_symtable.h`**: Declares the new type-parameter block kind/flags that the symtable uses to model the dedicated lexical scope introduced by a type-parameter list.
- **`Python/compile.c`**: Builds the type-parameter scope at compile time. `compiler.compiler_type_params` / `compiler_type_params` materialize the TypeVar/ParamSpec/TypeVarTuple objects into the new scope, while `compiler.compiler_set_qualname` / `compiler_set_qualname` and `compiler_enter_scope` enter the scope and set qualified names so the enclosed function, class, or alias sees the type parameters lexically.
- **`Python/symtable.c`**: Introduces the matching symbol-table scope. `symtable_enter_typeparam_block` / `symtable.symtable_enter_typeparam_block` pushes the new block kind when a type-parameter list is encountered, and `symtable_visit_typeparam` / `symtable.symtable_visit_typeparam` records each declared `TypeVar`/`ParamSpec`/`TypeVarTuple` symbol inside that block.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_params.py` | Added | — | Tests covering the new type-parameter lexical scope semantics | — | — |

---

## Section 13: Accessing Type Parameters at Runtime
*Path: Specification > Accessing Type Parameters at Runtime*
*Classification: Implementable*

> A new attribute called `__type_params__` is available on generic classes,
> functions, and type aliases. This attribute is a tuple of the
> type parameters that parameterize the class, function, or alias.
> The tuple contains `TypeVar`, `ParamSpec`, and `TypeVarTuple` instances.
>
> Type parameters declared using the new syntax will not appear within the
> dictionary returned by `globals()` or `locals()`.

#### Requirement Summary
A new attribute called `__type_params__` is available on generic classes, functions, and type aliases. This attribute is a tuple of the type parameters that parameterize the class, function, or alias.


**File proportion:** 7/56 files mapped (12.5%) + 1/56 files associated (1.8%) = 8/56 accounted (14.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/cpython/funcobject.h` | Modified | +1 / -0 | — | — |
| `Include/internal/pycore_function.h` | Modified | +2 / -0 | — | — |
| `Objects/funcobject.c` | Modified | +27 / -0 | — | `_PyFunction_FromConstructor`, `PyFunction_NewWithQualName`, `func_get_type_params`, `_Py_set_function_type_params`, `func_clear`, `func_traverse` |
| `Objects/typeobject.c` | Modified | +45 / -2 | — | `type_get_type_params`, `type_new_copy_slots`, `type_new_set_classdictcell`, `type_new_set_attrs` |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typealias_type_params` |
| `Python/compile.c` | Modified | +520 / -103 | — | — |
| `Python/symtable.c` | Modified | +329 / -26 | — | — |

#### Modification Summary
- **`Include/cpython/funcobject.h`**: Adds the `func_type_params` slot to `PyFunctionObject` that backs the public `__type_params__` attribute on function objects.
- **`Include/internal/pycore_function.h`**: Declares `_Py_set_function_type_params`, the internal helper the compiler emits a call to in order to populate a function's `__type_params__` from inside the type-parameter scope.
- **`Objects/funcobject.c`**: Implements function-level `__type_params__`. `func_get_type_params` exposes the attribute, `_Py_set_function_type_params` installs the type-parameter tuple from the compiler-emitted bytecode, `PyFunction_NewWithQualName` and `_PyFunction_FromConstructor` initialize the slot when functions are created, and `func_traverse`/`func_clear` keep it GC-tracked.
- **`Objects/typeobject.c`**: Implements class-level `__type_params__`. `type_get_type_params` exposes the attribute, and `type_new_copy_slots` / `type_new_set_classdictcell` / `type_new_set_attrs` propagate the tuple of declared type parameters when a generic class is being constructed.
- **`Objects/typevarobject.c`**: Exposes `TypeAliasType.__type_params__` via `typealias_type_params`, returning the tuple of TypeVar/ParamSpec/TypeVarTuple parameters declared on the alias.
- **`Python/compile.c`**: Section 13's compile-side wiring — building the `__type_params__` tuple inside the type-parameter scope and emitting the call to `_Py_set_function_type_params` / class-dict-cell write — is folded into `compiler_function`/`compiler_class` (owned by Section 6) and `compiler_type_params` (owned by Section 12). This row carries `—` for Classes/Functions because every touched scope is already attributed to those sections under the `(file, class, function)` uniqueness rule; the section's contribution is the runtime-attribute wiring narrative that ties those scopes into `__type_params__` exposure.
- **`Python/symtable.c`**: Section 13's symbol-table contribution is the visibility of declared type-parameter symbols to the enclosing function/class/alias; that visibility is implemented by `symtable_enter_typeparam_block`/`symtable_visit_typeparam` owned by Section 12. This row carries `—` to preserve `(file, class, function)` uniqueness.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_type_params.py` | Added | — | Tests runtime access to `__type_params__` on generic classes, functions, and aliases | — | — |

---

## Section 15: Auto Variance For TypeVar
*Path: Specification > Auto Variance For TypeVar*
*Classification: Implementable*

> The existing `TypeVar` class constructor accepts keyword parameters named
> `covariant` and `contravariant`. If both of these are `False`, the
> type variable is assumed to be invariant. We propose to add another keyword
> parameter named `infer_variance` indicating that a type checker should use
> inference to determine whether the type variable is invariant, covariant or
> contravariant. A corresponding instance variable `__infer_variance__` can be
> accessed at runtime to determine whether the variance is inferred. Type
> variables that are implicitly allocated using the new syntax will always
> have `__infer_variance__` set to `True`.
>
> A generic class that uses the traditional syntax may include combinations of
> type variables with explicit and inferred variance.
>
> ```
> T1 = TypeVar("T1", infer_variance=True)  # Inferred variance
> T2 = TypeVar("T2")  # Invariant
> T3 = TypeVar("T3", covariant=True)  # Covariant
>
> ## A type checker should infer the variance for T1 but use the
> ## specified variance for T2 and T3.
> class ClassA(Generic[T1, T2, T3]): ...
> ```

#### Requirement Summary
The existing `TypeVar` class constructor accepts keyword parameters named `covariant` and `contravariant`. If both of these are `False`, the type variable is assumed to be invariant.


**File proportion:** 2/56 files mapped (3.6%) + 1/56 files associated (1.8%) = 3/56 accounted (5.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/typing.py` | Modified | +170 / -421 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `typevar_new_impl`, `typevar_repr` |


#### Modification Summary
- **`Lib/typing.py`**: Section 15's Python-side facade plumbs the new `infer_variance` keyword through the `TypeVar` skeleton so user code constructing a TypeVar without explicit variance ends up with auto-variance enabled. The touched class-level scopes (`_BoundVarianceMixin`, `TypeVar`) are owned by Section 11 to preserve `(file, class, function)` uniqueness; this row carries `—`.
- **`Objects/typevarobject.c`**: Implements auto-variance on the C `TypeVar`. `typevar_new_impl` validates the covariant/contravariant/infer_variance combinations the section requires (rejecting the contradictory pairs) and stores the auto-variance flag; `typevar_repr` renders the resulting variance in the TypeVar's printable form.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_typing.py` | Modified | — | Tests for section implementation | — | — |

---

## Section 16: Compatibility with Traditional TypeVars
*Path: Specification > Compatibility with Traditional TypeVars*
*Classification: Implementable*

> The existing mechanism for allocating `TypeVar`, `TypeVarTuple`, and
> `ParamSpec` is retained for backward compatibility. However, these
> "traditional" type variables should not be combined with type parameters
> allocated using the new syntax. Such a combination should be flagged as
> an error by type checkers. This is necessary because the type parameter
> order is ambiguous.
>
> It is OK to combine traditional type variables with new-style type parameters
> if the class, function, or type alias does not use the new syntax. The
> new-style type parameters must come from an outer scope in this case.
>
> ```
> K = TypeVar("K")
>
> class ClassA[V](dict[K, V]): ...  # Type checker error
>
> class ClassB[K, V](dict[K, V]): ...  # OK
>
> class ClassC[V]:
>     # The use of K and V for "method1" is OK because it uses the
>     # "traditional" generic function mechanism where type parameters
>     # are implicit. In this case V comes from an outer scope (ClassC)
>     # and K is introduced implicitly as a type parameter for "method1".
>     def method1(self, a: V, b: K) -> V | K: ...
>
>     # The use of M and K are not allowed for "method2". A type checker
>     # should generate an error in this case because this method uses the
>     # new syntax for type parameters, and all type parameters associated
>     # with the method must be explicitly declared. In this case, `K`
>     # is not declared by "method2", nor is it supplied by a new-style
>     # type parameter defined in an outer scope.
>     def method2[M](self, a: M, b: K) -> M | K: ...
> ```

#### Requirement Summary
The existing mechanism for allocating `TypeVar`, `TypeVarTuple`, and `ParamSpec` is retained for backward compatibility. However, these "traditional" type variables should not be combined with type parameters.


**File proportion:** 1/56 files mapped (1.8%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/typing.py` | Modified | +170 / -421 | — | — |

#### Modification Summary
- **`Lib/typing.py`**: Section 16's compatibility contract is implemented as a preserved-API guarantee: the existing public `TypeVar`/`TypeVarTuple`/`ParamSpec` constructors continue to work. The actual class-level changes touched by this PR (the `_BoundVarianceMixin`, `TypeVar`, `TypeVarTuple`, `ParamSpec`, `Generic` facades) are owned by Section 11 to satisfy `(file, class, function)` uniqueness, so this section's row has `—` for Classes/Functions — the compatibility contribution is the absence of breaking changes to those public constructors.

---

## Section 18: Grammar Changes
*Path: Runtime Implementation > Grammar Changes*
*Classification: Implementable*

> This PEP introduces a new soft keyword `type`. It modifies the grammar
> in the following ways:
>
> 1. Addition of optional type parameter clause in `class` and `def` statements.
>
> ```
> type_params: '[' t=type_param_seq  ']'
>
> type_param_seq: a[asdl_typeparam_seq*]=','.type_param+ [',']
>
> type_param:
>     | a=NAME b=[type_param_bound]
>     | '*' a=NAME
>     | '**' a=NAME
>
> type_param_bound: ":" e=expression
>
> ## Grammar definitions for class_def_raw and function_def_raw are modified
> ## to reference type_params as an optional syntax element. The definitions
> ## of class_def_raw and function_def_raw are simplified here for brevity.
>
> class_def_raw: 'class' n=NAME t=[type_params] ...
>
> function_def_raw: a=[ASYNC] 'def' n=NAME t=[type_params] ...
> ```
> 2. Addition of new `type` statement for defining type aliases.
>
> ```
> type_alias: "type" n=NAME t=[type_params] '=' b=expression
> ```

#### Requirement Summary
This PEP introduces a new soft keyword `type`. It modifies the grammar in the following ways: 1.


**File proportion:** 4/56 files mapped (7.1%) + 3/56 files associated (5.4%) = 7/56 accounted (12.5%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +40 / -6 | — | — |
| `Lib/keyword.py` | Modified | +2 / -1 | — | — |
| `Parser/Python.asdl` | Modified | +9 / -2 | — | — |
| `Parser/action_helpers.c` | Modified | +7 / -4 | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the new `type` soft keyword and the grammar productions for type-parameter lists and the `type` alias statement, implementing the grammar changes the PEP introduces.
- **`Lib/keyword.py`**: Lists `type` in the soft keywords table so other tooling (and the tokenizer) recognize the new keyword exactly where the grammar uses it.
- **`Parser/Python.asdl`**: Adds the AST node kinds the new grammar productions emit (`TypeAlias` statement, `TypeVar`/`ParamSpec`/`TypeVarTuple` typeparam alternatives), keeping the ASDL in sync with the grammar.
- **`Parser/action_helpers.c`**: Updates the pegen action helpers so the generated parser threads the new `type_params` field through to `FunctionDef`/`ClassDef`/`TypeAlias` constructors when the grammar matches.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +2690 / -2091 | Regenerated parser tables embodying the new soft keyword, type-parameter clause, and `type` statement productions | — | — |
| `Lib/importlib/_bootstrap_external.py` | Modified | +2 / -1 | Magic-number bump tied to the new grammar/bytecode layout | — | — |
| `Lib/test/test_keyword.py` | Modified | — | Verifies the new `type` soft keyword registration | — | — |

---

## Section 19: AST Changes
*Path: Runtime Implementation > AST Changes*
*Classification: Implementable*

> This PEP introduces a new AST node type called `TypeAlias`.
>
> ```
> TypeAlias(expr name, typeparam* typeparams, expr value)
> ```
> It also adds an AST node type that represents a type parameter.
>
> ```
> typeparam = TypeVar(identifier name, expr? bound)
>     | ParamSpec(identifier name)
>     | TypeVarTuple(identifier name)
> ```
> Bounds and constraints are represented identically in the AST. In the implementation,
> any expression that is a `Tuple` AST node is treated as a constraint, and any other
> expression is treated as a bound.
>
> It also modifies existing AST node types `FunctionDef`, `AsyncFunctionDef`
> and `ClassDef` to include an additional optional attribute called
> `typeparams` that includes a list of type parameters associated with the
> function or class.

#### Requirement Summary
This PEP introduces a new AST node type called `TypeAlias`. :: TypeAlias(expr name, typeparam* typeparams, expr value) It also adds an AST node type that represents a type parameter.


**File proportion:** 3/56 files mapped (5.4%) + 5/56 files associated (8.9%) = 8/56 accounted (14.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/ast.py` | Modified | +26 / -0 | `_Unparser` | — |
| `Python/ast.c` | Modified | +45 / -0 | `validator` | `validate_stmt`, `validate_typeparam`, `validator.validate_typeparam`, `validate_typeparams`, `validator.validate_typeparams` |
| `Python/ast_opt.c` | Modified | +24 / -0 | — | `astfold_stmt`, `astfold_typeparam` |

#### Modification Summary
- **`Lib/ast.py`**: Adds Python-side AST node classes/visitors and the `_Unparser` support for `TypeVar`, `ParamSpec`, `TypeVarTuple`, and `TypeAlias` statements.
- **`Python/ast.c`**: Adds validation for the new AST nodes (`validate_type_param`, `validate_TypeAlias`, etc.), checking the shape of bound/constraint expressions and ensuring well-formed type parameter sequences.
- **`Python/ast_opt.c`**: Threads constant folding/walks through the new AST node kinds so the optimiser visits TypeAlias and type-parameter expressions consistently with existing nodes.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Python/Python-ast.c` | Modified | +736 / -31 | Generated AST C output from `Parser/Python.asdl` providing constructor/getter/setter implementations for the new TypeVar/ParamSpec/TypeVarTuple/TypeAlias node kinds | — | — |
| `Include/internal/pycore_ast.h` | Modified | +76 / -21 | Generated AST header output (from `Parser/Python.asdl`) declaring the new TypeVar/ParamSpec/TypeVarTuple/TypeAlias node kinds and struct fields | — | — |
| `Include/internal/pycore_ast_state.h` | Modified | +7 / -0 | Generated AST-state header output registering the identifier interning slots used by the new AST node field names | — | — |
| `Doc/library/ast.rst` | Modified | +3 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Lib/test/test_ast.py` | Modified | — | Supporting change for the implementation | — | — |

---

## Section 20: Lazy Evaluation
*Path: Runtime Implementation > Lazy Evaluation*
*Classification: Implementable*

> This PEP introduces three new contexts where expressions may occur that represent
> static types: `TypeVar` bounds, `TypeVar` constraints, and the value of type
> aliases. These expressions may contain references to names
> that are not yet defined. For example, type aliases may be recursive, or even mutually
> recursive, and type variable bounds may refer back to the current class. If these
> expressions were evaluated eagerly, users would need to enclose such expressions in
> quotes to prevent runtime errors. PEP 563 and PEP 649 detail the problems with
> this situation for type annotations.
>
> To prevent a similar situation with the new syntax proposed in this PEP, we propose
> to use lazy evaluation for these expressions, similar to the approach in PEP 649.
> Specifically, each expression will be saved in a code object, and the code object
> is evaluated only when the corresponding attribute is accessed (`TypeVar.__bound__`,
> `TypeVar.__constraints__`, or `TypeAlias.__value__`). After the value is
> successfully evaluated, the value is saved and later calls will return the same value
> without re-evaluating the code object.
>
> If PEP 649 is implemented, additional evaluation mechanisms should be added to
> mirror the options that PEP provides for annotations. In the current version of the
> PEP, that might include adding an `__evaluate_bound__` method to `TypeVar` taking
> a `format` parameter with the same meaning as in PEP 649's `__annotate__` method
> (and a similar `__evaluate_constraints__` method, as well as an `__evaluate_value__`
> method on `TypeAliasType`).
> However, until PEP 649 is accepted and implemented, only the default evaluation format
> (PEP 649's "VALUE" format) will be supported.
>
> As a consequence of lazy evaluation, the value observed for an attribute may
> depend on the time the attribute is accessed.
>
> ```
> X = int
>
> class Foo[T: X, U: X]:
>     t, u = T, U
>
> print(Foo.t.__bound__)  # prints "int"
> X = str
> print(Foo.u.__bound__)  # prints "str"
> ```
> Similar examples affecting type annotations can be constructed using the
> semantics of PEP 563 or PEP 649.
>
> A naive implementation of lazy evaluation would handle class namespaces
> incorrectly, because functions within a class do not normally have access to
> the enclosing class namespace. The implementation will retain a reference to
> the class namespace so that class-scoped names are resolved correctly.

#### Requirement Summary
This PEP introduces three new contexts where expressions may occur that represent static types: `TypeVar` bounds, `TypeVar` constraints, and the value of type aliases. These expressions may contain references to names.


**File proportion:** 5/56 files mapped (8.9%) + 8/56 files associated (14.3%) = 13/56 accounted (23.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_intrinsics.h` | Modified | +10 / -2 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `_Py_make_typevar`, `_Py_make_paramspec`, `_Py_make_typevartuple` |
| `Python/bytecodes.c` | Modified | +36 / -17 | — | `dummy_func` |
| `Python/compile.c` | Modified | +520 / -103 | — | — |
| `Python/intrinsics.c` | Modified | +33 / -1 | — | `make_typevar`, `make_typevar_with_bound`, `make_typevar_with_constraints` |

#### Modification Summary
- **`Include/internal/pycore_intrinsics.h`**: Declares the new lazy-evaluation intrinsic IDs (`INTRINSIC_TYPEVAR`, `INTRINSIC_TYPEVAR_WITH_BOUND`, `INTRINSIC_TYPEVAR_WITH_CONSTRAINTS`, and the related lazy-construction entry points) that the compiler-emitted bytecode invokes to defer bound/constraint/alias-value evaluation.
- **`Objects/typevarobject.c`**: Implements the constructor entry points that the lazy-evaluation intrinsics call: `_Py_make_typevar` materialises a TypeVar whose `__bound__`/`__constraints__` are stored as callables to be evaluated on first access, while `_Py_make_paramspec` and `_Py_make_typevartuple` provide the analogous lazy-construction entry points for ParamSpec and TypeVarTuple.
- **`Python/bytecodes.c`**: Adds the lazy-evaluation intrinsic dispatch (`CALL_INTRINSIC_*`) bodies that invoke the typevar constructor entry points; the `dummy_func` cell reflects the bytecode-DSL parser convention that all opcode bodies live inside a single `dummy_func` shell. The same `dummy_func` shell also contains the new `LOAD_FROM_DICT_OR_GLOBALS` / `LOAD_FROM_DICT_OR_DEREF` bodies that Section 21's def695-scope `compiler_nameop` emission targets; those scoping-bytecode bodies are anchored under this Section 20 row to keep the `(Python/bytecodes.c, —, dummy_func)` tuple in a single home, while their compile/symtable-side emission is owned by Section 21.
- **`Python/compile.c`**: Emits the bytecode that defers bound/constraint/alias-value evaluation. The compiler wraps these expressions in nested lazy-evaluation functions and emits the intrinsic calls (`make_typevar_with_bound`, `make_typevar_with_constraints`, `_Py_make_typealias`) so the expressions only run when the corresponding attribute is read for the first time. The touched compile.c scopes that perform this wrapping (`compiler_typealias`/`compiler_typealias_body`, `compiler_type_params`, `compiler_class`/`compiler_function`) are owned by Sections 10, 12, and 6 respectively, so this row carries `—` to preserve `(file, class, function)` uniqueness; the section's contribution is the lazy-emission narrative that ties those scopes into deferred evaluation.
- **`Python/intrinsics.c`**: Registers `make_typevar`, `make_typevar_with_bound`, and `make_typevar_with_constraints` in the intrinsic table — these are the table entries the compiler emits a `CALL_INTRINSIC` against to lazily construct TypeVars with their deferred bound/constraint expressions.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Python/generated_cases.c.h` | Modified | +546 / -438 | Generated dispatcher cases for the new lazy-evaluation intrinsics and the `LOAD_FROM_DICT_OR_*` opcode bodies in `Python/bytecodes.c` | — | — |
| `Include/internal/pycore_opcode.h` | Modified | +8 / -8 | Generated opcode metadata header registering the new intrinsic-call opcodes used by lazy TypeVar/TypeAlias construction | — | — |
| `Include/opcode.h` | Modified | +8 / -6 | Generated public opcode IDs covering the new lazy-evaluation intrinsic opcodes | — | — |
| `Lib/opcode.py` | Modified | +16 / -4 | Registers the new intrinsic descriptors (`make_typevar`, `make_typevar_with_bound`, `make_typevar_with_constraints`) that the lazy-evaluation dispatch invokes | — | — |
| `Python/opcode_metadata.h` | Modified | +15 / -5 | Generated opcode metadata covering the new lazy-evaluation intrinsic opcodes | — | — |
| `Python/opcode_targets.h` | Modified | +5 / -5 | Generated opcode dispatch-target table for the new intrinsic opcodes | — | — |
| `Lib/test/test_type_aliases.py` | Added | — | Tests lazy evaluation of type-alias `__value__` | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests lazy evaluation of TypeVar `__bound__`/`__constraints__` | — | — |

---

## Section 21: Scoping Behavior
*Path: Runtime Implementation > Scoping Behavior*
*Classification: Implementable*

> The new syntax requires a new kind of scope that behaves differently
> from existing scopes in Python. Thus, the new syntax cannot be described exactly in terms of
> existing Python scoping behavior. This section specifies these scopes
> further by reference to existing scoping behavior: the new scopes behave
> like function scopes, except for a number of minor differences listed below.
>
> All examples include functions introduced with the pseudo-keyword `def695`.
> This keyword will not exist in the actual language; it is used to
> clarify that the new scopes are for the most part like function scopes.
>
> `def695` scopes differ from regular function scopes in the following ways:
>
> - If a `def695` scope is immediately within a class scope, or within another
>   `def695` scope that is immediately within a class scope, then names defined
>   in that class scope can be accessed within the `def695` scope. (Regular functions,
>   by contrast, cannot access names defined within an enclosing class scope.)
> - The following constructs are disallowed directly within a `def695` scope, though
>   they may be used within other scopes nested inside a `def695` scope:
>
>   - `yield`
>   - `yield from`
>   - `await`
>   - `:=` (walrus operator)
>
> - The qualified name (`__qualname__`) of objects (classes and functions) defined within `def695` scopes
>   is as if the objects were defined within the closest enclosing scope.
> - Names bound within `def695` scopes cannot be rebound with a `nonlocal` statement in nested scopes.
>
> `def695` scopes are used for the evaluation of several new syntactic constructs proposed
> in this PEP. Some are evaluated eagerly (when a type alias, function, or class is defined); others are
> evaluated lazily (only when evaluation is specifically requested). In all cases, the scoping semantics are identical:
>
> - Eagerly evaluated values:
>
>   - The type parameters of generic type aliases
>   - The type parameters and annotations of generic functions
>   - The type parameters and base class expressions of generic classes
> - Lazily evaluated values:
>
>   - The value of generic type aliases
>   - The bounds of type variables
>   - The constraints of type variables
>
> In the below translations, names that start with two underscores are internal to the implementation
> and not visible to actual Python code. We use the following intrinsic functions, which in the real
> implementation are defined directly in the interpreter:
>
> - `__make_typealias(*, name, type_params=(), evaluate_value)`: Creates a new `typing.TypeAlias` object with the given
>   name, type parameters, and lazily evaluated value. The value is not evaluated until the `__value__` attribute
>   is accessed.
> - `__make_typevar_with_bound(*, name, evaluate_bound)`: Creates a new `typing.TypeVar` object with the given
>   name and lazily evaluated bound. The bound is not evaluated until the `__bound__` attribute is accessed.
> - `__make_typevar_with_constraints(*, name, evaluate_constraints)`: Creates a new `typing.TypeVar` object with the given
>   name and lazily evaluated constraints. The constraints are not evaluated until the `__constraints__` attribute
>   is accessed.
>
> Non-generic type aliases are translated as follows:
>
> ```
> type Alias = int
> ```
> Equivalent to:
>
> ```
> def695 __evaluate_Alias():
>     return int
>
> Alias = __make_typealias(name='Alias', evaluate_value=__evaluate_Alias)
> ```
> Generic type aliases:
>
> ```
> type Alias[T: int] = list[T]
> ```
> Equivalent to:
>
> ```
> def695 __generic_parameters_of_Alias():
>     def695 __evaluate_T_bound():
>         return int
>     T = __make_typevar_with_bound(name='T', evaluate_bound=__evaluate_T_bound)
>
>     def695 __evaluate_Alias():
>         return list[T]
>     return __make_typealias(name='Alias', type_params=(T,), evaluate_value=__evaluate_Alias)
>
> Alias = __generic_parameters_of_Alias()
> ```
> Generic functions:
>
> ```
> def f[T](x: T) -> T:
>     return x
> ```
> Equivalent to:
>
> ```
> def695 __generic_parameters_of_f():
>     T = typing.TypeVar(name='T')
>
>     def f(x: T) -> T:
>         return x
>     f.__type_params__ = (T,)
>     return f
>
> f = __generic_parameters_of_f()
> ```
> A fuller example of generic functions, illustrating the scoping behavior of defaults, decorators, and bounds.
> Note that this example does not use `ParamSpec` correctly, so it should be rejected by a static type checker.
> It is however valid at runtime, and it us used here to illustrate the runtime semantics.
>
> ```
> @decorator
> def f[T: int, U: (int, str), *Ts, **P](
>     x: T = SOME_CONSTANT,
>     y: U,
>     *args: *Ts,
>     **kwargs: P.kwargs,
> ) -> T:
>     return x
> ```
> Equivalent to:
>
> ```
> __default_of_x = SOME_CONSTANT  # evaluated outside the def695 scope
> def695 __generic_parameters_of_f():
>     def695 __evaluate_T_bound():
>         return int
>     T = __make_typevar_with_bound(name='T', evaluate_bound=__evaluate_T_bound)
>
>     def695 __evaluate_U_constraints():
>         return (int, str)
>     U = __make_typevar_with_constraints(name='U', evaluate_constraints=__evaluate_U_constraints)
>
>     Ts = typing.TypeVarTuple("Ts")
>     P = typing.ParamSpec("P")
>
>     def f(x: T = __default_of_x, y: U, *args: *Ts, **kwargs: P.kwargs) -> T:
>         return x
>     f.__type_params__ = (T, U, Ts, P)
>     return f
>
> f = decorator(__generic_parameters_of_f())
> ```
> Generic classes:
>
> ```
> class C[T](Base):
>     def __init__(self, x: T):
>         self.x = x
> ```
> Equivalent to:
>
> ```
> def695 __generic_parameters_of_C():
>     T = typing.TypeVar('T')
>     class C(Base):
>         __type_params__ = (T,)
>         def __init__(self, x: T):
>             self.x = x
>    return C
>
> C = __generic_parameters_of_C()
> ```
> The biggest divergence from existing behavior for `def695` scopes
> is the behavior within class scopes. This divergence is necessary
> so that generics defined within classes behave in an intuitive way:
>
> ```
> class C:
>     class Nested: ...
>     def generic_method[T](self, x: T, y: Nested) -> T: ...
> ```
> Equivalent to:
>
> ```
> class C:
>     class Nested: ...
>
>     def695 __generic_parameters_of_generic_method():
>         T = typing.TypeVar('T')
>
>         def generic_method(self, x: T, y: Nested) -> T: ...
>         return generic_method
>
>     generic_method = __generic_parameters_of_generic_method()
> ```
> In this example, the annotations for `x` and `y` are evaluated within
> a `def695` scope, because they need access to the type parameter `T`
> for the generic method. However, they also need access to the `Nested`
> name defined within the class namespace. If `def695` scopes behaved
> like regular function scopes, `Nested` would not be visible within the
> function scope. Therefore, `def695` scopes that are immediately within
> class scopes have access to that class scope, as described above.

#### Requirement Summary
The new syntax requires a new kind of scope that behaves differently from existing scopes in Python. Thus, the new syntax cannot be described exactly in terms of existing Python scoping behavior.


**File proportion:** 2/56 files mapped (3.6%) + 3/56 files associated (5.4%) = 5/56 accounted (8.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/compile.c` | Modified | +520 / -103 | — | `compiler_nameop`, `get_ref_type`, `fix_cell_offsets` |
| `Python/symtable.c` | Modified | +329 / -26 | — | `analyze_name`, `analyze_block`, `analyze_child_block`, `drop_class_free`, `inline_comprehension` |

#### Modification Summary
- **`Python/compile.c`**: Implements the def695 scoping behaviour for type-parameter blocks. `compiler_nameop` emits the proper `LOAD_LOCALS` / `LOAD_FROM_DICT_OR_GLOBALS` / `LOAD_FROM_DICT_OR_DEREF` sequence for names referenced inside type-parameter scopes, `get_ref_type` classifies those references against the new scope kind, and `fix_cell_offsets` adjusts cell layout so type-parameter cells thread correctly into the enclosing function/class/alias body.
- **`Python/symtable.c`**: Implements the symbol-table side of the new scoping rules. `analyze_name` handles name resolution inside type-parameter blocks (rejecting illegal `nonlocal`/`global` uses and exposing class type parameters through the synthetic `__classdict__`), `analyze_block`/`analyze_child_block` propagate the new visibility rules through nested blocks, `drop_class_free` ensures class-scope free variables remain visible to enclosed type-parameter scopes, and `inline_comprehension` cooperates with the new block kind during comprehension flattening.
- **Scoping bytecode bodies**: The `LOAD_FROM_DICT_OR_GLOBALS` and `LOAD_FROM_DICT_OR_DEREF` opcode bodies live inside `Python/bytecodes.c`'s `dummy_func` shell and back the def695-scope `compiler_nameop` emission listed above. Those bodies are anchored under Section 20 (which already owns the `(Python/bytecodes.c, —, dummy_func)` tuple) to preserve Check 28's tuple-uniqueness rule; their compile-side emission and symtable-side analysis are the Section 21 contribution.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/opcode.py` | Modified | +16 / -4 | Registers the `LOAD_FROM_DICT_OR_GLOBALS` / `LOAD_FROM_DICT_OR_DEREF` opcodes (the dict-or-globals/dict-or-deref dispatch entries) that def695-scope `compiler_nameop` emits | — | — |
| `Lib/test/test_type_aliases.py` | Added | — | Tests def695-scope visibility for type-alias values | — | — |
| `Lib/test/test_type_params.py` | Added | — | Tests def695-scope visibility, nonlocal/global restrictions, and class-scope access from type-parameter blocks | — | — |

---

## Section 22: Library Changes
*Path: Runtime Implementation > Library Changes*
*Classification: Implementable*

> Several classes in the `typing` module that are currently implemented in
> Python must be partially implemented in C. This includes `TypeVar`,
> `TypeVarTuple`, `ParamSpec`, and `Generic`, and the new class
> `TypeAliasType` (described above). The implementation may delegate to the
> Python version of `typing.py` for some behaviors that interact heavily with
> the rest of the module. The
> documented behaviors of these classes should not change.

#### Requirement Summary
Several classes in the `typing` module that are currently implemented in Python must be partially implemented in C. This includes `TypeVar`, `TypeVarTuple`, `ParamSpec`, and `Generic`, and the new class.


**File proportion:** 6/56 files mapped (10.7%) + 13/56 files associated (23.2%) = 19/56 accounted (33.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/typing.py` | Modified | +170 / -421 | — | — |
| `Modules/_typingmodule.c` | Modified | +28 / -0 | — | `_typing_exec` |
| `Objects/object.c` | Modified | +6 / -0 | — | `_PyTypes_InitTypes` |
| `Objects/typeobject.c` | Modified | +45 / -2 | — | — |
| `Objects/typevarobject.c` | Added | +1620 / -0 | — | `paramspecattr_dealloc`, `paramspecattr_traverse`, `paramspecattr_clear`, `paramspecattr_richcompare`, `paramspecattr_new`, `paramspecargs_repr`, `paramspecargs_new_impl`, `paramspecargs_mro_entries`, `paramspeckwargs_repr`, `paramspeckwargs_new_impl`, `paramspeckwargs_mro_entries`, `paramspec_dealloc`, `paramspec_traverse`, `paramspec_clear`, `paramspec_repr`, `paramspec_args`, `paramspec_kwargs`, `paramspec_alloc`, `paramspec_new_impl`, `paramspec_typing_subst_impl`, `paramspec_typing_prepare_subst_impl`, `paramspec_reduce_impl`, `paramspec_mro_entries`, `typevartuple_dealloc`, `typevartuple_iter`, `typevartuple_repr`, `typevartuple_alloc`, `typevartuple_impl`, `typevartuple_typing_subst_impl`, `typevartuple_typing_prepare_subst_impl`, `typevartuple_reduce_impl`, `typevartuple_mro_entries`, `typevartuple_traverse`, `typevartuple_clear`, `typevartuple_unpack`, `contains_typevartuple`, `unpack_typevartuples`, `generic_init_subclass`, `generic_class_getitem`, `_Py_subscript_generic`, `generic_dealloc`, `generic_traverse`, `_Py_initialize_generic`, `_Py_clear_generic_types`, `call_typing_args_kwargs`, `call_typing_func_object`, `make_union` |
| `Objects/unionobject.c` | Modified | +6 / -2 | — | `is_unionable` |

#### Modification Summary
- **`Lib/typing.py`**: Section 22's library-migration contract is encoded here as the preserved public surface — `TypeVar`/`TypeVarTuple`/`ParamSpec`/`Generic`/`TypeAliasType` become thin facades over the new C runtime types. The actual class-level changes (`_BoundVarianceMixin`, `TypeVar`, `TypeVarTuple`, `ParamSpecArgs`, `ParamSpecKwargs`, `ParamSpec`, `Generic`, `NamedTupleMeta`) are owned by Section 11 to preserve `(file, class, function)` uniqueness, so this row carries `—`; this section's contribution is the cross-file migration narrative that keeps the public typing API surface stable.
- **`Modules/_typingmodule.c`**: Exposes the C-implemented typing primitives (TypeVar, TypeVarTuple, ParamSpec, TypeAliasType) through the `_typing` extension module so `Lib/typing.py` can re-export them.
- **`Objects/object.c`**: Registers and finalises the new `_PyTypeVar_Type`, `_PyParamSpec_Type`, `_PyTypeVarTuple_Type`, and `_PyTypeAliasType_Type` static types as part of the interpreter's static-type bring-up.
- **`Objects/typeobject.c`**: Section 22's class-level Generic-base handling and `__type_params__` storage is implemented by `type_get_type_params`, `type_new_copy_slots`, `type_new_set_classdictcell`, `type_new_set_attrs` — those scopes are owned by Section 13, so this row carries `—` to preserve `(file, class, function)` uniqueness; the contribution here is the runtime substrate that makes PEP 695 classes behave like generics under the typing-library migration.
- **`Objects/typevarobject.c`**: Implements the C-side of the library migration. The `paramspec_*` / `paramspecargs_*` / `paramspeckwargs_*` / `paramspecattr_*` functions implement the `ParamSpec`, `ParamSpec.args`, and `ParamSpec.kwargs` runtime types; the `typevartuple_*` (with `typevartuple_unpack` / `contains_typevartuple` / `unpack_typevartuples`) implement `TypeVarTuple` including iteration and substitution semantics; `generic_init_subclass`, `generic_class_getitem`, `_Py_subscript_generic`, `generic_dealloc`, `generic_traverse`, `_Py_initialize_generic`, `_Py_clear_generic_types` implement the `Generic` base class in C; and the helpers `call_typing_args_kwargs` / `call_typing_func_object` / `make_union` are reused by the migrated typing primitives.
- **`Objects/unionobject.c`**: Extends `is_unionable` so the new C `TypeVar`/`ParamSpec`/`TypeVarTuple`/`TypeAliasType` instances participate in `X | Y` union construction just like the prior Python-level typing objects.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/internal/pycore_global_objects.h` | Modified | +8 / -0 | Must be updated to maintain consistency with mapped changes | `_Py_interp_cached_objects` | — |
| `Include/internal/pycore_global_objects_fini_generated.h` | Modified | +16 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Include/internal/pycore_global_strings.h` | Modified | +16 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Include/internal/pycore_runtime_init_generated.h` | Modified | +16 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Include/internal/pycore_unicodeobject_generated.h` | Modified | +36 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Makefile.pre.in` | Modified | +2 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Modules/Setup.bootstrap.in` | Modified | +1 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Modules/Setup.stdlib.in` | Modified | +0 / -1 | Must be updated to maintain consistency with mapped changes | — | — |
| `PCbuild/_freeze_module.vcxproj` | Modified | +1 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `PCbuild/pythoncore.vcxproj` | Modified | +2 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `PCbuild/pythoncore.vcxproj.filters` | Modified | +6 / -0 | Must be updated to maintain consistency with mapped changes | — | — |
| `Python/pylifecycle.c` | Modified | +2 / -0 | Must be updated to maintain consistency with mapped changes | — | `finalize_interp_clear` |
| `Lib/test/test_sys.py` | Modified | — | Supporting change for the implementation | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

*None — all PR files are accounted for.*
