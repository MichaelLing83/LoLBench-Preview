# CPython - PEP-654: Exception Groups and except*

**PR:** https://github.com/python/cpython/pull/29581
**Requirement Doc:** https://peps.python.org/pep-0654/

## Matching Statistics
- **Requirement Doc Coverage:** 12/12 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 12/34 files mapped (35.3%) + 22/34 files associated (64.7%) = 34/34 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 654: Exception Groups and except* | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Rationale | No | N/A | contextual |
| 5 | Specification | No | N/A | knowledge |
| 6 | Specification > ExceptionGroup and BaseExceptionGroup | Yes | Yes | implementation |
| 7 | Specification > ExceptionGroup and BaseExceptionGroup > Subclassing Exception Groups | Yes | Yes | implementation |
| 8 | Specification > ExceptionGroup and BaseExceptionGroup > The Traceback of an Exception Group | Yes | Yes | implementation |
| 9 | Specification > ExceptionGroup and BaseExceptionGroup > Handling Exception Groups | No | N/A | knowledge |
| 10 | Specification > except* | Yes | Yes | implementation |
| 11 | Specification > except* > Recursive Matching | Yes | Yes | implementation |
| 12 | Specification > except* > Unmatched Exceptions | Yes | Yes | implementation |
| 13 | Specification > except* > Naked Exceptions | Yes | Yes | implementation |
| 14 | Specification > except* > Raising exceptions in an `except*` block | Yes | Yes | implementation |
| 15 | Specification > except* > Chaining | Yes | Yes | implementation |
| 16 | Specification > except* > Raising New Exceptions | Yes | Yes | implementation |
| 17 | Specification > except* > Caught Exception Objects | Yes | Yes | implementation |
| 18 | Specification > except* > Forbidden Combinations | Yes | Yes | implementation |
| 19 | Backwards Compatibility | No | N/A | contextual |
| 20 | How to Teach This | No | N/A | contextual |
| 21 | Reference Implementation | No | N/A | process |
| 22 | Rejected Ideas | No | N/A | contextual |
| 23 | Rejected Ideas > Make Exception Groups Iterable | No | N/A | knowledge |
| 24 | Rejected Ideas > Make `ExceptionGroup` Extend `BaseException` | No | N/A | knowledge |
| 25 | Rejected Ideas > Make it Impossible to Wrap `BaseExceptions` in an Exception Group | No | N/A | knowledge |
| 26 | Rejected Ideas > Traceback Representation | No | N/A | knowledge |
| 27 | Rejected Ideas > Extend `except` to Handle Exception Groups | No | N/A | knowledge |
| 28 | Rejected Ideas > A New `except` Alternative | No | N/A | knowledge |
| 29 | Rejected Ideas > Applying an `except*` Clause on One Exception at a Time | No | N/A | knowledge |
| 30 | Rejected Ideas > Not Matching Naked Exceptions in `except*` | No | N/A | knowledge |
| 31 | Rejected Ideas > Allow mixing `except:` and `except*:` in the same `try` | No | N/A | knowledge |
| 32 | Rejected Ideas > `try*` instead of `except*` | No | N/A | knowledge |
| 33 | Rejected Ideas > Alternative syntax options | No | N/A | contextual |
| 34 | Programming Without 'except \*' | No | N/A | contextual |
| 35 | See Also | No | N/A | contextual |
| 36 | Acknowledgements | No | N/A | process |
| 37 | Acceptance | No | N/A | contextual |
| 38 | References | No | N/A | process |
| 39 | Copyright | No | N/A | process |
| 40 | Linked Issue python-trio/trio#611 — MultiError v2 | No | N/A | contextual |
| 41 | Linked Issue python-trio/trio#611 — MultiError v2 > Trio: Current design | No | N/A | contextual |
| 42 | Linked Issue python-trio/trio#611 — MultiError v2 > Trio: Proposal for new design | No | N/A | contextual |
| 43 | Linked Issue python-trio/trio#611 — MultiError v2 > Trio: Limitations of the current design | No | N/A | contextual |
| 44 | Linked Issue pytest-dev/pytest#8217 — Improve reporting when multiple teardowns raise an exception | No | N/A | contextual |
| 45 | Linked Issue pytest-dev/pytest#8217 — Improve reporting when multiple teardowns raise an exception > #8217: What's the problem this feature will solve? | No | N/A | contextual |
| 46 | Linked Issue pytest-dev/pytest#8217 — Improve reporting when multiple teardowns raise an exception > #8217: Describe the solution you'd like | No | N/A | contextual |
| 47 | Linked Issue pytest-dev/pytest#8217 — Improve reporting when multiple teardowns raise an exception > #8217: Alternative Solutions | No | N/A | contextual |
| 48 | Linked Issue python/exceptiongroups#4 — Introducing try..except* | No | N/A | contextual |
| 49 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: Disclaimer | No | N/A | contextual |
| 50 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: Syntax | No | N/A | contextual |
| 51 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: Semantics | No | N/A | contextual |
| 52 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: New raise* Syntax | No | N/A | contextual |
| 53 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: Unmatched Exceptions | No | N/A | contextual |
| 54 | Linked Issue python/exceptiongroups#4 — Introducing try..except* > #4: Exception Chaining | No | N/A | contextual |
| 55 | Linked Reference: Yury Selivanov's analysis of how exception groups will likely be used in asyncio programs | No | N/A | contextual |
| 56 | Linked Reference: Yury Selivanov's analysis of how exception groups will likely be used in asyncio programs > Asyncio: Types of errors | No | N/A | contextual |
| 57 | Linked Reference: Yury Selivanov's analysis of how exception groups will likely be used in asyncio programs > Asyncio: Types of user code | No | N/A | contextual |
| 58 | Linked Reference: Yury Selivanov's analysis of how exception groups will likely be used in asyncio programs > Asyncio: Summary | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/ast.rst` | documentation | — | Section 10 |
| 2 | `Doc/library/dis.rst` | documentation | — | Section 10 |
| 3 | `Doc/whatsnew/3.11.rst` | documentation | — | Section 6 |
| 4 | `Grammar/python.gram` | source | Section 10 | — |
| 5 | `Include/internal/pycore_ast.h` | generated | — | Section 10 |
| 6 | `Include/internal/pycore_ast_state.h` | generated | — | Section 10 |
| 7 | `Include/internal/pycore_pyerrors.h` | source | Section 6, Section 14 | — |
| 8 | `Include/opcode.h` | generated | — | Section 10 |
| 9 | `Lib/ast.py` | source | Section 10 | — |
| 10 | `Lib/importlib/_bootstrap_external.py` | source | Section 10 | — |
| 11 | `Lib/opcode.py` | source | Section 10 | — |
| 12 | `Lib/test/test_ast.py` | test | — | Section 10 |
| 13 | `Lib/test/test_compile.py` | test | — | Section 10, Section 18 |
| 14 | `Lib/test/test_dis.py` | test | — | Section 10 |
| 15 | `Lib/test/test_except_star.py` | test | — | Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18 |
| 16 | `Lib/test/test_exception_group.py` | test | — | Section 6 |
| 17 | `Lib/test/test_exception_variations.py` | test | — | Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18 |
| 18 | `Lib/test/test_exceptions.py` | test | — | Section 6 |
| 19 | `Lib/test/test_grammar.py` | test | — | Section 10 |
| 20 | `Lib/test/test_syntax.py` | test | — | Section 10, Section 18 |
| 21 | `Lib/test/test_sys_settrace.py` | test | — | Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18 |
| 22 | `Lib/test/test_unparse.py` | test | — | Section 10 |
| 23 | `Misc/NEWS.d/next/Core and Builtins/2021-11-22-13-05-32.bpo-45292.pfEouJ.rst` | documentation | — | Section 6 |
| 24 | `Objects/exceptions.c` | source | Section 6, Section 7, Section 8, Section 14 | — |
| 25 | `Objects/frameobject.c` | source | — | Section 10 |
| 26 | `Parser/Python.asdl` | source | Section 10 | — |
| 27 | `Parser/parser.c` | generated | — | Section 10 |
| 28 | `Python/Python-ast.c` | generated | — | Section 10 |
| 29 | `Python/ast.c` | source | Section 10 | — |
| 30 | `Python/ast_opt.c` | source | Section 10 | — |
| 31 | `Python/ceval.c` | source | Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18 | — |
| 32 | `Python/compile.c` | source | Section 10, Section 11, Section 12, Section 13, Section 14, Section 15, Section 16, Section 17, Section 18 | — |
| 33 | `Python/opcode_targets.h` | generated | — | Section 10 |
| 34 | `Python/symtable.c` | source | Section 10 | — |

