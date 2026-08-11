# CPython - PEP 617: New PEG parser for CPython

**PR:** https://github.com/python/cpython/pull/19503
**Requirement Doc:** https://peps.python.org/pep-0617/

## Matching Statistics
- **Requirement Doc Coverage:** 5/5 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 61/91 files mapped (67.0%) + 30/91 files associated (33.0%) = 91/91 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 617: New PEG parser for CPython | No | N/A | knowledge |
| 2 | Overview | No | N/A | knowledge |
| 3 | Background on LL(1) parsers | No | N/A | contextual |
| 4 | Background on PEG parsers | No | N/A | contextual |
| 5 | Rationale | No | N/A | contextual |
| 6 | Rationale > Some rules are not actually LL(1) | No | N/A | knowledge |
| 7 | Rationale > Complicated AST parsing | No | N/A | knowledge |
| 8 | Rationale > Lack of left recursion | No | N/A | knowledge |
| 9 | Rationale > Intermediate parse tree | No | N/A | knowledge |
| 10 | The new proposed PEG parser | No | N/A | knowledge |
| 11 | The new proposed PEG parser > Left recursion | No | N/A | knowledge |
| 12 | The new proposed PEG parser > Syntax | No | N/A | knowledge |
| 13 | The new proposed PEG parser > Syntax > Grammar Expressions | Yes | Yes | implementation |
| 14 | The new proposed PEG parser > Syntax > Variables in the Grammar | No | N/A | knowledge |
| 15 | The new proposed PEG parser > Grammar actions | Yes | Yes | implementation |
| 16 | Migration plan | Yes | Yes | implementation |
| 17 | Performance and validation | No | N/A | knowledge |
| 18 | Performance and validation > Validation | Yes | Yes | evaluation |
| 19 | Performance and validation > Performance | Yes | Yes | implementation |
| 20 | Rejected Alternatives | No | N/A | contextual |
| 21 | References | No | N/A | process |
| 22 | Copyright | No | N/A | process |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `.github/workflows/build.yml` | source | — | Section 13 |
| 2 | `.travis.yml` | source | — | Section 13 |
| 3 | `Doc/using/cmdline.rst` | documentation | — | Section 13, Section 16 |
| 4 | `Grammar/python.gram` | source | Section 13 | — |
| 5 | `Include/compile.h` | source | Section 13 | — |
| 6 | `Include/cpython/initconfig.h` | source | — | Section 16 |
| 7 | `Include/pegen_interface.h` | source | Section 13 | — |
| 8 | `Lib/test/test_cmd_line_script.py` | test | Section 18 | — |
| 9 | `Lib/test/test_codeop.py` | test | Section 18 | — |
| 10 | `Lib/test/test_compile.py` | test | Section 18 | — |
| 11 | `Lib/test/test_embed.py` | test | Section 16, Section 18 | — |
| 12 | `Lib/test/test_eof.py` | test | Section 18 | — |
| 13 | `Lib/test/test_exceptions.py` | test | Section 18 | — |
| 14 | `Lib/test/test_flufl.py` | test | Section 18 | — |
| 15 | `Lib/test/test_fstring.py` | test | Section 18 | — |
| 16 | `Lib/test/test_generators.py` | test | Section 18 | — |
| 17 | `Lib/test/test_parser.py` | test | Section 18 | — |
| 18 | `Lib/test/test_peg_generator/__init__.py` | test | Section 18 | — |
| 19 | `Lib/test/test_peg_generator/__main__.py` | test | Section 18 | — |
| 20 | `Lib/test/test_peg_generator/ast_dump.py` | test | Section 18 | — |
| 21 | `Lib/test/test_peg_generator/test_c_parser.py` | test | Section 18 | — |
| 22 | `Lib/test/test_peg_generator/test_first_sets.py` | test | Section 18 | — |
| 23 | `Lib/test/test_peg_generator/test_pegen.py` | test | Section 18 | — |
| 24 | `Lib/test/test_peg_parser.py` | test | Section 18 | — |
| 25 | `Lib/test/test_positional_only_arg.py` | test | Section 18 | — |
| 26 | `Lib/test/test_string_literals.py` | test | Section 18 | — |
| 27 | `Lib/test/test_syntax.py` | test | Section 18 | — |
| 28 | `Lib/test/test_sys.py` | test | Section 16, Section 18 | — |
| 29 | `Lib/test/test_traceback.py` | test | Section 18 | — |
| 30 | `Lib/test/test_type_comments.py` | test | Section 18 | — |
| 31 | `Lib/test/test_unpack_ex.py` | test | Section 18 | — |
| 32 | `Lib/test/test_unparse.py` | test | Section 18 | — |
| 33 | `Makefile.pre.in` | build | — | Section 13 |
| 34 | `Misc/NEWS.d/next/Core and Builtins/2020-04-20-14-06-19.bpo-40334.CTLGEp.rst` | documentation | — | Section 13 |
| 35 | `Modules/Setup` | source | Section 13 | — |
| 36 | `Modules/_peg_parser.c` | source | Section 13 | — |
| 37 | `PC/config.c` | source | — | Section 13 |
| 38 | `PCbuild/pythoncore.vcxproj` | source | — | Section 13 |
| 39 | `PCbuild/pythoncore.vcxproj.filters` | source | — | Section 13 |
| 40 | `PCbuild/regen.vcxproj` | source | — | Section 13 |
| 41 | `Parser/pegen/parse.c` | source | Section 13 | — |
| 42 | `Parser/pegen/parse_string.c` | source | Section 13 | — |
| 43 | `Parser/pegen/parse_string.h` | source | Section 13 | — |
| 44 | `Parser/pegen/peg_api.c` | source | Section 13 | — |
| 45 | `Parser/pegen/pegen.c` | source | Section 13 | — |
| 46 | `Parser/pegen/pegen.h` | source | Section 13 | — |
| 47 | `Programs/_testembed.c` | source | — | Section 13, Section 16 |
| 48 | `Python/ast_opt.c` | source | Section 13 | — |
| 49 | `Python/bltinmodule.c` | source | Section 13, Section 16 | — |
| 50 | `Python/compile.c` | source | Section 13 | — |
| 51 | `Python/importlib.h` | source | — | Section 13 |
| 52 | `Python/importlib_external.h` | source | — | Section 13 |
| 53 | `Python/initconfig.c` | source | — | Section 16 |
| 54 | `Python/pythonrun.c` | source | Section 13, Section 16 | — |
| 55 | `Python/sysmodule.c` | source | Section 13, Section 16 | — |
| 56 | `Tools/README` | source | — | Section 13 |
| 57 | `Tools/peg_generator/.clang-format` | source | — | Section 15 |
| 58 | `Tools/peg_generator/.gitignore` | build | — | Section 13 |
| 59 | `Tools/peg_generator/Makefile` | build | — | Section 13 |
| 60 | `Tools/peg_generator/data/cprog.py` | source | — | Section 15 |
| 61 | `Tools/peg_generator/data/xxl.zip` | source | — | Section 15 |
| 62 | `Tools/peg_generator/mypy.ini` | source | — | Section 15 |
| 63 | `Tools/peg_generator/peg_extension/peg_extension.c` | source | — | Section 15 |
| 64 | `Tools/peg_generator/pegen/__init__.py` | source | Section 15 | — |
| 65 | `Tools/peg_generator/pegen/__main__.py` | source | Section 15 | — |
| 66 | `Tools/peg_generator/pegen/build.py` | source | Section 15 | — |
| 67 | `Tools/peg_generator/pegen/c_generator.py` | source | Section 15 | — |
| 68 | `Tools/peg_generator/pegen/first_sets.py` | source | Section 15 | — |
| 69 | `Tools/peg_generator/pegen/grammar.py` | source | Section 15 | — |
| 70 | `Tools/peg_generator/pegen/grammar_parser.py` | source | Section 15 | — |
| 71 | `Tools/peg_generator/pegen/grammar_visualizer.py` | source | Section 15 | — |
| 72 | `Tools/peg_generator/pegen/metagrammar.gram` | source | Section 15 | — |
| 73 | `Tools/peg_generator/pegen/parser.py` | source | Section 15 | — |
| 74 | `Tools/peg_generator/pegen/parser_generator.py` | source | Section 15 | — |
| 75 | `Tools/peg_generator/pegen/python_generator.py` | source | Section 15 | — |
| 76 | `Tools/peg_generator/pegen/sccutils.py` | source | Section 15 | — |
| 77 | `Tools/peg_generator/pegen/testutil.py` | test | Section 15 | — |
| 78 | `Tools/peg_generator/pegen/tokenizer.py` | source | Section 15 | — |
| 79 | `Tools/peg_generator/pyproject.toml` | build | — | Section 13 |
| 80 | `Tools/peg_generator/requirements.pip` | source | — | Section 15 |
| 81 | `Tools/peg_generator/scripts/__init__.py` | source | — | Section 15 |
| 82 | `Tools/peg_generator/scripts/ast_timings.py` | source | Section 19 | — |
| 83 | `Tools/peg_generator/scripts/benchmark.py` | source | Section 19 | — |
| 84 | `Tools/peg_generator/scripts/download_pypi_packages.py` | source | — | Section 18 |
| 85 | `Tools/peg_generator/scripts/find_max_nesting.py` | source | — | Section 15 |
| 86 | `Tools/peg_generator/scripts/grammar_grapher.py` | source | — | Section 15 |
| 87 | `Tools/peg_generator/scripts/joinstats.py` | source | Section 19 | — |
| 88 | `Tools/peg_generator/scripts/show_parse.py` | source | — | Section 15 |
| 89 | `Tools/peg_generator/scripts/test_parse_directory.py` | test | Section 18 | — |
| 90 | `Tools/peg_generator/scripts/test_pypi_packages.py` | test | Section 18 | — |
| 91 | `Tools/scripts/run_tests.py` | test | — | Section 18 |

