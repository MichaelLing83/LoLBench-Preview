import ast
import sys
import tempfile
import types
import unittest
from io import StringIO
from pathlib import Path
from tokenize import TokenInfo
from tokenize import open as tokenize_open
from typing import Any, Dict, Iterable, List

from test import test_tools

test_tools.skip_if_missing("peg_generator")
with test_tools.imports_under_tool("peg_generator"):
    from pegen.first_sets import FirstSetCalculator
    from pegen.grammar import Grammar
    from pegen.grammar_parser import GeneratedParser as GrammarParser
    from pegen.testutil import (
        generate_parser,
        generate_parser_c_extension,
        make_parser,
        parse_string,
    )


def _require_active_peg_parser() -> None:
    if not getattr(sys.flags, "use_peg", False):
        raise AssertionError("PEG parser is not active")


class _ActivePegParserAdapter:
    @staticmethod
    def parse_string(source: str, mode: str = "exec") -> ast.AST:
        _require_active_peg_parser()
        return ast.parse(source, mode=mode)

    @staticmethod
    def parse_file(filename: str, mode: str = "exec") -> ast.AST:
        _require_active_peg_parser()
        with tokenize_open(filename) as handle:
            source = handle.read()
        return ast.parse(source, filename=filename, mode=mode)


peg_parser = _ActivePegParserAdapter()


class PegParserModeAugTest(unittest.TestCase):
    def assertAstEqual(self, actual: ast.AST, expected: ast.AST) -> None:
        self.assertEqual(
            ast.dump(actual, include_attributes=True),
            ast.dump(expected, include_attributes=True),
        )

    def test_parse_string_modes_and_cookie_handling(self) -> None:
        module_source = "# coding: definitely-not-an-encoding\nx = 1\ny = x + 2\n"
        self.assertAstEqual(peg_parser.parse_string(module_source), ast.parse(module_source))

        expr_source = "1 + 2 * 3"
        actual_expr = peg_parser.parse_string(expr_source, mode="eval")
        self.assertIsInstance(actual_expr, ast.Expression)
        self.assertAstEqual(actual_expr, ast.parse(expr_source, mode="eval"))

        single_source = "answer = 42\n"
        actual_single = peg_parser.parse_string(single_source, mode="single")
        self.assertIsInstance(actual_single, ast.Interactive)
        self.assertAstEqual(actual_single, ast.parse(single_source, mode="single"))

    def test_parse_file_modes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            exec_path = Path(tmp) / "program.py"
            exec_path.write_text("a = 1\nb = a + 2\n", encoding="utf-8")
            self.assertAstEqual(
                peg_parser.parse_file(str(exec_path)),
                ast.parse(exec_path.read_text(encoding="utf-8")),
            )

            single_path = Path(tmp) / "single.py"
            single_path.write_text("value = 5\n", encoding="utf-8")
            actual_single = peg_parser.parse_file(str(single_path), mode="single")
            self.assertIsInstance(actual_single, ast.Interactive)
            self.assertAstEqual(
                actual_single,
                ast.parse(single_path.read_text(encoding="utf-8"), mode="single"),
            )

    def test_generated_extension_parse_string_modes(self) -> None:
        grammar_source = """
        start[mod_ty]: a=[statements] ENDMARKER { Module(a, NULL, p->arena) }
        statements[asdl_seq*]: a=statement+ { a }
        statement[stmt_ty]: pass_stmt
        pass_stmt[stmt_ty]: 'pass' NEWLINE { _Py_Pass(EXTRA) }
        """
        extension = build_c_extension(grammar_source)

        self.assertIsNone(extension.parse_string("pass\n", mode=0))
        ast_obj = extension.parse_string("pass\n", mode=1)
        self.assertEqual(type(ast_obj).__name__, "Module")
        self.assertEqual(len(ast_obj.body), 1)
        self.assertEqual(type(ast_obj.body[0]).__name__, "Pass")
        code_obj = extension.parse_string("pass\n", mode=2)
        self.assertIsInstance(code_obj, types.CodeType)
        exec(code_obj, {})


