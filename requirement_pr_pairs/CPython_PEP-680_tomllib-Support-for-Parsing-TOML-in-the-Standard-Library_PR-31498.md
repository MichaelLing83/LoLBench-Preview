# CPython - PEP 680: tomllib: Support for Parsing TOML in the Standard Library

**PR:** https://github.com/python/cpython/pull/31498
**Requirement Doc:** https://peps.python.org/pep-0680/

## Matching Statistics
- **Requirement Doc Coverage:** 1/1 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 5/90 files mapped (5.6%) + 85/90 files associated (94.4%) = 90/90 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 680: tomllib: Support for Parsing TOML in the Standard Library | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | contextual |
| 4 | Rationale | No | N/A | contextual |
| 5 | Specification | Yes | Yes | implementation |
| 6 | Maintenance Implications | No | N/A | knowledge |
| 7 | Maintenance Implications > Stability of TOML | No | N/A | contextual |
| 8 | Maintenance Implications > Maintainability of proposed implementation | No | N/A | contextual |
| 9 | Maintenance Implications > TOML support a slippery slope for other things | No | N/A | contextual |
| 10 | Backwards Compatibility | No | N/A | contextual |
| 11 | Security Implications | No | N/A | contextual |
| 12 | How to Teach This | No | N/A | contextual |
| 13 | Reference Implementation | No | N/A | process |
| 14 | Rejected Ideas | No | N/A | knowledge |
| 15 | Rejected Ideas > Basing on another TOML implementation | No | N/A | contextual |
| 16 | Rejected Ideas > Including an API for writing TOML | No | N/A | contextual |
| 17 | Rejected Ideas > Assorted API details | No | N/A | contextual |
| 18 | Rejected Ideas > Assorted API details > Types accepted as the first argument of `tomllib.load` | No | N/A | contextual |
| 19 | Rejected Ideas > Assorted API details > Type accepted as the first argument of `tomllib.loads` | No | N/A | contextual |
| 20 | Rejected Ideas > Controlling the type of mappings returned by `tomllib.load[s]` | No | N/A | contextual |
| 21 | Rejected Ideas > Removing support for `parse_float` in `tomllib.load[s]` | No | N/A | contextual |
| 22 | Rejected Ideas > Alternative names for the module | No | N/A | contextual |
| 23 | Previous Discussion | No | N/A | contextual |
| 24 | Appendix A: Differences between proposed API and `toml` | No | N/A | contextual |
| 25 | Copyright | No | N/A | process |
| 26 | Linked PEP 517 — A build-system independent format for source trees | No | N/A | contextual |
| 27 | Linked PEP 517 — A build-system independent format for source trees > Abstract | No | N/A | knowledge |
| 28 | Linked PEP 517 — A build-system independent format for source trees > Terminology and goals | No | N/A | knowledge |
| 29 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects | No | N/A | contextual |
| 30 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects > Abstract | No | N/A | knowledge |
| 31 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects > Rationale | No | N/A | contextual |
| 32 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects > Specification (File Format) | No | N/A | knowledge |
| 33 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects > Specification (File Format) > build-system table | No | N/A | knowledge |
| 34 | Linked PEP 518 — Specifying Minimum Build System Requirements for Python Projects > Specification (File Format) > tool table | No | N/A | knowledge |
| 35 | Linked PEP 621 — Storing project metadata in pyproject.toml | No | N/A | contextual |
| 36 | Linked PEP 621 — Storing project metadata in pyproject.toml > Abstract | No | N/A | knowledge |
| 37 | Linked PEP 621 — Storing project metadata in pyproject.toml > Motivation | No | N/A | contextual |
| 38 | Linked PEP 621 — Storing project metadata in pyproject.toml > Rationale | No | N/A | contextual |
| 39 | Linked PEP 621 — Storing project metadata in pyproject.toml > Specification (Details) | No | N/A | knowledge |
| 40 | Linked PEP 621 — Storing project metadata in pyproject.toml > Specification (Details) > Table name | No | N/A | knowledge |
| 41 | Linked Issue #84240 — Provide a toml module in the standard library (bpo-40059) | No | N/A | contextual |
| 42 | Linked Issue #141 (hukkin/tomli) — Please consider pushing tomli into stdlib | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `.github/CODEOWNERS` | build | — | Section 5 |
| 2 | `Doc/library/fileformats.rst` | documentation | — | Section 5 |
| 3 | `Doc/library/tomllib.rst` | documentation | — | Section 5 |
| 4 | `Doc/whatsnew/3.11.rst` | documentation | — | Section 5 |
| 5 | `Lib/test/test_tomllib/__init__.py` | test | — | Section 5 |
| 6 | `Lib/test/test_tomllib/__main__.py` | test | — | Section 5 |
| 7 | `Lib/test/test_tomllib/burntsushi.py` | test | — | Section 5 |
| 8 | `Lib/test/test_tomllib/data/invalid/array-missing-comma.toml` | test-data | — | Section 5 |
| 9 | `Lib/test/test_tomllib/data/invalid/array-of-tables/overwrite-array-in-parent.toml` | test-data | — | Section 5 |
| 10 | `Lib/test/test_tomllib/data/invalid/array-of-tables/overwrite-bool-with-aot.toml` | test-data | — | Section 5 |
| 11 | `Lib/test/test_tomllib/data/invalid/array/file-end-after-val.toml` | test-data | — | Section 5 |
| 12 | `Lib/test/test_tomllib/data/invalid/array/unclosed-after-item.toml` | test-data | — | Section 5 |
| 13 | `Lib/test/test_tomllib/data/invalid/array/unclosed-empty.toml` | test-data | — | Section 5 |
| 14 | `Lib/test/test_tomllib/data/invalid/basic-str-ends-in-escape.toml` | test-data | — | Section 5 |
| 15 | `Lib/test/test_tomllib/data/invalid/boolean/invalid-false-casing.toml` | test-data | — | Section 5 |
| 16 | `Lib/test/test_tomllib/data/invalid/boolean/invalid-true-casing.toml` | test-data | — | Section 5 |
| 17 | `Lib/test/test_tomllib/data/invalid/dates-and-times/invalid-day.toml` | test-data | — | Section 5 |
| 18 | `Lib/test/test_tomllib/data/invalid/dotted-keys/access-non-table.toml` | test-data | — | Section 5 |
| 19 | `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-aot.toml` | test-data | — | Section 5 |
| 20 | `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-table-with-subtable.toml` | test-data | — | Section 5 |
| 21 | `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-table.toml` | test-data | — | Section 5 |
| 22 | `Lib/test/test_tomllib/data/invalid/inline-table-missing-comma.toml` | test-data | — | Section 5 |
| 23 | `Lib/test/test_tomllib/data/invalid/inline-table/define-twice-in-subtable.toml` | test-data | — | Section 5 |
| 24 | `Lib/test/test_tomllib/data/invalid/inline-table/define-twice.toml` | test-data | — | Section 5 |
| 25 | `Lib/test/test_tomllib/data/invalid/inline-table/file-end-after-key-val.toml` | test-data | — | Section 5 |
| 26 | `Lib/test/test_tomllib/data/invalid/inline-table/mutate.toml` | test-data | — | Section 5 |
| 27 | `Lib/test/test_tomllib/data/invalid/inline-table/override-val-in-table.toml` | test-data | — | Section 5 |
| 28 | `Lib/test/test_tomllib/data/invalid/inline-table/override-val-with-array.toml` | test-data | — | Section 5 |
| 29 | `Lib/test/test_tomllib/data/invalid/inline-table/override-val-with-table.toml` | test-data | — | Section 5 |
| 30 | `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-implicitly.toml` | test-data | — | Section 5 |
| 31 | `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-value-in-inner-array.toml` | test-data | — | Section 5 |
| 32 | `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-value-in-inner-table.toml` | test-data | — | Section 5 |
| 33 | `Lib/test/test_tomllib/data/invalid/inline-table/unclosed-empty.toml` | test-data | — | Section 5 |
| 34 | `Lib/test/test_tomllib/data/invalid/invalid-comment-char.toml` | test-data | — | Section 5 |
| 35 | `Lib/test/test_tomllib/data/invalid/invalid-escaped-unicode.toml` | test-data | — | Section 5 |
| 36 | `Lib/test/test_tomllib/data/invalid/invalid-hex.toml` | test-data | — | Section 5 |
| 37 | `Lib/test/test_tomllib/data/invalid/keys-and-vals/ends-early-table-def.toml` | test-data | — | Section 5 |
| 38 | `Lib/test/test_tomllib/data/invalid/keys-and-vals/ends-early.toml` | test-data | — | Section 5 |
| 39 | `Lib/test/test_tomllib/data/invalid/keys-and-vals/no-value.toml` | test-data | — | Section 5 |
| 40 | `Lib/test/test_tomllib/data/invalid/keys-and-vals/only-ws-after-dot.toml` | test-data | — | Section 5 |
| 41 | `Lib/test/test_tomllib/data/invalid/keys-and-vals/overwrite-with-deep-table.toml` | test-data | — | Section 5 |
| 42 | `Lib/test/test_tomllib/data/invalid/literal-str/unclosed.toml` | test-data | — | Section 5 |
| 43 | `Lib/test/test_tomllib/data/invalid/missing-closing-double-square-bracket.toml` | test-data | — | Section 5 |
| 44 | `Lib/test/test_tomllib/data/invalid/missing-closing-square-bracket.toml` | test-data | — | Section 5 |
| 45 | `Lib/test/test_tomllib/data/invalid/multiline-basic-str/carriage-return.toml` | test-data | — | Section 5 |
| 46 | `Lib/test/test_tomllib/data/invalid/multiline-basic-str/escape-only.toml` | test-data | — | Section 5 |
| 47 | `Lib/test/test_tomllib/data/invalid/multiline-basic-str/file-ends-after-opening.toml` | test-data | — | Section 5 |
| 48 | `Lib/test/test_tomllib/data/invalid/multiline-basic-str/last-line-escape.toml` | test-data | — | Section 5 |
| 49 | `Lib/test/test_tomllib/data/invalid/multiline-basic-str/unclosed-ends-in-whitespace-escape.toml` | test-data | — | Section 5 |
| 50 | `Lib/test/test_tomllib/data/invalid/multiline-literal-str/file-ends-after-opening.toml` | test-data | — | Section 5 |
| 51 | `Lib/test/test_tomllib/data/invalid/multiline-literal-str/unclosed.toml` | test-data | — | Section 5 |
| 52 | `Lib/test/test_tomllib/data/invalid/non-scalar-escaped.toml` | test-data | — | Section 5 |
| 53 | `Lib/test/test_tomllib/data/invalid/table/eof-after-opening.toml` | test-data | — | Section 5 |
| 54 | `Lib/test/test_tomllib/data/invalid/table/redefine-1.toml` | test-data | — | Section 5 |
| 55 | `Lib/test/test_tomllib/data/invalid/table/redefine-2.toml` | test-data | — | Section 5 |
| 56 | `Lib/test/test_tomllib/data/invalid/unclosed-multiline-string.toml` | test-data | — | Section 5 |
| 57 | `Lib/test/test_tomllib/data/invalid/unclosed-string.toml` | test-data | — | Section 5 |
| 58 | `Lib/test/test_tomllib/data/valid/apostrophes-in-literal-string.json` | test-data | — | Section 5 |
| 59 | `Lib/test/test_tomllib/data/valid/apostrophes-in-literal-string.toml` | test-data | — | Section 5 |
| 60 | `Lib/test/test_tomllib/data/valid/array/array-subtables.json` | test-data | — | Section 5 |
| 61 | `Lib/test/test_tomllib/data/valid/array/array-subtables.toml` | test-data | — | Section 5 |
| 62 | `Lib/test/test_tomllib/data/valid/array/open-parent-table.json` | test-data | — | Section 5 |
| 63 | `Lib/test/test_tomllib/data/valid/array/open-parent-table.toml` | test-data | — | Section 5 |
| 64 | `Lib/test/test_tomllib/data/valid/boolean.json` | test-data | — | Section 5 |
| 65 | `Lib/test/test_tomllib/data/valid/boolean.toml` | test-data | — | Section 5 |
| 66 | `Lib/test/test_tomllib/data/valid/dates-and-times/datetimes.json` | test-data | — | Section 5 |
| 67 | `Lib/test/test_tomllib/data/valid/dates-and-times/datetimes.toml` | test-data | — | Section 5 |
| 68 | `Lib/test/test_tomllib/data/valid/dates-and-times/localtime.json` | test-data | — | Section 5 |
| 69 | `Lib/test/test_tomllib/data/valid/dates-and-times/localtime.toml` | test-data | — | Section 5 |
| 70 | `Lib/test/test_tomllib/data/valid/empty-inline-table.json` | test-data | — | Section 5 |
| 71 | `Lib/test/test_tomllib/data/valid/empty-inline-table.toml` | test-data | — | Section 5 |
| 72 | `Lib/test/test_tomllib/data/valid/five-quotes.json` | test-data | — | Section 5 |
| 73 | `Lib/test/test_tomllib/data/valid/five-quotes.toml` | test-data | — | Section 5 |
| 74 | `Lib/test/test_tomllib/data/valid/hex-char.json` | test-data | — | Section 5 |
| 75 | `Lib/test/test_tomllib/data/valid/hex-char.toml` | test-data | — | Section 5 |
| 76 | `Lib/test/test_tomllib/data/valid/multiline-basic-str/ends-in-whitespace-escape.json` | test-data | — | Section 5 |
| 77 | `Lib/test/test_tomllib/data/valid/multiline-basic-str/ends-in-whitespace-escape.toml` | test-data | — | Section 5 |
| 78 | `Lib/test/test_tomllib/data/valid/no-newlines.json` | test-data | — | Section 5 |
| 79 | `Lib/test/test_tomllib/data/valid/no-newlines.toml` | test-data | — | Section 5 |
| 80 | `Lib/test/test_tomllib/data/valid/trailing-comma.json` | test-data | — | Section 5 |
| 81 | `Lib/test/test_tomllib/data/valid/trailing-comma.toml` | test-data | — | Section 5 |
| 82 | `Lib/test/test_tomllib/test_data.py` | test | — | Section 5 |
| 83 | `Lib/test/test_tomllib/test_error.py` | test | — | Section 5 |
| 84 | `Lib/test/test_tomllib/test_misc.py` | test | — | Section 5 |
| 85 | `Lib/tomllib/__init__.py` | source | Section 5 | — |
| 86 | `Lib/tomllib/_parser.py` | source | Section 5 | — |
| 87 | `Lib/tomllib/_re.py` | source | Section 5 | — |
| 88 | `Lib/tomllib/_types.py` | source | Section 5 | — |
| 89 | `Misc/NEWS.d/next/Library/2022-02-23-01-11-08.bpo-40059.Iwc9UH.rst` | documentation | — | Section 5 |
| 90 | `Python/stdlib_module_names.h` | source | Section 5 | — |

