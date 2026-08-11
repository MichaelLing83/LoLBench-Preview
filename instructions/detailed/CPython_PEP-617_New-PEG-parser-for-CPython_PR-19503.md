> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# PEP 617: New PEG parser for CPython

## Overview
This PEP proposes replacing the current LL(1)-based parser of CPython
with a new PEG-based parser. This new parser would allow the elimination of multiple
"hacks" that exist in the current grammar to circumvent the LL(1)-limitation.
It would substantially reduce the maintenance costs in some areas related to the
compiling pipeline such as the grammar, the parser and the AST generation. The new PEG
parser will also lift the LL(1) restriction on the current Python grammar.

## Background on LL(1) parsers
The current Python grammar is an LL(1)-based grammar. A grammar can be said to be
LL(1) if it can be parsed by an LL(1) parser, which in turn is defined as a
top-down parser that parses the input from left to right, performing leftmost
derivation of the sentence, with just one token of lookahead.
The traditional approach to constructing or generating an LL(1) parser is to
produce a *parse table* which encodes the possible transitions between all possible
states of the parser. These tables are normally constructed from the *first sets*
and the *follow sets* of the grammar:

* Given a rule, the *first set* is the collection of all terminals that can occur
  first in a full derivation of that rule. Intuitively, this helps the parser decide
  among the alternatives in a rule. For
  instance, given the rule:

```
rule: A | B
```
  if only `A` can start with the terminal *a* and only `B` can start with the
  terminal *b* and the parser sees the token *b* when parsing this rule, it knows
  that it needs to follow the non-terminal `B`.

* An extension to this simple idea is needed when a rule may expand to the empty string.
  Given a rule, the *follow set* is the collection of terminals that can appear
  immediately to the right of that rule in a partial derivation. Intuitively, this
  solves the problem of the empty alternative. For instance,
  given this rule:

```
rule: A 'b'
```
  if the parser has the token *b* and the non-terminal `A` can only start
  with the token *a*, then the parser can tell that this is an invalid program.
  But if `A` could expand to the empty string (called an ε-production),
  then the parser would recognise a valid empty `A`,
  since the next token *b* is in the *follow set*  of `A`.

The current Python grammar does not contain ε-productions, so the *follow sets* are not
needed when creating the parse tables. Currently, in CPython, a parser generator
program reads the grammar and produces a parsing table representing a set of
deterministic finite automata (DFA) that can be included in a C program, the
parser. The parser is a pushdown automaton that uses this data to produce a Concrete
Syntax Tree (CST) sometimes known directly as a "parse tree". In this process, the
*first sets* are used indirectly when generating the DFAs.

LL(1) parsers and grammars are usually efficient and simple to implement
and generate. However, it is not possible, under the LL(1) restriction,
to express certain common constructs in a way natural to the language
designer and the reader. This includes some in the Python language.

As LL(1) parsers can only look one token ahead to distinguish
possibilities, some rules in the grammar may be ambiguous. For instance the rule:

```
rule: A | B
```
is ambiguous if the *first sets* of both `A` and `B` have some elements in
common. When the parser sees a token in the input
program that both *A* and *B* can start with, it is impossible for it to deduce
which option to expand, as no further token of the program can be examined to
disambiguate.
The rule may be transformed to equivalent LL(1) rules, but then it may
be harder for a human reader to grasp its meaning.
Examples later in this document show that the current LL(1)-based
grammar suffers a lot from this scenario.

Another broad class of rules precluded by LL(1) is left-recursive rules.
A rule is left-recursive if it can derive to a
sentential form with itself as the leftmost symbol. For instance this rule:

```
rule: rule 'a'
```
is left-recursive because the rule can be expanded to an expression that starts
with itself. As will be described later, left-recursion is the natural way to
express certain desired language properties directly in the grammar.

## Background on PEG parsers
A PEG (Parsing Expression Grammar) grammar differs from a context-free grammar
(like the current one) in the fact that the way it is written more closely
reflects how the parser will operate when parsing it. The fundamental technical
difference is that the choice operator is ordered. This means that when writing:

```
rule: A | B | C
```
a context-free-grammar parser (like an LL(1) parser) will generate constructions
that given an input string will *deduce* which alternative (`A`, `B` or `C`)
must be expanded, while a PEG parser will check if the first alternative succeeds
and only if it fails, will it continue with the second or the third one in the
order in which they are written. This makes the choice operator not commutative.

Unlike LL(1) parsers, PEG-based parsers cannot be ambiguous: if a string parses,
it has exactly one valid parse tree. This means that a PEG-based parser cannot
suffer from the ambiguity problems described in the previous section.

PEG parsers are usually constructed as a recursive descent parser in which every
rule in the grammar corresponds to a function in the program implementing the
parser and the parsing expression (the "expansion" or "definition" of the rule)
represents the "code" in said function. Each parsing function conceptually takes
an input string as its argument, and yields one of the following results:

* A "success" result. This result indicates that the expression can be parsed by
  that rule and the function may optionally move forward or consume one or more
  characters of the input string supplied to it.
* A "failure" result, in which case no input is consumed.

Notice that "failure" results do not imply that the program is incorrect or a
parsing failure because as the choice operator is ordered, a "failure" result
merely indicates "try the following option". A direct implementation of a PEG
parser as a recursive descent parser will present exponential time performance in
the worst case as compared with LL(1) parsers, because PEG parsers have infinite lookahead
(this means that they can consider an arbitrary number of tokens before deciding
for a rule). Usually, PEG parsers avoid this exponential time complexity with a
technique called "packrat parsing" [1]_ which not only loads the entire
program in memory before parsing it but also allows the parser to backtrack
arbitrarily. This is made efficient by memoizing the rules already matched for
each position. The cost of the memoization cache is that the parser will naturally
use more memory than a simple LL(1) parser, which normally are table-based. We
will explain later in this document why we consider this cost acceptable.

