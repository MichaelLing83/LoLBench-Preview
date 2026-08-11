# CPython - PEP 709: Inlined comprehensions

**PR:** https://github.com/python/cpython/pull/101441
**Requirement Doc:** https://peps.python.org/pep-0709/

## Matching Statistics
- **Requirement Doc Coverage:** 1/1 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 10/27 files mapped (37.0%) + 17/27 files associated (63.0%) = 27/27 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 709: Inlined comprehensions | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Rationale | No | N/A | contextual |
| 5 | Specification | Yes | Yes | implementation |
| 6 | Backwards Compatibility | No | N/A | contextual |
| 7 | Backwards Compatibility > locals() includes outer variables | No | N/A | knowledge |
| 8 | Backwards Compatibility > No comprehension frame in tracebacks | No | N/A | knowledge |
| 9 | Backwards Compatibility > Tracing/profiling will no longer show a call/return for the comprehension | No | N/A | knowledge |
| 10 | Impact on other Python implementations | No | N/A | contextual |
| 11 | How to Teach This | No | N/A | contextual |
| 12 | Security Implications | No | N/A | contextual |
| 13 | Reference Implementation | No | N/A | process |
| 14 | Rejected Ideas | No | N/A | contextual |
| 15 | Rejected Ideas > More efficient comprehension calling, without inlining | No | N/A | knowledge |
| 16 | Copyright | No | N/A | process |
| 17 | Linked Issue #101310 — gh-97933: add opcode for more efficient comprehension execution | No | N/A | knowledge |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/dis.rst` | documentation | — | Section 5 |
| 2 | `Doc/whatsnew/3.12.rst` | documentation | — | Section 5 |
| 3 | `Include/internal/pycore_code.h` | source | Section 5 | — |
| 4 | `Include/internal/pycore_compile.h` | source | Section 5 | — |
| 5 | `Include/internal/pycore_flowgraph.h` | source | Section 5 | — |
| 6 | `Include/internal/pycore_opcode.h` | generated | — | Section 5 |
| 7 | `Include/internal/pycore_symtable.h` | source | Section 5 | — |
| 8 | `Include/opcode.h` | generated | — | Section 5 |
| 9 | `Lib/importlib/_bootstrap_external.py` | source | — | Section 5 |
| 10 | `Lib/opcode.py` | source | — | Section 5 |
| 11 | `Lib/test/test_compile.py` | test | — | Section 5 |
| 12 | `Lib/test/test_compiler_assemble.py` | test | — | Section 5 |
| 13 | `Lib/test/test_dis.py` | test | — | Section 5 |
| 14 | `Lib/test/test_inspect.py` | test | — | Section 5 |
| 15 | `Lib/test/test_listcomps.py` | test | — | Section 5 |
| 16 | `Lib/test/test_trace.py` | test | — | Section 5 |
| 17 | `Misc/NEWS.d/next/Core and Builtins/2023-01-30-15-40-29.gh-issue-97933.nUlp3r.rst` | documentation | — | Section 5 |
| 18 | `Modules/_testinternalcapi.c` | test | — | Section 5 |
| 19 | `Objects/frameobject.c` | source | Section 5 | — |
| 20 | `Python/assemble.c` | source | Section 5 | — |
| 21 | `Python/bytecodes.c` | source | Section 5 | — |
| 22 | `Python/compile.c` | source | Section 5 | — |
| 23 | `Python/flowgraph.c` | source | Section 5 | — |
| 24 | `Python/generated_cases.c.h` | generated | — | Section 5 |
| 25 | `Python/opcode_metadata.h` | generated | — | Section 5 |
| 26 | `Python/opcode_targets.h` | generated | — | Section 5 |
| 27 | `Python/symtable.c` | source | Section 5 | — |

---

## Section 5: Specification
*Classification: Implementable*

