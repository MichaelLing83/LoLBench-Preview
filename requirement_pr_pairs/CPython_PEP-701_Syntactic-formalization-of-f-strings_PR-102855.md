# CPython - PEP 701: Syntactic formalization of f-strings

**PR:** https://github.com/python/cpython/pull/102855
**Requirement Doc:** https://peps.python.org/pep-0701/

## Matching Statistics
- **Requirement Doc Coverage:** 6/6 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 11/27 files mapped (40.7%) + 16/27 files associated (59.3%) = 27/27 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | PEP 701: Syntactic formalization of f-strings | No | N/A | knowledge |
| 2 | Abstract | No | N/A | knowledge |
| 3 | Motivation | No | N/A | knowledge |
| 4 | Rationale | No | N/A | contextual |
| 5 | Specification | Yes | Yes | implementation |
| 6 | Specification > Handling of f-string debug expressions | Yes | Yes | implementation |
| 7 | Specification > New tokens | Yes | Yes | implementation |
| 8 | Specification > Changes to the tokenize module | Yes | Yes | implementation |
| 9 | Specification > How to produce these new tokens | Yes | Yes | implementation |
| 10 | Specification > Consequences of the new grammar | Yes | Yes | implementation |
| 11 | Specification > Considerations regarding quote reuse | No | N/A | contextual |
| 12 | Backwards Compatibility | No | N/A | contextual |
| 13 | How to Teach This | No | N/A | contextual |
| 14 | Reference Implementation | No | N/A | process |
| 15 | Rejected Ideas | No | N/A | contextual |
| 16 | Open Issues | No | N/A | process |
| 17 | Footnotes | No | N/A | process |
| 18 | Copyright | No | N/A | process |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Doc/library/token-list.inc` | documentation | — | Section 7 |
| 2 | `Grammar/Tokens` | source | Section 7 | — |
| 3 | `Grammar/python.gram` | source | Section 5 | — |
| 4 | `Include/internal/pycore_token.h` | source | Section 7 | — |
| 5 | `Lib/test/test_ast.py` | test | — | Section 5 |
| 6 | `Lib/test/test_cmd_line_script.py` | test | — | Section 5 |
| 7 | `Lib/test/test_eof.py` | test | — | Section 5 |
| 8 | `Lib/test/test_exceptions.py` | test | — | Section 5 |
| 9 | `Lib/test/test_fstring.py` | test | — | Section 5, Section 6, Section 9, Section 10 |
| 10 | `Lib/test/test_tokenize.py` | test | — | Section 8 |
| 11 | `Lib/test/test_type_comments.py` | test | — | Section 5 |
| 12 | `Lib/token.py` | source | Section 7 | — |
| 13 | `Misc/NEWS.d/next/Core and Builtins/2023-04-17-16-00-32.gh-issue-102856.UunJ7y.rst` | documentation | — | Section 9 |
| 14 | `Parser/action_helpers.c` | source | Section 5, Section 6 | — |
| 15 | `Parser/parser.c` | generated | — | Section 5 |
| 16 | `Parser/pegen.c` | source | — | Section 5 |
| 17 | `Parser/pegen.h` | source | — | Section 5 |
| 18 | `Parser/pegen_errors.c` | source | — | Section 5 |
| 19 | `Parser/string_parser.c` | source | Section 10 | — |
| 20 | `Parser/string_parser.h` | source | Section 10 | — |
| 21 | `Parser/token.c` | source | Section 7 | — |
| 22 | `Parser/tokenizer.c` | source | Section 9 | — |
| 23 | `Parser/tokenizer.h` | source | Section 9 | — |
| 24 | `Programs/test_frozenmain.h` | test-data | — | Section 7 |
| 25 | `Python/Python-tokenize.c` | source | Section 8 | — |
| 26 | `Tools/build/generate_token.py` | build | — | Section 7 |
| 27 | `Tools/peg_generator/pegen/c_generator.py` | build | — | Section 9 |

---

## Section 5: Specification
*Path: Specification*
*Classification: Implementable*

> The formal proposed PEG grammar specification for f-strings is (see PEP 617
> for details on the syntax):
>
> ```peg
> fstring
>     | FSTRING_START fstring_middle* FSTRING_END
> fstring_middle
>     | fstring_replacement_field
>     | FSTRING_MIDDLE
> fstring_replacement_field
>     | '{' (yield_expr | star_expressions) "="? [ "!" NAME ] [ ':' fstring_format_spec* ] '}'
> fstring_format_spec:
>     | FSTRING_MIDDLE
>     | fstring_replacement_field
> ```
> The new tokens (`FSTRING_START`, `FSTRING_MIDDLE`, `FSTRING_END`) are defined
> [later in this document](new tokens_).
>
> This PEP leaves up to the implementation the level of f-string nesting allowed
> (f-strings within the expression parts of other f-strings) but **specifies a
> lower bound of 5 levels of nesting**. This is to ensure that users can have a
> reasonable expectation of being able to nest f-strings with "reasonable" depth.
> This PEP implies that limiting nesting is **not part of the language
> specification** but also the language specification **doesn't mandate arbitrary
> nesting**.
>
> Similarly, this PEP leaves up to the implementation the level of expression nesting
> in format specifiers but **specifies a lower bound of 2 levels of nesting**. This means
> that the following should always be valid:
>
> ```python
> f"{'':*^{1:{1}}}"
> ```
> but the following can be valid or not depending on the implementation:
>
> ```python
> f"{'':*^{1:{1:{1}}}}"
> ```
> The new grammar will preserve the Abstract Syntax Tree (AST) of the current
> implementation. This means that no semantic changes will be introduced by this
> PEP on existing code that uses f-strings.

#### Requirement Summary
This section defines the formal PEG grammar for f-strings with new production rules (fstring, fstring_middle, fstring_replacement_field, fstring_format_spec) using three new tokens. It specifies minimum nesting depths (5 levels for f-string nesting, 2 levels for format specifier nesting) and mandates AST preservation. The PR implements this grammar directly in `Grammar/python.gram`.

**File proportion:** 2/27 files mapped (7.4%) + 10/27 files associated (37.0%) = 12/27 accounted (44.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/python.gram` | Modified | +48 / -6 | — | — |
| `Parser/action_helpers.c` | Modified | +449 / -90 | — | `_PyPegen_concatenate_strings`, `unpack_top_level_joined_strs`, `_PyPegen_joined_str`, `_PyPegen_constant_from_token`, `_PyPegen_constant_from_string` |