---

## Section 13: Grammar Expressions
*Path: The new proposed PEG parser > Syntax > Grammar Expressions*
*Classification: Implementable*

> `# comment`
> '''''''''''''
>
> Python-style comments.
>
> `e1 e2`
> '''''''''
>
> Match e1, then match e2.
>
> ```PEG
> rule_name: first_rule second_rule
> ```
> `e1 | e2`
> '''''''''''
>
> Match e1 or e2.
>
> The first alternative can also appear on the line after the rule name
> for formatting purposes. In that case, a \| must be used before the
> first alternative, like so:
>
> ```PEG
> rule_name[return_type]:
>     | first_alt
>     | second_alt
> ```
> `( e )`
> '''''''''
>
> Match e.
>
> ```PEG
> rule_name: (e)
> ```
> A slightly more complex and useful example includes using the grouping
> operator together with the repeat operators:
>
> ```PEG
> rule_name: (e1 e2)*
> ```
> `[ e ] or e?`
> '''''''''''''''
>
> Optionally match e.
>
> ```PEG
> rule_name: [e]
> ```
> A more useful example includes defining that a trailing comma is
> optional:
>
> ```PEG
> rule_name: e (',' e)* [',']
> ```
> `e*`
> ''''''
>
> Match zero or more occurrences of e.
>
> ```PEG
> rule_name: (e1 e2)*
> ```
> `e+`
> ''''''
>
> Match one or more occurrences of e.
>
> ```PEG
> rule_name: (e1 e2)+
> ```
> `s.e+`
> ''''''''
>
> Match one or more occurrences of e, separated by s. The generated parse
> tree does not include the separator. This is otherwise identical to
> `(e (s e)*)`.
>
> ```PEG
> rule_name: ','.e+
> ```
> `&e`
> ''''''
>
> Succeed if e can be parsed, without consuming any input.
>
> `!e`
> ''''''
>
> Fail if e can be parsed, without consuming any input.
>
> An example taken from the proposed Python grammar specifies that a primary
> consists of an atom, which is not followed by a `.` or a `(` or a
> `[`:
>
> ```PEG
> primary: atom !'.' !'(' !'['
> ```
> `~`
> ''''''
>
> Commit to the current alternative, even if it fails to parse.
>
> ```PEG
> rule_name: '(' ~ some_rule ')' | some_alt
> ```
> In this example, if a left parenthesis is parsed, then the other
> alternative won’t be considered, even if some_rule or ‘)’ fail to be
> parsed.

#### Requirement Summary
This section specifies the complete PEG grammar and generated C parser with direct AST construction, plus the integration of the PEG parser into the CPython runtime. The PR implements the grammar file with C actions, a 15K-line generated parser with packrat memoization and left-recursion support, runtime support library, f-string parsing, a public C API for parsing to AST, the `_peg_parser` extension module, and the runtime dispatch that routes `compile`, `exec`, and interactive parsing through the new PEG parser.