class PegParserGrammarCoverageAugTest(unittest.TestCase):
    VALID_PROGRAMS = [
        "pass\n",
        "a = 1; b = 2; c = a + b\n",
        "a = b = c = (1, 2, 3)\n",
        "name: int = 1\nbox.attr: str = 'value'\nitems[0]: object = None\n",
        "(target): int = 3\n",
        "total += 1\ntotal -= 1\ntotal *= 2\ntotal @= matrix\ntotal /= 2\n"
        "total %= 2\ntotal &= mask\ntotal |= flag\ntotal ^= bit\n"
        "total <<= 1\ntotal >>= 1\ntotal **= 2\ntotal //= 2\n",
        "import os, sys as system\nfrom pkg.subpkg import name as alias, other\n"
        "from . import local\nfrom ...pkg import thing\nfrom pkg import *\n",
        "assert ready, 'not ready'\ndel obj.attr, items[0], (name), [left, right]\n",
        "if first:\n    value = 1\nelif second:\n    value = 2\nelif third:\n    value = 3\nelse:\n    value = 4\n",
        "while running:\n    break\nelse:\n    finished = True\n",
        "for first, *middle, last in rows:\n    continue\nelse:\n    exhausted = True\n",
        "with manager() as resource, other_manager():\n    resource.use()\n",
        "with (manager() as resource, other_manager() as other):\n    result = other\n",
        "try:\n    risky()\nexcept ValueError as exc:\n    handle(exc)\nexcept:\n    recover()\nelse:\n    success()\nfinally:\n    cleanup()\n",
        "try:\n    cleanup_only()\nfinally:\n    done()\n",
        "raise RuntimeError('boom') from cause\nraise\n",
        "def plain():\n    return\n",
        "def params(a, b, /, c, d=4, *args, e, f=6, **kw):\n    return a, b, c, d, args, e, f, kw\n",
        "def annotated(a: int, /, b: str = 'x', *, c: float, **kw: object) -> None:\n    return None\n",
        "def keyword_only(*, option, default=True):\n    return option, default\n",
        "def var_kwargs(**kw):\n    return kw\n",
        "@decorator\n@factory(arg=1)\ndef decorated(value):\n    return value\n",
        "@class_decorator\nclass Child(Base, mixin=True, **metadata):\n    attr = 1\n",
        "def outer():\n    value = 0\n    def inner():\n        nonlocal value\n"
        "        value += 1\n        return value\n    return inner\n",
        "def uses_global():\n    global shared\n    shared = 1\n",
        "async def async_features(source, manager):\n    await source.ready()\n"
        "    async for item in source:\n        yield item\n"
        "    async with manager as handle:\n        return handle\n",
        "def generator():\n    yield\n    yield 1, 2\n    yield from other\n",
        "values = [x for x in data if x > 0 if x < 10]\n"
        "pairs = {(k, v) for k, v in entries if k}\n"
        "mapping = {k: v for k, v in entries if v}\n"
        "gen = (item async for item in stream if item)\n",
        "starred = [first, *middle, last]\n"
        "tupled = (*items, tail)\n"
        "called = func(1, *args, key=value, other=2, **kw)\n"
        "called2 = func(*(x for x in data), **kw)\n",
        "slices = data[1:10:2, :, ...]\n"
        "chained = root.child[index](arg).leaf\n"
        "target.attr[index] = value\n",
        "literals = (True, False, None, ..., 0xFF, 0b1010, 3.14, 1j, b'bytes')\n"
        "strings = 'a' 'b' f'{name!r:>10}' rf'{path}'\n",
        "exprs = (a or b and not c, a if b else c, lambda x, y=2: x + y)\n"
        "more = (lambda a, b, /, c=3, *args, d, **kw: (a, b, c, args, d, kw))\n",
        "comparisons = a == b != c <= d < e >= f > g not in h in i is not j is k\n",
        "numbers = (+a, -b, ~c, a ** b, a * b, a @ b, a / b, a // b, a % b,\n"
        "           a + b, a - b, a << b, a >> b, a & b, a ^ b, a | b)\n",
        "named = (result := compute())\n"
        "list_target, (nested_target), [another_target] = data\n",
    ]

    VALID_EVAL_EXPRESSIONS = [
        "1, 2, 3",
        "lambda a, b, /, c=3, *, d=4, **kw: (a, b, c, d, kw)",
        "{**base, 'x': value, **override}",
        "func(1, *(x for x in seq), key=value, **kw)",
        "(await coro())",
        "f'{value!s:^10} {other!r}'",
    ]

    INVALID_PROGRAMS = [
        "__new_parser__\n",
        "call(**kw, *items)\n",
        "call(x for x in seq, 1)\n",
        "1 := 2\n",
        "[target]: int = value\n",
        "(left, right): int = value\n",
        "1: int = value\n",
        "call() = value\n",
        "a + b = value\n",
        "if condition:\npass\n",
        "[*item for item in seq]\n",
        "(*item for item in seq)\n",
        "{*item for item in seq}\n",
        "def bad(a=1, b):\n    pass\n",
        "f'{}'\n",
        "f'{value'\n",
        "f'{1 # comment}'\n",
        "f'{(1 + 2}'\n",
    ]

    INVALID_EVAL_EXPRESSIONS = [
        "lambda a=1, b: a",
        "func(keyword=1, positional)",
        "(x := y) := z",
    ]

    EDGE_EXEC_STEMS = [
        "",
        "if condition",
        "if condition:",
        "if condition:\n",
        "if condition:\n    value = 1\nelif other",
        "while condition",
        "while condition:",
        "for item in items",
        "for item in",
        "async for item in items",
        "with manager",
        "with manager as",
        "with (manager() as resource",
        "async with manager",
        "try",
        "try:",
        "try:\n    risky()\nexcept ValueError as",
        "try:\n    risky()\nelse",
        "except ValueError:",
        "finally:",
        "def f",
        "def f(",
        "def f(a, /, b=1, c",
        "def f(*, a, b=1",
        "def f(**",
        "async def f",
        "class C",
        "class C(",
        "@decorator",
        "@decorator\nclass C",
        "return",
        "yield from",
        "raise ValueError from",
        "assert value,",
        "del",
        "global",
        "nonlocal",
        "import",
        "import pkg as",
        "from",
        "from . import",
        "from pkg import (",
        "a:",
        "a: int =",
        "(a, b): int = value",
        "[a]: int = value",
        "a =",
        "a + b =",
        "target.",
        "target[",
        "target[1:",
        "target.attr[0] =",
        "call(",
        "call(a,",
        "call(a=1,",
        "call(**kw,",
        "lambda_value = lambda",
        "lambda_value = lambda a=1, b",
        "comp = [x for",
        "comp = [*x for x in y]",
        "comp = {x: for x in y}",
        "text = f'{",
        "text = f'{}'",
    ]

    EDGE_EXEC_TAILS = [
        "",
        "\n",
        ":\n    pass\n",
        ":\n    pass\nelse:\n    pass\n",
        ":\n    yield value\n",
        " as name:\n    pass\n",
        " import name\n",
        " = value\n",
        " += value\n",
        ")\n",
    ]

    EDGE_EVAL_STEMS = [
        "",
        "lambda",
        "lambda a",
        "lambda a=1, b",
        "a if b",
        "a if b else",
        "a or",
        "a and",
        "not",
        "a ==",
        "a !=",
        "a <",
        "a not",
        "a is",
        "a +",
        "a -",
        "a *",
        "a @",
        "a /",
        "a //",
        "a %",
        "a <<",
        "a >>",
        "a &",
        "a ^",
        "a |",
        "+",
        "-",
        "~",
        "await",
        "obj.",
        "obj[",
        "obj[1:",
        "func(",
        "func(a,",
        "func(a=1,",
        "func(**kw,",
        "(x for",
        "(x for x in",
        "[x for",
        "[*x for x in y]",
        "{x for",
        "{x:",
        "{x: y for",
        "f'{",
        "f'{}'",
        "(a := b) :=",
    ]

    EDGE_EVAL_TAILS = [
        "",
        " x",
        ")",
        "]",
        "}",
        ",",
        " for x in y",
        " if z",
        " else z",
        ": z}",
        " *args)",
        " **kw)",
        "\n",
    ]

    CPYTHON_SYNTAX_REGRESSION_MODULES = [
        "test.test_syntax",
        "test.test_fstring",
        "test.test_compile",
        "test.test_type_comments",
        "test.test_grammar",
        "test.test_ast",
        "test.test_positional_only_arg",
        "test.test_string_literals",
        "test.test_codeop",
        "test.test_eof",
        "test.test_parser",
        "test.test_unparse",
        "test.test_exceptions",
        "test.test_flufl",
        "test.test_generators",
        "test.test_traceback",
        "test.test_unpack_ex",
    ]

    def assertAstEqual(self, actual: ast.AST, expected: ast.AST) -> None:
        self.assertEqual(ast.dump(actual), ast.dump(expected))

    def test_parse_string_covers_valid_grammar_alternatives(self) -> None:
        for source in self.VALID_PROGRAMS:
            with self.subTest(source=source):
                self.assertAstEqual(peg_parser.parse_string(source), ast.parse(source))

        for source in self.VALID_EVAL_EXPRESSIONS:
            with self.subTest(eval_source=source):
                self.assertAstEqual(
                    peg_parser.parse_string(source, mode="eval"),
                    ast.parse(source, mode="eval"),
                )

    def test_parse_string_covers_specialized_error_alternatives(self) -> None:
        for source in self.INVALID_PROGRAMS:
            with self.subTest(source=source):
                with self.assertRaises(SyntaxError):
                    peg_parser.parse_string(source)

        for source in self.INVALID_EVAL_EXPRESSIONS:
            with self.subTest(eval_source=source):
                with self.assertRaises(SyntaxError):
                    peg_parser.parse_string(source, mode="eval")

        mismatches: List[str] = []
        for source in self.generated_edge_corpus():
            self.assertPegOutcomeMatchesAst(source, "exec", mismatches)
        for source in self.generated_eval_edge_corpus():
            self.assertPegOutcomeMatchesAst(source, "eval", mismatches)
        self.assertEqual(mismatches[:5], [])

    def test_parse_string_covers_standard_library_sources(self) -> None:
        lib_root = Path(__file__).resolve().parents[1]
        skipped_parts = {"__pycache__", "data"}
        parsed_count = 0

        for path in sorted(lib_root.rglob("*.py")):
            rel = path.relative_to(lib_root)
            if skipped_parts.intersection(rel.parts):
                continue
            try:
                with tokenize_open(str(path)) as handle:
                    source = handle.read()
                expected = ast.parse(source, filename=str(path))
            except (SyntaxError, UnicodeError, ValueError, LookupError):
                continue

            with self.subTest(path=str(rel)):
                actual = peg_parser.parse_string(source)
                self.assertAstEqual(actual, expected)
                try:
                    compile(source, str(path), "exec")
                except SyntaxError:
                    pass
                parsed_count += 1

        self.assertGreater(parsed_count, 100)

    def test_cpython_syntax_regression_modules_under_peg_parser(self) -> None:
        _require_active_peg_parser()
        stream = StringIO()
        suite = unittest.defaultTestLoader.loadTestsFromNames(
            self.CPYTHON_SYNTAX_REGRESSION_MODULES
        )
        result = unittest.TextTestRunner(
            stream=stream,
            verbosity=0,
            buffer=True,
        ).run(suite)
        if not result.wasSuccessful():
            self.fail(stream.getvalue())
        self.assertGreater(result.testsRun, 400)

    def generated_edge_corpus(self) -> Iterable[str]:
        seen = set()
        for stem in self.EDGE_EXEC_STEMS:
            for tail in self.EDGE_EXEC_TAILS:
                source = stem + tail
                if source not in seen:
                    seen.add(source)
                    yield source

    def generated_eval_edge_corpus(self) -> Iterable[str]:
        seen = set()
        for stem in self.EDGE_EVAL_STEMS:
            for tail in self.EDGE_EVAL_TAILS:
                source = stem + tail
                if source not in seen:
                    seen.add(source)
                    yield source

    def assertPegOutcomeMatchesAst(
        self,
        source: str,
        mode: str,
        mismatches: List[str],
    ) -> None:
        try:
            expected = ast.parse(source, mode=mode)
        except SyntaxError:
            expected = None

        try:
            actual = peg_parser.parse_string(source, mode=mode)
        except SyntaxError:
            actual = None
        except Exception as exc:
            mismatches.append(f"{mode}:{source!r}: unexpected {type(exc).__name__}")
            return

        if expected is None:
            if actual is not None:
                mismatches.append(f"{mode}:{source!r}: expected SyntaxError")
            return
        if actual is None:
            mismatches.append(f"{mode}:{source!r}: unexpected SyntaxError")
            return
        if ast.dump(actual) != ast.dump(expected):
            mismatches.append(f"{mode}:{source!r}: AST mismatch")