#### Modification Summary
- **`Grammar/python.gram`**: Adds the PEG grammar rules for f-strings as specified in the PEP, including the `fstring`, `fstring_middle`, `fstring_replacement_field`, and `fstring_format_spec` productions that use the new `FSTRING_START`, `FSTRING_MIDDLE`, and `FSTRING_END` tokens.
- **`Parser/action_helpers.c`**: Implements the AST-construction helpers for the new PEG f-string grammar: `_PyPegen_concatenate_strings` joins adjacent string/f-string literals, `unpack_top_level_joined_strs` flattens nested `JoinedStr` nodes, `_PyPegen_joined_str` builds the top-level `JoinedStr` node, and `_PyPegen_constant_from_token`/`_PyPegen_constant_from_string` build the `Constant` nodes for `FSTRING_MIDDLE` literal segments. (Debug-expression helpers belong to Section 5.)

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Parser/parser.c` | Modified | +5024 / -2822 | Auto-generated parser output from Grammar/python.gram; regenerated to include the new f-string grammar rules | — | — |
| `Parser/pegen.c` | Modified | +1 / -1 | Parser infrastructure adjustment needed to support the new f-string grammar productions | — | `_PyPegen_expect_token` |
| `Parser/pegen.h` | Modified | +14 / -4 | Adds function declarations for f-string concatenation and node construction helpers used by the generated parser | — | — |
| `Parser/pegen_errors.c` | Modified | +12 / -4 | Improves error messages for f-string parsing failures, leveraging the new PEG parser error infrastructure | — | `_PyPegen_tokenize_full_source_to_check_for_errors`, `_PyPegen_raise_error` |
| `Lib/test/test_ast.py` | Modified | +0 / -5 | Removes old AST tests for f-string restrictions that no longer apply under the new grammar | — | — |
| `Lib/test/test_cmd_line_script.py` | Modified | +3 / -3 | Adjusts expected command line script output to account for new f-string tokenization behavior | — | — |
| `Lib/test/test_eof.py` | Modified | +3 / -1 | Updates EOF error tests that are affected by the new f-string parsing behavior | — | — |
| `Lib/test/test_exceptions.py` | Modified | +2 / -1 | Adjusts exception test expectations for f-string related syntax errors under the new parser | — | — |
| `Lib/test/test_type_comments.py` | Modified | +1 / -1 | Adjusts type comment test expectations affected by the new tokenization | — | — |
| `Lib/test/test_fstring.py` | Modified | +237 / -74 | Exercises the new PEG f-string grammar productions, including quote reuse, multi-line expressions, and AST preservation | — | — |

---

## Section 6: Specification > Handling of f-string debug expressions
*Path: Specification > Handling of f-string debug expressions*
*Classification: Implementable*

> Since Python 3.8, f-strings can be used to debug expressions by using the
> `=` operator. For example:
>
> ```
> >>> a = 1
> >>> f"{1+1=}"
> '1+1=2'
> ```
> This semantics were not introduced formally in a PEP and they were implemented
> in the current string parser as a special case in [bpo-36817](https://bugs.python.org/issue?@action=redirect&bpo=36817) and documented in
> [the f-string lexical analysis section](https://docs.python.org/3/reference/lexical_analysis.html#f-strings).
>
> This feature is not affected by the changes proposed in this PEP but is
> important to specify that the formal handling of this feature requires the lexer
> to be able to "untokenize" the expression part of the f-string. This is not a
> problem for the current string parser as it can operate directly on the string
> token contents. However, incorporating this feature into a given parser
> implementation requires the lexer to keep track of the raw string contents of
> the expression part of the f-string and make them available to the parser when
> the parse tree is constructed for f-string nodes. A pure "untokenization" is not
> enough because as specified currently, f-string debug expressions preserve whitespace in the expression,
> including spaces after the `{` and the `=` characters. This means that the
> raw string contents of the expression part of the f-string must be kept intact
> and not just the associated tokens.
>
> How parser/lexer implementations deal with this problem is of course up to the
> implementation.

#### Requirement Summary
This section specifies that f-string debug expressions (`f"{expr=}"`) must continue to work with the new grammar, requiring the lexer to track raw string contents for untokenization. The PR implements this in `Parser/action_helpers.c` which handles the construction of f-string debug expressions by preserving raw text from the tokenizer.

**File proportion:** 1/27 files mapped (3.7%) + 1/27 files associated (3.7%) = 2/27 accounted (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Parser/action_helpers.c` | Modified | +449 / -90 | — | `_PyPegen_check_fstring_conversion`, `decode_fstring_buffer`, `_PyPegen_decode_fstring_part`, `_PyPegen_formatted_value` |

#### Modification Summary
- **`Parser/action_helpers.c`**: Implements f-string debug-expression handling specified by this section. `_PyPegen_check_fstring_conversion` validates conversion specifiers (`!s`, `!r`, `!a`) used with debug syntax, `decode_fstring_buffer` and `_PyPegen_decode_fstring_part` recover raw tokenizer text so the `=` debug form can preserve the original source expression, and `_PyPegen_formatted_value` constructs the `FormattedValue` AST node that records the debug-expression text alongside its conversion/format-spec.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_fstring.py` | Modified | +237 / -74 | Covers debug expression (`f"{x=}"`) behavior under the new grammar | — | — |

---

## Section 7: Specification > New tokens
*Path: Specification > New tokens*
*Classification: Implementable*

> Three new tokens are introduced: `FSTRING_START`, `FSTRING_MIDDLE` and
> `FSTRING_END`. Different lexers may have different implementations that may be
> more efficient than the ones proposed here given the context of the particular
> implementation. However, the following definitions will be used as part of the
> public APIs of CPython (such as the `tokenize` module) and are also provided
> as a reference so that the reader can have a better understanding of the
> proposed grammar changes and how the tokens are used:
>
> * `FSTRING_START`: This token includes the f-string prefix (`f`/`F`/`fr`) and the opening quote(s).
> * `FSTRING_MIDDLE`: This token includes a portion of text inside the string that's not part of the
>   expression part and isn't an opening or closing brace. This can include the text between the opening quote
>   and the first expression brace (`{`), the text between two expression braces (`}` and `{`) and the text
>   between the last expression brace (`}`) and the closing quote.
> * `FSTRING_END`: This token includes the closing quote.
>
> These tokens are always string parts and they are semantically equivalent to the
> `STRING` token with the restrictions specified. These tokens must be produced by the lexer
> when lexing f-strings.  This means that **the tokenizer cannot produce a single token for f-strings anymore**.
> How the lexer emits this token is **not specified** as this will heavily depend on every
> implementation (even the Python version of the lexer in the standard library is implemented
> differently to the one used by the PEG parser).
>
> As an example:
>
> ```
> f'some words {a+b:.3f} more words {c+d=} final words'
> ```
> will be tokenized as:
>
> ```
> FSTRING_START - "f'"
> FSTRING_MIDDLE - 'some words '
> LBRACE - '{'
> NAME - 'a'
> PLUS - '+'
> NAME - 'b'
> OP - ':'
> FSTRING_MIDDLE - '.3f'
> RBRACE - '}'
> FSTRING_MIDDLE - ' more words '
> LBRACE - '{'
> NAME - 'c'
> PLUS - '+'
> NAME - 'd'
> OP - '='
> RBRACE - '}'
> FSTRING_MIDDLE - ' final words'
> FSTRING_END - "'"
> ```
> while `f"""some words"""` will be tokenized simply as:
>
> ```
> FSTRING_START - 'f"""'
> FSTRING_MIDDLE - 'some words'
> FSTRING_END - '"""'
> ```

#### Requirement Summary
This section defines three new tokens (FSTRING_START, FSTRING_MIDDLE, FSTRING_END) with precise semantics for how f-strings are tokenized. The PR adds these token definitions to the grammar token list, the C header, the Python token module, and the C token utilities.

**File proportion:** 4/27 files mapped (14.8%) + 3/27 files associated (11.1%) = 7/27 accounted (25.9%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Grammar/Tokens` | Modified | +4 / -0 | — | — |
| `Include/internal/pycore_token.h` | Modified | +14 / -8 | — | — |
| `Lib/token.py` | Modified | +16 / -11 | — | — |
| `Parser/token.c` | Modified | +5 / -0 | — | `_PyToken_OneChar` |

#### Modification Summary
- **`Grammar/Tokens`**: Adds the three new token type entries (FSTRING_START, FSTRING_MIDDLE, FSTRING_END) to the canonical token definition file used by the token generation pipeline.
- **`Include/internal/pycore_token.h`**: Updates the C-level token type constants and macros to include FSTRING_START, FSTRING_MIDDLE, and FSTRING_END, adjusting token count and classification macros accordingly.
- **`Lib/token.py`**: Updates the Python-level token module to include the new FSTRING_START, FSTRING_MIDDLE, and FSTRING_END token types with their numeric values, making them available to tools using the `token` module.
- **`Parser/token.c`**: Adds the new token type names to the token name array so they can be printed in debug output and error messages.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Doc/library/token-list.inc` | Modified | +10 / -0 | Documentation for the new token types must be added to the token list reference | — | — |
| `Tools/build/generate_token.py` | Modified | +2 / -0 | Token generation script must be updated to handle the new token types during build | — | — |
| `Programs/test_frozenmain.h` | Modified | +4 / -4 | Frozen main test data must be regenerated because token numeric values shifted with the new additions | — | — |

---

## Section 8: Specification > Changes to the tokenize module
*Path: Specification > Changes to the tokenize module*
*Classification: Implementable*

> The `tokenize` module will be adapted to emit these tokens as described in the previous section
> when parsing f-strings so tools can take advantage of this new tokenization schema and avoid having
> to implement their own f-string tokenizer and parser.

#### Requirement Summary
This section specifies that the `tokenize` module must be adapted to emit the new f-string tokens. The PR updates the C-level tokenize implementation to produce FSTRING_START, FSTRING_MIDDLE, and FSTRING_END tokens.

**File proportion:** 1/27 files mapped (3.7%) + 1/27 files associated (3.7%) = 2/27 accounted (7.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Python/Python-tokenize.c` | Modified | +2 / -2 | — | `tokenizeriter_next` |

#### Modification Summary
- **`Python/Python-tokenize.c`**: Adapts the C-level tokenize module interface to correctly handle and emit the new f-string token types (FSTRING_START, FSTRING_MIDDLE, FSTRING_END) when tokenizing Python source code.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_tokenize.py` | Modified | +23 / -5 | Tests for the tokenize module must be updated to verify correct emission of the new f-string tokens | — | — |

---

## Section 9: Specification > How to produce these new tokens
*Path: Specification > How to produce these new tokens*
*Classification: Implementable*

> One way existing lexers can be adapted to emit these tokens is to incorporate a
> stack of "lexer modes" or to use a stack of different lexers. This is because
> the lexer needs to switch from "regular Python lexing" to "f-string lexing" when
> it encounters an f-string start token and as f-strings can be nested, the
> context needs to be preserved until the f-string closes. Also, the "lexer mode"
> inside an f-string expression part needs to behave as a "super-set" of the
> regular Python lexer (as it needs to be able to switch back to f-string lexing
> when it encounters the `}` terminator for the expression part as well as
> handling f-string formatting and debug expressions). For reference, here is a
> draft of the algorithm to modify a CPython-like tokenizer to emit these new
> tokens:
>
> 1. If the lexer detects that an f-string is starting (by detecting the letter
>    'f/F' and one of the possible quotes) keep advancing until a valid quote is
>    detected (one of `"`, `"""`, `'` or `'''`) and emit a
>    `FSTRING_START` token with the contents captured (the 'f/F' and the
>    starting quote). Push a new tokenizer mode to the tokenizer mode stack for
>    "F-string tokenization". Go to step 2.
> 2. Keep consuming tokens until a one of the following is encountered:
>
>    * A closing quote equal to the opening quote.
>    * If in "format specifier mode" (see step 3), an opening brace (`{`), a
>      closing brace (`}`), or a newline token (`\n`).
>    * If not in "format specifier mode" (see step 3), an opening brace (`{`) or
>      a closing brace (`}`) that is not immediately followed by another opening/closing
>      brace.
>
>    In all cases, if the character buffer is not empty, emit a `FSTRING_MIDDLE`
>    token with the contents captured so far but transform any double
>    opening/closing braces into single opening/closing braces.  Now, proceed as
>    follows depending on the character encountered:
>
>    * If a closing quote matching the opening quite is encountered go to step 4.
>    * If an opening bracket (not immediately followed by another opening bracket)
>      is encountered, go to step 3.
>    * If a closing bracket (not immediately followed by another closing bracket)
>      is encountered, emit a token for the closing bracket and go to step 2.
> 3. Push a new tokenizer mode to the tokenizer mode stack for "Regular Python
>    tokenization within f-string" and proceed to tokenize with it. This mode
>    tokenizes as the "Regular Python tokenization" until a `:` or a `}`
>    character is encountered with the same level of nesting as the opening
>    bracket token that was pushed when we enter the f-string part. Using this mode,
>    emit tokens until one of the stop points are reached. When this happens, emit
>    the corresponding token for the stopping character encountered and, pop the
>    current tokenizer mode from the tokenizer mode stack and go to step 2. If the
>    stopping point is a `:` character, enter step 2 in "format specifier" mode.
> 4. Emit a `FSTRING_END` token with the contents captured and pop the current
>    tokenizer mode (corresponding to "F-string tokenization") and go back to
>    "Regular Python mode".
>
> Of course, as mentioned before, it is not possible to provide a precise
> specification of how this should be done for an arbitrary tokenizer as it will
> depend on the specific implementation and nature of the lexer to be changed.

#### Requirement Summary
This section provides a detailed algorithm for adapting lexers to emit the new f-string tokens using a stack of lexer modes. The PR implements this algorithm in the CPython tokenizer, adding f-string lexing state management with a mode stack that switches between regular Python tokenization and f-string tokenization.

**File proportion:** 2/27 files mapped (7.4%) + 3/27 files associated (11.1%) = 5/27 accounted (18.5%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Parser/tokenizer.c` | Modified | +483 / -6 | `tok_state`, `token` | `tok_state.TOK_GET_MODE`, `TOK_GET_MODE`, `tok_state.TOK_NEXT_MODE`, `TOK_NEXT_MODE`, `TOK_GET_BRACKET_MARK`, `tok_new`, `update_fstring_buffers`, `tok_state.update_fstring_buffers`, `update_fstring_expr`, `tok_state.update_fstring_expr`, `free_fstring_expressions`, `tok_state.free_fstring_expressions`, `tok_reserve_buf`, `_PyTokenizer_Free`, `tok_readline_raw`, `tok_underflow_interactive`, `tok_nextc`, `tok_backup`, `syntaxerror`, `warn_invalid_escape_sequence`, `tok_state.warn_invalid_escape_sequence`, `token_setup`, `token.tok_get`, `token.tok_get_normal_mode`, `tok_get_normal_mode`, `tok_get`, `tok_get_fstring_mode`, `token.tok_get_fstring_mode` |
| `Parser/tokenizer.h` | Modified | +29 / -0 | `_tokenizer_mode`, `tok_state` | — |

