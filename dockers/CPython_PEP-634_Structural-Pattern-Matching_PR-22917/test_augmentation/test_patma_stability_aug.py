import ast
import keyword
import unittest
from collections import namedtuple
from dataclasses import dataclass, field


class PatternMatchingStabilityAugmentedTests(unittest.TestCase):
    def test_soft_keyword_names_remain_ordinary_identifiers(self):
        self.assertFalse(keyword.iskeyword("match"))
        self.assertFalse(keyword.iskeyword("case"))

        namespace = {}
        exec(
            "match = 2\n"
            "case = 3\n"
            "_ = 4\n"
            "result = match * case + _\n",
            namespace,
        )
        self.assertEqual(namespace["result"], 10)

    def test_namedtuple_existing_contracts_are_unchanged(self):
        Point = namedtuple("Point", ["x", "y"], defaults=[99])

        point = Point(4)
        self.assertEqual(point.x, 4)
        self.assertEqual(point.y, 99)
        self.assertEqual(point[0], 4)
        self.assertEqual(point._asdict(), {"x": 4, "y": 99})
        self.assertEqual(Point._fields, ("x", "y"))

    def test_dataclass_existing_init_defaults_and_repr_are_unchanged(self):
        @dataclass
        class Item:
            value: int
            label: str = "default"
            cached: int = field(init=False, default=5)

        item = Item(3)
        self.assertEqual((item.value, item.label, item.cached), (3, "default", 5))
        self.assertIn("Item(value=3, label='default', cached=5)", repr(item))

        with self.assertRaises(TypeError):
            Item(3, "name", 7)

    def test_ast_compile_existing_control_flow_is_unchanged(self):
        source = """
def f(values):
    total = 0
    for value in values:
        if value % 2:
            total += value
    return total
"""
        tree = ast.parse(source)
        code = compile(tree, "<ordinary control flow>", "exec")
        namespace = {}
        exec(code, namespace)
        self.assertEqual(namespace["f"]([1, 2, 3, 4, 5]), 9)


if __name__ == "__main__":
    unittest.main()