class CGeneratorSemanticsAugTest(unittest.TestCase):
    def test_c_generator_operator_semantics(self) -> None:
        cases = [
            (
                """
                start: 'a'? 'b' NEWLINE? ENDMARKER
                """,
                ["b", "a b"],
                ["a"],
            ),
            (
                """
                start: 'a'* 'b' NEWLINE? ENDMARKER
                """,
                ["b", "a a b"],
                ["a a"],
            ),
            (
                """
                start: 'a'+ 'b' NEWLINE? ENDMARKER
                """,
                ["a b", "a a b"],
                ["b"],
            ),
            (
                """
                start: &'a' 'a' NEWLINE? ENDMARKER
                """,
                ["a"],
                ["b"],
            ),
            (
                """
                start: !'a' NAME NEWLINE? ENDMARKER
                """,
                ["b"],
                ["a"],
            ),
            (
                """
                start: 'a' NEWLINE? ENDMARKER | 'a' 'b' NEWLINE? ENDMARKER
                """,
                ["a", "a b"],
                [],
            ),
            (
                """
                start: 'x' ~ 'y' NEWLINE? ENDMARKER | 'x' 'z' NEWLINE? ENDMARKER
                """,
                ["x y"],
                ["x z"],
            ),
            (
                """
                start: ','.NAME+ NEWLINE? ENDMARKER
                """,
                ["a, b, c"],
                ["a b c", "a, b,"],
            ),
        ]
        for grammar_source, valid_cases, invalid_cases in cases:
            with self.subTest(grammar=grammar_source):
                extension = build_c_extension(grammar_source)
                for source in valid_cases:
                    extension.parse_string(source, mode=0)
                for source in invalid_cases:
                    with self.assertRaises(SyntaxError):
                        extension.parse_string(source, mode=0)

    def test_c_generator_left_recursion_consumes_full_expression(self) -> None:
        grammar_source = """
        start: expr NEWLINE? ENDMARKER
        expr: expr '+' term | term
        term: NUMBER
        """
        extension = build_c_extension(grammar_source)
        for source in ["1", "1 + 2", "1 + 2 + 3 + 4"]:
            with self.subTest(source=source):
                extension.parse_string(source, mode=0)
        with self.assertRaises(SyntaxError):
            extension.parse_string("1 +", mode=0)