---

## Section 6: ExceptionGroup and BaseExceptionGroup
*Path: Specification > ExceptionGroup and BaseExceptionGroup*
*Classification: Implementable*

> We propose to add two new builtin exception types:
> `BaseExceptionGroup(BaseException)` and
> `ExceptionGroup(BaseExceptionGroup, Exception)`. They are assignable to
> `Exception.__cause__` and `Exception.__context__`, and they can be
> raised and handled as any exception with `raise ExceptionGroup(...)` and
> `try: ... except ExceptionGroup: ...` or `raise BaseExceptionGroup(...)`
> and `try: ... except BaseExceptionGroup: ...`.
>
> Both have a constructor that takes two positional-only arguments: a message
> string and a sequence of the nested exceptions, which are exposed in the
> fields `message` and `exceptions`. For example:
> `ExceptionGroup('issues', [ValueError('bad value'), TypeError('bad type')])`.
> The difference between them is that `ExceptionGroup` can only wrap
> `Exception` subclasses while `BaseExceptionGroup` can wrap any
> `BaseException` subclass. The `BaseExceptionGroup` constructor
> inspects the nested exceptions and if they are all `Exception` subclasses,
> it returns an `ExceptionGroup` rather than a `BaseExceptionGroup`. The
> `ExceptionGroup` constructor raises a `TypeError` if any of the nested
> exceptions is not an `Exception` instance.  In the rest of the document,
> when we refer to an exception group, we mean either an `ExceptionGroup`
> or a `BaseExceptionGroup`. When it is necessary to make the distinction,
> we use the class name. For brevity, we will use `ExceptionGroup` in code
> examples that are relevant to both.
>
> Since an exception group can be nested, it represents a tree of exceptions,
> where the leaves are plain exceptions and each internal node represents a time
> at which the program grouped some unrelated exceptions into a new group and
> raised them together.
>
> The `BaseExceptionGroup.subgroup(condition)` method gives us a way to obtain
> an exception group that has the same metadata (message, cause, context,
> traceback) as the original group, and the same nested structure of groups, but
> contains only those exceptions for which the condition is true:
>
> ```
> >>> eg = ExceptionGroup(
> ...     "one",
> ...     [
> ...         TypeError(1),
> ...         ExceptionGroup(
> ...             "two",
> ...              [TypeError(2), ValueError(3)]
> ...         ),
> ...         ExceptionGroup(
> ...              "three",
> ...               [OSError(4)]
> ...         )
> ...     ]
> ... )
> >>> import traceback
> >>> traceback.print_exception(eg)
>   | ExceptionGroup: one (3 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | TypeError: 1
>     +---------------- 2 ----------------
>     | ExceptionGroup: two (2 sub-exceptions)
>     +-+---------------- 1 ----------------
>       | TypeError: 2
>       +---------------- 2 ----------------
>       | ValueError: 3
>       +------------------------------------
>     +---------------- 3 ----------------
>     | ExceptionGroup: three (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | OSError: 4
>       +------------------------------------
>
> >>> type_errors = eg.subgroup(lambda e: isinstance(e, TypeError))
> >>> traceback.print_exception(type_errors)
>   | ExceptionGroup: one (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | TypeError: 1
>     +---------------- 2 ----------------
>     | ExceptionGroup: two (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | TypeError: 2
>       +------------------------------------
> >>>
> ```
> The match condition is also applied to interior nodes (the exception
> groups), and a match causes the whole subtree rooted at this node
> to be included in the result.
>
> Empty nested groups are omitted from the result, as in the
> case of `ExceptionGroup("three")` in the example above.  If none of the
> exceptions match the condition, `subgroup` returns `None` rather
> than an empty group. The original `eg`
> is unchanged by `subgroup`, but the value returned is not necessarily a full
> new copy. Leaf exceptions are not copied, nor are exception groups which are
> fully contained in the result. When it is necessary to partition a
> group because the condition holds for some, but not all of its
> contained exceptions, a new `ExceptionGroup` or `BaseExceptionGroup`
> instance is created, while the `__cause__`, `__context__` and
> `__traceback__` fields are copied by reference, so they are shared with
> the original `eg`.
>
> If both the subgroup and its complement are needed, the
> `BaseExceptionGroup.split(condition)` method can be used:
>
> ```
> >>> type_errors, other_errors = eg.split(lambda e: isinstance(e, TypeError))
> >>> traceback.print_exception(type_errors)
>   | ExceptionGroup: one (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | TypeError: 1
>     +---------------- 2 ----------------
>     | ExceptionGroup: two (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | TypeError: 2
>       +------------------------------------
> >>> traceback.print_exception(other_errors)
>   | ExceptionGroup: one (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | ExceptionGroup: two (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | ValueError: 3
>       +------------------------------------
>     +---------------- 2 ----------------
>     | ExceptionGroup: three (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | OSError: 4
>       +------------------------------------
> >>>
> ```
> If a split is trivial (one side is empty), then None is returned for the
> other side:
>
> ```
> >>> other_errors.split(lambda e: isinstance(e, SyntaxError))
> (None, ExceptionGroup('one', [
>   ExceptionGroup('two', [
>     ValueError(3)
>   ]),
>   ExceptionGroup('three', [
>     OSError(4)])]))
> ```
> Since splitting by exception type is a very common use case, `subgroup` and
> `split` can take an exception type or tuple of exception types and treat it
> as a shorthand for matching that type: `eg.split(T)` divides `eg` into the
> subgroup of leaf exceptions that match the type `T`, and the subgroup of those
> that do not (using the same check as `except` for a match).

#### Requirement Summary
Specifies two new builtin types, `BaseExceptionGroup` and `ExceptionGroup`, with constructors, `message`/`exceptions` attributes, `subgroup()` and `split()` methods for partitioning by type or predicate, and `derive()` for creating modified copies.

