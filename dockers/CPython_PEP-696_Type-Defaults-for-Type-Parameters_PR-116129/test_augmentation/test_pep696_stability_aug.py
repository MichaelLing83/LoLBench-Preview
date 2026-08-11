import string
import sys
import unittest


class TypeParameterDefaultsStabilityAugmentedTests(unittest.TestCase):
    def test_string_template_substitution_and_formatter_are_stable(self):
        template = string.Template("$name scored ${points} points")
        self.assertEqual(
            template.substitute(name="Ada", points=42),
            "Ada scored 42 points",
        )
        self.assertEqual("{name}:{value:04d}".format(name="id", value=7), "id:0007")

    def test_numeric_literal_and_float_roundtrip_behaviour_is_stable(self):
        self.assertEqual(int("1_000_000"), 1000000)
        self.assertEqual(int("ff", 16), 255)
        value = float.fromhex("0x1.8p+2")
        self.assertEqual(value.hex(), "0x1.8000000000000p+2")

    def test_regular_function_and_class_execution_are_stable(self):
        class Accumulator:
            def __init__(self, initial=0):
                self.total = initial

            def add(self, *values):
                for value in values:
                    self.total += value
                return self.total

        acc = Accumulator(10)
        self.assertEqual(acc.add(1, 2, 3), 16)
        self.assertEqual([x * x for x in range(4)], [0, 1, 4, 9])

    def test_sys_frame_metadata_for_regular_calls_is_stable(self):
        def inner():
            frame = sys._getframe()
            return frame.f_code.co_name, frame.f_globals["__name__"]

        self.assertEqual(inner(), ("inner", __name__))


if __name__ == "__main__":
    unittest.main()
