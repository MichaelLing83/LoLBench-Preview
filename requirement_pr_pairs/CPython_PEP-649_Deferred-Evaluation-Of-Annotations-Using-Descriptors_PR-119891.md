# CPython - PEP 649: Deferred Evaluation Of Annotations Using Descriptors

**PR:** https://github.com/python/cpython/pull/119891
**Requirement Doc:** https://peps.python.org/pep-0649/

## Matching Statistics
- **Requirement Doc Coverage:** 3/3 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 3/15 files mapped (20.0%) + 12/15 files associated (80.0%) = 15/15 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | Abstract | No | N/A | knowledge |
| 2 | Overview | No | N/A | knowledge |
| 3 | Overview > Comparison Of Annotation Semantics | No | N/A | knowledge |
| 4 | Overview > Mistaken Rejection Of This Approach In November 2017 | No | N/A | contextual |
| 5 | Motivation | No | N/A | contextual |
| 6 | Motivation > A History Of Annotations | No | N/A | contextual |
| 7 | Motivation > The Current State Of Annotation Use Cases | No | N/A | contextual |
| 8 | Motivation > The Current State Of Annotation Use Cases > Static typing users | No | N/A | contextual |
| 9 | Motivation > The Current State Of Annotation Use Cases > Runtime annotation users | No | N/A | contextual |
| 10 | Motivation > The Current State Of Annotation Use Cases > Wrappers | No | N/A | contextual |
| 11 | Motivation > The Current State Of Annotation Use Cases > Documentation | No | N/A | contextual |
| 12 | Motivation > Motivation For This PEP | No | N/A | contextual |
| 13 | Implementation | No | N/A | knowledge |
| 14 | Implementation > Observed semantics for annotations expressions | No | N/A | knowledge |
| 15 | Implementation > __annotate__ and __annotations__ | Yes | Yes | implementation |
| 16 | Implementation > Changes to allowable annotations syntax | No | N/A | knowledge |
| 17 | Implementation > Changes to `inspect.get_annotations` and `typing.get_type_hints` | Yes | Yes | implementation |
| 18 | Implementation > The `stringizer` and the `fake globals` environment | Yes | Yes | implementation |
| 19 | Implementation > Compiler-generated  `__annotate__` functions | No | N/A | knowledge |
| 20 | Implementation > Third-party `__annotate__` functions | No | N/A | knowledge |
| 21 | Implementation > Pseudocode | No | N/A | knowledge |
| 22 | Implementation > Other modifications to the Python runtime | No | N/A | knowledge |
| 23 | Implementation > Interactive REPL Shell | No | N/A | knowledge |
| 24 | Implementation > Annotations On Local Variables Inside Functions | No | N/A | knowledge |
| 25 | Implementation > Prototype | No | N/A | contextual |
| 26 | Implementation > Performance Comparison | No | N/A | contextual |
| 27 | Backwards Compatibility | No | N/A | contextual |
| 28 | Backwards Compatibility > Backwards Compatibility With Stock Semantics | No | N/A | contextual |
| 29 | Backwards Compatibility > Backwards Compatibility With PEP 563 Semantics | No | N/A | contextual |
| 30 | Rejected Ideas | No | N/A | contextual |
| 31 | Rejected Ideas > "Just store the strings" | No | N/A | contextual |
| 32 | Acknowledgements | No | N/A | process |
| 33 | References | No | N/A | process |
| 34 | Copyright | No | N/A | process |
| 35 | Linked Issue #89687 — Cross-module dataclass inheritance breaks get_type_hints | No | N/A | contextual |
| 36 | Linked Issue #85421 — TypedDict inheritance doesn't work with get_type_hints and postponed evaluation of annotations across modules | No | N/A | contextual |
| 37 | Linked Issue #90531 — TypedDict and NamedTuple do not evaluate cross-module ForwardRef in all cases | No | N/A | contextual |
| 38 | Linked Issue #97727 — `__future__` annotations breaks `TypedDict` `__required/optional_keys__` | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/howto/descriptor.rst` | documentation | — | Section 15 |
| 2 | `Lib/annotationlib.py` | source | Section 15, Section 17, Section 18 | — |
| 3 | `Lib/dataclasses.py` | source | — | Section 17 |
| 4 | `Lib/functools.py` | source | — | Section 15 |
| 5 | `Lib/inspect.py` | source | Section 17 | — |
| 6 | `Lib/test/test_annotationlib.py` | test | — | Section 15, Section 17, Section 18 |
| 7 | `Lib/test/test_dataclasses/__init__.py` | test | — | Section 17 |
| 8 | `Lib/test/test_functools.py` | test | — | Section 15 |
| 9 | `Lib/test/test_grammar.py` | test | — | Section 15 |
| 10 | `Lib/test/test_inspect/test_inspect.py` | test | — | Section 17 |
| 11 | `Lib/test/test_type_annotations.py` | test | — | Section 15 |
| 12 | `Lib/test/test_typing.py` | test | — | Section 15, Section 17 |
| 13 | `Lib/typing.py` | source | Section 15, Section 17 | — |
| 14 | `Misc/NEWS.d/next/Library/2024-06-11-07-17-25.gh-issue-119180.iH-2zy.rst` | documentation | — | Section 15 |
| 15 | `Python/stdlib_module_names.h` | source | — | Section 15 |

