import ast
import sys
import unittest


class ExceptionStabilityAugTest(unittest.TestCase):
    def test_regular_try_except_else_finally_order_is_unchanged(self):
        events = []
        try:
            events.append("try")
        except ValueError:
            events.append("except")
        else:
            events.append("else")
        finally:
            events.append("finally")

        self.assertEqual(events, ["try", "else", "finally"])

    def test_regular_exception_chaining_and_context_are_unchanged(self):
        try:
            try:
                raise KeyError("inner")
            except KeyError as exc:
                raise RuntimeError("outer") from exc
        except RuntimeError as exc:
            self.assertIsInstance(exc.__cause__, KeyError)
            self.assertIs(exc.__context__, exc.__cause__)
            self.assertTrue(exc.__suppress_context__)

    def test_ast_unparse_regular_try_uses_except_keyword(self):
        source = (
            "try:\n"
            "    raise ValueError('x')\n"
            "except ValueError as exc:\n"
            "    handled = str(exc)\n"
        )
        tree = ast.parse(source)
        self.assertEqual(type(tree.body[0]).__name__, "Try")
        rendered = ast.unparse(tree)
        self.assertIn("except ValueError as exc", rendered)
        self.assertNotIn("except* ValueError as exc", rendered)

    def test_sys_exc_info_restores_after_handled_exception(self):
        before = sys.exc_info()
        try:
            raise ValueError("handled")
        except ValueError:
            self.assertIs(sys.exc_info()[0], ValueError)
        self.assertEqual(sys.exc_info(), before)


if __name__ == "__main__":
    unittest.main()