**File proportion:** 2/34 files mapped (5.9%) + 4/34 files associated (11.8%) = 6/34 accounted (17.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_pyerrors.h` | Modified | +8 / -0 | — | — |
| `Objects/exceptions.c` | Modified | +135 / -23 | — | `_PyExc_CreateExceptionGroup`, `exceptiongroup_subset`, `get_matcher_type`, `exceptiongroup_split_check_match`, `exceptiongroup_split_recursive`, `BaseExceptionGroup_split`, `BaseExceptionGroup_subgroup`, `collect_exception_group_leaves` |

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_exception_group.py` | Modified | +2 / -1 | Test file for ExceptionGroup functionality | — | — |
| `Lib/test/test_exceptions.py` | Modified | +2 / -0 | Test file for exception handling | — | — |
| `Doc/whatsnew/3.11.rst` | Modified | +2 / -0 | What's New entry | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2021-11-22-13-05-32.bpo-45292.pfEouJ.rst` | Added | +1 / -0 | NEWS entry | — | — |

#### Modification Summary
- **`Include/internal/pycore_pyerrors.h`**: Declares the internal C structures and helper functions for `BaseExceptionGroup` and `ExceptionGroup`. Addresses the requirement for adding these new exception group types.
- **`Objects/exceptions.c`**: Implements `BaseExceptionGroup` and `ExceptionGroup` types with `subgroup()`, `split()`, `derive()`, and `__new__()` methods. Addresses the core requirement for new exception group types with all specified operations.

---

## Section 7: Subclassing Exception Groups
*Path: Specification > ExceptionGroup and BaseExceptionGroup > Subclassing Exception Groups*
*Classification: Implementable*

> It is possible to subclass exception groups, but when doing that it is
> usually necessary to specify how `subgroup()` and `split()` should
> create new instances for the matching or non-matching part of the partition.
> `BaseExceptionGroup` exposes an instance method `derive(self, excs)`
> which is called whenever `subgroup` and `split` need to create a new
> exception group. The parameter `excs` is the sequence of exceptions to
> include in the new group. Since `derive` has access to self, it can
> copy data from it to the new object. For example, if we need an exception
> group subclass that has an additional error code field, we can do this:
>
> ```
> class MyExceptionGroup(ExceptionGroup):
>     def __new__(cls, message, excs, errcode):
>         obj = super().__new__(cls, message, excs)
>         obj.errcode = errcode
>         return obj
>
>     def derive(self, excs):
>         return MyExceptionGroup(self.message, excs, self.errcode)
> ```
> Note that we override `__new__` rather than `__init__`; this is because
> `BaseExceptionGroup.__new__` needs to inspect the constructor arguments, and
> its signature is different from that of the subclass. Note also that our
> `derive` function does not copy the `__context__`, `__cause__` and
> `__traceback__` fields, because `subgroup` and `split` do that for us.
>
> With the class defined above, we have the following:
>
> ```
> >>> eg = MyExceptionGroup("eg", [TypeError(1), ValueError(2)], 42)
> >>>
> >>> match, rest = eg.split(ValueError)
> >>> print(f'match: {match!r}: {match.errcode}')
> match: MyExceptionGroup('eg', [ValueError(2)], 42): 42
> >>> print(f'rest: {rest!r}: {rest.errcode}')
> rest: MyExceptionGroup('eg', [TypeError(1)], 42): 42
> >>>
> ```
> If we do not override `derive`, then split calls the one defined
> on `BaseExceptionGroup`, which returns an instance of `ExceptionGroup`
> if all contained exceptions are of type `Exception`, and
> `BaseExceptionGroup` otherwise. For example:
>
> ```
> >>> class MyExceptionGroup(BaseExceptionGroup):
> ...     pass
> ...
> >>> eg = MyExceptionGroup("eg", [ValueError(1), KeyboardInterrupt(2)])
> >>> match, rest = eg.split(ValueError)
> >>> print(f'match: {match!r}')
> match: ExceptionGroup('eg', [ValueError(1)])
> >>> print(f'rest: {rest!r}')
> rest: BaseExceptionGroup('eg', [KeyboardInterrupt(2)])
> >>>
> ```

#### Requirement Summary
Specifies how to subclass exception groups by overriding the `derive()` method so that `subgroup()` and `split()` create instances of the correct subclass type.

**File proportion:** 1/34 files mapped (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/exceptions.c` | Modified | +135 / -23 | — | — |

#### Modification Summary
- **`Objects/exceptions.c`**: Implements the `derive(self, excs)` instance method on `BaseExceptionGroup`, which `subgroup` and `split` call to create new exception group instances when partitioning. Also refines `get_matcher_type` to properly validate tuple contents for type-based matching, supporting correct subclass-aware split/subgroup behavior needed for user-defined exception group subclasses.

---

## Section 8: The Traceback of an Exception Group
*Path: Specification > ExceptionGroup and BaseExceptionGroup > The Traceback of an Exception Group*
*Classification: Implementable*

> For regular exceptions, the traceback represents a simple path of frames,
> from the frame in which the exception was raised to the frame in which it
> was caught or, if it hasn't been caught yet, the frame that the program's
> execution is currently in. The list is constructed by the interpreter, which
> appends any frame from which it exits to the traceback of the 'current
> exception' if one exists. To support efficient appends, the links in a
> traceback's list of frames are from the oldest to the newest frame. Appending
> a new frame is then simply a matter of inserting a new head to the linked
> list referenced from the exception's `__traceback__` field. Crucially, the
> traceback's frame list is immutable in the sense that frames only need to be
> added at the head, and never need to be removed.
>
> We do not need to make any changes to this data structure. The `__traceback__`
> field of the exception group instance represents the path that the contained
> exceptions travelled through together after being joined into the
> group, and the same field on each of the nested exceptions
> represents the path through which this exception arrived at the frame of the
> merge.
>
> What we do need to change is any code that interprets and displays tracebacks,
> because it now needs to continue into tracebacks of nested exceptions, as
> in the following example:
>
> ```
> >>> def f(v):
> ...     try:
> ...         raise ValueError(v)
> ...     except ValueError as e:
> ...         return e
> ...
> >>> try:
> ...     raise ExceptionGroup("one", [f(1)])
> ... except ExceptionGroup as e:
> ...     eg = e
> ...
> >>> raise ExceptionGroup("two", [f(2), eg])
>  + Exception Group Traceback (most recent call last):
>  |   File "<stdin>", line 1, in <module>
>  | ExceptionGroup: two (2 sub-exceptions)
>  +-+---------------- 1 ----------------
>    | Traceback (most recent call last):
>    |   File "<stdin>", line 3, in f
>    | ValueError: 2
>    +---------------- 2 ----------------
>    | Exception Group Traceback (most recent call last):
>    |   File "<stdin>", line 2, in <module>
>    | ExceptionGroup: one (1 sub-exception)
>    +-+---------------- 1 ----------------
>      | Traceback (most recent call last):
>      |   File "<stdin>", line 3, in f
>      | ValueError: 1
>      +------------------------------------
> >>>
> ```

#### Requirement Summary
Specifies that exception groups share traceback objects across the tree, so tracebacks form a tree structure mirroring the group hierarchy, with rendering displaying a formatted tree rather than a single linear path.

**File proportion:** 1/34 files mapped (2.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Objects/exceptions.c` | Modified | +135 / -23 | — | — |

#### Modification Summary
- **`Objects/exceptions.c`**: Implements `collect_exception_group_leaves` and `_PyExc_ExceptionGroupProjection` which traverse the nested exception group tree to collect leaf exceptions and reconstruct subgroups, preserving the traceback structure across grouped exceptions. Also refines `exceptiongroup_subset` to correctly copy `__traceback__`, `__cause__`, and `__context__` by reference when creating partitioned groups.

---

## Section 10: except*
*Path: Specification > except**
*Classification: Implementable*

> We are proposing to introduce a new variant of the `try..except` syntax to
> simplify working with exception groups. The `*` symbol indicates that multiple
> exceptions can be handled by each `except*` clause:
>
> ```
> try:
>     ...
> except* SpamError:
>     ...
> except* FooError as e:
>     ...
> except* (BarError, BazError) as e:
>     ...
> ```
> In a traditional `try-except` statement there is only one exception to handle,
> so the body of at most one `except` clause executes; the first one that matches
> the exception. With the new syntax, an `except*` clause can match a subgroup
> of the exception group that was raised, while the remaining part is matched
> by following `except*` clauses. In other words, a single exception group can
> cause several `except*` clauses to execute, but each such clause executes at
> most once (for all matching exceptions from the group) and each exception is
> either handled by exactly one clause (the first one that matches its type)
> or is reraised at the end. The manner in which each exception is handled by
> a `try-except*` block is independent of any other exceptions in the group.
>
> For example, suppose that the body of the `try` block above raises
> `eg = ExceptionGroup('msg', [FooError(1), FooError(2), BazError()])`.
> The `except*` clauses are evaluated in order by calling `split` on the
> `unhandled` exception group, which is initially equal to `eg` and then shrinks
> as exceptions are matched and extracted from it.  In the first `except*` clause,
> `unhandled.split(SpamError)` returns `(None, unhandled)` so the body of this
> block is not executed and `unhandled` is unchanged. For the second block,
> `unhandled.split(FooError)` returns a non-trivial split `(match, rest)` with
> `match = ExceptionGroup('msg', [FooError(1), FooError(2)])`
> and `rest = ExceptionGroup('msg', [BazError()])`. The body of this `except*`
> block is executed, with the value of `e` and `sys.exc_info()` set to `match`.
> Then, `unhandled` is set to `rest`.
> Finally, the third block matches the remaining exception so it is executed
> with `e` and `sys.exc_info()` set to `ExceptionGroup('msg', [BazError()])`.
>
> Exceptions are matched using a subclass check. For example:
>
> ```
> try:
>     low_level_os_operation()
> except* OSError as eg:
>     for e in eg.exceptions:
>         print(type(e).__name__)
> ```
> could output:
>
> ```
> BlockingIOError
> ConnectionRefusedError
> OSError
> InterruptedError
> BlockingIOError
> ```
> The order of `except*` clauses is significant just like with the regular
> `try..except`:
>
> ```
> >>> try:
> ...     raise ExceptionGroup("problem", [BlockingIOError()])
> ... except* OSError as e:   # Would catch the error
> ...     print(repr(e))
> ... except* BlockingIOError: # Would never run
> ...     print('never')
> ...
> ExceptionGroup('problem', [BlockingIOError()])
> ```

#### Requirement Summary
Specifies the `except*` syntax for handling exception groups, where each clause matches leaf exceptions by type, binds the matched sub-group, and multiple clauses can handle different parts of the same group.

**File proportion:** 10/34 files mapped (29.4%) + 18/34 files associated (52.9%) = 28/34 accounted (82.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +15 / -2 | — | — |
| `Lib/ast.py` | Modified | +19 / -2 | `_Unparser` | — |
| `Lib/importlib/_bootstrap_external.py` | Modified | +2 / -1 | — | — |
| `Lib/opcode.py` | Modified | +3 / -0 | — | — |
| `Parser/Python.asdl` | Modified | +1 / -0 | — | — |
| `Python/ast.c` | Modified | +25 / -0 | — | `validate_stmt` |
| `Python/ast_opt.c` | Modified | +6 / -0 | — | `astfold_stmt` |
| `Python/ceval.c` | Modified | +347 / -8 | — | — |
| `Python/compile.c` | Modified | +338 / -1 | `compiler` | `stack_effect`, `find_ann`, `compiler.compiler_try_star_finally`, `compiler_try_except`, `compiler_try_star_except`, `compiler.compiler_try_star_except`, `compiler.compiler_try_star`, `compiler_visit_stmt` |
| `Python/symtable.c` | Modified | +6 / -0 | — | `symtable_visit_stmt` |

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_ast.py` | Modified | +23 / -0 | Test file for AST except* nodes | — | — |
| `Lib/test/test_compile.py` | Modified | +33 / -0 | Test file for except* compilation | — | — |
| `Lib/test/test_dis.py` | Modified | +22 / -30 | Test file for except* disassembly | — | — |
| `Lib/test/test_except_star.py` | Added | +976 / -0 | Comprehensive test suite for except* | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +278 / -0 | Test file for exception handling variations | — | — |
| `Lib/test/test_grammar.py` | Modified | +24 / -0 | Test file for except* grammar | — | — |
| `Lib/test/test_syntax.py` | Modified | +100 / -0 | Test file for except* syntax validation | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +175 / -0 | Test file for except* tracing | — | — |
| `Lib/test/test_unparse.py` | Modified | +16 / -0 | Test file for except* AST unparsing | — | — |
| `Include/internal/pycore_ast.h` | Modified | +14 / -3 | Generated AST header regenerated from `Parser/Python.asdl` to add the `TryStar` AST node | — | — |
| `Include/internal/pycore_ast_state.h` | Modified | +1 / -0 | Generated AST state for the new `TryStar` node | `ast_state` | — |
| `Include/opcode.h` | Modified | +4 / -2 | Generated opcode header adding `CHECK_EG_MATCH`, `PREP_RERAISE_STAR`, and related opcode constants | — | — |
| `Parser/parser.c` | Modified | +2770 / -1826 | Generated PEG parser regenerated from `Grammar/python.gram` for the except* rule | — | — |
| `Python/Python-ast.c` | Modified | +229 / -0 | Generated AST constructors/visitors regenerated from `Parser/Python.asdl` for `TryStar` nodes | — | `_PyAST_Fini`, `init_types`, `_PyAST_TryStar`, `ast2obj_stmt`, `obj2ast_stmt`, `astmodule_exec` |
| `Python/opcode_targets.h` | Modified | +3 / -3 | Generated opcode dispatch table updated for the new opcodes | — | — |
| `Objects/frameobject.c` | Modified | +4 / -1 | Frame object adaptation for except* opcodes | — | `mark_stacks` |
| `Doc/library/ast.rst` | Modified | +31 / -0 | Documents the `TryStar` AST node introduced by this section | — | — |
| `Doc/library/dis.rst` | Modified | +26 / -0 | Documents the new `JUMP_IF_NOT_EG_MATCH` / `PREP_RERAISE_STAR` opcodes introduced by this section | — | — |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the `except*` grammar rule as a new variant of try/except blocks. Addresses the core syntactic requirement for except* clauses.

- **`Lib/ast.py`**: Adds `TryStar` AST node handling in the ast module. Addresses the Python-level AST API requirement.
- **`Lib/importlib/_bootstrap_external.py`**: Updates the magic number for new opcodes. Required for bytecode compatibility.
- **`Lib/opcode.py`**: Registers the new except* opcodes. Addresses the opcode registration requirement.
- **`Parser/Python.asdl`**: Adds `TryStar` to the ASDL grammar definition. Addresses the AST definition requirement.

- **`Python/ast.c`**: AST validation for except* nodes.
- **`Python/ast_opt.c`**: AST optimization handling for except* nodes.
- **`Python/ceval.c`**: Implements the except* evaluation semantics including `CHECK_EG_MATCH` and `PREP_RERAISE_STAR` opcodes. Addresses the core except* runtime behavior requirement.
- **`Python/compile.c`**: Compiles except* AST nodes into bytecode. Implements the control flow for matching exception groups against except* clauses. Addresses the except* compilation requirement.

- **`Python/symtable.c`**: Symbol table analysis for except* blocks.

---

## Section 11: Recursive Matching
*Path: Specification > except* > Recursive Matching*
*Classification: Implementable*

> The matching of `except*` clauses against an exception group is performed
> recursively, using the `split()` method:
>
> ```
> >>> try:
> ...     raise ExceptionGroup(
> ...         "eg",
> ...         [
> ...             ValueError('a'),
> ...             TypeError('b'),
> ...             ExceptionGroup(
> ...                 "nested",
> ...                 [TypeError('c'), KeyError('d')])
> ...         ]
> ...     )
> ... except* TypeError as e1:
> ...     print(f'e1 = {e1!r}')
> ... except* Exception as e2:
> ...     print(f'e2 = {e2!r}')
> ...
> e1 = ExceptionGroup('eg', [TypeError('b'), ExceptionGroup('nested', [TypeError('c')])])
> e2 = ExceptionGroup('eg', [ValueError('a'), ExceptionGroup('nested', [KeyError('d')])])
> >>>
> ```

#### Requirement Summary
The matching of `except*` clauses against an exception group is performed recursively, using the `split()` method:.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | — |
| `Python/compile.c` | Modified | +338 / -1 | — | — |

The functions named in the modification summary (`exception_group_match` for `ceval.c`; `compiler_try_star_except` for `compile.c`) implement the recursive-matching behavior here, but their `(file, class, function)` tuples are anchored once elsewhere per Check 28: `exception_group_match` under Section 17 (Caught Exception Objects) and `compiler_try_star_except` under Section 10 (Specification > except*). This section's row therefore leaves the Functions cells as `—` and the summary documents the specific functions involved.

#### Modification Summary
- **`Python/ceval.c`**: Implements `exception_group_match` which calls `split()` on the active exception group with the clause type to recursively decompose nested groups. The match and rest sub-groups are placed on the stack so that nested exception groups are recursively split across `except*` clauses. The `exception_group_match` function scope is listed once under Section 17 to satisfy Check 28.
- **`Python/compile.c`**: `compiler_try_star_except` emits the `JUMP_IF_NOT_EG_MATCH` instruction for each `except*` clause, generating the control flow that iteratively splits the remaining unhandled exception group against each clause's type, enabling recursive matching through nested groups. The `compiler_try_star_except` function scope is listed once under Section 9.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Exercises recursive `split`-based matching of nested exception groups against `except*` clauses | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover recursive `except*` matching across nested groups | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests assert handler entry order under recursive `except*` matching | — | — |

---

## Section 12: Unmatched Exceptions
*Path: Specification > except* > Unmatched Exceptions*
*Classification: Implementable*

> If not all exceptions in an exception group were matched by the `except*`
> clauses, the remaining part of the group is propagated on:
>
> ```
> >>> try:
> ...     try:
> ...         raise ExceptionGroup(
> ...             "msg", [
> ...                  ValueError('a'), TypeError('b'),
> ...                  TypeError('c'), KeyError('e')
> ...             ]
> ...         )
> ...     except* ValueError as e:
> ...         print(f'got some ValueErrors: {e!r}')
> ...     except* TypeError as e:
> ...         print(f'got some TypeErrors: {e!r}')
> ... except ExceptionGroup as e:
> ...     print(f'propagated: {e!r}')
> ...
> got some ValueErrors: ExceptionGroup('msg', [ValueError('a')])
> got some TypeErrors: ExceptionGroup('msg', [TypeError('b'), TypeError('c')])
> propagated: ExceptionGroup('msg', [KeyError('e')])
> >>>
> ```

#### Requirement Summary
Specifies that unmatched exceptions from an exception group are propagated after all `except*` clauses execute, preserving the group structure of the remainder.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | — |
| `Python/compile.c` | Modified | +338 / -1 | — | — |

The functions named in the modification summary (`do_reraise_star` for `ceval.c`; `compiler_try_star_except` for `compile.c`) implement the unmatched-propagation behavior here, but their `(file, class, function)` tuples are anchored once under Section 14 (Raising exceptions in an `except*` block) for `do_reraise_star` and under Section 10 for `compiler_try_star_except` per Check 28; this section's row therefore leaves the Functions cells as `—` and the summary documents the specific functions involved.

#### Modification Summary
- **`Python/ceval.c`**: After all `except*` clauses are evaluated, the `PREP_RERAISE_STAR` opcode invokes `do_reraise_star`, which collects unmatched exceptions from the result list and re-raises them as a new exception group, propagating the unhandled remainder. The `do_reraise_star` function scope is listed once under Section 13.
- **`Python/compile.c`**: `compiler_try_star_except` emits, after the last `except*` handler, code to append the remaining unhandled exception (the "rest" after all splits) to the result list, then emits `PREP_RERAISE_STAR` to propagate any unmatched exceptions. The `compiler_try_star_except` function scope is listed once under Section 9.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Exercises propagation of unmatched remainder after `except*` clauses execute | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover unmatched-exception propagation through `except*` | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests assert handler-completion behavior when exceptions remain unmatched | — | — |

---

## Section 13: Naked Exceptions
*Path: Specification > except* > Naked Exceptions*
*Classification: Implementable*

> If the exception raised inside the `try` body is not of type `ExceptionGroup`
> or `BaseExceptionGroup`, we call it a `naked` exception. If its type matches
> one of the `except*` clauses, it is caught and wrapped by an `ExceptionGroup`
> (or `BaseExceptionGroup` if it is not an `Exception` subclass) with an empty
> message string. This is to make the type of `e` consistent and statically known:
>
> ```
> >>> try:
> ...     raise BlockingIOError
> ... except* OSError as e:
> ...     print(repr(e))
> ...
> ExceptionGroup('', [BlockingIOError()])
> ```
> However, if a naked exception is not caught, it propagates in its original
> naked form:
>
> ```
> >>> try:
> ...     try:
> ...         raise ValueError(12)
> ...     except* TypeError as e:
> ...         print('never')
> ... except ValueError as e:
> ...     print(f'caught ValueError: {e!r}')
> ...
> caught ValueError: ValueError(12)
> >>>
> ```

#### Requirement Summary
If the exception raised inside the `try` body is not of type `ExceptionGroup` or `BaseExceptionGroup`, we call it a `naked` exception. If its type matches one of the `except*` clauses, it is caught and wrapped by an `ExceptionGroup`.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | — |
| `Python/compile.c` | Modified | +338 / -1 | — | — |

The functions named in the modification summary implement the naked-exception behavior here, but their `(file, class, function)` tuples are anchored once elsewhere per Check 28: `exception_group_match` under Section 17, `compiler_try_star_except` under Section 10, `do_reraise_star` under Section 14, `check_except_star_type_valid` under Section 17. This section's row therefore leaves the Functions cells as `—`.

#### Modification Summary
- **`Python/ceval.c`**: In `exception_group_match`, when a non-exception-group ("naked") exception matches the `except*` type, it is wrapped in a new `ExceptionGroup` with an empty message via `_PyExc_CreateExceptionGroup("", ...)`. `check_except_star_type_valid` rejects bare `BaseExceptionGroup`/`ExceptionGroup` types and tuples containing them. If the naked exception does not match any clause, it propagates in its original unwrapped form through `do_reraise_star`. The `exception_group_match` scope is listed under Section 17, `do_reraise_star` under Section 14, and `check_except_star_type_valid` under Section 17.
- **`Python/compile.c`**: `compiler_try_star_except` generates bytecode that passes both naked and grouped exceptions through the same `JUMP_IF_NOT_EG_MATCH` / `PREP_RERAISE_STAR` pipeline, relying on the runtime to handle wrapping and unwrapping of naked exceptions transparently. The `compiler_try_star_except` function scope is listed once under Section 9.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Exercises naked-exception wrapping and pass-through behavior under `except*` | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover naked-exception handling through `except*` | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover wrapping of naked exceptions in `except*` handlers | — | — |

---

## Section 14: Raising exceptions in an `except*` block
*Path: Specification > except* > Raising exceptions in an `except*` block*
*Classification: Implementable*

> In a traditional `except` block, there are two ways to raise exceptions:
> `raise e` to explicitly raise an exception object `e`, or naked `raise` to
> reraise the 'current exception'. When `e` is the current exception, the two
> forms are not equivalent because a reraise does not add the current frame to
> the stack:
>
> ```
> def foo():                           | def foo():
>     try:                             |     try:
>         1 / 0                        |         1 / 0
>     except ZeroDivisionError as e:   |     except ZeroDivisionError:
>         raise e                      |         raise
>                                      |
> foo()                                | foo()
>                                      |
> Traceback (most recent call last):   | Traceback (most recent call last):
>   File "/Users/guido/a.py", line 7   |   File "/Users/guido/b.py", line 7
>    foo()                             |     foo()
>   File "/Users/guido/a.py", line 5   |   File "/Users/guido/b.py", line 3
>    raise e                           |     1/0
>   File "/Users/guido/a.py", line 3   | ZeroDivisionError: division by zero
>    1/0                               |
> ZeroDivisionError: division by zero  |
> ```
> This holds for exception groups as well, but the situation is now more complex
> because there can be exceptions raised and reraised from multiple `except*`
> clauses, as well as unhandled exceptions that need to propagate.
> The interpreter needs to combine all those exceptions into a result, and
> raise that.
>
> The reraised exceptions and the unhandled exceptions are subgroups of the
> original group, and share its metadata (cause, context, traceback).
> On the other hand, each of the explicitly raised exceptions has its own
> metadata - the traceback contains the line from which it was raised, its
> cause is whatever it may have been explicitly chained to, and its context is the
> value of `sys.exc_info()` in the `except*` clause of the raise.
>
> In the aggregated exception group, the reraised and unhandled exceptions have
> the same relative structure as in the original exception, as if they were split
> off together in one `subgroup` call. For example, in the snippet below the
> inner `try-except*` block raises an `ExceptionGroup` that contains all
> `ValueErrors` and `TypeErrors` merged back into the same shape they had in
> the original `ExceptionGroup`:
>
> ```
> >>> try:
> ...     try:
> ...         raise ExceptionGroup(
> ...             "eg",
> ...             [
> ...                 ValueError(1),
> ...                 TypeError(2),
> ...                 OSError(3),
> ...                 ExceptionGroup(
> ...                     "nested",
> ...                     [OSError(4), TypeError(5), ValueError(6)])
> ...             ]
> ...         )
> ...     except* ValueError as e:
> ...         print(f'*ValueError: {e!r}')
> ...         raise
> ...     except* OSError as e:
> ...         print(f'*OSError: {e!r}')
> ... except ExceptionGroup as e:
> ...     print(repr(e))
> ...
> *ValueError: ExceptionGroup('eg', [ValueError(1), ExceptionGroup('nested', [ValueError(6)])])
> *OSError: ExceptionGroup('eg', [OSError(3), ExceptionGroup('nested', [OSError(4)])])
> ExceptionGroup('eg', [ValueError(1), TypeError(2), ExceptionGroup('nested', [TypeError(5), ValueError(6)])])
> >>>
> ```
> When exceptions are raised explicitly, they are independent of the original
> exception group, and cannot be merged with it (they have their own cause,
> context and traceback). Instead, they are combined into a new `ExceptionGroup`
> (or `BaseExceptionGroup`), which also contains the reraised/unhandled
> subgroup described above.
>
> In the following example, the `ValueErrors` were raised so they are in their
> own `ExceptionGroup`, while the `OSErrors` were reraised so they were
> merged with the unhandled `TypeErrors`.
>
> ```
> >>> try:
> ...     raise ExceptionGroup(
> ...         "eg",
> ...         [
> ...             ValueError(1),
> ...             TypeError(2),
> ...             OSError(3),
> ...             ExceptionGroup(
> ...                 "nested",
> ...                 [OSError(4), TypeError(5), ValueError(6)])
> ...         ]
> ...     )
> ... except* ValueError as e:
> ...     print(f'*ValueError: {e!r}')
> ...     raise e
> ... except* OSError as e:
> ...     print(f'*OSError: {e!r}')
> ...     raise
> ...
> *ValueError: ExceptionGroup('eg', [ValueError(1), ExceptionGroup('nested', [ValueError(6)])])
> *OSError: ExceptionGroup('eg', [OSError(3), ExceptionGroup('nested', [OSError(4)])])
>   | ExceptionGroup:  (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 15, in <module>
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: eg (2 sub-exceptions)
>     +-+---------------- 1 ----------------
>       | ValueError: 1
>       +---------------- 2 ----------------
>       | ExceptionGroup: nested (1 sub-exception)
>       +-+---------------- 1 ----------------
>         | ValueError: 6
>         +------------------------------------
>     +---------------- 2 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: eg (3 sub-exceptions)
>     +-+---------------- 1 ----------------
>       | TypeError: 2
>       +---------------- 2 ----------------
>       | OSError: 3
>       +---------------- 3 ----------------
>       | ExceptionGroup: nested (2 sub-exceptions)
>       +-+---------------- 1 ----------------
>         | OSError: 4
>         +---------------- 2 ----------------
>         | TypeError: 5
>         +------------------------------------
> >>>
> ```

#### Requirement Summary
When exceptions are raised or reraised inside `except*` blocks, the interpreter must aggregate reraised exceptions (which preserve the original group's metadata and structure) together with unhandled exceptions and explicitly raised exceptions into a single result `ExceptionGroup`. The `PREP_RERAISE_STAR` opcode and `_PyExc_PrepReraiseStar` helper implement this merging logic.

**File proportion:** 4/34 files mapped (11.8%) + 3/34 files associated (8.8%) = 7/34 accounted (20.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_pyerrors.h` | Modified | +8 / -0 | — | — |
| `Objects/exceptions.c` | Modified | +299 / -1 | — | `_PyExc_PrepReraiseStar`, `_PyExc_ExceptionGroupProjection` |
| `Python/ceval.c` | Modified | +347 / -8 | — | `do_reraise_star` |
| `Python/compile.c` | Modified | +338 / -1 | — | `compiler_try_star` |

#### Modification Summary
- **`Include/internal/pycore_pyerrors.h`**: Declares internal C structures and helper function prototypes (including `_PyExc_PrepReraiseStar`) used by the exception group reraise merging logic.
- **`Objects/exceptions.c`**: `_PyExc_PrepReraiseStar` merges reraised subgroups and new exceptions into an aggregated `ExceptionGroup`. It calls `_PyExc_ExceptionGroupProjection` to split the original group into reraised vs. new-exception components, preserving the original group's tree structure for reraised exceptions.
- **`Python/ceval.c`**: Implements the `PREP_RERAISE_STAR` opcode handler `do_reraise_star`, which calls `_PyExc_PrepReraiseStar` with the original exception and the list of raised/reraised exceptions collected from `except*` clauses.
- **`Python/compile.c`**: `compiler_try_star` / `compiler_try_star_except` compile the reraising control flow for `except*` blocks, emitting `PREP_RERAISE_STAR` after collecting raised/reraised exceptions from each handler clause.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Validates raising and reraising semantics inside `except*` handlers | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover raising/reraising in `except*` blocks | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover handler reraises and aggregated reraise groups | — | — |

---

## Section 15: Chaining
*Path: Specification > except* > Chaining*
*Classification: Implementable*

> Explicitly raised exception groups are chained as with any exceptions. The
> following example shows how part of `ExceptionGroup` "one" became the
> context for `ExceptionGroup` "two", while the other part was combined with
> it into the new `ExceptionGroup`.
>
> ```
> >>> try:
> ...     raise ExceptionGroup("one", [ValueError('a'), TypeError('b')])
> ... except* ValueError:
> ...     raise ExceptionGroup("two", [KeyError('x'), KeyError('y')])
> ...
>   | ExceptionGroup:  (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: one (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | ValueError: a
>       +------------------------------------
>     |
>     | During handling of the above exception, another exception occurred:
>     |
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 4, in <module>
>     | ExceptionGroup: two (2 sub-exceptions)
>     +-+---------------- 1 ----------------
>       | KeyError: 'x'
>       +---------------- 2 ----------------
>       | KeyError: 'y'
>       +------------------------------------
>     +---------------- 2 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: one (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | TypeError: b
>       +------------------------------------
> >>>
> ```

#### Requirement Summary
Specifies that exceptions raised in `except*` handlers are chained with standard `__context__` linking, and the final propagated group merges unmatched exceptions with newly raised ones.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | `is_same_exception_metadata` |
| `Python/compile.c` | Modified | +338 / -1 | — | `compiler_try_star_finally` |

#### Modification Summary
- **`Python/ceval.c`**: In `do_reraise_star`, exceptions raised in `except*` handlers are detected by comparing metadata (`__traceback__`, `__context__`, `__cause__`) against the original exception via `is_same_exception_metadata`. Newly raised exceptions retain their implicit chaining (the matched sub-group as `__context__`), and are combined with reraised/unhandled exceptions into the final exception group.
- **`Python/compile.c`**: `compiler_try_star_except` / `compiler_try_star_finally` emit `SETUP_FINALLY`/`SETUP_CLEANUP` around each `except*` handler body so that exceptions raised within a handler are caught, appended to the result list via `LIST_APPEND`, and later processed by `PREP_RERAISE_STAR` which merges them with proper chaining.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Validates `__context__` / `__cause__` chaining of exceptions raised inside `except*` handlers | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover exception chaining in `except*` blocks | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover chained exceptions emerging from `except*` handlers | — | — |

---

## Section 16: Raising New Exceptions
*Path: Specification > except* > Raising New Exceptions*
*Classification: Implementable*

> In the previous examples the explicit raises were of the exceptions that
> were caught, so for completion we show a new exception being raised, with
> chaining:
>
> ```
> >>> try:
> ...     raise TypeError('bad type')
> ... except* TypeError as e:
> ...     raise ValueError('bad value') from e
> ...
>   | ExceptionGroup:  (1 sub-exception)
>   +-+---------------- 1 ----------------
>     | Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | TypeError: bad type
>     +------------------------------------
>
> The above exception was the direct cause of the following exception:
>
> Traceback (most recent call last):
>   File "<stdin>", line 4, in <module>
> ValueError: bad value
> >>>
> ```
> Note that exceptions raised in one `except*` clause are not eligible to match
> other clauses from the same `try` statement:
>
> ```
> >>> try:
> ...     raise TypeError(1)
> ... except* TypeError:
> ...     raise ValueError(2) from None  # <- not caught in the next clause
> ... except* ValueError:
> ...     print('never')
> ...
> Traceback (most recent call last):
>   File "<stdin>", line 4, in <module>
> ValueError: 2
> >>>
> ```
> Raising a new instance of a naked exception does not cause this exception to
> be wrapped by an exception group. Rather, the exception is raised as is, and
> if it needs to be combined with other propagated exceptions, it becomes a
> direct child of the new exception group created for that:
>
> ```
> >>> try:
> ...     raise ExceptionGroup("eg", [ValueError('a')])
> ... except* ValueError:
> ...     raise KeyError('x')
> ...
>   | ExceptionGroup:  (1 sub-exception)
>   +-+---------------- 1 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: eg (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | ValueError: a
>       +------------------------------------
>     |
>     | During handling of the above exception, another exception occurred:
>     |
>     | Traceback (most recent call last):
>     |   File "<stdin>", line 4, in <module>
>     | KeyError: 'x'
>     +------------------------------------
> >>>
> >>> try:
> ...     raise ExceptionGroup("eg", [ValueError('a'), TypeError('b')])
> ... except* ValueError:
> ...     raise KeyError('x')
> ...
>   | ExceptionGroup:  (2 sub-exceptions)
>   +-+---------------- 1 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: eg (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | ValueError: a
>       +------------------------------------
>     |
>     | During handling of the above exception, another exception occurred:
>     |
>     | Traceback (most recent call last):
>     |   File "<stdin>", line 4, in <module>
>     | KeyError: 'x'
>     +---------------- 2 ----------------
>     | Exception Group Traceback (most recent call last):
>     |   File "<stdin>", line 2, in <module>
>     | ExceptionGroup: eg (1 sub-exception)
>     +-+---------------- 1 ----------------
>       | TypeError: b
>       +------------------------------------
> >>>
> ```
> Finally, as an example of how the proposed semantics can help us work
> effectively with exception groups, the following code ignores all `EPIPE`
> OS errors, while letting all other exceptions propagate.
>
> ```
> try:
>     low_level_os_operation()
> except* OSError as errors:
>     exc = errors.subgroup(lambda e: e.errno != errno.EPIPE)
>     if exc is not None:
>         raise exc from None
> ```

#### Requirement Summary
Specifies that newly raised exceptions inside `except*` handlers are separated from reraised ones and merged into the final propagated exception group with proper chaining.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | — |
| `Python/compile.c` | Modified | +338 / -1 | — | — |

The functions named in the modification summary (`do_reraise_star` / `is_same_exception_metadata` for `ceval.c`; `compiler_try_star_except` for `compile.c`) implement the newly-raised-exception behavior here, but their `(file, class, function)` tuples are anchored once under Section 14 (`do_reraise_star`), Section 15 (`is_same_exception_metadata`), and Section 10 (`compiler_try_star_except`) per Check 28. This section's row therefore leaves the Functions cells as `—`.

#### Modification Summary
- **`Python/ceval.c`**: In `do_reraise_star`, when an `except*` handler raises a new (non-reraised) exception, it is separated from reraised exceptions by the `is_same_exception_metadata` check and placed into the `raised_list`. These raised exceptions are then combined into a new exception group via `_PyExc_CreateExceptionGroup`, ensuring newly raised exceptions are not eligible for matching by subsequent `except*` clauses in the same `try` block. The `do_reraise_star` scope is listed under Section 14 and `is_same_exception_metadata` under Section 14.
- **`Python/compile.c`**: `compiler_try_star_except` generates bytecode so that each `except*` handler body is wrapped in its own try/finally. Exceptions raised within a handler are caught and appended to the result list, then control jumps past subsequent handlers to `PREP_RERAISE_STAR`, preventing cross-clause matching of newly raised exceptions. The `compiler_try_star_except` function scope is listed once under Section 9.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Validates newly raised exceptions in `except*` handlers are not matched by subsequent clauses and are aggregated into the propagated group | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover newly raised exceptions inside `except*` blocks | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover newly raised exceptions emerging from `except*` handlers | — | — |

---

## Section 17: Caught Exception Objects
*Path: Specification > except* > Caught Exception Objects*
*Classification: Implementable*

> It is important to point out that the exception group bound to `e` in an
> `except*` clause is an ephemeral object. Raising it via `raise` or
> `raise e` will not cause changes to the overall shape of the original
> exception group.  Any modifications to `e` will likely be lost:
>
> ```
> >>> eg = ExceptionGroup("eg", [TypeError(12)])
> >>> eg.foo = 'foo'
> >>> try:
> ...     raise eg
> ... except* TypeError as e:
> ...     e.foo = 'bar'
> ... #   ^----------- ``e`` is an ephemeral object that might get
> >>> #                      destroyed after the ``except*`` clause.
> >>> eg.foo
> 'foo'
> ```

#### Requirement Summary
Specifies that the exception group bound in an `except*` clause is ephemeral — reraising it does not alter the original group's structure, and the caught object should not be stored or referenced after the handler.

**File proportion:** 2/34 files mapped (5.9%) + 3/34 files associated (8.8%) = 5/34 accounted (14.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | `exception_group_match` |
| `Python/compile.c` | Modified | +338 / -1 | — | — |

The `compiler_try_star_except` function named in the `Python/compile.c` modification summary implements the bytecode for preserving the original exception during handler bodies, but its `(file, class, function)` tuple is anchored once under Section 10 per Check 28; this section's `compile.c` row therefore leaves the Functions cells as `—` and the summary documents the specific function involved. The `exception_group_match` scope for `Python/ceval.c` is owned here in Section 17 (the caught-object ephemerality is most directly implemented by the matched/rest split it performs).

#### Modification Summary
- **`Python/ceval.c`**: In `exception_group_match`, the matched sub-group bound to `e` in an `except*` clause is an ephemeral copy produced by `split()`. The original exception group is preserved on the stack as `orig`, so modifications to the ephemeral `e` do not affect the original exception group's structure or attributes.
- **`Python/compile.c`**: `compiler_try_star_except` generates bytecode that saves a copy of the original exception (`DUP_TOP_TWO` + `ROT_FOUR`) before entering `except*` handlers, and uses the original (not the handler-bound copy) when constructing the final reraise via `PREP_RERAISE_STAR`, ensuring the ephemeral nature of caught exception objects. The `compiler_try_star_except` function scope is listed once under Section 9.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Validates the ephemeral nature of the caught exception object bound by `except*` | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover the ephemeral caught-group semantics | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover lifecycle of the caught `except*` exception binding | — | — |

---

## Section 18: Forbidden Combinations
*Path: Specification > except* > Forbidden Combinations*
*Classification: Implementable*

> It is not possible to use both traditional `except` blocks and the new
> `except*` clauses in the same `try` statement. The following is a
> `SyntaxError`:
>
> ```
> try:
>     ...
> except ValueError:
>     pass
> except* CancelledError:  # <- SyntaxError:
>     pass                 #    combining ``except`` and ``except*``
>                          #    is prohibited
> ```
> It is possible to catch the `ExceptionGroup` and `BaseExceptionGroup`
> types with `except`, but not with `except*` because the latter is
> ambiguous:
>
> ```
> try:
>     ...
> except ExceptionGroup:  # <- This works
>     pass
>
> try:
>     ...
> except* ExceptionGroup:  # <- Runtime error
>     pass
>
> try:
>     ...
> except* (TypeError, ExceptionGroup):  # <- Runtime error
>     pass
> ```
> An empty "match anything" `except*` block is not supported as its meaning may
> be confusing:
>
> ```
> try:
>     ...
> except*:   # <- SyntaxError
>     pass
> ```
> `continue`, `break`, and `return` are disallowed in `except*` clauses,
> causing a `SyntaxError`. This is because the exceptions in an
> `ExceptionGroup` are assumed to be independent, and the presence or absence
> of one of them should not impact handling of the others, as could happen if we
> allow an `except*` clause to change the way control flows through other
> clauses.

#### Requirement Summary
It is not possible to use both traditional `except` blocks and the new `except*` clauses in the same `try` statement. The following is a `SyntaxError`:.

**File proportion:** 2/34 files mapped (5.9%) + 5/34 files associated (14.7%) = 7/34 accounted (20.6%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/ceval.c` | Modified | +347 / -8 | — | `check_except_star_type_valid` |
| `Python/compile.c` | Modified | +338 / -1 | — | `compiler_unwind_fblock_stack`, `compiler_unwind_fblock` |

#### Modification Summary
- **`Python/ceval.c`**: Implements `check_except_star_type_valid`, which raises a `TypeError` at runtime if `except*` is used to catch `ExceptionGroup` or `BaseExceptionGroup` (or a tuple containing them), enforcing the prohibition on catching exception groups with `except*`.
- **`Python/compile.c`**: Adds the `EXCEPTION_GROUP_HANDLER` fblock type and checks in `compiler_unwind_fblock_stack` / `compiler_unwind_fblock` that raise a `SyntaxError` if `break`, `continue`, or `return` appear inside an `except*` block. The grammar and compiler also prevent mixing `except` and `except*` in the same `try` via the separate `TryStar_kind` AST node, and disallow bare `except*:` without a type.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_compile.py` | Modified | +12 / -0 | Validates compile-time rejection of forbidden `break`/`continue`/`return` inside `except*` blocks | — | — |
| `Lib/test/test_except_star.py` | Added | +1480 / -0 | Validates runtime/grammar enforcement of forbidden combinations (mixed `except`/`except*`, group types in `except*`) | — | — |
| `Lib/test/test_exception_variations.py` | Modified | +84 / -0 | Variation tests cover forbidden combinations of handler clauses | — | — |
| `Lib/test/test_syntax.py` | Modified | +24 / -0 | Validates `SyntaxError` for mixed `except`/`except*` and bare `except*:` clauses | — | — |
| `Lib/test/test_sys_settrace.py` | Modified | +56 / -0 | Trace tests cover behavior at the runtime check for forbidden type combinations | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