#### Modification Summary
- **`Parser/tokenizer.c`**: Implements the f-string tokenization algorithm described in the PEP, adding a lexer mode stack that tracks f-string nesting state. Adds logic to detect f-string start sequences, emit FSTRING_START/FSTRING_MIDDLE/FSTRING_END tokens, handle transitions between f-string text mode and expression mode, manage format specifier mode, and handle nested f-strings through the mode stack.
- **`Parser/tokenizer.h`**: Adds new state structures and fields to the tokenizer state to support f-string lexing, including the f-string nesting stack, mode tracking fields, quote type tracking, and buffer management for raw expression text needed by debug expressions.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Tools/peg_generator/pegen/c_generator.py` | Modified | +1 / -0 | PEG parser C code generator must be updated to handle the new f-string token types in generated parser code | — | — |
| `Misc/NEWS.d/next/Core and Builtins/2023-04-17-16-00-32.gh-issue-102856.UunJ7y.rst` | Added | +1 / -0 | Release notes entry announcing the C tokenizer changes implementing PEP 701 | — | — |
| `Lib/test/test_fstring.py` | Modified | +237 / -74 | Validates emission of `FSTRING_START`/`FSTRING_MIDDLE`/`FSTRING_END` tokens through end-to-end f-string parsing | — | — |

---

## Section 10: Specification > Consequences of the new grammar
*Path: Specification > Consequences of the new grammar*
*Classification: Implementable*

> All restrictions mentioned in the PEP are lifted from f-string literals, as explained below:
>
> * Expression portions may now contain strings delimited with the same kind of
>   quote that is used to delimit the f-string literal.
> * Backslashes may now appear within expressions just like anywhere else in
>   Python code. In case of strings nested within f-string literals, escape sequences are
>   expanded when the innermost string is evaluated.
> * New lines are now allowed within expression brackets. This means that these are now allowed:
>
> ```
> >>> x = 1
> >>> f"___{
> ...     x
> ... }___"
> '___1___'
>
> >>> f"___{(
> ...     x
> ... )}___"
> '___1___'
> ```
> * Comments, using the `#` character, are allowed within the expression part of an f-string.
>   Note that comments require that the closing bracket (`}`) of the expression part to be present in
>   a different line as the one the comment is in or otherwise it will be ignored as part of the comment.