---


## Section 5: Specification -- The `tomllib` Module
**File proportion:** 5/90 files mapped (5.6%) + 85/90 files associated (94.4%) = 90/90 accounted (100.0%)

*Path: Specification*
*Classification: Implementable*
*File proportion: 5 of 90 files (5.6%)*

> A new module `tomllib` will be added to the Python standard library,
> exposing the following public functions:
>
> ```
> def load(
>     fp: SupportsRead[bytes],
>     /,
>     *,
>     parse_float: Callable[[str], Any] = ...,
>  ) -> dict[str, Any]: ...
>
> def loads(
>     s: str,
>     /,
>     *,
>     parse_float: Callable[[str], Any] = ...,
> ) -> dict[str, Any]: ...
> ```
> `tomllib.load` deserializes a binary file-like object containing a
> TOML document to a Python `dict`.
> The `fp` argument must have a `read()` method with the same API as
> `io.RawIOBase.read()`.
>
> `tomllib.loads` deserializes a `str` instance containing a TOML document
> to a Python `dict`.
>
> The `parse_float` argument is a callable object that takes as input the
> original string representation of a TOML float, and returns a corresponding
> Python object (similar to `parse_float` in `json.load`).
> For example, the user may pass a function returning a `decimal.Decimal`,
> for use cases where exact precision is important. By default, TOML floats
> are parsed as instances of the Python `float` type.
>
> The returned object contains only basic Python objects (`str`, `int`,
> `bool`, `float`, `datetime.{datetime,date,time}`, `list`, `dict` with
> string keys), and the results of `parse_float`.
>
> `tomllib.TOMLDecodeError` is raised in the case of invalid TOML.
>
> Note that this PEP does not propose `tomllib.dump` or `tomllib.dumps`
> functions; see `Including an API for writing TOML`_ for details.