**File proportion:** 16/91 files mapped (17.6%) + 16/91 files associated (17.6%) = 32/91 accounted (35.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Added | +555 / -0 | — | — |
| `Include/compile.h` | Modified | +3 / -0 | — | — |
| `Include/pegen_interface.h` | Added | +32 / -0 | — | — |
| `Modules/Setup` | Modified | +3 / -0 | — | — |
| `Modules/_peg_parser.c` | Added | +107 / -0 | `PyModuleDef` | `_Py_parse_file`, `_Py_parse_string`, `PyInit__peg_parser` |
| `Parser/pegen/parse.c` | Added | +15391 / -0 | — | — |
| `Parser/pegen/parse_string.c` | Added | +1387 / -0 | `tok_state` | `warn_invalid_escape_sequence`, `decode_utf8`, `decode_unicode_with_escapes`, `decode_bytes_with_escapes`, `_PyPegen_parsestr`, `shift_expr`, `shift_arg`, `fstring_shift_seq_locations`, `fstring_shift_slice_locations`, `fstring_shift_comprehension`, `fstring_shift_argument`, `fstring_shift_arguments`, `fstring_shift_children_locations`, `fstring_shift_expr_locations`, `fstring_fix_expr_location`, `fstring_compile_expr`, `tok_state.fstring_compile_expr`, `fstring_find_literal`, `fstring_find_expr`, `fstring_find_literal_and_expr`, `ExprList_check_invariants`, `ExprList_Init`, `ExprList_Append`, `ExprList_Dealloc`, `ExprList_Finish`, `FstringParser_check_invariants`, `_PyPegen_FstringParser_Init`, `_PyPegen_FstringParser_Dealloc`, `make_str_node_and_del`, `_PyPegen_FstringParser_ConcatAndDel`, `_PyPegen_FstringParser_ConcatFstring`, `_PyPegen_FstringParser_Finish`, `fstring_parse` |
| `Parser/pegen/parse_string.h` | Added | +46 / -0 | — | — |
| `Parser/pegen/peg_api.c` | Added | +134 / -0 | — | `PyPegen_ASTFromString`, `PyPegen_ASTFromStringObject`, `PyPegen_ASTFromFile`, `PyPegen_ASTFromFileObject`, `PyPegen_CodeObjectFromString`, `PyPegen_CodeObjectFromFile`, `PyPegen_CodeObjectFromFileObject` |
| `Parser/pegen/pegen.c` | Added | +1865 / -0 | `tok_state` | `init_normalization`, `_PyPegen_new_identifier`, `_create_dummy_identifier`, `byte_offset_to_character_offset`, `_PyPegen_get_expr_name`, `raise_decode_error`, `raise_tokenizer_init_error`, `get_error_line`, `tokenizer_error_with_col_offset`, `tokenizer_error`, `_PyPegen_raise_error`, `_PyPegen_arguments_parsing_error`, `token_name`, `_PyPegen_insert_memo`, `_PyPegen_update_memo`, `_PyPegen_dummy_name`, `_get_keyword_or_name_type`, `_PyPegen_fill_token`, `_PyPegen_clear_memo_statistics`, `_PyPegen_get_memo_statistics`, `_PyPegen_is_memoized`, `_PyPegen_lookahead_with_string`, `_PyPegen_lookahead_with_int`, `_PyPegen_lookahead`, `_PyPegen_expect_token`, `_PyPegen_get_last_nonnwhitespace_token`, `_PyPegen_async_token`, `_PyPegen_await_token`, `_PyPegen_endmarker_token`, `_PyPegen_name_token`, `_PyPegen_string_token`, `_PyPegen_newline_token`, `_PyPegen_indent_token`, `_PyPegen_dedent_token`, `parsenumber_raw`, `parsenumber`, `_PyPegen_number_token`, `_PyPegen_Parser_Free`, `_PyPegen_Parser_New`, `tok_state._PyPegen_Parser_New`, `_PyPegen_run_parser`, `_PyPegen_run_parser_from_file_pointer`, `tok_state._PyPegen_run_parser_from_file_pointer`, `_PyPegen_run_parser_from_file`, `_PyPegen_run_parser_from_string`, `tok_state._PyPegen_run_parser_from_string`, `_PyPegen_interactive_exit`, `_PyPegen_singleton_seq`, `_PyPegen_seq_insert_in_front`, `_get_flattened_seq_size`, `_PyPegen_seq_flatten`, `_PyPegen_join_names_with_dot`, `_PyPegen_seq_count_dots`, `_PyPegen_alias_for_star`, `_PyPegen_map_names_to_ids`, `_PyPegen_cmpop_expr_pair`, `_PyPegen_get_cmpops`, `_PyPegen_get_exprs`, `_set_seq_context`, `_set_name_context`, `_set_tuple_context`, `_set_list_context`, `_set_subscript_context`, `_set_attribute_context`, `_set_starred_context`, `_PyPegen_set_expr_context`, `_PyPegen_key_value_pair`, `_PyPegen_get_keys`, `_PyPegen_get_values`, `_PyPegen_name_default_pair`, `_PyPegen_slash_with_default`, `_PyPegen_star_etc`, `_PyPegen_join_sequences`, `_get_names`, `_get_defaults`, `_PyPegen_make_arguments`, `_PyPegen_empty_arguments`, `_PyPegen_augoperator`, `_PyPegen_function_def_decorators`, `_PyPegen_class_def_decorators`, `_PyPegen_keyword_or_starred`, `_seq_number_of_starred_exprs`, `_PyPegen_seq_extract_starred_exprs`, `_PyPegen_seq_delete_starred_exprs`, `_PyPegen_concatenate_strings` |
| `Parser/pegen/pegen.h` | Added | +179 / -0 | `_memo`, `tok_state` | `CHECK_CALL`, `CHECK_CALL_NULL_ALLOWED` |
| `Python/ast_opt.c` | Modified | +2 / -1 | — | `astfold_expr` |
| `Python/bltinmodule.c` | Modified | +5 / -0 | — | `builtin_compile_impl` |
| `Python/compile.c` | Modified | +67 / -0 | `compiler` | `forbidden_name`, `compiler.forbidden_name`, `compiler_check_debug_one_arg`, `compiler.compiler_check_debug_one_arg`, `compiler_check_debug_args_seq`, `compiler.compiler_check_debug_args_seq`, `compiler_check_debug_args`, `compiler.compiler_check_debug_args`, `compiler_function`, `compiler_lambda`, `compiler_nameop`, `validate_keywords`, `compiler_visit_expr1`, `compiler_annassign` |
| `Python/pythonrun.c` | Modified | +46 / -8 | — | `PyRun_InteractiveOneObjectEx`, `PyRun_StringFlags`, `PyRun_FileExFlags`, `Py_CompileStringObject`, `_Py_SymtableStringObjectFlags` |
| `Python/sysmodule.c` | Modified | +3 / -1 | — | `make_flags` |

#### Modification Summary
- **`Grammar/python.gram`**: The complete Python grammar in PEG notation with C actions. Defines all Python constructs (statements, expressions, comprehensions, imports, classes, functions, decorators, etc.) with actions that directly call CPython AST construction functions (`_Py_Module`, `_Py_If`, `_Py_BinOp`, `_Py_FunctionDef`, etc.). Includes a `@trailer` block defining the `_PyPegen_parse` entry point that dispatches to `file_rule`, `interactive_rule`, `eval_rule`, or `fstring_rule` based on the start rule. Uses left-recursive rules for expressions (e.g., `expr: expr '+' term`), demonstrating the PEG parser's ability to handle left recursion naturally.
- **`Parser/pegen/parse.c`**: The generated C parser (15,391 lines), produced by running `pegen` on `python.gram`. Contains one C function per grammar rule, with memoization, backtracking, left-recursion handling, and direct AST node construction. This is a generated file but is checked into the repository.
- **`Parser/pegen/pegen.c`**: The PEG parser runtime library. Implements the `Parser` struct lifecycle (`_PyPegen_Parser_New`, `_PyPegen_Parser_Free`), token filling and management (`_PyPegen_fill_token`), memoization (`_PyPegen_is_memoized`, `_PyPegen_insert_memo`, `_PyPegen_update_memo`), error reporting (`_PyPegen_raise_error`, `_PyPegen_get_expr_name`), and numerous AST helper functions used by grammar actions.
- **`Parser/pegen/pegen.h`**: Header defining the `Parser` struct, helper typedefs (`Token`, `Memo`, `CmpopExprPair`, `KeyValuePair`, `NameDefaultPair`, `SlashWithDefault`, `StarEtc`, `AugOperator`, `KeywordOrStarred`), and declarations for all runtime functions and macros.
- **`Parser/pegen/parse_string.c`**: String literal and f-string parsing routines, ported from `Python/ast.c` and adapted for the PEG parser.
- **`Parser/pegen/parse_string.h`**: Header for the string parsing module, defining `ExprList` and `FstringParser` structs and declaring the string/f-string parsing API.
- **`Parser/pegen/peg_api.c`**: Public API implementation. Defines `PyPegen_ASTFromString`, `PyPegen_ASTFromStringObject`, `PyPegen_ASTFromFile`, `PyPegen_ASTFromFileObject`, `PyPegen_CodeObjectFromString`, `PyPegen_CodeObjectFromFile`, and `PyPegen_CodeObjectFromFileObject`.
- **`Include/pegen_interface.h`**: Public header declaring the `PyPegen_ASTFrom*` and `PyPegen_CodeObjectFrom*` C API functions.
- **`Include/compile.h`**: Adds `Py_fstring_input` (800) start rule constant used by the PEG parser for parsing f-string subexpressions.
- **`Modules/Setup`**: Adds the `_peg_parser` extension module entry (`_peg_parser _peg_parser.c`) to the static modules list.
- **`Modules/_peg_parser.c`**: New C extension module providing `_peg_parser.parse_string()` and `_peg_parser.parse_file()` functions that call `PyPegen_ASTFromString`/`PyPegen_ASTFromFile` and return AST objects. Used by tests to directly invoke the PEG parser.
- **`Python/pythonrun.c`**: Includes `pegen_interface.h` and adds PEG parser dispatch: `PyRun_InteractiveOneObjectEx`, `PyRun_SimpleFileExFlags`, and `PyRun_StringFlags` now check `config.use_peg` and call `PyPegen_ASTFromFileObject`/`PyPegen_ASTFromStringObject` when enabled, falling back to `PyParser_ASTFromFileObject`/`PyParser_ASTFromStringObject` otherwise.
- **`Python/bltinmodule.c`**: Adds PEG parser integration to `builtin_compile_impl`: temporarily sets `config.use_peg = 0` when `PyCF_TYPE_COMMENTS` or `feature_version` is specified (since the PEG parser does not yet support type comments), then restores it after compilation.
- **`Python/compile.c`**: Adds `forbidden_name` function checking for `__debug__` assignment, plus `compiler_check_debug_args`/`compiler_check_debug_args_seq`/`compiler_check_debug_one_arg` helpers to validate function parameter names. This moves the `__debug__` assignment check from the old parser into the compiler so it works with the PEG parser.
- **`Python/sysmodule.c`**: Adds `use_peg` to `sys.flags` struct sequence (field name and value), incrementing the field count from 15 to 16. Uses `SetFlag(config->use_peg)` to populate the value.
- **`Python/ast_opt.c`**: Adds a `node_->v.Name.ctx == Load` guard before the `__debug__` constant-folding check in `astfold_expr`, fixing a bug where Store context `__debug__` references were incorrectly folded.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `.github/workflows/build.yml` | Modified | +45 / -0 | Adds `pegen` branch to CI triggers and duplicates build jobs for old/new parser testing | — | — |
| `.travis.yml` | Modified | +5 / -2 | Switches Travis CI dist to bionic, adds `pegen` branch, changes regen to use python3.8 | — | — |
| `Doc/using/cmdline.rst` | Modified | +8 / -0 | Documents the `-X oldparser` option and `PYTHONOLDPARSER` environment variable | — | — |
| `Makefile.pre.in` | Modified | +23 / -3 | Adds `PEGEN_OBJS` and `PEGEN_HEADERS` variables for building the PEG parser C files | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2020-04-20-14-06-19.bpo-40334.CTLGEp.rst` | Added | +5 / -0 | NEWS entry announcing the new PEG-based parser | — | — |
| `PC/config.c` | Modified | +3 / -0 | Adds `PyInit__peg_parser` extern and registers it in `_PyImport_Inittab[]` for Windows | — | — |
| `PCbuild/pythoncore.vcxproj` | Modified | +9 / -0 | Adds PEG parser header and source file entries for Visual Studio build | — | — |
| `PCbuild/pythoncore.vcxproj.filters` | Modified | +12 / -0 | Adds filter entries for PEG parser source files under the Parser filter group | — | — |
| `PCbuild/regen.vcxproj` | Modified | +9 / -1 | Adds `_RegenPegen` build target to regenerate `parse.c` from `python.gram` | — | — |
| `Programs/_testembed.c` | Modified | +3 / -0 | Adds `config.use_peg = 0` in `test_init_from_config` to test old parser configuration | — | `test_init_from_config` |
| `Python/importlib.h` | Modified | +45 / -44 | Regenerated frozen bytecode for `importlib._bootstrap` reflecting parser switch | — | — |
| `Python/importlib_external.h` | Modified | +4 / -3 | Regenerated frozen bytecode for `importlib._bootstrap_external` | — | — |
| `Tools/README` | Modified | +2 / -0 | Adds `peg_generator` entry describing the PEG-based parser generator tool | — | — |
| `Tools/peg_generator/.gitignore` | Added | +3 / -0 | Ignores generated files: `peg_extension/parse.c`, `data/xxl.py`, and `@data` | — | — |
| `Tools/peg_generator/Makefile` | Added | +116 / -0 | Build system for peg_generator: targets for regeneration, C extension, tests, benchmarks | — | — |
| `Tools/peg_generator/pyproject.toml` | Added | +9 / -0 | Minimal pyproject.toml for the peg_generator package with setuptools build backend | — | — |

---

## Section 15: Grammar actions
*Path: The new proposed PEG parser > Grammar actions*
*Classification: Implementable*

> To avoid the intermediate steps that obscure the relationship between the
> grammar and the AST generation the proposed PEG parser allows directly
> generating AST nodes for a rule via grammar actions. Grammar actions are
> language-specific expressions that are evaluated when a grammar rule is
> successfully parsed. These expressions can be written in Python or C
> depending on the desired output of the parser generator. This means that if
> one would want to generate a parser in Python and another in C, two grammar
> files should be written, each one with a different set of actions, keeping
> everything else apart from said actions identical in both files. As an
> example of a grammar with Python actions, the piece of the parser generator
> that parses grammar files is bootstrapped from a meta-grammar file with
> Python actions that generate the grammar tree as a result of the parsing.
>
> In the specific case of the new proposed PEG grammar for Python, having
> actions allows directly describing how the AST is composed in the grammar
> itself, making it more clear and maintainable. This AST generation process is
> supported by the use of some helper functions that factor out common AST
> object manipulations and some other required operations that are not directly
> related to the grammar.
>
> To indicate these actions each alternative can be followed by the action code
> inside curly-braces, which specifies the return value of the alternative:
>
> ```
> rule_name[return_type]:
>     | first_alt1 first_alt2 { first_alt1 }
>     | second_alt1 second_alt2 { second_alt1 }
> ```
> If the action is omitted and C code is being generated, then there are two
> different possibilities:
>
> 1. If there’s a single name in the alternative, this gets returned.
> 2. If not, a dummy name object gets returned (this case should be avoided).
>
> If the action is omitted and Python code is being generated, then a list
> with all the parsed expressions gets returned (this is meant for debugging).
>
> The full meta-grammar for the grammars supported by the PEG generator is:
>
> ```PEG
> start[Grammar]: grammar ENDMARKER { grammar }
>
> grammar[Grammar]:
>     | metas rules { Grammar(rules, metas) }
>     | rules { Grammar(rules, []) }
>
> metas[MetaList]:
>     | meta metas { [meta] + metas }
>     | meta { [meta] }
>
> meta[MetaTuple]:
>     | "@" NAME NEWLINE { (name.string, None) }
>     | "@" a=NAME b=NAME NEWLINE { (a.string, b.string) }
>     | "@" NAME STRING NEWLINE { (name.string, literal_eval(string.string)) }
>
> rules[RuleList]:
>     | rule rules { [rule] + rules }
>     | rule { [rule] }
>
> rule[Rule]:
>     | rulename ":" alts NEWLINE INDENT more_alts DEDENT {
>           Rule(rulename[0], rulename[1], Rhs(alts.alts + more_alts.alts)) }
>     | rulename ":" NEWLINE INDENT more_alts DEDENT { Rule(rulename[0], rulename[1], more_alts) }
>     | rulename ":" alts NEWLINE { Rule(rulename[0], rulename[1], alts) }
>
> rulename[RuleName]:
>     | NAME '[' type=NAME '*' ']' {(name.string, type.string+"*")}
>     | NAME '[' type=NAME ']' {(name.string, type.string)}
>     | NAME {(name.string, None)}
>
> alts[Rhs]:
>     | alt "|" alts { Rhs([alt] + alts.alts)}
>     | alt { Rhs([alt]) }
>
> more_alts[Rhs]:
>     | "|" alts NEWLINE more_alts { Rhs(alts.alts + more_alts.alts) }
>     | "|" alts NEWLINE { Rhs(alts.alts) }
>
> alt[Alt]:
>     | items '$' action { Alt(items + [NamedItem(None, NameLeaf('ENDMARKER'))], action=action) }
>     | items '$' { Alt(items + [NamedItem(None, NameLeaf('ENDMARKER'))], action=None) }
>     | items action { Alt(items, action=action) }
>     | items { Alt(items, action=None) }
>
> items[NamedItemList]:
>     | named_item items { [named_item] + items }
>     | named_item { [named_item] }
>
> named_item[NamedItem]:
>     | NAME '=' ~ item {NamedItem(name.string, item)}
>     | item {NamedItem(None, item)}
>     | it=lookahead {NamedItem(None, it)}
>
> lookahead[LookaheadOrCut]:
>     | '&' ~ atom {PositiveLookahead(atom)}
>     | '!' ~ atom {NegativeLookahead(atom)}
>     | '~' {Cut()}
>
> item[Item]:
>     | '[' ~ alts ']' {Opt(alts)}
>     |  atom '?' {Opt(atom)}
>     |  atom '*' {Repeat0(atom)}
>     |  atom '+' {Repeat1(atom)}
>     |  sep=atom '.' node=atom '+' {Gather(sep, node)}
>     |  atom {atom}
>
> atom[Plain]:
>     | '(' ~ alts ')' {Group(alts)}
>     | NAME {NameLeaf(name.string) }
>     | STRING {StringLeaf(string.string)}

#### Requirement Summary
This section specifies the grammar action mechanism and the parser generator toolchain that implements it. Grammar actions allow rules to directly generate AST nodes via language-specific expressions in curly braces, eliminating intermediate CST construction. The PR implements the full `pegen` parser generator package: grammar AST data structures, a metagrammar-bootstrapped grammar parser, C and Python code generators that emit recursive-descent parsers with action support, FIRST set computation, left-recursion detection via SCC analysis, packrat memoization, and tokenizer integration.

**File proportion:** 15/91 files mapped (16.5%) + 10/91 files associated (11.0%) = 25/91 accounted (27.5%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Tools/peg_generator/pegen/__init__.py` | Added | +0 / -0 | — | — |
| `Tools/peg_generator/pegen/__main__.py` | Added | +136 / -0 | — | `main` |
| `Tools/peg_generator/pegen/build.py` | Added | +169 / -0 | — | `build_generator`, `build_parser`, `build_parser_and_generator`, `compile_c_extension` |
| `Tools/peg_generator/pegen/c_generator.py` | Added | +605 / -0 | `CCallMakerVisitor`, `CParserGenerator` | — |
| `Tools/peg_generator/pegen/first_sets.py` | Added | +153 / -0 | `FirstSetCalculator` | `main` |
| `Tools/peg_generator/pegen/grammar.py` | Added | +470 / -0 | `GrammarError`, `GrammarVisitor`, `Grammar`, `Rule`, `Leaf`, `NameLeaf`, `StringLeaf`, `Rhs`, `Alt`, `NamedItem`, `Lookahead`, `PositiveLookahead`, `NegativeLookahead`, `Opt`, `Repeat`, `Repeat0`, `Repeat1`, `Gather`, `Group`, `Cut` | — |
| `Tools/peg_generator/pegen/grammar_parser.py` | Added | +677 / -0 | `GeneratedParser` | — |
| `Tools/peg_generator/pegen/grammar_visualizer.py` | Added | +65 / -0 | `ASTGrammarPrinter` | `main` |
| `Tools/peg_generator/pegen/metagrammar.gram` | Added | +123 / -0 | — | — |
| `Tools/peg_generator/pegen/parser.py` | Added | +310 / -0 | `Parser` | `logger`, `memoize`, `memoize_left_rec`, `simple_parser_main` |
| `Tools/peg_generator/pegen/parser_generator.py` | Added | +188 / -0 | `RuleCheckingVisitor`, `ParserGenerator` | `compute_left_recursives`, `compute_nullables`, `dedupe`, `make_first_graph` |
| `Tools/peg_generator/pegen/python_generator.py` | Added | +224 / -0 | `PythonCallMakerVisitor`, `PythonParserGenerator` | — |
| `Tools/peg_generator/pegen/sccutils.py` | Added | +128 / -0 | — | `find_cycles_in_scc`, `strongly_connected_components`, `topsort` |
| `Tools/peg_generator/pegen/testutil.py` | Added | +126 / -0 | — | — |
| `Tools/peg_generator/pegen/tokenizer.py` | Added | +86 / -0 | `Tokenizer` | `shorttok` |

#### Modification Summary
- **`Tools/peg_generator/pegen/__init__.py`**: Empty package init file for the pegen Python package.
- **`Tools/peg_generator/pegen/__main__.py`**: CLI entry point for pegen: parses command-line arguments (`-c` for C output, `-o` for output path, `--compile-extension`) and calls `build_parser_and_generator` to generate the parser.
- **`Tools/peg_generator/pegen/build.py`**: Build utilities: `build_parser` tokenizes and parses a `.gram` file, `build_parser_and_generator` generates either Python or C parser code, and `compile_c_extension` compiles the generated C source into a loadable extension module.
- **`Tools/peg_generator/pegen/c_generator.py`**: `CParserGenerator` class (605 lines) that visits the grammar AST and emits C code for each rule. Includes `CCallMakerVisitor` for generating function call expressions and keyword handling, and produces the `_PyPegen_parse` entry point via `EXTENSION_SUFFIX`.
- **`Tools/peg_generator/pegen/first_sets.py`**: `FirstSetCalculator` (GrammarVisitor subclass) that computes FIRST sets for all grammar rules, used by the parser generator to determine which tokens can start each rule.
- **`Tools/peg_generator/pegen/grammar.py`**: Defines the grammar AST data structures: `Grammar`, `Rule`, `Rhs`, `Alt`, `NamedItem`, `NameLeaf`, `StringLeaf`, `Lookahead`, `Opt`, `Repeat0`, `Repeat1`, `Gather`, `Group`, `Cut`, and the `GrammarVisitor` base class.
- **`Tools/peg_generator/pegen/grammar_parser.py`**: Auto-generated recursive-descent parser for the metagrammar (`.gram` files). Parses grammar rules, alternatives, named items, lookaheads, repetitions, and actions into the grammar AST.
- **`Tools/peg_generator/pegen/grammar_visualizer.py`**: `ASTGrammarPrinter` class that pretty-prints a grammar AST as a tree structure with box-drawing characters for debugging.
- **`Tools/peg_generator/pegen/metagrammar.gram`**: The PEG metagrammar defining the `.gram` file syntax: rules, alternatives, named items, lookaheads, repetitions, grouping, and actions. Used to bootstrap the grammar parser.
- **`Tools/peg_generator/pegen/parser.py`**: Base `Parser` class implementing the core PEG parsing algorithm with packrat memoization (`@memoize` decorator), left-recursion support (`@memoize_left_rec`), token management, mark/reset for backtracking, and error reporting.
- **`Tools/peg_generator/pegen/parser_generator.py`**: Abstract `ParserGenerator` base class with shared logic for both Python and C code generation: rule collection, deduplication, first-set computation, alt/rule formatting, and keyword type assignment.
- **`Tools/peg_generator/pegen/python_generator.py`**: `PythonParserGenerator` that visits the grammar AST and emits Python source code for a recursive-descent parser, used for testing and prototyping.
- **`Tools/peg_generator/pegen/sccutils.py`**: Strongly Connected Components (SCC) utility implementing Tarjan's algorithm, used to detect left-recursive rule cycles in the grammar.
- **`Tools/peg_generator/pegen/testutil.py`**: Test utilities: `parse_string` (parses a grammar string), `generate_parser` (generates a Python parser from grammar), `make_parser` (creates a parser class), `generate_parser_c_extension` and `generate_c_parser_source` (generates C parser extension), and `print_memstats`.
- **`Tools/peg_generator/pegen/tokenizer.py`**: `Tokenizer` class wrapping Python's `tokenize` module to provide a token stream with mark/reset support for backtracking, used by the grammar parser.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Tools/peg_generator/.clang-format` | Added | +17 / -0 | Clang-format configuration approximating PEP 7 C style for peg_generator C code | — | — |
| `Tools/peg_generator/data/cprog.py` | Added | +10 / -0 | Small test Python program used as parse input for testing the PEG parser | — | — |
| `Tools/peg_generator/data/xxl.zip` | Added | +0 / -0 | Compressed large Python source file for parser performance benchmarking | — | — |
| `Tools/peg_generator/mypy.ini` | Added | +26 / -0 | Mypy configuration for strict type checking of the pegen Python modules | — | — |
| `Tools/peg_generator/peg_extension/peg_extension.c` | Added | +153 / -0 | C extension wrapper exposing `parse_file`/`parse_string` for testing the generated parser | `PyModuleDef` | `_build_return_object`, `parse_file`, `parse_string`, `clear_memo_stats`, `get_memo_stats`, `dump_memo_stats`, `PyInit_parse` |
| `Tools/peg_generator/requirements.pip` | Added | +2 / -0 | Development dependencies (flask, mypy) for the peg_generator tool | — | — |
| `Tools/peg_generator/scripts/__init__.py` | Added | +1 / -0 | Package init file for the peg_generator scripts subpackage | — | — |
| `Tools/peg_generator/scripts/find_max_nesting.py` | Added | +61 / -0 | Script finding maximum nesting depth the parser can handle | — | `check_nested_expr`, `main` |
| `Tools/peg_generator/scripts/grammar_grapher.py` | Added | +111 / -0 | Script generating DOT graph visualization of grammar rule dependencies | — | `main`, `references_for_item` |
| `Tools/peg_generator/scripts/show_parse.py` | Added | +117 / -0 | Debug script parsing a file and displaying the resulting AST | — | `diff_trees`, `format_tree`, `main`, `print_parse`, `show_parse` |

---

## Section 16: Migration plan
*Classification: Implementable*

> This section describes the migration plan when porting to the new PEG-based parser
> if this PEP is accepted. The migration will be executed in a series of steps that allow
> initially to fallback to the previous parser if needed:
>
> 1.  Starting with Python 3.9 alpha 6, include the new PEG-based parser machinery in CPython
>     with a command-line flag and environment variable that allows switching between
>     the new and the old parsers together with explicit APIs that allow invoking the
>     new and the old parsers independently. At this step, all Python APIs like `ast.parse`
>     and `compile` will use the parser set by the flags or the environment variable and
>     the default parser will be the new PEG-based parser.
>
> 2.  Between Python 3.9 and Python 3.10, the old parser and related code (like the
>     "parser" module) will be kept until a new Python release happens (Python 3.10). In
>     the meanwhile and until the old parser is removed, **no new Python Grammar
>     addition will be added that requires the PEG parser**. This means that the grammar
>     will be kept LL(1) until the old parser is removed.
>
> 3.  In Python 3.10, remove the old parser, the command-line flag, the environment
>     variable and the "parser" module and related code.

#### Requirement Summary
This section specifies the migration plan for transitioning to the PEG parser, including the `-X oldparser` command-line flag and `PYTHONOLDPARSER` environment variable that allow switching back to the LL(1) parser during the transition period.

**File proportion:** 5/91 files mapped (5.5%) + 4/91 files associated (4.4%) = 9/91 accounted (9.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/bltinmodule.c` | Modified | +5 / -0 | — | — |
| `Python/pythonrun.c` | Modified | +46 / -8 | — | — |
| `Python/sysmodule.c` | Modified | +3 / -1 | — | — |
| `Lib/test/test_embed.py` | Modified | +2 / -0 | — | — |
| `Lib/test/test_sys.py` | Modified | +4 / -4 | — | — |

#### Modification Summary
- **`Python/bltinmodule.c`**: Implements the migration toggle in `builtin_compile_impl` by clearing `config.use_peg` for `PyCF_TYPE_COMMENTS`/`feature_version` paths during the transition period, then restoring the user's parser preference after compilation.
- **`Python/pythonrun.c`**: Implements the migration dispatch in `PyRun_*` entry points by checking `config.use_peg` and routing to either `PyPegen_AST*` or `PyParser_AST*` so the `-X oldparser`/`PYTHONOLDPARSER` switch chooses between the new and old parser at runtime.
- **`Python/sysmodule.c`**: Exposes the migration flag to Python by adding `use_peg` to the `sys.flags` struct sequence (incrementing field count from 15 to 16) so user code and tests can observe which parser the interpreter is using.
- **`Lib/test/test_embed.py`**: Adds `use_peg: 1` to the default config dict and `use_peg: 0` to the `test_init_from_config` expected config, directly validating the migration flag's presence in `PyConfig`.
- **`Lib/test/test_sys.py`**: Adds `use_peg` to the `sys.flags` attribute tuple, directly validating the migration flag's exposure to Python code.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Include/cpython/initconfig.h` | Modified | +4 / -0 | Adds `int use_peg` field to `PyConfig` for the `-X oldparser` flag | — | — |
| `Python/initconfig.c` | Modified | +10 / -0 | Initializes `config->use_peg = 1`, adds `-X oldparser` help text and config copy/serialization | — | `_PyConfig_InitCompatConfig`, `_PyConfig_Copy`, `config_as_dict`, `config_read_complex_options`, `PyConfig_Read` |
| `Doc/using/cmdline.rst` | Modified | +8 / -0 | Documents the `-X oldparser` option and `PYTHONOLDPARSER` environment variable that drive the migration plan | — | — |
| `Programs/_testembed.c` | Modified | +3 / -0 | Embed test exercises the migration config (sets `config.use_peg = 0` to validate the old-parser path) | — | — |

---

## Section 18: Validation
*Path: Performance and validation > Validation*
*Classification: Implementable*

> To start with validation, we regularly compile the entire Python 3.8
> stdlib and compare every aspect of the resulting AST with that
> produced by the standard compiler. (In the process we found a few bugs
> in the standard parser's treatment of line and column numbers, which
> we have all fixed upstream via a series of issues and PRs.)
>
> We have also occasionally compiled a much larger codebase (the approx.
> 3800 most popular packages on PyPI) and this has helped us find a (very)
> few additional bugs in the new parser.
>
> (One area we have not explored extensively is rejection of all wrong
> programs. We have unit tests that check for a certain number of
> explicit rejections, but more work could be done, e.g. by using a
> fuzzer that inserts random subtle bugs into existing code. We're open
> to help in this area.)

#### Requirement Summary
This section specifies the validation approach: compiling the entire Python 3.8 stdlib and comparing AST output with the standard compiler, plus testing the 3800 most popular PyPI packages to find parser bugs.

**File proportion:** 27/91 files mapped (29.7%) + 2/91 files associated (2.2%) = 29/91 accounted (31.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/test/test_cmd_line_script.py` | Modified | +9 / -10 | — | — |
| `Lib/test/test_codeop.py` | Modified | +2 / -1 | — | — |
| `Lib/test/test_compile.py` | Modified | +1 / -0 | — | — |
| `Lib/test/test_embed.py` | Modified | +2 / -0 | — | — |
| `Lib/test/test_eof.py` | Modified | +2 / -0 | — | — |
| `Lib/test/test_exceptions.py` | Modified | +1 / -0 | — | — |
| `Lib/test/test_flufl.py` | Modified | +3 / -0 | — | — |
| `Lib/test/test_fstring.py` | Modified | +3 / -1 | — | — |
| `Lib/test/test_generators.py` | Modified | +5 / -4 | — | — |
| `Lib/test/test_parser.py` | Modified | +3 / -1 | — | — |
| `Lib/test/test_peg_generator/__init__.py` | Added | +7 / -0 | — | — |
| `Lib/test/test_peg_generator/__main__.py` | Added | +4 / -0 | — | — |
| `Lib/test/test_peg_generator/ast_dump.py` | Added | +62 / -0 | — | — |
| `Lib/test/test_peg_generator/test_c_parser.py` | Added | +333 / -0 | — | — |
| `Lib/test/test_peg_generator/test_first_sets.py` | Added | +225 / -0 | — | — |
| `Lib/test/test_peg_generator/test_pegen.py` | Added | +728 / -0 | — | — |
| `Lib/test/test_peg_parser.py` | Added | +764 / -0 | — | — |
| `Lib/test/test_positional_only_arg.py` | Modified | +18 / -11 | — | — |
| `Lib/test/test_string_literals.py` | Modified | +8 / -4 | — | — |
| `Lib/test/test_syntax.py` | Modified | +49 / -39 | — | — |
| `Lib/test/test_sys.py` | Modified | +4 / -4 | — | — |
| `Lib/test/test_traceback.py` | Modified | +2 / -0 | — | — |
| `Lib/test/test_type_comments.py` | Modified | +1 / -0 | — | — |
| `Lib/test/test_unpack_ex.py` | Modified | +9 / -8 | — | — |
| `Lib/test/test_unparse.py` | Modified | +2 / -0 | — | — |
| `Tools/peg_generator/scripts/test_parse_directory.py` | Added | +289 / -0 | — | — |
| `Tools/peg_generator/scripts/test_pypi_packages.py` | Added | +101 / -0 | — | — |

#### Modification Summary
- **`Lib/test/test_cmd_line_script.py`**: Updates `SyntaxError` caret position assertions: the PEG parser places the caret under the `=` in `1 + 1 = 2` (column 12) rather than at column 4 as the old parser did.
- **`Lib/test/test_codeop.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to skip `test_incomplete` because PEG parser does not yet support `PyCF_DONT_IMPLY_DEDENT`.
- **`Lib/test/test_compile.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to skip `test_bad_single_statement` because PEG parser does not yet disallow multiline single statements.
- **`Lib/test/test_embed.py`**: Adds `use_peg: 1` to the default config dict and `use_peg: 0` to the `test_init_from_config` expected config to test the old-parser configuration.
- **`Lib/test/test_eof.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to `test_line_continuation_EOF` and `@unittest.skip` to `test_line_continuation_EOF_from_file_bpo2180` because the PEG parser handles these EOF cases differently.
- **`Lib/test/test_exceptions.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to `testSyntaxErrorOffset` because PEG parser column offsets differ from the old parser.
- **`Lib/test/test_flufl.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to the entire `FLUFLTests` class because the PEG parser does not yet support `from __future__ import barry_as_FLUFL`.
- **`Lib/test/test_fstring.py`**: Wraps an f-string `col_offset` assertion in `if not sys.flags.use_peg` because the PEG parser produces different column offsets for nested f-string expressions.
- **`Lib/test/test_generators.py`**: Comments out the `def f(): x = yield = y` SyntaxError doctest because the PEG parser does not yet produce the "assignment to yield expression" error message.
- **`Lib/test/test_parser.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to `test_trigger_memory_error` and passes `-Xoldparser` flag because the PEG parser does not trigger memory error with deeply nested parentheses the same way.
- **`Lib/test/test_peg_generator/__init__.py`**: Package init that loads all tests via `load_package_tests` for the peg_generator test package.
- **`Lib/test/test_peg_generator/__main__.py`**: Main entry point (`unittest.main()`) for running the peg_generator test package.
- **`Lib/test/test_peg_generator/ast_dump.py`**: A copy of `ast.dump` modified to use string-based class checks instead of `isinstance`, needed because the C extension's AST nodes have different type objects than `Python-ast.c`.
- **`Lib/test/test_peg_generator/test_c_parser.py`**: Tests for the C PEG parser extension: verifies grammar rules compile to working C extensions, tests expression parsing, operator precedence, left recursion, error handling, and AST comparison with the standard parser.
- **`Lib/test/test_peg_generator/test_first_sets.py`**: Tests for the FIRST set calculator: verifies correct FIRST sets for alternatives, optionals, repeats, left recursion, nested rules, and nullable rules.
- **`Lib/test/test_peg_generator/test_pegen.py`**: Tests for the Python PEG parser generator: verifies grammar parsing, rule generation, lookaheads, gather expressions, named items, cut semantics, left recursion, and error recovery.
- **`Lib/test/test_peg_parser.py`**: Comprehensive validation test (764 lines) comparing AST output of the PEG parser against the standard parser for hundreds of Python constructs (assignments, classes, functions, comprehensions, imports, etc.), ensuring AST equivalence.
- **`Lib/test/test_positional_only_arg.py`**: Wraps several "non-default argument follows default argument" `check_syntax_error` calls in `if not sys.flags.use_peg` because the PEG parser produces different error messages for positional-only argument validation.
- **`Lib/test/test_string_literals.py`**: Wraps `lineno` assertions for invalid escape warnings in `if not sys.flags.use_peg` because the PEG parser reports different line numbers for multiline string literals with invalid escapes.
- **`Lib/test/test_syntax.py`**: Comments out several SyntaxError doctests (e.g., `del f()`, literal assignment, starred-True assignment) that produce different error messages under the PEG parser.
- **`Lib/test/test_sys.py`**: Adds `use_peg` to the `sys.flags` attribute tuple, reflecting the new flag field.
- **`Lib/test/test_traceback.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to `test_syntax_error_offset_at_eol` because the PEG parser handles end-of-line syntax error offsets differently.
- **`Lib/test/test_type_comments.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to the entire `TypeCommentTests` class because the PEG parser does not yet support type comments.
- **`Lib/test/test_unpack_ex.py`**: Comments out the `list(*x for x in ...)` SyntaxError doctest because the PEG parser handles starred expressions in generator comprehension arguments differently.
- **`Lib/test/test_unparse.py`**: Adds `@unittest.skipIf(sys.flags.use_peg, ...)` to `test_function_type` because the PEG parser does not yet support type annotation parsing.
- **`Tools/peg_generator/scripts/test_parse_directory.py`**: Test script (289 lines) that parses all `.py` files in a directory using the PEG parser C extension and compares the AST output against the standard `ast.parse`, reporting pass/fail with colored output and optional short/verbose modes.
- **`Tools/peg_generator/scripts/test_pypi_packages.py`**: Test script (101 lines) that downloads and tests the top PyPI packages by parsing them with the PEG parser and comparing AST output, implementing the large-scale validation approach described in the PEP.

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Tools/scripts/run_tests.py` | Modified | +3 / -1 | Adds `peg_generator` to the list of tool test directories for test discovery | — | — |
| `Tools/peg_generator/scripts/download_pypi_packages.py` | Added | +86 / -0 | Utility script downloading top PyPI packages for large-scale parser testing | — | `download_package_code`, `download_package_json`, `load_json`, `main`, `remove_json` |

---

## Section 19: Performance
*Path: Performance and validation > Performance*
*Classification: Implementable*

> We have tuned the performance of the new parser to come within 10% of
> the current parser both in speed and memory consumption. While the
> PEG/packrat parsing algorithm inherently consumes more memory than the
> current LL(1) parser, we have an advantage because we don't construct
> an intermediate CST.
>
> Below are some benchmarks. These are focused on compiling source code
> to bytecode, because this is the most realistic situation. Returning
> an AST to Python code is not as representative, because the process to
> convert the *internal* AST (only accessible to C code) to an
> *external* AST (an instance of `ast.AST`) takes more time than the
> parser itself.
>
> All measurements reported here are done on a recent MacBook Pro,
> taking the median of three runs. No particular care was taken to stop
> other applications running on the same machine.
>
> The first timings are for our canonical test file, which has 100,000
> lines endlessly repeating the following three lines:
>
> ```python
> 1 + 2 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + ((((((11 * 12 * 13 * 14 * 15 + 16 * 17 + 18 * 19 * 20))))))
> 2*3 + 4*5*6
> 12 + (2 * 3 * 4 * 5 + 6 + 7 * 8)
> ```
> - Just parsing and throwing away the internal AST takes 1.16 seconds
>   with a max RSS of 681 MiB.
>
> - Parsing and converting to `ast.AST` takes 6.34 seconds, max RSS
>   1029 MiB.
>
> - Parsing and compiling to bytecode takes 1.28 seconds, max RSS 681
>   MiB.
>
> - With the current parser, parsing and compiling takes 1.44 seconds,
>   max RSS 836 MiB.
>
> For this particular test file, the new parser is faster and uses less
> memory than the current parser (compare the last two bullets).
>
> We also did timings with a more realistic payload, the entire Python
> 3.8 stdlib. This payload consists of 1,641 files, 749,570 lines,
> 27,622,497 bytes. (Though 11 files can't be compiled by any Python 3
> parser due to encoding issues, sometimes intentional.)
>
> - Compiling and throwing away the internal AST took 2.141 seconds.
>   That's 350,040 lines/sec, or 12,899,367 bytes/sec. The max RSS was
>   74 MiB (the largest file in the stdlib is much smaller than our
>   canonical test file).
>
> - Compiling to bytecode took 3.290 seconds. That's 227,861 lines/sec,
>   or 8,396,942 bytes/sec. Max RSS 77 MiB.
>
> - Compiling to bytecode using the current parser took 3.367 seconds.
>   That's 222,620 lines/sec, or 8,203,780 bytes/sec. Max RSS 70 MiB.
>
> Comparing the last two bullets we find that the new parser is slightly
> faster but uses slightly (about 10%) more memory. We believe this is
> acceptable. (Also, there are probably some more tweaks we can make to
> reduce memory usage.)

#### Requirement Summary
This section specifies that the new PEG parser should be tuned to be within 10% of the old LL(1) parser in speed and memory. The PR adds dedicated benchmark/timing/statistics scripts that directly implement the performance-measurement workflow used to validate that target.

**File proportion:** 3/91 files mapped (3.3%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Tools/peg_generator/scripts/ast_timings.py` | Added | +28 / -0 | — | `main` |
| `Tools/peg_generator/scripts/benchmark.py` | Added | +140 / -0 | — | `benchmark`, `main`, `run_benchmark_stdlib`, `run_benchmark_xxl`, `time_check`, `time_compile`, `time_parse` |
| `Tools/peg_generator/scripts/joinstats.py` | Added | +66 / -0 | `TypeMapper` | `main` |

#### Modification Summary
- **`Tools/peg_generator/scripts/ast_timings.py`**: Benchmarking script that measures AST compilation timing for the new parser, providing one of the inputs to the speed comparison required by the section.
- **`Tools/peg_generator/scripts/benchmark.py`**: Performance benchmark harness that times parsing of input under both the old and new parsers, directly implementing the speed/memory comparison the section calls for.
- **`Tools/peg_generator/scripts/joinstats.py`**: Joins and aggregates raw parsing statistics from multiple benchmark runs (via the `TypeMapper` class) into the comparable performance summaries that back up the within-10% claim in this section.

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None

---

## Linked Issue Expansion Notes

The requirement doc references two CPython issues:

- **`#56991` (bpo-12782) — "Multiple context expressions do not support parentheses for continuation across lines"**: The GitHub issue body contains only the BPO migration stub (a `BPO | 12782` field row, a `Nosy` list of `@username` mentions, and a `<details>` block of migrated bugs.python.org fields such as `activity`, `assignee`, `closed_at`, `created_at`, `creator`, `dependencies`, `files`, `keywords`, `messages`, `nosy_count`, `pr_nums`, `priority`, `resolution`, `stage`, `status`, `versions`). There is no descriptive prose body — the issue was filed pre-migration on bugs.python.org and only the title plus metadata table survived the migration. Per the EXCLUSIONS rule (no PEP metadata, no personal info, no comment threads), no `## Linked Issue` section is appended.
- **`#70603` (bpo-26415) — "Excessive peak memory consumption by the Python parser"**: Same situation — the body contains only the BPO field table, a `Nosy` list of `@username` mentions, a `PRs` link, a `Files` list of bpo attachment URLs, and the `<details>` block of migrated bugs.python.org fields. No descriptive prose. Per the same EXCLUSIONS rule, no `## Linked Issue` section is appended.

## Linked PEP Expansion Notes

The doc body contains no substantive in-body links to other PEPs. The only PEP reference is the document's own title (PEP 617). The "Rejected Alternatives" section discusses LALR(1), Yacc, Bison, LR, LL, and ANTLR in general parser-theory terms but does not cite any PEP. No additional `## Linked PEP` sections are appended.