#### Requirement Summary
This section specifies the concrete behavioral consequences of the new grammar: quote reuse in expressions, backslashes in expressions, newlines in expression brackets, and comments in expressions. The PR implements these by removing the old restriction-enforcing code from the string parser, which previously rejected these constructs.

**File proportion:** 2/27 files mapped (7.4%) + 1/27 files associated (3.7%) = 3/27 accounted (11.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `Parser/string_parser.c` | Modified | +35 / -1054 | `tok_state` | `decode_unicode_with_escapes`, `_PyPegen_parsestr`, `_PyPegen_decode_string`, `_PyPegen_parse_string`, `fstring_find_expr_location`, `fstring_compile_expr`, `tok_state.fstring_compile_expr`, `fstring_find_literal`, `fstring_find_expr`, `fstring_find_literal_and_expr`, `ExprList_check_invariants`, `ExprList_Init`, `ExprList_Append`, `ExprList_Dealloc`, `ExprList_Finish`, `FstringParser_check_invariants`, `_PyPegen_FstringParser_Init`, `_PyPegen_FstringParser_Dealloc`, `make_str_node_and_del`, `_PyPegen_FstringParser_ConcatAndDel`, `_PyPegen_FstringParser_ConcatFstring`, `_PyPegen_FstringParser_Finish`, `fstring_parse` |
| `Parser/string_parser.h` | Modified | +2 / -37 | — | — |

#### Modification Summary
- **`Parser/string_parser.c`**: Removes the old hand-written f-string expression parser (over 1,000 lines deleted) that previously enforced restrictions on quote reuse, backslashes, and comments within f-string expressions. The remaining code handles only simple string literal processing, as f-string expression parsing is now handled by the PEG parser and new tokenizer.
- **`Parser/string_parser.h`**: Removes the old function declarations for the hand-written f-string parser that was eliminated, retaining only the simplified string processing interface.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Lib/test/test_fstring.py` | Modified | +237 / -74 | Comprehensive f-string test suite updated to verify the lifted restrictions: adds tests for quote reuse, backslashes in expressions, comments in expressions, and nested f-strings | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