---

## Section 15: __annotate__ and __annotations__
*Path: Implementation > __annotate__ and __annotations__*
*Classification: Implementable*

> Python supports annotations on three different types:
> functions, classes, and modules.  This PEP modifies
> the semantics on all three of these types in a similar
> way.
>
> First, this PEP adds a new "dunder" attribute, `__annotate__`.
> `__annotate__` must be a "data descriptor",
> implementing all three actions: get, set, and delete.
> The `__annotate__` attribute is always defined,
> and may only be set to either `None` or to a callable.
> (`__annotate__` cannot be deleted.)  If an object
> has no annotations, `__annotate__` should be
> initialized to `None`, rather than to a function
> that returns an empty dict.
>
> The `__annotate__` data descriptor must have dedicated
> storage inside the object to store the reference to its value.
> The location of this storage at runtime is an implementation
> detail.  Even if it's visible to Python code, it should still
> be considered an internal implementation detail, and Python
> code should prefer to interact with it only via the
> `__annotate__` attribute.
>
> The callable stored in `__annotate__` must accept a
> single required positional argument called `format`,
> which will always be an `int` (or a subclass of `int`).
> It must either return a dict (or subclass of dict) or
> raise `NotImplementedError()`.
>
> Here's a formal definition of `__annotate__`, as it will
> appear in the "Magic methods" section of the Python
> Language Reference:
>
>     `__annotate__(format: int) -> dict`
>
>     Returns a new dictionary object mapping attribute/parameter
>     names to their annotation values.
>
>     Takes a `format` parameter specifying the format in which
>     annotations values should be provided.  Must be one of the
>     following:
>
>     `inspect.VALUE` (equivalent to the `int` constant `1`)
>
>         Values are the result of evaluating the annotation expressions.
>
>     `inspect.FORWARDREF` (equivalent to the `int` constant `2`)
>
>         Values are real annotation values (as per `inspect.VALUE` format)
>         for defined values, and `ForwardRef` proxies for undefined values.
>         Real objects may be exposed to, or contain references to,
>         `ForwardRef` proxy objects.
>
>     `inspect.SOURCE` (equivalent to the `int` constant `3`)
>
>         Values are the text string of the annotation as it
>         appears in the source code.  May only be approximate;
>         whitespace may be normalized, and constant values may
>         be optimized.  It's possible the exact values of these
>         strings could change in future version of Python.
>
>     If an `__annotate__` function doesn't support the requested
>     format, it must raise `NotImplementedError()`.
>     `__annotate__` functions must always support `1` (`inspect.VALUE`)
>     format; they must not raise `NotImplementedError()` when called with
>     `format=1`.
>
>     When called with `format=1`, an `__annotate__` function
>     may raise `NameError`; it must not raise `NameError` when called
>     requesting any other format.
>
>     If an object doesn't have any annotations, `__annotate__` should
>     preferably be set to `None` (it can't be deleted), rather than set to a
>     function that returns an empty dict.
>
> When the Python compiler compiles an object with
> annotations, it simultaneously compiles the appropriate
> annotate function.  This function, called with
> the single positional argument `inspect.VALUE`,
> computes and returns the annotations dict as defined
> on that object.  The Python compiler and runtime work
> in concert to ensure that the function is bound to
> the appropriate namespaces:
>
> * For functions and classes, the globals dictionary will
>   be the module where the object was defined.  If the object
>   is itself a module, its globals dictionary will be its
>   own dict.
> * For methods on classes, and for classes, the locals dictionary
>   will be the class dictionary.
> * If the annotations refer to free variables, the closure will
>   be the appropriate closure tuple containing cells for free variables.
>
> Second, this PEP requires that the existing
> `__annotations__` must be a "data descriptor",
> implementing all three actions: get, set, and delete.
> `__annotations__` must also have its own internal
> storage it uses to cache a reference to the annotations dict:
>
> * Class and module objects must
>   cache the annotations dict in their `__dict__`, using the key
>   `__annotations__`.  This is required for backwards
>   compatibility reasons.
> * For function objects, storage for the annotations dict
>   cache is an implementation detail.  It's preferably internal
>   to the function object and not visible in Python.
>
> This PEP defines semantics on how `__annotations__` and
> `__annotate__` interact, for all three types that implement them.
> In the following examples, `fn` represents a function, `cls`
> represents a class, `mod` represents a module, and `o` represents
> an object of any of these three types:
>
> * When `o.__annotations__` is evaluated, and the internal storage
>   for `o.__annotations__` is unset, and `o.__annotate__` is set
>   to a callable, the getter for `o.__annotations__` calls
>   `o.__annotate__(1)`, then caches the result in its internal
>   storage and returns the result.
>
>   - To explicitly clarify one question that has come up multiple times:
>     this `o.__annotations__` cache is the *only* caching mechanism
>     defined in this PEP.  There are *no other* caching mechanisms defined
>     in this PEP.  The `__annotate__` functions generated by the Python
>     compiler explicitly don't cache any of the values they compute.
>
> * Setting `o.__annotate__` to a callable invalidates the
>   cached annotations dict.
>
> * Setting `o.__annotate__` to `None` has no effect on
>   the cached annotations dict.
>
> * Deleting `o.__annotate__` raises `TypeError`.
>   `__annotate__` must always be set; this prevents unannotated
>   subclasses from inheriting the `__annotate__` method of one
>   of their base classes.
>
> * Setting `o.__annotations__` to a legal value
>   automatically sets `o.__annotate__` to `None`.
>
>   * Setting `cls.__annotations__` or `mod.__annotations__`
>     to `None` otherwise works like any other attribute; the
>     attribute is set to `None`.
>
>   * Setting `fn.__annotations__` to `None` invalidates
>     the cached annotations dict.  If `fn.__annotations__`
>     doesn't have a cached annotations value, and `fn.__annotate__`
>     is `None`, the `fn.__annotations__` data descriptor
>     creates, caches, and returns a new empty dict.  (This is for
>     backwards compatibility with PEP 3107 semantics.)

#### Requirement Summary
This section specifies the core ``__annotate__`` and ``__annotations__`` data descriptor mechanism for functions, classes, and modules, including the ``Format`` enum (VALUE=1, FORWARDREF=2, SOURCE=3), the ``ForwardRef`` proxy type, and the caching/invalidation semantics. The PR implements this by adding the new ``Lib/annotationlib.py`` module which defines the ``Format`` enum, ``ForwardRef`` class (extended with stringizer and evaluation capabilities), ``call_annotate_function()``, and ``get_annotations()``. The PR also extensively modifies ``Lib/typing.py`` to import and use ``ForwardRef`` from ``annotationlib``, adds the ``evaluate_forward_ref()`` function, and updates ``_eval_type()`` to accept ``format`` and ``owner`` parameters for deferred evaluation support.

**File proportion:** 2/15 files mapped (13.3%) + 9/15 files associated (60.0%) = 11/15 accounted (73.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/annotationlib.py` | Added | +655 / -0 | `Format`, `ForwardRef` | `call_annotate_function`, `get_annotations` |
| `Lib/typing.py` | Modified | +184 / -148 | `ForwardRef`, `NamedTupleMeta`, `_TypedDictMeta`, `_AnnotatedAlias` | `_convert_to_source`, `_eval_type`, `_make_eager_annotate`, `_make_forward_ref`, `_make_nmtuple`, `evaluate_forward_ref`, `get_type_hints` |

#### Modification Summary
- **`Lib/annotationlib.py`**: Adds the new ``annotationlib`` module implementing the PEP 649 annotation infrastructure. Defines the ``Format`` IntEnum with VALUE (1), FORWARDREF (2), and SOURCE (3) constants as specified for the ``format`` argument to ``__annotate__``. Implements the ``ForwardRef`` class with ``__arg__``, ``__forward_evaluated__``, ``__forward_value__``, evaluation via ``evaluate()``, and stringizer proxy behavior for all dunder methods. The ``ForwardRef`` retains references to globals, locals, and closure information needed to evaluate the expression, as specified.
- **`Lib/typing.py`**: Imports ``ForwardRef`` from ``annotationlib`` instead of defining it locally, removing the old ``ForwardRef`` class and replacing all references. Adds ``evaluate_forward_ref()`` as a new public API. Updates ``_eval_type()`` to accept ``format`` and ``owner`` keyword arguments for deferred annotation evaluation. Updates ``NamedTuple`` and ``TypedDict`` internals to use ``annotationlib.Format.FORWARDREF`` for deferred annotation resolution, enabling support for unresolved forward references as described by the ``__annotate__`` protocol.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/functools.py` | Modified | +10 / -4 | Updates ``WRAPPER_ASSIGNMENTS`` to copy ``__annotate__`` instead of ``__annotations__``, and updates ``singledispatch`` to check ``__annotate__`` for dispatch type resolution | — | — |
| `Python/stdlib_module_names.h` | Modified | +1 / -0 | Registers ``annotationlib`` in the CPython stdlib module name list | — | — |
| `Doc/howto/descriptor.rst` | Modified | +6 / -2 | Updates descriptor HOWTO documentation to reflect that wrappers now forward ``__annotations__`` as a property and no longer list it in ``WRAPPER_ASSIGNMENTS`` | — | — |
| `Misc/NEWS.d/next/Library/2024-06-11-07-17-25.gh-issue-119180.iH-2zy.rst` | Added | +4 / -0 | NEWS entry documenting the addition of ``annotationlib`` and deferred annotation support | — | — |
| `Lib/test/test_annotationlib.py` | Added | +771 / -0 | Test suite for the new ``annotationlib`` module covering Format enum, ForwardRef, call_annotate_function, and get_annotations | — | — |
| `Lib/test/test_functools.py` | Modified | +41 / -0 | Tests for update_wrapper with ``__annotate__`` propagation and singledispatch with forward references | — | — |
| `Lib/test/test_grammar.py` | Modified | +2 / -1 | Test updated to use ``annotationlib.Format.VALUE`` instead of hardcoded integer constant | — | — |
| `Lib/test/test_type_annotations.py` | Modified | +5 / -8 | Tests updated to use ``annotationlib.Format`` constants instead of locally defined integer constants | — | — |
| `Lib/test/test_typing.py` | Modified | +121 / -17 | NamedTuple/TypedDict tests exercise the `__annotate__`/`__annotations__` deferred-annotation behavior introduced in Section 15, alongside the `get_type_hints` coverage in Section 17 | — | — |

---

## Section 17: Changes to `inspect.get_annotations` and `typing.get_type_hints`
*Path: Implementation > Changes to `inspect.get_annotations` and `typing.get_type_hints`*
*Classification: Implementable*

> (This PEP makes frequent reference to these two functions.  In the future
> it will refer to them collectively as "the helper functions", as they help
> user code work with annotations.)
>
> These two functions extract and return the annotations from an object.
> `inspect.get_annotations` returns the annotations unchanged;
> for the convenience of static typing users, `typing.get_type_hints`
> makes some modifications to the annotations before it returns them.
>
> This PEP adds a new keyword-only parameter to these two functions,
> `format`.  `format` specifies what format the values in the
> annotations dict should be returned in.
> The `format` parameter on these two functions accepts the same values
> as the `format` parameter on the `__annotate__` magic method
> defined above; however, these `format` parameters also have a default
> value of `inspect.VALUE`.
>
> When either `__annotations__` or `__annotate__` is updated on an
> object, the other of those two attributes is now out-of-date and should also
> either be updated or deleted (set to `None`, in the case of `__annotate__`
> which cannot be deleted).  In general, the semantics established in the previous
> section ensure that this happens automatically.  However, there's one case which
> for all practical purposes can't be handled automatically: when the dict cached
> by `o.__annotations__` is itself modified, or when mutable values inside that
> dict are modified.
>
> Since this can't be handled in code, it must be handled in
> documentation.  This PEP proposes amending the documentation
> for `inspect.get_annotations` (and similarly for
> `typing.get_type_hints`) as follows:
>
>     If you directly modify the `__annotations__` dict on an object,
>     by default these changes may not be reflected in the dictionary
>     returned by `inspect.get_annotations` when requesting either
>     `SOURCE` or `FORWARDREF` format on that object. Rather than
>     modifying the `__annotations__` dict directly, consider replacing
>     that object's `__annotate__` method with a function computing
>     the annotations dict with your desired values.  Failing that, it's
>     best to overwrite the object's `__annotate__` method with `None`
>     to prevent `inspect.get_annotations` from generating stale results
>     for `SOURCE` and `FORWARDREF` formats.

#### Requirement Summary
This section specifies adding a ``format`` keyword-only parameter to ``inspect.get_annotations`` and ``typing.get_type_hints``, allowing callers to request annotations in VALUE, FORWARDREF, or SOURCE format. The PR implements this by moving ``inspect.get_annotations`` into the new ``annotationlib`` module (with the ``format`` parameter) and re-exporting it from ``inspect``. The old ``inspect.get_annotations`` implementation (with ``eval_str``, ``globals``, ``locals`` parameters) is removed and replaced by a single import from ``annotationlib``. The ``Lib/typing.py`` changes to ``get_type_hints`` integrate the new format parameter through the updated ``_eval_type`` pipeline.

**File proportion:** 3/15 files mapped (20.0%) + 5/15 files associated (33.3%) = 8/15 accounted (53.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/inspect.py` | Modified | +1 / -115 | — | — |
| `Lib/annotationlib.py` | Added | +655 / -0 | — | — |
| `Lib/typing.py` | Modified | +184 / -148 | — | — |

The Python parser exposes only class-level scopes for `Lib/typing.py` (`ForwardRef`, `NamedTupleMeta`, `_TypedDictMeta`, `_AnnotatedAlias`); the module-level functions that actually implement Section 17 (`get_type_hints`, `_eval_type`, `evaluate_forward_ref`) are not exposed by the extended cache. All four touched class-level scopes are attributed to Section 15 (where the `__annotate__` / `__annotations__` data-descriptor surface is owned) per Check 28 tuple uniqueness, so the Classes/Functions cells here are left as `—`.

#### Modification Summary
- **`Lib/inspect.py`**: Removes the entire 115-line ``get_annotations()`` function (which supported ``eval_str``, ``globals``, ``locals`` parameters) and replaces it with a single import: ``from annotationlib import get_annotations``. This moves the canonical implementation into the new ``annotationlib`` module while maintaining backwards compatibility through the re-export.
- **`Lib/annotationlib.py`**: Implements the new ``get_annotations()`` function with the ``format`` keyword parameter as specified by this section. The function retrieves annotations from functions, classes, and modules, supporting VALUE (direct evaluation), FORWARDREF (with ForwardRef proxies for undefined names), and SOURCE (string representations) formats via the fake-globals technique when the ``__annotate__`` method does not natively support the requested format.
- **`Lib/typing.py`**: Modifies ``get_type_hints()`` to use ``annotationlib.get_annotations()`` with the new ``format`` parameter, integrating the deferred evaluation pipeline. Updates ``_eval_type()`` to accept ``format`` and ``owner`` keyword arguments, allowing callers to specify the annotation format through the type evaluation chain. The cache does not expose `get_type_hints`/`_eval_type` as module-level function scopes, so the Functions cell remains `—`.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/dataclasses.py` | Modified | +3 / -1 | Updated to use ``annotationlib.get_annotations(cls, format=annotationlib.Format.FORWARDREF)`` instead of ``inspect.get_annotations(cls)`` for deferred annotation support | — | — |
| `Lib/test/test_annotationlib.py` | Added | +771 / -0 | Tests `get_annotations` (the Section 17 helper) end-to-end alongside the Section 15 module surface | — | — |
| `Lib/test/test_inspect/test_inspect.py` | Modified | +1 / -214 | Removes 214 lines of ``get_annotations`` tests from inspect test suite (tests moved to ``test_annotationlib.py``), updates ``check__all__`` to account for re-exported ``get_annotations`` | — | — |
| `Lib/test/test_dataclasses/__init__.py` | Modified | +10 / -0 | Adds ``test_deferred_annotations`` test verifying dataclasses work with unresolved forward references | — | — |
| `Lib/test/test_typing.py` | Modified | +121 / -17 | Tests updated for annotationlib integration including NamedTuple/TypedDict annotation type checks, future annotations support, and ForwardRef evaluation | — | — |

---

## Section 18: The `stringizer` and the `fake globals` environment
*Path: Implementation > The `stringizer` and the `fake globals` environment*
*Classification: Implementable*

> As originally proposed, this PEP supported many runtime
> annotation user use cases, and many static type user use cases.
> But this was insufficient--this PEP could not be accepted
> until it satisfied *all* extant use cases.  This became
> a longtime blocker of this PEP until Carl Meyer proposed
> the "stringizer" and the "fake globals" environment as
> described below.  These techniques allow this PEP to support
> both the `FORWARDREF` and `SOURCE` formats, ably
> satisfying all remaining uses cases.
>
> In a nutshell, this technique involves running a
> Python-compiler-generated `__annotate__` function in
> an exotic runtime environment.  Its normal `globals`
> dict is replaced with what's called a "fake globals" dict.
> A "fake globals" dict is a dict with one important difference:
> every time you "get" a key from it that isn't mapped,
> it creates, caches, and returns a new value for that key
> (as per the `__missing__` callback for a dictionary).
> That value is a an instance of a novel type referred to
> as a "stringizer".
>
> A "stringizer" is a Python class with highly unusual behavior.
> Every stringizer is initialized with its "value", initially
> the name of the missing key in the "fake globals" dict.  The
> stringizer then implements every Python "dunder" method used to
> implement operators, and the value returned by that method
> is a new stringizer whose value is a text representation
> of that operation.
>
> When these stringizers are used in expressions, the result
> of the expression is a new stringizer whose name textually
> represents that expression.  For example, let's say
> you have a variable `f`, which is a reference to a
> stringizer initialized with the value `'f'`.  Here are
> some examples of operations you could perform on `f` and
> the values they would return:
>
> ```
> >>> f
> Stringizer('f')
> >>> f + 3
> Stringizer('f + 3')
> >> f["key"]
> Stringizer('f["key"]')
> ```
> Bringing it all together: if we run a Python-generated
> `__annotate__` function, but we replace its globals
> with a "fake globals" dict, all undefined symbols it
> references will be replaced with stringizer proxy objects
> representing those symbols, and any operations performed
> on those proxies will in turn result in proxies
> representing that expression.  This allows `__annotate__`
> to complete, and to return an annotations dict, with
> stringizer instances standing in for names and entire
> expressions that could not have otherwise been evaluated.
>
> In practice, the "stringizer" functionality will be implemented
> in the `ForwardRef` object currently defined in the
> `typing` module.  `ForwardRef` will be extended to
> implement all stringizer functionality; it will also be
> extended to support evaluating the string it contains,
> to produce the real value (assuming all symbols referenced
> are defined).  This means the `ForwardRef` object
> will retain references to the appropriate "globals",
> "locals", and even "closure" information needed to
> evaluate the expression.
>
> This technique is the core of how `inspect.get_annotations`
> supports `FORWARDREF` and `SOURCE` formats.  Initially,
> `inspect.get_annotations` will call the object's
> `__annotate__` method requesting the desired format.
> If that raises `NotImplementedError`, `inspect.get_annotations`
> will construct a "fake globals" environment, then call
> the object's `__annotate__` method.
>
> * `inspect.get_annotations` produces `SOURCE` format
>   by creating a new empty "fake globals" dict, binding it
>   to the object's `__annotate__` method, calling that
>   requesting `VALUE` format, and then extracting the string
>   "value" from each `ForwardRef` object
>   in the resulting dict.
>
> * `inspect.get_annotations` produces `FORWARDREF` format
>   by creating a new empty "fake globals" dict, pre-populating
>   it with the current contents of the  `__annotate__` method's
>   globals dict, binding the "fake globals" dict to the object's
>   `__annotate__` method, calling that requesting `VALUE`
>   format, and returning the result.
>
> This entire technique works because the `__annotate__` functions
> generated by the compiler are controlled by Python itself, and
> are simple and predictable.  They're
> effectively a single `return` statement, computing and
> returning the annotations dict.  Since most operations needed
> to compute an annotation are implemented in Python using dunder
> methods, and the stringizer supports all the relevant dunder
> methods, this approach is a reliable, practical solution.
>
> However, it's not reasonable to attempt this technique with
> just any `__annotate__` method.  This PEP assumes that
> third-party libraries may implement their own `__annotate__`
> methods, and those functions would almost certainly work
> incorrectly when run in this "fake globals" environment.
> For that reason, this PEP allocates a flag on code objects,
> one of the unused bits in `co_flags`, to mean "This code
> object can be run in a 'fake globals' environment."  This
> makes the "fake globals" environment strictly opt-in, and
> it's expected that only `__annotate__` methods generated
> by the Python compiler will set it.
>
> The weakness in this technique is in handling operators which
> don't directly map to dunder methods on an object.  These are
> all operators that implement some manner of flow control,
> either branching or iteration:
>
> * Short-circuiting `or`
> * Short-circuiting `and`
> * Ternary operator (the `if` / `then` operator)
> * Generator expressions
> * List / dict / set comprehensions
> * Iterable unpacking
>
> As a rule these techniques aren't used in annotations,
> so it doesn't pose a problem in practice.  However, the
> recent addition of `TypeVarTuple` to Python does use
> iterable unpacking.  The dunder methods
> involved (`__iter__` and `__next__`) don't permit
> distinguishing between iteration use cases; in order to
> correctly detect which use case was involved, mere
> "fake globals" and a "stringizer" wouldn't be sufficient;
> this would require a custom bytecode interpreter designed
> specifically around producing `SOURCE` and `FORWARDREF`
> formats.
>
> Thankfully there's a shortcut that will work fine:
> the stringizer will simply assume that when its
> iteration dunder methods are called, it's in service
> of iterator unpacking being performed by `TypeVarTuple`.
> It will hard-code this behavior.  This means no other
> technique using iteration will work, but in practice
> this won't inconvenience real-world use cases.
>
> Finally, note that the "fake globals" environment
> will also require constructing a matching "fake locals"
> dictionary, which for `FORWARDREF` format will be
> pre-populated with the relevant locals dict.  The
> "fake globals" environment will also have to create
> a fake "closure", a tuple of `ForwardRef` objects
> pre-created with the names of the free variables
> referenced by the `__annotate__` method.
>
> `ForwardRef` proxies created from `__annotate__`
> methods that reference free variables will map the
> names and closure values of those free variables into
> the locals dictionary, to ensure that `eval` uses
> the correct values for those names.

#### Requirement Summary
This section specifies the "stringizer" and "fake globals" technique that enables ``FORWARDREF`` and ``SOURCE`` format support. Undefined names in annotations are replaced by ``ForwardRef`` proxy objects that implement all dunder methods to produce textual representations of expressions. The PR implements this in ``Lib/annotationlib.py`` through the ``_Stringifier`` class (which implements all operator dunder methods to build string representations), the ``_StringifierDict`` (the "fake globals" dict with ``__missing__`` that creates stringizer instances for unknown keys), and ``call_annotate_function()`` which constructs the fake globals/locals/closure environment, invokes the ``__annotate__`` callable, and converts results to the requested format.

**File proportion:** 1/15 files mapped (6.7%) + 1/15 files associated (6.7%) = 2/15 accounted (13.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/annotationlib.py` | Added | +655 / -0 | `_Stringifier`, `_StringifierDict` | — |

#### Modification Summary
- **`Lib/annotationlib.py`**: Implements the ``_Stringifier`` class as the "stringizer" specified in this section, with all operator dunder methods (``__add__``, ``__getitem__``, ``__or__``, ``__iter__``, etc.) returning new ``_Stringifier`` instances whose ``__arg__`` is the textual representation of the operation. Implements ``_StringifierDict`` as the "fake globals" dict with a ``__missing__`` method that creates and caches ``_Stringifier`` instances for undefined names. Implements ``call_annotate_function()`` which replaces the annotate function's globals with a ``_StringifierDict`` (empty for SOURCE, pre-populated with real globals for FORWARDREF), constructs fake closure cells containing ``ForwardRef`` objects for free variables, calls the function requesting VALUE format, and then either extracts string values (for SOURCE) or returns the mixed real/proxy dict (for FORWARDREF).

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_annotationlib.py` | Added | +771 / -0 | Test suite also exercises the SOURCE/FORWARDREF stringizer-and-fake-globals pipeline (Section 18 behavior) in addition to Sections 15 and 17 | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