> Given a simple comprehension:
>
> ```
> def f(lst):
>     return [x for x in lst]
> ```
> The compiler currently emits the following bytecode for the function `f`:
>
> ```text
> 1           0 RESUME                   0
>
> 2           2 LOAD_CONST               1 (<code object <listcomp> at 0x...)
>             4 MAKE_FUNCTION            0
>             6 LOAD_FAST                0 (lst)
>             8 GET_ITER
>            10 CALL                     0
>            20 RETURN_VALUE
>
> Disassembly of <code object <listcomp> at 0x...>:
> 2           0 RESUME                   0
>             2 BUILD_LIST               0
>             4 LOAD_FAST                0 (.0)
>       >>    6 FOR_ITER                 4 (to 18)
>            10 STORE_FAST               1 (x)
>            12 LOAD_FAST                1 (x)
>            14 LIST_APPEND              2
>            16 JUMP_BACKWARD            6 (to 6)
>       >>   18 END_FOR
>            20 RETURN_VALUE
> ```
> The bytecode for the comprehension is in a separate code object. Each time
> `f()` is called, a new single-use function object is allocated (by
> `MAKE_FUNCTION`), called (allocating and then destroying a new frame on the
> Python stack), and then immediately thrown away.
>
> Under this PEP, the compiler will emit the following bytecode for `f()`
> instead:
>
> ```text
> 1           0 RESUME                   0
>
> 2           2 LOAD_FAST                0 (lst)
>             4 GET_ITER
>             6 LOAD_FAST_AND_CLEAR      1 (x)
>             8 SWAP                     2
>            10 BUILD_LIST               0
>            12 SWAP                     2
>       >>   14 FOR_ITER                 4 (to 26)
>            18 STORE_FAST               1 (x)
>            20 LOAD_FAST                1 (x)
>            22 LIST_APPEND              2
>            24 JUMP_BACKWARD            6 (to 14)
>       >>   26 END_FOR
>            28 SWAP                     2
>            30 STORE_FAST               1 (x)
>            32 RETURN_VALUE
> ```
> There is no longer a separate code object, nor creation of a single-use function
> object, nor any need to create and destroy a Python frame.
>
> Isolation of the `x` iteration variable is achieved by the combination of the
> new `LOAD_FAST_AND_CLEAR` opcode at offset `6`, which saves any outer value
> of `x` on the stack before running the comprehension, and `30 STORE_FAST`,
> which restores the outer value of `x` (if any) after running the
> comprehension.
>
> If the comprehension accesses variables from the outer scope, inlining avoids
> the need to place these variables in a cell, allowing the comprehension (and all
> other code in the outer function) to access them as normal fast locals instead.
> This provides further performance gains.
>
> In some cases, the comprehension iteration variable may be a global or cellvar
> or freevar, rather than a simple function local, in the outer scope. In these
> cases, the compiler also internally pushes and pops the scope information for
> the variable when entering/leaving the comprehension, so that semantics are
> maintained. For example, if the variable is a global outside the comprehension,
> `LOAD_GLOBAL` will still be used where it is referenced outside the
> comprehension, but `LOAD_FAST` / `STORE_FAST` will be used within the
> comprehension. If it is a cellvar/freevar outside the comprehension, the
> `LOAD_FAST_AND_CLEAR` / `STORE_FAST` used to save/restore it do not change
> (there is no `LOAD_DEREF_AND_CLEAR`), meaning that the entire cell (not just
> the value within it) is saved/restored, so the comprehension does not write to
> the outer cell.
>
> Comprehensions occurring in module or class scope are also inlined. In this
> case, the comprehension will introduce usage of fast-locals (`LOAD_FAST` /
> `STORE_FAST`) for the comprehension iteration variable within the
> comprehension only, in a scope where otherwise only `LOAD_NAME` /
> `STORE_NAME` would be used, maintaining isolation.
>
> In effect, comprehensions introduce a sub-scope where local variables are fully
> isolated, but without the performance cost or stack frame entry of a call.
>
> Generator expressions are currently not inlined in the reference implementation
> of this PEP. In the future, some generator expressions may be inlined, where the
> returned generator object does not leak.
>
> Asynchronous comprehensions are inlined the same as synchronous ones; no special
> handling is needed.

#### Requirement Summary
The Specification describes inlining comprehensions so they no longer create a separate code object or function call. The compiler emits bytecode that uses `LOAD_FAST_AND_CLEAR` and `STORE_FAST` to save/restore iteration variables, maintaining variable isolation without the overhead of a dedicated frame.