## Rationale
In this section, we describe a list of problems that are present in the current parser
machinery in CPython that motivates the need for a new parser.

### Some rules are not actually LL(1)
Although the Python grammar is technically an LL(1) grammar (because it is parsed by
an LL(1) parser) several rules are not LL(1) and several workarounds are
implemented in the grammar and in other parts of CPython to deal with this. For
example, consider the rule for assignment expressions:

```
namedexpr_test: [NAME ':='] test
```
This simple rule is not compatible with the Python grammar as *NAME* is among the
elements of the *first set* of the rule *test*. To work around this limitation the
actual rule that appears in the current grammar is:

```
namedexpr_test: test [':=' test]
```
Which is a much broader rule than the previous one allowing constructs like ``[x
for x in y] := [1,2,3]``. The way the rule is limited to its desired form is by
disallowing these unwanted constructions when transforming the parse tree to the
abstract syntax tree. This is not only inelegant but a considerable maintenance
burden as it forces the AST creation routines and the compiler into a situation in
which they need to know how to separate valid programs from invalid programs,
which should be a responsibility solely of the parser. This also leads to the
actual grammar file not reflecting correctly what the *actual* grammar is (that
is, the collection of all valid Python programs).

Similar workarounds appear in multiple other rules of the current grammar.
Sometimes this problem is unsolvable. For instance, [bpo-12782: Multiple context expressions do not support parentheses for continuation across lines](https://github.com/python/cpython/issues/56991) shows how making an LL(1) rule that supports
writing:

```
with (
    open("a_really_long_foo") as foo,
    open("a_really_long_baz") as baz,
    open("a_really_long_bar") as bar
):
  ...
```
is not possible since the first sets of the grammar items that can
appear as context managers include the open parenthesis, making the rule
ambiguous. This rule is not only consistent with other parts of the language (like
the rule for multiple imports), but is also very useful to auto-formatting tools,
as parenthesized groups are normally used to group elements to be
formatted together (in the same way the tools operate on the contents of lists,
sets...).

### Complicated AST parsing
Another problem of the current parser is that there is a huge coupling between the
AST generation routines and the particular shape of the produced parse trees. This
makes the code for generating the AST especially complicated as many actions and
choices are implicit. For instance, the AST generation code knows what
alternatives of a certain rule are produced based on the number of child nodes
present in a given parse node. This makes the code difficult to follow as this
property is not directly related to the grammar file and is influenced by
implementation details. As a result of this, a considerable amount of the AST
generation code needs to deal with inspecting and reasoning about the particular
shape of the parse trees that it receives.

### Lack of left recursion
As described previously, a limitation of LL(1) grammars is that they cannot allow
left-recursion. This makes writing some rules very unnatural and far from how
programmers normally think about the program. For instance this construct (a simpler
variation of several rules present in the current grammar):

```
expr: expr '+' term | term
```
cannot be parsed by an LL(1) parser. The traditional remedy is to rewrite the
grammar to circumvent the problem:

```
expr: term ('+' term)*
```
The problem that appears with this form is that the parse tree is forced to have a
very unnatural shape. This is because with this rule, for the input program ``a +
b + c` the parse tree will be flattened (`['a', '+', 'b', '+', 'c']``) and must
be post-processed to construct a left-recursive parse tree (``[['a', '+', 'b'],
'+', 'c']``). Being forced to write the second rule not only leads to the parse
tree not correctly reflecting the desired associativity, but also imposes further
pressure on later compilation stages to detect and post-process these cases.

