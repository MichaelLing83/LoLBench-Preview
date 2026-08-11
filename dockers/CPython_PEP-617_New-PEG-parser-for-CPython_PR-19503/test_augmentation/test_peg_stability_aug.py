import ast
import codeop
import unittest


class ParserStabilityAugTest(unittest.TestCase):
    def test_compile_exec_eval_and_single_modes_still_work(self) -> None:
        ns = {}
        exec(compile("total = sum(i * i for i in range(5))\n", "<aug>", "exec"), ns)
        self.assertEqual(ns["total"], 30)

        self.assertEqual(eval(compile("(1, 2, 3)[-1]", "<aug>", "eval")), 3)
        self.assertIsNotNone(codeop.compile_command("answer = 42\n", symbol="single"))

    def test_ast_parse_preserves_comprehension_shape(self) -> None:
        tree = ast.parse("result = {x: x * x for x in range(4) if x % 2}\n")
        assign = tree.body[0]
        self.assertIsInstance(assign, ast.Assign)
        comp = assign.value
        self.assertIsInstance(comp, ast.DictComp)
        self.assertEqual(comp.generators[0].target.id, "x")
        self.assertEqual(ast.dump(comp.key), "Name(id='x', ctx=Load())")
        self.assertIsInstance(comp.generators[0].ifs[0], ast.BinOp)

    def test_function_annotations_and_positional_only_args_are_unchanged(self) -> None:
        source = "def f(a, /, b: int = 2, *, c: str = 'x') -> tuple:\n    return a, b, c\n"
        ns = {}
        exec(compile(source, "<aug>", "exec"), ns)
        self.assertEqual(ns["f"](1, c="z"), (1, 2, "z"))
        parsed = ast.parse(source)
        args = parsed.body[0].args
        self.assertEqual([arg.arg for arg in args.posonlyargs], ["a"])
        self.assertEqual([arg.arg for arg in args.args], ["b"])
        self.assertEqual([arg.arg for arg in args.kwonlyargs], ["c"])