**File proportion:** 10/27 files mapped (37.0%) + 17/27 files associated (63.0%) = 27/27 accounted (100.0%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Include/internal/pycore_code.h` | Modified | +1 / -0 | — | — |
| `Include/internal/pycore_compile.h` | Modified | +3 / -0 | — | — |
| `Include/internal/pycore_flowgraph.h` | Modified | +1 / -1 | — | — |
| `Include/internal/pycore_symtable.h` | Modified | +1 / -0 | `_symtable_entry` | — |
| `Objects/frameobject.c` | Modified | +4 / -0 | — | `_PyFrame_FastToLocalsWithError` |
| `Python/assemble.c` | Modified | +3 / -0 | — | `compute_localsplus_info` |
| `Python/bytecodes.c` | Modified | +6 / -0 | — | `dummy_func`, `LOAD_FAST_AND_CLEAR` |
| `Python/compile.c` | Modified | +288 / -75 | `compiler_unit`, `compiler` | `compiler_unit_free`, `stack_effect`, `compiler_enter_scope`, `compiler_class`, `compiler_nameop`, `compiler_comprehension_generator`, `compiler_sync_comprehension_generator`, `compiler_async_comprehension_generator`, `push_inlined_comprehension_state`, `compiler.push_inlined_comprehension_state`, `pop_inlined_comprehension_state`, `compiler.pop_inlined_comprehension_state`, `compiler_comprehension_iter`, `compiler.compiler_comprehension_iter`, `compiler_comprehension`, `optimize_and_assemble_code_unit`, `_PyCompile_Assemble` |
| `Python/flowgraph.c` | Modified | +13 / -3 | — | `scan_block_for_locals`, `fast_scan_many_locals`, `_PyCfg_ConvertExceptionHandlersToNops`, `_PyCfg_ConvertPseudoOps` |
| `Python/symtable.c` | Modified | +109 / -27 | — | `ste_new`, `is_free_in_any_child`, `inline_comprehension`, `analyze_block`, `analyze_child_block` |


#### Modification Summary
- **`Include/internal/pycore_code.h`**: Adds the `CO_FAST_HIDDEN` flag (0x10) to the fast-locals kind bitmask, used to mark variables that are temporarily fast-locals only within an inlined comprehension so they are excluded from `locals()`
- **`Include/internal/pycore_compile.h`**: Adds the `u_fasthidden` dictionary field to `_PyCompile_CodeUnitMetadata`, which tracks names that are temporarily treated as fast-locals during inlined comprehension compilation
- **`Include/internal/pycore_flowgraph.h`**: Renames `_PyCfg_ConvertExceptionHandlersToNops` to `_PyCfg_ConvertPseudoOps` to reflect that it now also converts the new `STORE_FAST_MAYBE_NULL` pseudo-opcode to `STORE_FAST` during code generation
- **`Include/internal/pycore_symtable.h`**: Adds the `ste_comp_inlined` flag to `_symtable_entry`, set to 1 when a comprehension's symbol table entry is inlined into its parent scope during analysis
- **`Objects/frameobject.c`**: Modifies `_PyFrame_FastToLocalsWithError` to skip variables marked with `CO_FAST_HIDDEN` when populating the `locals()` dict, so inlined comprehension iteration variables are not visible to outer scope introspection
- **`Python/assemble.c`**: Modifies `compute_localsplus_info` to set the `CO_FAST_HIDDEN` kind flag on local variables that appear in the `u_fasthidden` dict, marking them in the compiled code object
- **`Python/bytecodes.c`**: Implements the new `LOAD_FAST_AND_CLEAR` bytecode instruction; the `dummy_func` cell reflects the bytecode-DSL parser convention — `bytecodes.c` declares all opcode bodies inside a single `dummy_func` shell, so the change to that shell IS the `LOAD_FAST_AND_CLEAR` op, which pushes the current value of a local variable onto the stack (or NULL if uninitialized) and then sets that local slot to NULL, enabling save/restore of iteration variables for inlined comprehensions
- **`Python/compile.c`**: Core implementation of comprehension inlining: adds `push_inlined_comprehension_state`/`pop_inlined_comprehension_state` functions that emit `LOAD_FAST_AND_CLEAR`/`STORE_FAST_MAYBE_NULL` to save/restore outer variables, manages temporary scope overrides via `u_fasthidden` and `temp_symbols`, modifies `compiler_comprehension` to check `ste_comp_inlined` and emit inline bytecode instead of creating a separate code object, and updates `compiler_nameop` to use fast-locals for `u_fasthidden` names in non-function scopes
- **`Python/flowgraph.c`**: Updates the flow graph optimizer to handle new opcodes: adds `LOAD_FAST_AND_CLEAR` and `STORE_FAST_MAYBE_NULL` to the unsafe-locals mask in `scan_block_for_locals` and `fast_scan_many_locals` (since they may leave locals as NULL), makes `STORE_FAST_MAYBE_NULL` swappable in `swaptimize`, and renames/extends `_PyCfg_ConvertPseudoOps` to convert `STORE_FAST_MAYBE_NULL` to `STORE_FAST` after optimization
- **`Python/symtable.c`**: Implements comprehension inlining at the symbol table level: adds `inline_comprehension` to merge a comprehension's symbols into its parent scope, adds `is_free_in_any_child` helper, modifies `analyze_block` to call `inline_comprehension` for non-generator comprehensions and set `ste_comp_inlined`, changes `analyze_child_block` to return `child_free` sets for per-child handling, and splices inlined comprehension children into the parent's children list

---


#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Doc/library/dis.rst` | Modified | +8 / -0 | Documents the new `LOAD_FAST_AND_CLEAR` opcode in the `dis` module reference | — | — |
| `Doc/whatsnew/3.12.rst` | Modified | +24 / -0 | What's New entry for PEP 709 comprehension inlining in Python 3.12 | — | — |
| `Include/internal/pycore_opcode.h` | Modified | +7 / -6 | Generated internal opcode metadata updated with `LOAD_FAST_AND_CLEAR` deoptimization table and opcode name entries | — | — |
| `Include/opcode.h` | Modified | +12 / -9 | Generated public opcode definitions updated with `LOAD_FAST_AND_CLEAR` and renumbered opcodes | — | — |
| `Lib/importlib/_bootstrap_external.py` | Modified | +2 / -1 | Bumps the bytecode magic number to 3529 for the new inlined-comprehension bytecode format | — | — |
| `Lib/opcode.py` | Modified | +4 / -0 | Registers `LOAD_FAST_AND_CLEAR` (143) in the opcode module and adds it to `haslocal` | — | — |
| `Modules/_testinternalcapi.c` | Modified | +2 / -0 | Updates test infrastructure to pass the new `u_fasthidden` field in `assemble_code_object` | — | — |
| `Python/generated_cases.c.h` | Modified | +487 / -475 | Auto-generated interpreter loop cases regenerated to include `LOAD_FAST_AND_CLEAR` handler | — | — |
| `Python/opcode_metadata.h` | Modified | +5 / -0 | Generated opcode metadata updated with stack effect entries for `LOAD_FAST_AND_CLEAR` | — | — |
| `Python/opcode_targets.h` | Modified | +4 / -4 | Generated opcode jump target table updated with `LOAD_FAST_AND_CLEAR` dispatch target | — | — |
| `Lib/test/test_compile.py` | Modified | +6 / -18 | Tests for compiler behavior changes from inlined comprehensions | — | — |
| `Lib/test/test_compiler_assemble.py` | Modified | +4 / -1 | Tests for assembler changes supporting inlined comprehensions | — | — |
| `Lib/test/test_dis.py` | Modified | +21 / -12 | Tests for disassembly output changes from inlined comprehensions | — | — |
| `Lib/test/test_inspect.py` | Modified | +5 / -5 | Tests for inspect behavior changes from inlined comprehensions | — | — |
| `Lib/test/test_listcomps.py` | Modified | +220 / -55 | Tests for list comprehension inlining behavior | — | — |
| `Lib/test/test_trace.py` | Modified | +1 / -3 | Tests for trace count changes from inlined comprehensions | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2023-01-30-15-40-29.gh-issue-97933.nUlp3r.rst` | Added | +2 / -0 | Changelog entry for PEP 709 inlined comprehensions | — | — |

## Unmapped Requirement Sections

*None — all implementable sections are mapped.*

## Unmapped PR Files

*None — all PR files are accounted for.*