### Intermediate parse tree
The last problem present in the current parser is the intermediate creation of a
parse tree or Concrete Syntax Tree that is later transformed to an Abstract Syntax
Tree. Although the construction of a CST is very common in parser and compiler
pipelines, in CPython this intermediate CST is not used by anything else (it is
only indirectly exposed by the *parser* module and a surprisingly small part of
the code in the CST production is reused in the module). Which is worse: the whole
tree is kept in memory, keeping many branches that consist of chains of nodes with
a single child. This has been shown to consume a considerable amount of memory (for
instance in [bpo-26415: Excessive peak memory consumption by the Python parser](https://github.com/python/cpython/issues/70603)).

Having to produce an intermediate result between the grammar and the AST is not only
undesirable but also makes the AST generation step much more complicated, raising
considerably the maintenance burden.

## The new proposed PEG parser
The new proposed PEG parser contains the following pieces:

* A parser generator that can read a grammar file and produce a PEG parser
  written in Python or C that can parse said grammar.

* A PEG meta-grammar that automatically generates a Python parser that is used
  for the parser generator itself (this means that there are no manually-written
  parsers).

* A generated parser (using the parser generator) that can directly produce C and
  Python AST objects.

On the implementation side, the Python parser generator exposes these steps as `parse_string`, which runs a parser class over grammar source text; `generate_parser`, which turns a parsed `Grammar` into a parser class; and `make_parser`, which composes the two to build a parser directly from grammar source.
Expose the parser-generator package under `Tools/peg_generator/pegen/`; in
particular, provide `pegen.grammar_parser.GeneratedParser` (commonly used as
`GrammarParser`), `pegen.testutil.parse_string`,
`pegen.testutil.generate_parser`, `pegen.testutil.make_parser`,
`pegen.testutil.generate_parser_c_extension`,
`pegen.testutil.generate_c_parser_source`, `pegen.grammar.Grammar`,
`pegen.grammar.GrammarError`, `pegen.grammar.GrammarVisitor`, and
`pegen.first_sets.FirstSetCalculator`.

### Left recursion
PEG parsers normally do not support left recursion but we have implemented a
technique similar to the one described in Medeiros et al. [2]_ but using the
memoization cache instead of static variables. This approach is closer to the one
described in Warth et al. [3]_. This allows us to write not only simple left-recursive
rules but also more complicated rules that involve indirect left-recursion like:

```
rule1: rule2 | 'a'
rule2: rule3 | 'b'
rule3: rule1 | 'c'
```
and "hidden left-recursion" like:

```
rule: 'optional'? rule '@' some_other_rule
```
### Syntax
The grammar consists of a sequence of rules of the form:

```
rule_name: expression
```
Optionally, a type can be included right after the rule name, which
specifies the return type of the C or Python function corresponding to
the rule:

```
rule_name[return_type]: expression
```
If the return type is omitted, then a `void *` is returned in C and an
`Any` in Python.

#### Grammar Expressions
`# comment`
'''''''''''''

Python-style comments.

`e1 e2`
'''''''''

Match e1, then match e2.

```PEG
rule_name: first_rule second_rule
```
`e1 | e2`
'''''''''''

Match e1 or e2.

The first alternative can also appear on the line after the rule name
for formatting purposes. In that case, a \| must be used before the
first alternative, like so:

```PEG
rule_name[return_type]:
    | first_alt
    | second_alt
```
`( e )`
'''''''''

Match e.

```PEG
rule_name: (e)
```
A slightly more complex and useful example includes using the grouping
operator together with the repeat operators:

```PEG
rule_name: (e1 e2)*
```
`[ e ] or e?`
'''''''''''''''

Optionally match e.

```PEG
rule_name: [e]
```
A more useful example includes defining that a trailing comma is
optional:

```PEG
rule_name: e (',' e)* [',']
```
`e*`
''''''

Match zero or more occurrences of e.

```PEG
rule_name: (e1 e2)*
```
`e+`
''''''

Match one or more occurrences of e.

```PEG
rule_name: (e1 e2)+
```
`s.e+`
''''''''

Match one or more occurrences of e, separated by s. The generated parse
tree does not include the separator. This is otherwise identical to
`(e (s e)*)`.

```PEG
rule_name: ','.e+
```
`&e`
''''''

Succeed if e can be parsed, without consuming any input.

`!e`
''''''

Fail if e can be parsed, without consuming any input.

An example taken from the proposed Python grammar specifies that a primary
consists of an atom, which is not followed by a `.` or a `(` or a
`[`:

```PEG
primary: atom !'.' !'(' !'['
```
`~`
''''''

Commit to the current alternative, even if it fails to parse.

```PEG
rule_name: '(' ~ some_rule ')' | some_alt
```
In this example, if a left parenthesis is parsed, then the other
alternative won’t be considered, even if some_rule or ‘)’ fail to be
parsed.


### Implementation Guidance

1. Add `Grammar/python.gram`. The complete Python grammar in PEG notation with C actions. Defines all Python constructs (statements, expressions, comprehensions, imports, classes, functions, decorators, etc.) with actions that directly call CPython AST construction functions (`_Py_Module`, `_Py_If`, `_Py_BinOp`, `_Py_FunctionDef`, etc.). Includes a `@trailer` block defining the `_PyPegen_parse` entry point that dispatches to `file_rule`, `interactive_rule`, `eval_rule`, or `fstring_rule` based on the start rule. Uses left-recursive rules for expressions (e.g., `expr: expr '+' term`), demonstrating the PEG parser's ability to handle left recursion naturally.

2. In `Include/compile.h`, apply the required changes. Adds `Py_fstring_input` (800) start rule constant used by the PEG parser for parsing f-string subexpressions.

3. Add `Include/pegen_interface.h`. Public header declaring the `PyPegen_ASTFrom*` and `PyPegen_CodeObjectFrom*` C API functions.

4. In `Modules/Setup`, apply the required changes. Adds the `_peg_parser` extension module entry (`_peg_parser _peg_parser.c`) to the static modules list.

5. Add `Modules/_peg_parser.c` defining `PyModuleDef` with functions `_Py_parse_file`, `_Py_parse_string`, and `PyInit__peg_parser`. New C extension module providing `_peg_parser.parse_string` and `_peg_parser.parse_file` functions that call `PyPegen_ASTFromString`/`PyPegen_ASTFromFile` and return AST objects. Used by tests to directly invoke the PEG parser.

6. Add `Parser/pegen/parse.c`. The generated C parser (15,391 lines), produced by running `pegen` on `python.gram`. Contains one C function per grammar rule, with memoization, backtracking, left-recursion handling, and direct AST node construction. This is a generated file but is checked into the repository.

7. Add `Parser/pegen/parse_string.c` defining `tok_state` with functions `warn_invalid_escape_sequence`, `decode_utf8`, `decode_unicode_with_escapes`, `decode_bytes_with_escapes`, `_PyPegen_parsestr`, `shift_expr`, `shift_arg`, `fstring_shift_seq_locations`, `fstring_shift_slice_locations`, `fstring_shift_comprehension`, `fstring_shift_argument`, `fstring_shift_arguments`, `fstring_shift_children_locations`, `fstring_shift_expr_locations`, `fstring_fix_expr_location`, `fstring_compile_expr`, `tok_state.fstring_compile_expr`, `fstring_find_literal`, `fstring_find_expr`, `fstring_find_literal_and_expr`, `ExprList_check_invariants`, `ExprList_Init`, `ExprList_Append`, `ExprList_Dealloc`, `ExprList_Finish`, `FstringParser_check_invariants`, `_PyPegen_FstringParser_Init`, `_PyPegen_FstringParser_Dealloc`, `make_str_node_and_del`, `_PyPegen_FstringParser_ConcatAndDel`, `_PyPegen_FstringParser_ConcatFstring`, `_PyPegen_FstringParser_Finish`, and `fstring_parse`. String literal and f-string parsing routines, ported from `Python/ast.c` and adapted for the PEG parser.

8. Add `Parser/pegen/parse_string.h`. Header for the string parsing module, defining `ExprList` and `FstringParser` structs and declaring the string/f-string parsing API.

9. Add `Parser/pegen/peg_api.c` defining functions `PyPegen_ASTFromString`, `PyPegen_ASTFromStringObject`, `PyPegen_ASTFromFile`, `PyPegen_ASTFromFileObject`, `PyPegen_CodeObjectFromString`, `PyPegen_CodeObjectFromFile`, and `PyPegen_CodeObjectFromFileObject`. Public API implementation. Defines `PyPegen_ASTFromString`, `PyPegen_ASTFromStringObject`, `PyPegen_ASTFromFile`, `PyPegen_ASTFromFileObject`, `PyPegen_CodeObjectFromString`, `PyPegen_CodeObjectFromFile`, and `PyPegen_CodeObjectFromFileObject`.

10. Add `Parser/pegen/pegen.c` defining `tok_state` with functions `init_normalization`, `_PyPegen_new_identifier`, `_create_dummy_identifier`, `byte_offset_to_character_offset`, `_PyPegen_get_expr_name`, `raise_decode_error`, `raise_tokenizer_init_error`, `get_error_line`, `tokenizer_error_with_col_offset`, `tokenizer_error`, `_PyPegen_raise_error`, `_PyPegen_arguments_parsing_error`, `token_name`, `_PyPegen_insert_memo`, `_PyPegen_update_memo`, `_PyPegen_dummy_name`, `_get_keyword_or_name_type`, `_PyPegen_fill_token`, `_PyPegen_clear_memo_statistics`, `_PyPegen_get_memo_statistics`, `_PyPegen_is_memoized`, `_PyPegen_lookahead_with_string`, `_PyPegen_lookahead_with_int`, `_PyPegen_lookahead`, `_PyPegen_expect_token`, `_PyPegen_get_last_nonnwhitespace_token`, `_PyPegen_async_token`, `_PyPegen_await_token`, `_PyPegen_endmarker_token`, `_PyPegen_name_token`, `_PyPegen_string_token`, `_PyPegen_newline_token`, `_PyPegen_indent_token`, `_PyPegen_dedent_token`, `parsenumber_raw`, `parsenumber`, `_PyPegen_number_token`, `_PyPegen_Parser_Free`, `_PyPegen_Parser_New`, `tok_state._PyPegen_Parser_New`, `_PyPegen_run_parser`, `_PyPegen_run_parser_from_file_pointer`, `tok_state._PyPegen_run_parser_from_file_pointer`, `_PyPegen_run_parser_from_file`, `_PyPegen_run_parser_from_string`, `tok_state._PyPegen_run_parser_from_string`, `_PyPegen_interactive_exit`, `_PyPegen_singleton_seq`, `_PyPegen_seq_insert_in_front`, `_get_flattened_seq_size`, `_PyPegen_seq_flatten`, `_PyPegen_join_names_with_dot`, `_PyPegen_seq_count_dots`, `_PyPegen_alias_for_star`, `_PyPegen_map_names_to_ids`, `_PyPegen_cmpop_expr_pair`, `_PyPegen_get_cmpops`, `_PyPegen_get_exprs`, `_set_seq_context`, `_set_name_context`, `_set_tuple_context`, `_set_list_context`, `_set_subscript_context`, `_set_attribute_context`, `_set_starred_context`, `_PyPegen_set_expr_context`, `_PyPegen_key_value_pair`, `_PyPegen_get_keys`, `_PyPegen_get_values`, `_PyPegen_name_default_pair`, `_PyPegen_slash_with_default`, `_PyPegen_star_etc`, `_PyPegen_join_sequences`, `_get_names`, `_get_defaults`, `_PyPegen_make_arguments`, `_PyPegen_empty_arguments`, `_PyPegen_augoperator`, `_PyPegen_function_def_decorators`, `_PyPegen_class_def_decorators`, `_PyPegen_keyword_or_starred`, `_seq_number_of_starred_exprs`, `_PyPegen_seq_extract_starred_exprs`, `_PyPegen_seq_delete_starred_exprs`, and `_PyPegen_concatenate_strings`. The PEG parser runtime library. Implements the `Parser` struct lifecycle (`_PyPegen_Parser_New`, `_PyPegen_Parser_Free`), token filling and management (`_PyPegen_fill_token`), memoization (`_PyPegen_is_memoized`, `_PyPegen_insert_memo`, `_PyPegen_update_memo`), error reporting (`_PyPegen_raise_error`, `_PyPegen_get_expr_name`), and numerous AST helper functions used by grammar actions.

11. Add `Parser/pegen/pegen.h` defining `_memo` and `tok_state` with functions `CHECK_CALL` and `CHECK_CALL_NULL_ALLOWED`. Header defining the `Parser` struct, helper typedefs (`Token`, `Memo`, `CmpopExprPair`, `KeyValuePair`, `NameDefaultPair`, `SlashWithDefault`, `StarEtc`, `AugOperator`, `KeywordOrStarred`), and declarations for all runtime functions and macros.

12. In `Python/ast_opt.c`, update `astfold_expr`. Adds a `node_->v.Name.ctx == Load` guard before the `__debug__` constant-folding check in `astfold_expr`, fixing a bug where Store context `__debug__` references were incorrectly folded.

13. In `Python/bltinmodule.c`, update `builtin_compile_impl`. Adds PEG parser integration to `builtin_compile_impl`: temporarily sets `config.use_peg = 0` when `PyCF_TYPE_COMMENTS` or `feature_version` is specified (since the PEG parser does not yet support type comments), then restores it after compilation.

14. In `Python/compile.c`, update `forbidden_name`, `compiler.forbidden_name`, `compiler_check_debug_one_arg`, `compiler.compiler_check_debug_one_arg`, `compiler_check_debug_args_seq`, `compiler.compiler_check_debug_args_seq`, `compiler_check_debug_args`, `compiler.compiler_check_debug_args`, `compiler_function`, `compiler_lambda`, `compiler_nameop`, `validate_keywords`, `compiler_visit_expr1`, and `compiler_annassign`. Adds `forbidden_name` function checking for `__debug__` assignment, plus `compiler_check_debug_args`/`compiler_check_debug_args_seq`/`compiler_check_debug_one_arg` helpers to validate function parameter names. This moves the `__debug__` assignment check from the old parser into the compiler so it works with the PEG parser.

15. In `Python/pythonrun.c`, update `PyRun_InteractiveOneObjectEx`, `PyRun_StringFlags`, `PyRun_FileExFlags`, `Py_CompileStringObject`, and `_Py_SymtableStringObjectFlags`. Includes `pegen_interface.h` and adds PEG parser dispatch: `PyRun_InteractiveOneObjectEx`, `PyRun_SimpleFileExFlags`, and `PyRun_StringFlags` now check `config.use_peg` and call `PyPegen_ASTFromFileObject`/`PyPegen_ASTFromStringObject` when enabled, falling back to `PyParser_ASTFromFileObject`/`PyParser_ASTFromStringObject` otherwise.

16. In `Python/sysmodule.c`, update `make_flags`. Adds `use_peg` to `sys.flags` struct sequence (field name and value), incrementing the field count from 15 to 16. Uses `SetFlag(config->use_peg)` to populate the value.

**Supporting changes:**

1. In `.github/workflows/build.yml`, apply the required changes. Adds `pegen` branch to CI triggers and duplicates build jobs for old/new parser testing.

2. In `.travis.yml`, apply the required changes. Switches Travis CI dist to bionic, adds `pegen` branch, changes regen to use python3.8.

3. In `Doc/using/cmdline.rst`, apply the required changes. Documents the `-X oldparser` option and `PYTHONOLDPARSER` environment variable.

4. In `Makefile.pre.in`, apply the required changes. Adds `PEGEN_OBJS` and `PEGEN_HEADERS` variables for building the PEG parser C files.

5. Add `Misc/NEWS.d/next/Core and Builtins/2020-04-20-14-06-19.bpo-40334.CTLGEp.rst`. NEWS entry announcing the new PEG-based parser.

6. In `PC/config.c`, apply the required changes. Adds `PyInit__peg_parser` extern and registers it in `_PyImport_Inittab[]` for Windows.

7. In `PCbuild/pythoncore.vcxproj`, apply the required changes. Adds PEG parser header and source file entries for Visual Studio build.

8. In `PCbuild/pythoncore.vcxproj.filters`, apply the required changes. Adds filter entries for PEG parser source files under the Parser filter group.

9. In `PCbuild/regen.vcxproj`, apply the required changes. Adds `_RegenPegen` build target to regenerate `parse.c` from `python.gram`.

10. In `Programs/_testembed.c`, update `test_init_from_config`. Adds `config.use_peg = 0` in `test_init_from_config` to test old parser configuration.

11. In `Python/importlib.h`, apply the required changes. Regenerated frozen bytecode for `importlib._bootstrap` reflecting parser switch.

12. In `Python/importlib_external.h`, apply the required changes. Regenerated frozen bytecode for `importlib._bootstrap_external`.

13. In `Tools/README`, apply the required changes. Adds `peg_generator` entry describing the PEG-based parser generator tool.

14. Add `Tools/peg_generator/.gitignore`. Ignores generated files: `peg_extension/parse.c`, `data/xxl.py`, and `@data`.

15. Add `Tools/peg_generator/Makefile`. Build system for peg_generator: targets for regeneration, C extension, tests, benchmarks.

16. Add `Tools/peg_generator/pyproject.toml`. Minimal pyproject.toml for the peg_generator package with setuptools build backend.
#### Variables in the Grammar
A subexpression can be named by preceding it with an identifier and an
`=` sign. The name can then be used in the action (see below), like this:

```
rule_name[return_type]: '(' a=some_other_rule ')' { a }
```
### Grammar actions
To avoid the intermediate steps that obscure the relationship between the
grammar and the AST generation the proposed PEG parser allows directly
generating AST nodes for a rule via grammar actions. Grammar actions are
language-specific expressions that are evaluated when a grammar rule is
successfully parsed. These expressions can be written in Python or C
depending on the desired output of the parser generator. This means that if
one would want to generate a parser in Python and another in C, two grammar
files should be written, each one with a different set of actions, keeping
everything else apart from said actions identical in both files. As an
example of a grammar with Python actions, the piece of the parser generator
that parses grammar files is bootstrapped from a meta-grammar file with
Python actions that generate the grammar tree as a result of the parsing.

In the specific case of the new proposed PEG grammar for Python, having
actions allows directly describing how the AST is composed in the grammar
itself, making it more clear and maintainable. This AST generation process is
supported by the use of some helper functions that factor out common AST
object manipulations and some other required operations that are not directly
related to the grammar.

To indicate these actions each alternative can be followed by the action code
inside curly-braces, which specifies the return value of the alternative:

```
rule_name[return_type]:
    | first_alt1 first_alt2 { first_alt1 }
    | second_alt1 second_alt2 { second_alt1 }
```
If the action is omitted and C code is being generated, then there are two
different possibilities:

1. If there’s a single name in the alternative, this gets returned.
2. If not, a dummy name object gets returned (this case should be avoided).

If the action is omitted and Python code is being generated, then a list
with all the parsed expressions gets returned (this is meant for debugging).

The full meta-grammar for the grammars supported by the PEG generator is:

```PEG
start[Grammar]: grammar ENDMARKER { grammar }

grammar[Grammar]:
    | metas rules { Grammar(rules, metas) }
    | rules { Grammar(rules, []) }

metas[MetaList]:
    | meta metas { [meta] + metas }
    | meta { [meta] }

meta[MetaTuple]:
    | "@" NAME NEWLINE { (name.string, None) }
    | "@" a=NAME b=NAME NEWLINE { (a.string, b.string) }
    | "@" NAME STRING NEWLINE { (name.string, literal_eval(string.string)) }

rules[RuleList]:
    | rule rules { [rule] + rules }
    | rule { [rule] }

rule[Rule]:
    | rulename ":" alts NEWLINE INDENT more_alts DEDENT {
          Rule(rulename[0], rulename[1], Rhs(alts.alts + more_alts.alts)) }
    | rulename ":" NEWLINE INDENT more_alts DEDENT { Rule(rulename[0], rulename[1], more_alts) }
    | rulename ":" alts NEWLINE { Rule(rulename[0], rulename[1], alts) }

rulename[RuleName]:
    | NAME '[' type=NAME '*' ']' {(name.string, type.string+"*")}
    | NAME '[' type=NAME ']' {(name.string, type.string)}
    | NAME {(name.string, None)}

alts[Rhs]:
    | alt "|" alts { Rhs([alt] + alts.alts)}
    | alt { Rhs([alt]) }

more_alts[Rhs]:
    | "|" alts NEWLINE more_alts { Rhs(alts.alts + more_alts.alts) }
    | "|" alts NEWLINE { Rhs(alts.alts) }

alt[Alt]:
    | items '$' action { Alt(items + [NamedItem(None, NameLeaf('ENDMARKER'))], action=action) }
    | items '$' { Alt(items + [NamedItem(None, NameLeaf('ENDMARKER'))], action=None) }
    | items action { Alt(items, action=action) }
    | items { Alt(items, action=None) }

items[NamedItemList]:
    | named_item items { [named_item] + items }
    | named_item { [named_item] }

named_item[NamedItem]:
    | NAME '=' ~ item {NamedItem(name.string, item)}
    | item {NamedItem(None, item)}
    | it=lookahead {NamedItem(None, it)}

lookahead[LookaheadOrCut]:
    | '&' ~ atom {PositiveLookahead(atom)}
    | '!' ~ atom {NegativeLookahead(atom)}
    | '~' {Cut()}

item[Item]:
    | '[' ~ alts ']' {Opt(alts)}
    |  atom '?' {Opt(atom)}
    |  atom '*' {Repeat0(atom)}
    |  atom '+' {Repeat1(atom)}
    |  sep=atom '.' node=atom '+' {Gather(sep, node)}
    |  atom {atom}

atom[Plain]:
    | '(' ~ alts ')' {Group(alts)}
    | NAME {NameLeaf(name.string) }
    | STRING {StringLeaf(string.string)}


### Implementation Guidance

1. Add `Tools/peg_generator/pegen/__init__.py`. Empty package init file for the pegen Python package.

2. Add `Tools/peg_generator/pegen/__main__.py`. CLI entry point for pegen: parses command-line arguments (`-c` for C output, `-o` for output path, `--compile-extension`) and calls `build_parser_and_generator` to generate the parser.

3. Add `Tools/peg_generator/pegen/build.py`. Build utilities: `build_parser` tokenizes and parses a `.gram` file, `build_parser_and_generator` generates either Python or C parser code, and `compile_c_extension` compiles the generated C source into a loadable extension module.

4. Add `Tools/peg_generator/pegen/c_generator.py` defining `CCallMakerVisitor` and `CParserGenerator`. `CParserGenerator` class (605 lines) that visits the grammar AST and emits C code for each rule. Includes `CCallMakerVisitor` for generating function call expressions and keyword handling, and produces the `_PyPegen_parse` entry point via `EXTENSION_SUFFIX`.

5. Add `Tools/peg_generator/pegen/first_sets.py` defining `FirstSetCalculator`. `FirstSetCalculator` (GrammarVisitor subclass) that computes FIRST sets for all grammar rules, used by the parser generator to determine which tokens can start each rule.

6. Add `Tools/peg_generator/pegen/grammar.py` defining `GrammarError`, `GrammarVisitor`, `Grammar`, `Rule`, `Leaf`, `NameLeaf`, `StringLeaf`, `Rhs`, `Alt`, `NamedItem`, `Lookahead`, `PositiveLookahead`, `NegativeLookahead`, `Opt`, `Repeat`, `Repeat0`, `Repeat1`, `Gather`, `Group`, and `Cut`. Defines the grammar AST data structures: `Grammar`, `Rule`, `Rhs`, `Alt`, `NamedItem`, `NameLeaf`, `StringLeaf`, `Lookahead`, `Opt`, `Repeat0`, `Repeat1`, `Gather`, `Group`, `Cut`, and the `GrammarVisitor` base class.

7. Add `Tools/peg_generator/pegen/grammar_parser.py` defining `GeneratedParser`. Auto-generated recursive-descent parser for the metagrammar (`.gram` files). Parses grammar rules, alternatives, named items, lookaheads, repetitions, and actions into the grammar AST.

8. Add `Tools/peg_generator/pegen/grammar_visualizer.py` defining `ASTGrammarPrinter`. `ASTGrammarPrinter` class that pretty-prints a grammar AST as a tree structure with box-drawing characters for debugging.

9. Add `Tools/peg_generator/pegen/metagrammar.gram`. The PEG metagrammar defining the `.gram` file syntax: rules, alternatives, named items, lookaheads, repetitions, grouping, and actions. Used to bootstrap the grammar parser.

10. Add `Tools/peg_generator/pegen/parser.py` defining `Parser`. Base `Parser` class implementing the core PEG parsing algorithm with packrat memoization (`@memoize` decorator), left-recursion support (`@memoize_left_rec`), token management, mark/reset for backtracking, and error reporting.

11. Add `Tools/peg_generator/pegen/parser_generator.py` defining `RuleCheckingVisitor` and `ParserGenerator`. Abstract `ParserGenerator` base class with shared logic for both Python and C code generation: rule collection, deduplication, first-set computation, alt/rule formatting, and keyword type assignment.

12. Add `Tools/peg_generator/pegen/python_generator.py` defining `PythonCallMakerVisitor` and `PythonParserGenerator`. `PythonParserGenerator` that visits the grammar AST and emits Python source code for a recursive-descent parser, used for testing and prototyping.

13. Add `Tools/peg_generator/pegen/sccutils.py`. Strongly Connected Components (SCC) utility implementing Tarjan's algorithm, used to detect left-recursive rule cycles in the grammar.

14. Add `Tools/peg_generator/pegen/tokenizer.py` defining `Tokenizer`. `Tokenizer` class wrapping Python's `tokenize` module to provide a token stream with mark/reset support for backtracking, used by the grammar parser.

**Supporting changes:**

1. Add `Tools/peg_generator/.clang-format`. Clang-format configuration approximating PEP 7 C style for peg_generator C code.

2. Add `Tools/peg_generator/data/cprog.py`. Small test Python program used as parse input for testing the PEG parser.

3. Add `Tools/peg_generator/data/xxl.zip`. Compressed large Python source file for parser performance benchmarking.

4. Add `Tools/peg_generator/mypy.ini`. Mypy configuration for strict type checking of the pegen Python modules.

5. Add `Tools/peg_generator/peg_extension/peg_extension.c` defining `PyModuleDef` with functions `_build_return_object`, `parse_file`, `parse_string`, `clear_memo_stats`, `get_memo_stats`, `dump_memo_stats`, and `PyInit_parse`. C extension wrapper exposing `parse_file`/`parse_string` for testing the generated parser.

6. Add `Tools/peg_generator/requirements.pip`. Development dependencies (flask, mypy) for the peg_generator tool.

7. Add `Tools/peg_generator/scripts/__init__.py`. Package init file for the peg_generator scripts subpackage.

8. Add `Tools/peg_generator/scripts/find_max_nesting.py`. Script finding maximum nesting depth the parser can handle.

9. Add `Tools/peg_generator/scripts/grammar_grapher.py`. Script generating DOT graph visualization of grammar rule dependencies.

10. Add `Tools/peg_generator/scripts/show_parse.py`. Debug script parsing a file and displaying the resulting AST.
## Mini-grammar for the actions

action[str]: "{" ~ target_atoms "}" { target_atoms }

target_atoms[str]:
    | target_atom target_atoms { target_atom + " " + target_atoms }
    | target_atom { target_atom }

target_atom[str]:
    | "{" ~ target_atoms "}" { "{" + target_atoms + "}" }
    | NAME { name.string }
    | NUMBER { number.string }
    | STRING { string.string }
    | "?" { "?" }
    | ":" { ":" }
```
As an illustrative example this simple grammar file allows directly
generating a full parser that can parse simple arithmetic expressions and that
returns a valid C-based Python AST:

```PEG
start[mod_ty]: a=expr_stmt* $ { Module(a, NULL, p->arena) }
expr_stmt[stmt_ty]: a=expr NEWLINE { _Py_Expr(a, EXTRA) }
expr[expr_ty]:
    | l=expr '+' r=term { _Py_BinOp(l, Add, r, EXTRA) }
    | l=expr '-' r=term { _Py_BinOp(l, Sub, r, EXTRA) }
    | t=term { t }

term[expr_ty]:
    | l=term '*' r=factor { _Py_BinOp(l, Mult, r, EXTRA) }
    | l=term '/' r=factor { _Py_BinOp(l, Div, r, EXTRA) }
    | f=factor { f }

factor[expr_ty]:
    | '(' e=expr ')' { e }
    | a=atom { a }

atom[expr_ty]:
    | n=NAME { n }
    | n=NUMBER { n }
    | s=STRING { s }
```
Here `EXTRA` is a macro that expands to ``start_lineno, start_col_offset,
end_lineno, end_col_offset, p->arena``, those being variables automatically
injected by the parser; `p` points to an object that holds on to all state
for the parser.

A similar grammar written to target Python AST objects:

```PEG
start: expr NEWLINE? ENDMARKER { ast.Expression(expr) }
expr:
    | expr '+' term { ast.BinOp(expr, ast.Add(), term) }
    | expr '-' term { ast.BinOp(expr, ast.Sub(), term) }
    | term { term }

term:
    | l=term '*' r=factor { ast.BinOp(l, ast.Mult(), r) }
    | term '/' factor { ast.BinOp(term, ast.Div(), factor) }
    | factor { factor }

factor:
    | '(' expr ')' { expr }
    | atom { atom }

atom:
    | NAME { ast.Name(id=name.string, ctx=ast.Load()) }
    | NUMBER { ast.Constant(value=ast.literal_eval(number.string)) }
```
## Migration plan
This section describes the migration plan when porting to the new PEG-based parser
if this PEP is accepted. The migration will be executed in a series of steps that allow
initially to fallback to the previous parser if needed:

1.  Starting with Python 3.9 alpha 6, include the new PEG-based parser machinery in CPython
    with a command-line flag and environment variable that allows switching between
    the new and the old parsers together with explicit APIs that allow invoking the
    new and the old parsers independently. At this step, all Python APIs like `ast.parse`
    and `compile` will use the parser set by the flags or the environment variable and
    the default parser will be the new PEG-based parser. Which parser is active is
    observable at runtime through `sys.flags.use_peg`, a new member of the `sys.flags`
    struct sequence that is nonzero while the PEG parser is in effect.

2.  Between Python 3.9 and Python 3.10, the old parser and related code (like the
    "parser" module) will be kept until a new Python release happens (Python 3.10). In
    the meanwhile and until the old parser is removed, **no new Python Grammar
    addition will be added that requires the PEG parser**. This means that the grammar
    will be kept LL(1) until the old parser is removed.

3.  In Python 3.10, remove the old parser, the command-line flag, the environment
    variable and the "parser" module and related code.


### Implementation Guidance

1. In `Python/bltinmodule.c`, apply the required changes. Implements the migration toggle in `builtin_compile_impl` by clearing `config.use_peg` for `PyCF_TYPE_COMMENTS`/`feature_version` paths during the transition period, then restoring the user's parser preference after compilation.

2. In `Python/pythonrun.c`, apply the required changes. Implements the migration dispatch in `PyRun_*` entry points by checking `config.use_peg` and routing to either `PyPegen_AST*` or `PyParser_AST*` so the `-X oldparser`/`PYTHONOLDPARSER` switch chooses between the new and old parser at runtime.

3. In `Python/sysmodule.c`, apply the required changes. Exposes the migration flag to Python by adding `use_peg` to the `sys.flags` struct sequence (incrementing field count from 15 to 16) so user code and tests can observe which parser the interpreter is using.

**Supporting changes:**

1. In `Include/cpython/initconfig.h`, apply the required changes. Adds `int use_peg` field to `PyConfig` for the `-X oldparser` flag.

2. In `Python/initconfig.c`, update `_PyConfig_InitCompatConfig`, `_PyConfig_Copy`, `config_as_dict`, `config_read_complex_options`, and `PyConfig_Read`. Initializes `config->use_peg = 1`, adds `-X oldparser` help text and config copy/serialization.

3. In `Doc/using/cmdline.rst`, apply the required changes. Documents the `-X oldparser` option and `PYTHONOLDPARSER` environment variable that drive the migration plan.

4. In `Programs/_testembed.c`, apply the required changes. Embed test exercises the migration config (sets `config.use_peg = 0` to validate the old-parser path).
## Performance and validation
We have done extensive timing and validation of the new parser, and
this gives us confidence that the new parser is of high enough quality
to replace the current parser.

### Performance
We have tuned the performance of the new parser to come within 10% of
the current parser both in speed and memory consumption. While the
PEG/packrat parsing algorithm inherently consumes more memory than the
current LL(1) parser, we have an advantage because we don't construct
an intermediate CST.

Below are some benchmarks. These are focused on compiling source code
to bytecode, because this is the most realistic situation. Returning
an AST to Python code is not as representative, because the process to
convert the *internal* AST (only accessible to C code) to an
*external* AST (an instance of `ast.AST`) takes more time than the
parser itself.

All measurements reported here are done on a recent MacBook Pro,
taking the median of three runs. No particular care was taken to stop
other applications running on the same machine.

The first timings are for our canonical test file, which has 100,000
lines endlessly repeating the following three lines:

```python
1 + 2 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + ((((((11 * 12 * 13 * 14 * 15 + 16 * 17 + 18 * 19 * 20))))))
2*3 + 4*5*6
12 + (2 * 3 * 4 * 5 + 6 + 7 * 8)
```
- Just parsing and throwing away the internal AST takes 1.16 seconds
  with a max RSS of 681 MiB.

- Parsing and converting to `ast.AST` takes 6.34 seconds, max RSS
  1029 MiB.

- Parsing and compiling to bytecode takes 1.28 seconds, max RSS 681
  MiB.

- With the current parser, parsing and compiling takes 1.44 seconds,
  max RSS 836 MiB.

For this particular test file, the new parser is faster and uses less
memory than the current parser (compare the last two bullets).

We also did timings with a more realistic payload, the entire Python
3.8 stdlib. This payload consists of 1,641 files, 749,570 lines,
27,622,497 bytes. (Though 11 files can't be compiled by any Python 3
parser due to encoding issues, sometimes intentional.)

- Compiling and throwing away the internal AST took 2.141 seconds.
  That's 350,040 lines/sec, or 12,899,367 bytes/sec. The max RSS was
  74 MiB (the largest file in the stdlib is much smaller than our
  canonical test file).

- Compiling to bytecode took 3.290 seconds. That's 227,861 lines/sec,
  or 8,396,942 bytes/sec. Max RSS 77 MiB.

- Compiling to bytecode using the current parser took 3.367 seconds.
  That's 222,620 lines/sec, or 8,203,780 bytes/sec. Max RSS 70 MiB.

Comparing the last two bullets we find that the new parser is slightly
faster but uses slightly (about 10%) more memory. We believe this is
acceptable. (Also, there are probably some more tweaks we can make to
reduce memory usage.)


### Implementation Guidance

1. Add `Tools/peg_generator/scripts/ast_timings.py`. Benchmarking script that measures AST compilation timing for the new parser, providing one of the inputs to the speed comparison required by the section.

2. Add `Tools/peg_generator/scripts/benchmark.py`. Performance benchmark harness that times parsing of input under both the old and new parsers, directly implementing the speed/memory comparison the section calls for.

3. Add `Tools/peg_generator/scripts/joinstats.py` defining `TypeMapper`. Joins and aggregates raw parsing statistics from multiple benchmark runs (via the `TypeMapper` class) into the comparable performance summaries that back up the within-10% claim in this section.
## Rejected Alternatives
We did not seriously consider alternative ways to implement the new
parser, but here's a brief discussion of LALR(1).

Thirty years ago the first author decided to go his own way with
Python's parser rather than using LALR(1), which was the industry
standard at the time (e.g. Bison and Yacc).  The reasons were
primarily emotional (gut feelings, intuition), based on past experience
using Yacc in other projects, where grammar development took more
effort than anticipated (in part due to shift-reduce conflicts).  A
specific criticism of Bison and Yacc that still holds is that their
meta-grammar (the notation used to feed the grammar into the parser
generator) does not support EBNF conveniences like
`[optional_clause]` or `(repeated_clause)*`.  Using a custom
parser generator, a syntax tree matching the structure of the grammar
could be generated automatically, and with EBNF that tree could match
the "human-friendly" structure of the grammar.

Other variants of LR were not considered, nor was LL (e.g. ANTLR).
PEG was selected because it was easy to understand given a basic
understanding of recursive-descent parsing.