class PythonGeneratorSemanticsAugTest(unittest.TestCase):
    def test_python_generator_operator_semantics(self) -> None:
        self.assertParses("start: &'a' 'a' NEWLINE? ENDMARKER", ["a"], ["b"])
        self.assertParses("start: !'a' NAME NEWLINE? ENDMARKER", ["b"], ["a"])
        self.assertParses("start: 'a'? 'b' NEWLINE? ENDMARKER", ["b", "a b"], ["a"])
        self.assertParses("start: 'a'* 'b' NEWLINE? ENDMARKER", ["b", "a a b"], ["a a"])
        self.assertParses("start: 'a'+ 'b' NEWLINE? ENDMARKER", ["a b"], ["b"])
        self.assertParses(
            "start: 'x' ~ 'y' NEWLINE? ENDMARKER | 'x' 'z' NEWLINE? ENDMARKER",
            ["x y"],
            ["x z"],
        )

        parser_class = make_parser("start: ','.NAME+ NEWLINE? ENDMARKER")
        node = parse_string("a, b, c", parser_class)
        self.assertEqual(token_strings(node)[:3], ["a", "b", "c"])
        with self.assertRaises(SyntaxError):
            parse_string("a b c", parser_class)

    def test_python_parser_memoized_hit_advances(self) -> None:
        parser_class = make_parser(
            """
            start: (&thing thing) thing NEWLINE? ENDMARKER
            thing: NAME
            """
        )
        node = parse_string("alpha beta", parser_class)
        self.assertEqual(token_strings(node)[:2], ["alpha", "beta"])

    def test_metagrammar_operator_semantics_reach_generated_parser(self) -> None:
        self.assertParses("start: NAME? '+' NEWLINE? ENDMARKER", ["+", "name +"], [])
        self.assertParses("start: NAME* '+' NEWLINE? ENDMARKER", ["+", "a b +"], [])
        self.assertParses("start: NAME+ '+' NEWLINE? ENDMARKER", ["a +"], ["+"])

        parser_class = make_parser("start: ','.NAME+ NEWLINE? ENDMARKER")
        node = parse_string("a, b, c", parser_class)
        self.assertEqual(token_strings(node)[:3], ["a", "b", "c"])
        with self.assertRaises(SyntaxError):
            parse_string("a b c", parser_class)

    def test_first_sets_for_predicates_and_repeat_one(self) -> None:
        self.assertFirstSets(
            """
            start: expr NEWLINE
            expr: !'a' opt
            opt: 'a' | 'b' | 'c'
            """,
            {
                "opt": {"'a'", "'b'", "'c'"},
                "expr": {"'b'", "'c'"},
                "start": {"'b'", "'c'"},
            },
        )
        self.assertFirstSets(
            """
            start: thing+ '-' NEWLINE
            thing: NUMBER
            """,
            {
                "thing": {"NUMBER"},
                "start": {"NUMBER"},
            },
        )

    def assertParses(
        self,
        grammar_source: str,
        valid_cases: Iterable[str],
        invalid_cases: Iterable[str],
    ) -> None:
        parser_class = make_parser(grammar_source)
        for source in valid_cases:
            with self.subTest(source=source, grammar=grammar_source):
                parse_string(source, parser_class)
        for source in invalid_cases:
            with self.subTest(source=source, grammar=grammar_source):
                with self.assertRaises(SyntaxError):
                    parse_string(source, parser_class)

    def assertFirstSets(self, grammar_source: str, expected: Dict[str, Any]) -> None:
        grammar: Grammar = parse_string(grammar_source, GrammarParser)
        self.assertEqual(FirstSetCalculator(grammar.rules).calculate(), expected)


def build_c_extension(grammar_source: str) -> Any:
    grammar: Grammar = parse_string(grammar_source, GrammarParser)
    temp = tempfile.TemporaryDirectory()
    try:
        extension = generate_parser_c_extension(grammar, Path(temp.name))
    except Exception:
        temp.cleanup()
        raise
    setattr(extension, "_lolbench_tempdir", temp)
    return extension


def token_strings(node: Any) -> List[str]:
    out: List[str] = []

    def walk(value: Any) -> None:
        if isinstance(value, TokenInfo):
            out.append(value.string)
            return
        if isinstance(value, (list, tuple)):
            for child in value:
                walk(child)

    walk(node)
    return out
