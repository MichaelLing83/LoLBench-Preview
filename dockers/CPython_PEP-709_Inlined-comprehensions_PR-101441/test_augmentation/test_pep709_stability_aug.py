import unittest


class InlinedComprehensionStabilityAugmentedTests(unittest.TestCase):
    def test_comprehension_results_and_iteration_variable_isolation_are_stable(self):
        x = "outer"
        values = [x * 2 for x in range(4) if x % 2]
        self.assertEqual(values, [2, 6])
        self.assertEqual(x, "outer")

        self.assertEqual({x for x in [1, 1, 2]}, {1, 2})
        self.assertEqual({x: x * x for x in range(3)}, {0: 0, 1: 1, 2: 4})

    def test_nested_comprehension_semantics_are_stable(self):
        pairs = [(x, y) for x in range(3) for y in range(x)]
        self.assertEqual(pairs, [(1, 0), (2, 0), (2, 1)])

    def test_generator_expressions_keep_lazy_behavior(self):
        calls = []

        def source():
            for value in range(3):
                calls.append(value)
                yield value

        gen = (value * 10 for value in source())
        self.assertEqual(calls, [])
        self.assertEqual(next(gen), 0)
        self.assertEqual(calls, [0])

    def test_exception_behavior_inside_comprehension_is_stable(self):
        with self.assertRaises(ZeroDivisionError):
            [1 // x for x in [1, 0, 2]]


if __name__ == "__main__":
    unittest.main()