#### Requirement Summary
This section specifies adding a read-only TOML parser to the standard library. The PR adds the `tomllib` package with `load`/`loads`/`TOMLDecodeError`, a 691-line TOML 1.0.0 compliant parser ported from `tomli`, regex helpers, type definitions, and stdlib module registration.

#### Modified Files

| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Lib/tomllib/__init__.py` | Added | +10 / -0 | — | — |
| `Lib/tomllib/_parser.py` | Added | +691 / -0 | `Flags`, `NestedDict`, `Output`, `TOMLDecodeError` | `coord_repr`, `create_dict_rule`, `create_list_rule`, `is_unicode_scalar_value`, `key_value_rule`, `load`, `loads`, `make_safe_parse_float`, `parse_array`, `parse_basic_str`, `parse_basic_str_escape`, `parse_basic_str_escape_multiline`, `parse_hex_char`, `parse_inline_table`, `parse_key`, `parse_key_part`, `parse_key_value_pair`, `parse_literal_str`, `parse_multiline_str`, `parse_one_line_basic_str`, `parse_value`, `safe_parse_float`, `skip_chars`, `skip_comment`, `skip_comments_and_array_ws`, `skip_until`, `suffixed_err`, `Flags.__init__`, `Flags.add_pending`, `Flags.finalize_pending`, `Flags.is_`, `Flags.set`, `Flags.unset_all`, `NestedDict.__init__`, `NestedDict.append_nest_to_list`, `NestedDict.get_or_create_nest` |
| `Lib/tomllib/_re.py` | Added | +107 / -0 | — | `cached_tz`, `match_to_datetime`, `match_to_localtime`, `match_to_number` |
| `Lib/tomllib/_types.py` | Added | +10 / -0 | — | — |
| `Python/stdlib_module_names.h` | Modified | +1 / -0 | — | — |

#### Modification Summary
- **`Lib/tomllib/__init__.py`**: Package init file that exposes the public API: imports and re-exports ``loads``, ``load`` from ``_parser`` and ``TOMLDecodeError`` from ``_parser``, defining the ``__all__`` list for the module.
- **`Lib/tomllib/_parser.py`**: The core TOML parser implementation (691 lines), ported from the ``tomli`` library. Implements the ``load()`` and ``loads()`` public functions, the ``TOMLDecodeError`` exception class, and a complete TOML 1.0.0 compliant parser that handles all TOML data types including strings (basic, literal, multiline), integers (decimal, hex, octal, binary), floats (including special values inf/nan), booleans, datetimes (offset, local, date, time), arrays, inline tables, standard tables, and arrays of tables. Supports the ``parse_float`` callback for custom float parsing.
- **`Lib/tomllib/_re.py`**: Regular expression patterns and helper functions used by the parser for matching TOML datetime formats, and for caching and compiling the regex patterns used during parsing.
- **`Lib/tomllib/_types.py`**: Type alias definitions used internally by the parser, including the ``Key`` type and ``ParseFloat`` callable type alias.
- **`Python/stdlib_module_names.h`**: Adds ``"tomllib"`` to the frozen set of stdlib module names so the interpreter recognizes it as a built-in standard library module.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `.github/CODEOWNERS` | Modified | +2 / -0 | Assigns code ownership for the new ``Lib/tomllib/`` directory | — | — |
| `Doc/library/fileformats.rst` | Modified | +1 / -0 | Adds ``tomllib`` to the file formats section table of contents | — | — |
| `Doc/library/tomllib.rst` | Added | +117 / -0 | Full documentation for the new ``tomllib`` module including API reference, usage examples, and notes | — | — |
| `Doc/whatsnew/3.11.rst` | Modified | +2 / -1 | Adds "What's New" entry announcing the new ``tomllib`` module in Python 3.11 | — | — |
| `Misc/NEWS.d/next/Library/2022-02-23-01-11-08.bpo-40059.Iwc9UH.rst` | Added | +1 / -0 | NEWS entry for the addition of ``tomllib`` to the standard library | — | — |
| `Lib/test/test_tomllib/__init__.py` | Added | +15 / -0 | Test package init with helper utilities for the tomllib test suite | — | — |
| `Lib/test/test_tomllib/__main__.py` | Added | +6 / -0 | Allows running the tomllib test suite as ``python -m test.test_tomllib`` | — | — |
| `Lib/test/test_tomllib/burntsushi.py` | Added | +120 / -0 | Test runner for the BurntSushi TOML compliance test suite | — | — |
| `Lib/test/test_tomllib/test_data.py` | Added | +64 / -0 | Data-driven tests validating parsing of valid TOML files against expected JSON outputs | — | — |
| `Lib/test/test_tomllib/data/invalid/array-missing-comma.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/array-of-tables/overwrite-array-in-parent.toml` | Added | +4 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/array-of-tables/overwrite-bool-with-aot.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/array/file-end-after-val.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/array/unclosed-after-item.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/array/unclosed-empty.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/basic-str-ends-in-escape.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/boolean/invalid-false-casing.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/boolean/invalid-true-casing.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/dates-and-times/invalid-day.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/dotted-keys/access-non-table.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-aot.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-table-with-subtable.toml` | Added | +4 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/dotted-keys/extend-defined-table.toml` | Added | +4 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table-missing-comma.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/define-twice-in-subtable.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/define-twice.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/file-end-after-key-val.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/mutate.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/override-val-in-table.toml` | Added | +5 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/override-val-with-array.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/override-val-with-table.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-implicitly.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-value-in-inner-array.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/overwrite-value-in-inner-table.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/inline-table/unclosed-empty.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/invalid-comment-char.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/invalid-escaped-unicode.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/invalid-hex.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/keys-and-vals/ends-early-table-def.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/keys-and-vals/ends-early.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/keys-and-vals/no-value.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/keys-and-vals/only-ws-after-dot.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/keys-and-vals/overwrite-with-deep-table.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/literal-str/unclosed.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/missing-closing-double-square-bracket.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/missing-closing-square-bracket.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-basic-str/carriage-return.toml` | Added | +2 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-basic-str/escape-only.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-basic-str/file-ends-after-opening.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-basic-str/last-line-escape.toml` | Added | +4 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-basic-str/unclosed-ends-in-whitespace-escape.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-literal-str/file-ends-after-opening.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/multiline-literal-str/unclosed.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/non-scalar-escaped.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/table/eof-after-opening.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/table/redefine-1.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/table/redefine-2.toml` | Added | +3 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/unclosed-multiline-string.toml` | Added | +4 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/invalid/unclosed-string.toml` | Added | +1 / -0 | Test fixture: invalid TOML input for parser error handling | — | — |
| `Lib/test/test_tomllib/data/valid/apostrophes-in-literal-string.json` | Added | +1 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/apostrophes-in-literal-string.toml` | Added | +3 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/array/array-subtables.json` | Added | +11 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/array/array-subtables.toml` | Added | +7 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/array/open-parent-table.json` | Added | +6 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/array/open-parent-table.toml` | Added | +4 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/boolean.json` | Added | +4 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/boolean.toml` | Added | +2 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/dates-and-times/datetimes.json` | Added | +4 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/dates-and-times/datetimes.toml` | Added | +2 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/dates-and-times/localtime.json` | Added | +2 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/dates-and-times/localtime.toml` | Added | +1 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/empty-inline-table.json` | Added | +1 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/empty-inline-table.toml` | Added | +1 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/five-quotes.json` | Added | +4 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/five-quotes.toml` | Added | +6 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/hex-char.json` | Added | +5 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/hex-char.toml` | Added | +3 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/multiline-basic-str/ends-in-whitespace-escape.json` | Added | +1 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/multiline-basic-str/ends-in-whitespace-escape.toml` | Added | +6 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/no-newlines.json` | Added | +1 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/no-newlines.toml` | Added | +1 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/data/valid/trailing-comma.json` | Added | +7 / -0 | Test fixture: expected JSON output for valid TOML parsing | — | — |
| `Lib/test/test_tomllib/data/valid/trailing-comma.toml` | Added | +1 / -0 | Test fixture: valid TOML input for parser correctness | — | — |
| `Lib/test/test_tomllib/test_error.py` | Added | +57 / -0 | Tests for TOML parsing error handling and error messages | — | — |
| `Lib/test/test_tomllib/test_misc.py` | Added | +101 / -0 | Miscellaneous tests for tomllib edge cases and features | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
