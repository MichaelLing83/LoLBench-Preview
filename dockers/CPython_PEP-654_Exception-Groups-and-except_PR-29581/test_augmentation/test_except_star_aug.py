import ast
import unittest


def leaf_types(exc):
    leaves = []
    if isinstance(exc, BaseExceptionGroup):
        for nested in exc.exceptions:
            leaves.extend(leaf_types(nested))
    else:
        leaves.append(type(exc))
    return leaves


class ExceptionGroupAugTest(unittest.TestCase):
    def test_ast_unparse_opcode_and_validation_surface(self):
        source = (
            "try:\n"
            "    pass\n"
            "except* ValueError as exc:\n"
            "    pass\n"
            "finally:\n"
            "    pass\n"
        )
        tree = ast.parse(source)
        self.assertIsInstance(tree.body[0], ast.TryStar)
        rendered = ast.unparse(tree)
        self.assertIn("except* ValueError as exc", rendered)
        self.assertNotIn("except ValueError as exc", rendered)

        invalid = ast.Module(
            body=[ast.TryStar(body=[ast.Pass()], handlers=[], orelse=[], finalbody=[])],
            type_ignores=[],
        )
        ast.fix_missing_locations(invalid)
        with self.assertRaises(ValueError):
            compile(invalid, "<invalid-trystar>", "exec")

    def test_subgroup_and_split_partitioning_contracts(self):
        group = ExceptionGroup(
            "root",
            [
                ValueError("v1"),
                ExceptionGroup("nested", [TypeError("t"), ValueError("v2")]),
                OSError("os"),
            ],
        )
        subgroup = group.subgroup(lambda exc: isinstance(exc, ValueError))
        self.assertEqual(leaf_types(subgroup), [ValueError, ValueError])

        with self.assertRaises(TypeError):
            group.split((ValueError, 42))

        match, rest = ExceptionGroup("pair", [ValueError("v"), TypeError("t")]).split(ValueError)
        self.assertEqual(leaf_types(match), [ValueError])
        self.assertEqual(leaf_types(rest), [TypeError])

        derive_calls = []

        class TrackingGroup(ExceptionGroup):
            def derive(self, excs):
                derive_calls.append(tuple(type(exc) for exc in excs))
                return type(self)(self.message, excs)

        tracked = TrackingGroup("tracked", [ValueError("v"), TypeError("t")])
        self.assertEqual(leaf_types(tracked.subgroup(ValueError)), [ValueError])
        self.assertEqual(derive_calls, [(ValueError,)])

    def test_except_star_matching_wrapping_and_forbidden_handlers(self):
        caught = []
        try:
            raise ExceptionGroup("eg", [ValueError("v")])
        except* Exception as eg:
            caught.append(eg)
        self.assertEqual(caught[0].message, "eg")
        self.assertEqual(leaf_types(caught[0]), [ValueError])
        self.assertIsInstance(caught[0].exceptions[0], ValueError)

        naked = []
        try:
            raise ValueError("naked")
        except* ValueError as eg:
            naked.append(eg)
        self.assertIsInstance(naked[0], ExceptionGroup)
        self.assertEqual(leaf_types(naked[0]), [ValueError])

        with self.assertRaises(TypeError):
            try:
                raise ExceptionGroup("eg", [ValueError("v")])
            except* ExceptionGroup:
                pass

    def test_except_star_reraise_and_unmatched_rest(self):
        seen = []
        try:
            raise ExceptionGroup(
                "root",
                [ExceptionGroup("inner", [ValueError("v"), TypeError("t")])],
            )
        except* ValueError as eg:
            seen.append(leaf_types(eg))
        except* TypeError as eg:
            seen.append(leaf_types(eg))
        self.assertEqual(seen, [[ValueError], [TypeError]])

        with self.assertRaises(ExceptionGroup) as raised:
            try:
                raise ValueError("naked")
            except* ValueError:
                raise
        self.assertEqual(leaf_types(raised.exception), [ValueError])

        handled = []
        try:
            try:
                raise ExceptionGroup("eg", [ValueError("v"), TypeError("t")])
            except* ValueError as eg:
                handled.append(leaf_types(eg))
        except ExceptionGroup as rest:
            self.assertEqual(handled, [[ValueError]])
            self.assertEqual(leaf_types(rest), [TypeError])
        else:
            self.fail("unmatched TypeError subgroup was not reraised")

        try:
            try:
                raise ExceptionGroup("eg", [ValueError("v"), TypeError("t")])
            except* ValueError:
                raise
        except ExceptionGroup as reraised:
            self.assertEqual(leaf_types(reraised), [ValueError, TypeError])
        else:
            self.fail("bare reraise and unmatched rest were not combined")

    def test_except_star_new_exceptions_finally_else_and_routing(self):
        marker = []
        try:
            try:
                raise ExceptionGroup("eg", [ValueError("v")])
            except* ValueError:
                marker.append("handled")
            finally:
                marker.append("finally")
        except ExceptionGroup:
            self.fail("all sub-exceptions should be handled")
        self.assertEqual(marker, ["handled", "finally"])

        else_marker = []
        try:
            else_marker.append("try")
        except* ValueError:
            else_marker.append("handler")
        else:
            else_marker.append("else")
        self.assertEqual(else_marker, ["try", "else"])

        with self.assertRaises(ExceptionGroup) as cm:
            try:
                raise ExceptionGroup("eg", [ValueError("v")])
            except* ValueError:
                raise TypeError("new")
        self.assertEqual(leaf_types(cm.exception), [TypeError])

        routed = []
        try:
            raise ExceptionGroup("eg", [ValueError("v"), TypeError("t")])
        except* ValueError as eg:
            routed.append(("value", leaf_types(eg)))
        except* TypeError as eg:
            routed.append(("type", leaf_types(eg)))
        self.assertEqual(routed, [("value", [ValueError]), ("type", [TypeError])])

    def test_forbidden_control_flow_in_except_star_blocks(self):
        cases = [
            "for item in [1]:\n"
            "    try:\n"
            "        raise ExceptionGroup('eg', [ValueError()])\n"
            "    except* ValueError:\n"
            "        break\n",
            "for item in [1]:\n"
            "    try:\n"
            "        raise ExceptionGroup('eg', [ValueError()])\n"
            "    except* ValueError:\n"
            "        continue\n",
            "def f():\n"
            "    try:\n"
            "        raise ExceptionGroup('eg', [ValueError()])\n"
            "    except* ValueError:\n"
            "        return 1\n",
        ]
        for source in cases:
            with self.subTest(source=source):
                with self.assertRaises(SyntaxError):
                    compile(source, "<forbidden-except-star>", "exec")

    def test_exception_group_constructor_and_metadata_edges(self):
        with self.assertRaises(ValueError):
            ExceptionGroup("empty", [])
        with self.assertRaises(ValueError):
            ExceptionGroup("bad", [ValueError("v"), object()])

        class Fatal(BaseException):
            pass

        with self.assertRaises(TypeError):
            ExceptionGroup("bad-base", [Fatal("fatal")])

        base = BaseExceptionGroup("base", [Fatal("fatal")])
        self.assertIs(type(base), BaseExceptionGroup)
        auto = BaseExceptionGroup("auto", [ValueError("v")])
        self.assertIs(type(auto), ExceptionGroup)

        group = ExceptionGroup("root", [ValueError("v"), TypeError("t")])
        self.assertEqual(group.message, "root")
        self.assertEqual(tuple(type(exc) for exc in group.exceptions), (ValueError, TypeError))
        self.assertIsNone(group.subgroup(KeyError))

        match, rest = group.split((ValueError, TypeError))
        self.assertEqual(leaf_types(match), [ValueError, TypeError])
        self.assertIsNone(rest)

        match, rest = group.split(KeyError)
        self.assertIsNone(match)
        self.assertEqual(leaf_types(rest), [ValueError, TypeError])

        seen = []
        self.assertIsNone(group.subgroup(lambda exc: seen.append(type(exc)) or False))
        self.assertEqual(seen, [ExceptionGroup, ValueError, TypeError])

        try:
            try:
                raise OSError("cause")
            except OSError as cause:
                raise ExceptionGroup("eg", [TypeError("leaf")]) from cause
        except ExceptionGroup as eg:
            clone = eg.subgroup(TypeError)
            self.assertIs(clone.__cause__, eg.__cause__)
            self.assertIs(clone.__context__, eg.__context__)
            self.assertTrue(clone.__suppress_context__)
            self.assertEqual(leaf_types(clone), [TypeError])

    def test_except_star_runtime_and_compile_matrix(self):
        cases = [
            (
                "tuple_match_else_finally",
                """
events = []
try:
    raise ExceptionGroup('eg', [ValueError('v'), TypeError('t')])
except* (ValueError, TypeError) as eg:
    events.append(('caught', [type(e).__name__ for e in eg.exceptions]))
else:
    events.append(('else', []))
finally:
    events.append(('finally', []))
""",
                [("caught", ["ValueError", "TypeError"]), ("finally", [])],
            ),
            (
                "unmatched_rest_then_outer_group",
                """
events = []
try:
    try:
        raise ExceptionGroup('eg', [ValueError('v'), LookupError('l')])
    except* ValueError as eg:
        events.append(('value', [type(e).__name__ for e in eg.exceptions]))
except ExceptionGroup as rest:
    events.append(('rest', [type(e).__name__ for e in rest.exceptions]))
""",
                [("value", ["ValueError"]), ("rest", ["LookupError"])],
            ),
            (
                "new_exceptions_from_two_handlers",
                """
events = []
try:
    try:
        raise ExceptionGroup('eg', [ValueError('v'), TypeError('t')])
    except* ValueError:
        raise RuntimeError('new-v')
    except* TypeError:
        raise OSError('new-t')
except ExceptionGroup as raised:
    events = [type(e).__name__ for e in raised.exceptions]
""",
                ["RuntimeError", "OSError"],
            ),
            (
                "valid_nested_control_flow",
                """
events = []
try:
    raise ExceptionGroup('eg', [ValueError('v')])
except* ValueError:
    for i in range(2):
        if i:
            break
        events.append(i)
""",
                [0],
            ),
            (
                "function_return_after_except_star",
                """
def f():
    try:
        raise ExceptionGroup('eg', [ValueError('v')])
    except* ValueError:
        marker = 'handled'
    return marker
events = f()
""",
                "handled",
            ),
        ]
        globals_ = {
            "ExceptionGroup": ExceptionGroup,
            "LookupError": LookupError,
            "OSError": OSError,
            "RuntimeError": RuntimeError,
            "TypeError": TypeError,
            "ValueError": ValueError,
            "range": range,
            "type": type,
        }
        for name, source, expected in cases:
            with self.subTest(name=name):
                code = compile(source, f"<{name}>", "exec")
                ns = {}
                exec(code, globals_, ns)
                self.assertEqual(ns["events"], expected)

        invalid_sources = [
            "try:\n    pass\nexcept ValueError:\n    pass\nexcept* TypeError:\n    pass\n",
            "try:\n    pass\nexcept*:\n    pass\n",
            "try:\n    pass\nexcept* ValueError as exc, TypeError:\n    pass\n",
            "try:\n    pass\nexcept* (ValueError,):\n    pass\nexcept TypeError:\n    pass\n",
        ]
        for source in invalid_sources:
            with self.subTest(source=source):
                with self.assertRaises(SyntaxError):
                    compile(source, "<invalid-except-star>", "exec")

    def test_try_star_ast_manual_construction_roundtrip(self):
        handler = ast.ExceptHandler(
            type=ast.Name(id="ValueError", ctx=ast.Load()),
            name="exc",
            body=[
                ast.Assign(
                    targets=[ast.Name(id="handled", ctx=ast.Store())],
                    value=ast.Call(
                        func=ast.Name(id="isinstance", ctx=ast.Load()),
                        args=[
                            ast.Name(id="exc", ctx=ast.Load()),
                            ast.Name(id="ExceptionGroup", ctx=ast.Load()),
                        ],
                        keywords=[],
                    ),
                )
            ],
        )
        tree = ast.Module(
            body=[
                ast.Assign(
                    targets=[ast.Name(id="handled", ctx=ast.Store())],
                    value=ast.Constant(value=None),
                ),
                ast.TryStar(
                    body=[
                        ast.Raise(
                            exc=ast.Call(
                                func=ast.Name(id="ValueError", ctx=ast.Load()),
                                args=[ast.Constant(value="manual")],
                                keywords=[],
                            ),
                            cause=None,
                        )
                    ],
                    handlers=[handler],
                    orelse=[
                        ast.Assign(
                            targets=[ast.Name(id="handled", ctx=ast.Store())],
                            value=ast.Constant(value="else"),
                        )
                    ],
                    finalbody=[
                        ast.Assign(
                            targets=[ast.Name(id="done", ctx=ast.Store())],
                            value=ast.Constant(value=True),
                        )
                    ],
                ),
            ],
            type_ignores=[],
        )
        ast.fix_missing_locations(tree)
        ns = {}
        exec(
            compile(tree, "<manual-trystar>", "exec"),
            {"ExceptionGroup": ExceptionGroup, "ValueError": ValueError, "isinstance": isinstance},
            ns,
        )
        self.assertIs(ns["handled"], True)
        self.assertIs(ns["done"], True)

        rendered = ast.unparse(tree)
        self.assertIn("except* ValueError as exc", rendered)
        reparsed = ast.parse(rendered)
        self.assertIsInstance(reparsed.body[1], ast.TryStar)

        bad_handler = ast.Module(
            body=[
                ast.TryStar(
                    body=[ast.Pass()],
                    handlers=[ast.Pass()],
                    orelse=[],
                    finalbody=[],
                )
            ],
            type_ignores=[],
        )
        ast.fix_missing_locations(bad_handler)
        with self.assertRaises(TypeError):
            compile(bad_handler, "<bad-trystar-handler>", "exec")

    def test_except_star_error_cleanup_and_reraise_edges(self):
        def handler_name_is_cleared():
            try:
                raise ExceptionGroup("eg", [ValueError("v")])
            except* ValueError as exc:
                saved = exc
            return "exc" in locals(), leaf_types(saved)

        self.assertEqual(handler_name_is_cleared(), (False, [ValueError]))

        def handler_name_is_cleared_when_body_raises():
            try:
                try:
                    raise ExceptionGroup("eg", [ValueError("v")])
                except* ValueError as exc:
                    saved = exc
                    raise RuntimeError("new")
            except ExceptionGroup as raised:
                return "exc" in locals(), leaf_types(saved), leaf_types(raised)

        self.assertEqual(
            handler_name_is_cleared_when_body_raises(),
            (False, [ValueError], [RuntimeError]),
        )

        with self.assertRaises(ValueError):
            try:
                raise ValueError("plain")
            except* TypeError:
                pass

        with self.assertRaises(ExceptionGroup) as mixed:
            try:
                raise ExceptionGroup("eg", [ValueError("v"), TypeError("t")])
            except* ValueError:
                raise
            except* TypeError:
                raise RuntimeError("replacement")
        self.assertEqual(leaf_types(mixed.exception), [RuntimeError, ValueError])

        invalid_runtime_handlers = [
            "object",
            "(ValueError, object)",
            "(ValueError, ExceptionGroup)",
            "BaseExceptionGroup",
        ]
        for handler in invalid_runtime_handlers:
            source = (
                "try:\n"
                "    raise ExceptionGroup('eg', [ValueError('v')])\n"
                f"except* {handler}:\n"
                "    pass\n"
            )
            with self.subTest(handler=handler):
                with self.assertRaises(TypeError):
                    exec(source, {"ExceptionGroup": ExceptionGroup, "ValueError": ValueError})

        annotated_sources = [
            "try:\n"
            "    x: int = 1\n"
            "except* ValueError:\n"
            "    pass\n",
            "try:\n"
            "    pass\n"
            "except* ValueError:\n"
            "    y: int = 2\n"
            "else:\n"
            "    z: int = 3\n",
            "try:\n"
            "    pass\n"
            "except* ValueError:\n"
            "    pass\n"
            "finally:\n"
            "    w: int = 4\n",
        ]
        for source in annotated_sources:
            with self.subTest(source=source):
                compile(source, "<annotated-trystar>", "exec")


if __name__ == "__main__":
    unittest.main()
