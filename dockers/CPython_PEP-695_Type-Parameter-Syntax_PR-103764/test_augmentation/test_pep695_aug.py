import ast
import keyword
import pathlib
import textwrap
import types
import typing
import unittest


CPYTHON_ROOT = pathlib.Path(__file__).resolve().parents[2]


def run_source(source, namespace=None):
    ns = {} if namespace is None else dict(namespace)
    exec(textwrap.dedent(source), ns)
    return ns


class TypeParameterSyntaxAugmentedTests(unittest.TestCase):
    def test_ast_unparse_preserves_all_type_parameter_forms(self):
        cases = [
            ("class Box[T]:\n    pass", "class Box[T]:"),
            ("def ident[T](x: T) -> T:\n    return x", "def ident[T]"),
            ("async def coro[T]():\n    pass", "async def coro[T]"),
            ("class Array[*Shape]:\n    pass", "class Array[*Shape]:"),
            ("def deco[**P]():\n    pass", "def deco[**P]"),
            ("type Vec[T] = list[T]", "type Vec[T] = list[T]"),
        ]

        for source, expected in cases:
            with self.subTest(source=source):
                rendered = ast.unparse(ast.parse(source))
                self.assertIn(expected, rendered)
                self.assertNotIn("alias Vec", rendered)
                self.assertNotIn("Box(T)", rendered)

    def test_source_distribution_keeps_type_parameter_grammar_and_soft_keyword(self):
        grammar = (CPYTHON_ROOT / "Grammar" / "python.gram").read_text()
        keyword_source = (CPYTHON_ROOT / "Lib" / "keyword.py").read_text()

        self.assertIn("type_params[asdl_typeparam_seq*]", grammar)
        self.assertIn("'*' a=NAME", grammar)
        self.assertIn("'**' a=NAME", grammar)
        self.assertIn('"type" n=NAME t=[type_params]', grammar)
        self.assertIn("'type'", keyword_source)
        self.assertTrue(keyword.issoftkeyword("type"))

    def test_typing_forward_union_and_invalid_variadic_specialization(self):
        compile("class NeedsPEP695[T]:\n    pass", "<pep695-aug>", "exec")

        t = typing.TypeVar("T")
        union = t | "Later"
        self.assertEqual(typing.get_args(union)[0], t)
        self.assertIn("Later", repr(union))

        ts = typing.TypeVarTuple("Ts")
        us = typing.TypeVarTuple("Us")
        alias = tuple[typing.Unpack[ts], typing.Unpack[us]]
        with self.assertRaises(TypeError):
            alias[int, str]

        p = typing.ParamSpec("P")
        callback = typing.Callable[p, int]
        with self.assertRaises(TypeError):
            callback[()]

    def test_implicit_type_parameters_expose_variance_and_exact_runtime_tuple(self):
        ns = run_source(
            """
            class Box[T, *Ts, **P]:
                pass

            def func[S, **Q]():
                pass

            type Alias[*As] = tuple[*As]
            """
        )

        t, ts, p = ns["Box"].__type_params__
        self.assertEqual([param.__name__ for param in (t, ts, p)], ["T", "Ts", "P"])
        self.assertTrue(t.__infer_variance__)
        self.assertTrue(p.__infer_variance__)
        self.assertIsInstance(ts, typing.TypeVarTuple)
        self.assertEqual(ns["Alias"].__type_params__, (ns["Alias"].__type_params__[0],))
        self.assertIsInstance(ns["Alias"].__type_params__[0], typing.TypeVarTuple)
        self.assertEqual(ns["Box"].__parameters__, (t, ts, p))
        self.assertEqual(
            types.get_original_bases(ns["Box"]),
            (typing.Generic[t, typing.Unpack[ts], p],),
        )

        s, q = ns["func"].__type_params__
        self.assertEqual((s.__name__, q.__name__), ("S", "Q"))
        self.assertTrue(s.__infer_variance__)
        self.assertTrue(q.__infer_variance__)

    def test_public_type_parameter_constructors_reject_invalid_combinations(self):
        with self.assertRaises(ValueError):
            typing.TypeVar("T", infer_variance=True, covariant=True)
        with self.assertRaises(ValueError):
            typing.ParamSpec("P", infer_variance=True, contravariant=True)
        with self.assertRaises(TypeError):
            typing.TypeVar("SingleConstraint", int)
        with self.assertRaises(TypeError):
            typing.TypeVar("BoundAndConstraints", int, str, bound=object)

        tv = typing.TypeVar("T")
        with self.assertRaises(TypeError):
            typing.TypeAliasType("Alias", list[tv], type_params=[tv])

    def test_lazy_bounds_constraints_and_alias_values_are_cached(self):
        ns = run_source(
            """
            events = []
            def mark(value):
                events.append(value)
                return value

            class BoundBox[T: mark(int)]:
                pass

            class ConstraintBox[T: (mark(str), bytes)]:
                pass

            type Alias = mark(float)
            """
        )

        (bound_t,) = ns["BoundBox"].__type_params__
        self.assertEqual(ns["events"], [])
        self.assertIs(bound_t.__bound__, int)
        self.assertIs(bound_t.__bound__, int)
        self.assertEqual(ns["events"], [int])

        (constraint_t,) = ns["ConstraintBox"].__type_params__
        self.assertEqual(constraint_t.__constraints__, (str, bytes))
        self.assertEqual(constraint_t.__constraints__, (str, bytes))
        self.assertEqual(ns["events"], [int, str])

        self.assertIs(ns["Alias"].__value__, float)
        self.assertIs(ns["Alias"].__value__, float)
        self.assertEqual(ns["events"], [int, str, float])

    def test_type_alias_public_runtime_contract(self):
        ns = run_source(
            """
            type NonGeneric = int
            type Variadic[*Ts] = tuple[*Ts]
            type Plain = int
            """
        )

        non_generic = ns["NonGeneric"]
        variadic = ns["Variadic"]
        plain = ns["Plain"]

        with self.assertRaises(TypeError):
            non_generic[str]

        (ts,) = variadic.__type_params__
        self.assertIsInstance(ts, typing.TypeVarTuple)
        self.assertEqual(variadic.__parameters__, (*ts,))
        self.assertIs(plain.__value__, int)

        union = plain | str
        self.assertIsInstance(union, types.UnionType)
        self.assertEqual(typing.get_args(union), (plain, str))

    def test_bounds_constraints_and_empty_type_params_are_classified_correctly(self):
        ns = run_source(
            """
            class Bounds[T: int, S: (str, bytes)]:
                pass

            class Pair[T, U]:
                pass

            class Plain:
                pass

            def plain_func():
                pass
            """
        )

        t, s = ns["Bounds"].__type_params__
        self.assertIs(t.__bound__, int)
        self.assertEqual(t.__constraints__, None)
        self.assertIs(s.__bound__, None)
        self.assertEqual(s.__constraints__, (str, bytes))

        self.assertEqual([p.__name__ for p in ns["Pair"].__type_params__], ["T", "U"])
        self.assertEqual(ns["Plain"].__type_params__, ())
        self.assertEqual(ns["plain_func"].__type_params__, ())

    def test_type_parameter_scopes_and_prohibited_expressions(self):
        bad_sources = [
            "class C[T, T]:\n    pass",
            "class C[T]:\n    def m():\n        nonlocal T",
            "type Alias = (x := int)",
            "class C[T := int]:\n    pass",
            "class C[T: (x := int)]:\n    pass",
        ]
        for source in bad_sources:
            with self.subTest(source=source):
                with self.assertRaises(SyntaxError):
                    compile(source, "<pep695-aug>", "exec")

        ns = run_source(
            """
            class Outer:
                Bound = int
                class Inner[T: Bound]:
                    pass
            """
        )
        (inner_t,) = ns["Outer"].Inner.__type_params__
        self.assertIs(inner_t.__bound__, int)

    def test_manual_ast_type_parameter_nodes_compile_and_validate(self):
        module = ast.Module(
            body=[
                ast.FunctionDef(
                    name="identity",
                    args=ast.arguments(
                        posonlyargs=[],
                        args=[ast.arg("value")],
                        kwonlyargs=[],
                        kw_defaults=[],
                        defaults=[],
                    ),
                    body=[ast.Return(ast.Name("value", ast.Load()))],
                    decorator_list=[],
                    returns=None,
                    typeparams=[
                        ast.TypeVar("T", bound=ast.Name("int", ast.Load())),
                    ],
                ),
                ast.AsyncFunctionDef(
                    name="async_identity",
                    args=ast.arguments(
                        posonlyargs=[],
                        args=[ast.arg("value")],
                        kwonlyargs=[],
                        kw_defaults=[],
                        defaults=[],
                    ),
                    body=[ast.Return(ast.Name("value", ast.Load()))],
                    decorator_list=[],
                    returns=None,
                    typeparams=[ast.ParamSpec("P")],
                ),
                ast.ClassDef(
                    name="Array",
                    bases=[],
                    keywords=[],
                    body=[ast.Pass()],
                    decorator_list=[],
                    typeparams=[ast.TypeVarTuple("Shape")],
                ),
                ast.TypeAlias(
                    name=ast.Name("Alias", ast.Store()),
                    typeparams=[ast.TypeVar("A")],
                    value=ast.Name("list", ast.Load()),
                ),
            ],
            type_ignores=[],
        )
        ast.fix_missing_locations(module)
        namespace = {}
        exec(compile(module, "<manual-pep695-ast>", "exec"), namespace)

        (func_t,) = namespace["identity"].__type_params__
        self.assertIs(func_t.__bound__, int)
        (async_p,) = namespace["async_identity"].__type_params__
        self.assertIsInstance(async_p, typing.ParamSpec)
        (shape,) = namespace["Array"].__type_params__
        self.assertIsInstance(shape, typing.TypeVarTuple)
        (alias_a,) = namespace["Alias"].__type_params__
        self.assertEqual(alias_a.__name__, "A")
        self.assertIs(namespace["Alias"].__value__, list)

    def test_typing_runtime_dunder_and_paramspec_attr_contracts(self):
        compile("class NeedsPEP695[T]:\n    pass", "<pep695-aug>", "exec")

        t = typing.TypeVar("T")
        p = typing.ParamSpec("P")
        ts = typing.TypeVarTuple("Ts")

        self.assertEqual(t.__reduce__(), "T")
        self.assertEqual(p.__reduce__(), "P")
        self.assertEqual(ts.__reduce__(), "Ts")
        self.assertEqual(repr(p.args), "P.args")
        self.assertEqual(repr(p.kwargs), "P.kwargs")
        self.assertIs(p.args.__origin__, p)
        self.assertIs(p.kwargs.__origin__, p)
        self.assertEqual(p.args, p.args)
        self.assertNotEqual(p.args, p.kwargs)

        with self.assertRaisesRegex(TypeError, "Cannot subclass"):
            class BadTypeVar(t):
                pass

        with self.assertRaisesRegex(TypeError, "Cannot subclass"):
            class BadParamSpec(p):
                pass

        with self.assertRaisesRegex(TypeError, "Cannot subclass"):
            class BadTypeVarTuple(ts):
                pass

        self.assertEqual(
            typing.Callable[p, int][[str, bytes]],
            typing.Callable[[str, bytes], int],
        )
        self.assertEqual(tuple[typing.Unpack[ts]][int, str].__args__, (int, str))

    def test_regenerated_parser_keeps_broad_public_grammar_paths(self):
        compile("class NeedsPEP695[T]:\n    pass", "<pep695-aug>", "exec")

        valid_sources = [
            "value = (lambda a, b=1, *args, c=2, **kw: (a, b, args, c, kw))(0)",
            "items = [x * y for x in range(3) for y in range(2) if x != y]",
            "mapping = {k: v for k, v in [('a', 1), ('b', 2)] if v}",
            "result = (x for x in range(4) if x % 2)",
            "def f(a, /, b: int = 1, *args, c, d=2, **kw) -> tuple:\n    return a, b, args, c, d, kw",
            "async def afunc(x):\n    async with manager() as value:\n        async for item in value:\n            yield item",
            "try:\n    raise ExceptionGroup('x', [ValueError()])\nexcept* ValueError as exc:\n    handled = exc\nelse:\n    handled = None\nfinally:\n    done = True",
            "match {'kind': 'point', 'x': 1, 'y': 2}:\n    case {'kind': 'point', 'x': x, 'y': y} if x < y:\n        result = (x, y)\n    case _:\n        result = None",
            "text = f'{1 + 2 = !r:>10}'",
            "with (nullcontext(1) as first, nullcontext(2) as second):\n    pair = first, second",
            "type Alias[T] = tuple[T, list[T]]",
            "class Derived[T](Base[T], keyword=True):\n    attr: T\n    def method[U](self, value: U) -> tuple[T, U]:\n        return self.attr, value",
        ]
        for source in valid_sources:
            with self.subTest(source=source):
                compile(source, "<parser-regeneration>", "exec")

        invalid_sources = [
            "lambda a=1, b: a",
            "def bad(a=1, b):\n    pass",
            "class Bad[T, T]:\n    pass",
            "type Alias = (x := int)",
            "f'{value!}'",
            "try:\n    pass\nexcept* ValueError:\n    pass\nexcept Exception:\n    pass",
            "match value:\n    case [x, *x]:\n        pass",
        ]
        for source in invalid_sources:
            with self.subTest(source=source):
                with self.assertRaises(SyntaxError):
                    compile(source, "<parser-regeneration-invalid>", "exec")


if __name__ == "__main__":
    unittest.main()
