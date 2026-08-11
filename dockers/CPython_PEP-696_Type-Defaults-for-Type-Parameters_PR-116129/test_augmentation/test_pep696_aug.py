import ast
import importlib
import pathlib
import textwrap
import typing
import unittest


CPYTHON_ROOT = pathlib.Path(__file__).resolve().parents[2]


def run_source(source):
    namespace = {}
    exec(textwrap.dedent(source), namespace)
    return namespace


class TypeParameterDefaultsAugmentedTests(unittest.TestCase):
    def test_grammar_source_routes_defaults_into_ast_constructors(self):
        grammar = (CPYTHON_ROOT / "Grammar" / "python.gram").read_text()

        self.assertIn(
            "c=[type_param_default] { _PyAST_TypeVar(a->v.Name.id, b, c, EXTRA) }",
            grammar,
        )
        self.assertIn(
            "b=[type_param_starred_default] { _PyAST_TypeVarTuple(a->v.Name.id, b, EXTRA) }",
            grammar,
        )
        self.assertIn(
            "b=[type_param_default] { _PyAST_ParamSpec(a->v.Name.id, b, EXTRA) }",
            grammar,
        )
        self.assertIn(
            'CHECK_VERSION(expr_ty, 13, "Type parameter defaults are", e)',
            grammar,
        )
        self.assertEqual(
            grammar.count('CHECK_VERSION(expr_ty, 13, "Type parameter defaults are", e)'),
            2,
        )
        self.assertNotIn(
            'CHECK_VERSION(expr_ty, 12, "Type parameter defaults are", e)',
            grammar,
        )

    def test_typing_source_keeps_default_aware_specialization_guard(self):
        typing_source = (CPYTHON_ROOT / "Lib" / "typing.py").read_text()

        self.assertIn("def _check_generic_specialization(cls, arguments):", typing_source)
        self.assertIn(
            "if cls.__parameters__[actual_len].has_default():",
            typing_source,
        )
        self.assertNotIn(
            "if False and cls.__parameters__[actual_len].has_default():",
            typing_source,
        )

    def test_ast_nodes_preserve_all_type_parameter_defaults(self):
        tree = ast.parse(
            "class C[T = int, *Ts = *tuple[str, int], **P = [str, int]]:\n"
            "    pass"
        )
        params = tree.body[0].type_params

        self.assertIsInstance(params[0].default_value, ast.Name)
        self.assertEqual(params[0].default_value.id, "int")
        self.assertIsInstance(params[1].default_value, ast.Starred)
        self.assertIsInstance(params[1].default_value.value, ast.Subscript)
        self.assertIsInstance(params[2].default_value, ast.List)
        self.assertEqual([elt.id for elt in params[2].default_value.elts], ["str", "int"])

    def test_feature_version_and_unparse_keep_typevar_default_visible(self):
        source = "class C[T = int]:\n    pass"
        with self.assertRaises(SyntaxError):
            ast.parse(source, feature_version=(3, 12))

        tree = ast.parse(source)
        self.assertIn("T = int", ast.unparse(tree))

    def test_nodefault_reduce_repr_and_constructor_contract(self):
        nodefault = typing.NoDefault
        self.assertEqual(repr(nodefault), "typing.NoDefault")
        self.assertEqual(nodefault.__reduce__(), "NoDefault")
        self.assertIs(getattr(typing, nodefault.__reduce__()), nodefault)
        self.assertIs(type(nodefault)(), nodefault)
        with self.assertRaises(TypeError):
            type(nodefault)(1)
        with self.assertRaises(TypeError):
            nodefault()

    def test_default_accessors_report_direct_values_for_all_type_parameters(self):
        no_default = typing.NoDefault

        type_var = typing.TypeVar("T", default=int)
        self.assertIs(type_var.__default__, int)
        self.assertTrue(type_var.has_default())
        self.assertIs(typing.TypeVar("PlainT").__default__, no_default)

        param_spec = typing.ParamSpec("P", default=[str, int])
        self.assertEqual(param_spec.__default__, [str, int])
        self.assertTrue(param_spec.has_default())
        self.assertIs(typing.ParamSpec("PlainP").__default__, no_default)

        type_var_tuple = typing.TypeVarTuple(
            "Ts", default=typing.Unpack[tuple[str, int]]
        )
        self.assertEqual(type_var_tuple.__default__, typing.Unpack[tuple[str, int]])
        self.assertTrue(type_var_tuple.has_default())
        self.assertIs(typing.TypeVarTuple("PlainTs").__default__, no_default)

    def test_subscription_uses_typevar_defaults_and_rejects_bad_order(self):
        required = typing.TypeVar("Required")
        defaulted = typing.TypeVar("Defaulted", default=int)

        class Pair(typing.Generic[required, defaulted]):
            pass

        self.assertEqual(Pair[str].__args__, (str, int))
        self.assertEqual(Pair[str, bytes].__args__, (str, bytes))

        with self.assertRaisesRegex(TypeError, "without a default follows"):
            typing.Generic[defaulted, required]

        variadic = typing.TypeVarTuple("Variadic")
        with self.assertRaisesRegex(TypeError, "default.*TypeVarTuple"):
            class Bad(typing.Generic[typing.Unpack[variadic], defaulted]):
                pass

    def test_paramspec_and_typevartuple_defaults_are_used_for_subscription(self):
        required = typing.TypeVar("Required")
        params = typing.ParamSpec("P", default=[str, int])

        class CallbackBox(typing.Generic[required, params]):
            pass

        self.assertEqual(CallbackBox[float].__args__, (float, (str, int)))
        self.assertEqual(CallbackBox[float, [bytes]].__args__, (float, (bytes,)))

        type_var_tuple = typing.TypeVarTuple(
            "Ts", default=typing.Unpack[tuple[str, int]]
        )

        class TupleBox(typing.Generic[required, typing.Unpack[type_var_tuple]]):
            pass

        self.assertEqual(TupleBox[float].__args__, (float, str, int))
        self.assertEqual(TupleBox[float, bytes].__args__, (float, bytes))

    def test_pep695_runtime_defaults_are_lazily_attached(self):
        namespace = run_source(
            """
            class Holder[T = Later]:
                pass
            """
        )
        type_param = namespace["Holder"].__type_params__[0]
        with self.assertRaises(NameError):
            type_param.__default__

        namespace["Later"] = str
        self.assertIs(type_param.__default__, str)

        namespace = run_source(
            """
            class Chain[StartT = int, StopT = StartT]:
                pass
            """
        )
        start_t, stop_t = namespace["Chain"].__type_params__
        self.assertIs(start_t.__default__, int)
        self.assertIs(stop_t.__default__, start_t)

    def test_starred_typevartuple_default_from_pep695_syntax_is_attached(self):
        namespace = run_source(
            """
            default = tuple[int, str]
            class C[*Ts = *default]:
                pass
            """
        )
        (type_var_tuple,) = namespace["C"].__type_params__
        self.assertEqual(type_var_tuple.__default__, next(iter(namespace["default"])))

    def test_manual_ast_compile_accepts_type_parameter_defaults(self):
        module = ast.Module(
            body=[
                ast.ClassDef(
                    name="Manual",
                    bases=[],
                    keywords=[],
                    body=[ast.Pass()],
                    decorator_list=[],
                    type_params=[
                        ast.TypeVar(
                            "T",
                            bound=ast.Name("object", ast.Load()),
                            default_value=ast.Name("int", ast.Load()),
                        ),
                        ast.ParamSpec(
                            "P",
                            default_value=ast.List(
                                [ast.Name("str", ast.Load()), ast.Name("int", ast.Load())],
                                ast.Load(),
                            ),
                        ),
                        ast.TypeVarTuple(
                            "Ts",
                            default_value=ast.Tuple(
                                [ast.Name("str", ast.Load()), ast.Name("bytes", ast.Load())],
                                ast.Load(),
                            ),
                        ),
                    ],
                )
            ],
            type_ignores=[],
        )
        ast.fix_missing_locations(module)
        namespace = {}
        exec(compile(module, "<manual-ast>", "exec"), namespace)

        type_var, param_spec, type_var_tuple = namespace["Manual"].__type_params__
        self.assertIs(type_var.__bound__, object)
        self.assertIs(type_var.__default__, int)
        self.assertEqual(param_spec.__default__, [str, int])
        self.assertEqual(type_var_tuple.__default__, (str, bytes))

    def test_manual_ast_compile_accepts_missing_default_attributes(self):
        type_var = ast.TypeVar("T")
        type_var_tuple = ast.TypeVarTuple("Ts")
        param_spec = ast.ParamSpec("P")

        module = ast.Module(
            body=[
                ast.ClassDef(
                    name="Plain",
                    bases=[],
                    keywords=[],
                    body=[ast.Pass()],
                    decorator_list=[],
                    type_params=[type_var, type_var_tuple, param_spec],
                )
            ],
            type_ignores=[],
        )
        ast.fix_missing_locations(module)
        namespace = {}
        exec(compile(module, "<missing-default-ast>", "exec"), namespace)

        for type_param in namespace["Plain"].__type_params__:
            self.assertIs(type_param.__default__, typing.NoDefault)

    def test_pep695_defaults_on_functions_and_type_aliases(self):
        namespace = run_source(
            """
            def identity[T = int](value: T) -> T:
                return value

            def callback[**P = [str, int]](*args: P.args, **kwargs: P.kwargs):
                return args, kwargs

            type Alias[T = int, *Ts = *tuple[str, bytes], **P = [float]] = tuple[T, *Ts]
            """
        )

        identity_t = namespace["identity"].__type_params__[0]
        callback_p = namespace["callback"].__type_params__[0]
        alias_t, alias_ts, alias_p = namespace["Alias"].__type_params__
        self.assertIs(identity_t.__default__, int)
        self.assertEqual(callback_p.__default__, [str, int])
        self.assertIs(alias_t.__default__, int)
        self.assertEqual(alias_ts.__default__, next(iter(tuple[str, bytes])))
        self.assertEqual(alias_p.__default__, [float])

    def test_pep695_default_order_errors_cover_variadic_and_paramspec(self):
        with self.assertRaisesRegex(SyntaxError, "non-default type parameter"):
            run_source(
                """
                class BadTypeVarTuple[T = int, *Ts]:
                    pass
                """
            )
        with self.assertRaisesRegex(SyntaxError, "non-default type parameter"):
            run_source(
                """
                class BadParamSpec[T = int, **P]:
                    pass
                """
            )

    def test_lazy_defaults_cover_paramspec_typevartuple_and_class_scope(self):
        namespace = run_source(
            """
            class Outer:
                Later = tuple[str, bytes]

                class Inner[T = Later]:
                    pass

            class Callback[**P = LaterArgs]:
                pass

            class Spread[*Ts = *LaterTuple]:
                pass
            """
        )

        inner_t = namespace["Outer"].Inner.__type_params__[0]
        self.assertEqual(inner_t.__default__, tuple[str, bytes])

        callback_p = namespace["Callback"].__type_params__[0]
        spread_ts = namespace["Spread"].__type_params__[0]
        with self.assertRaises(NameError):
            callback_p.__default__
        with self.assertRaises(NameError):
            spread_ts.__default__

        namespace["LaterArgs"] = [int, str]
        namespace["LaterTuple"] = tuple[int, str]
        self.assertEqual(callback_p.__default__, [int, str])
        self.assertEqual(spread_ts.__default__, next(iter(namespace["LaterTuple"])))

    def test_typing_private_default_branches_are_exercised(self):
        importlib.reload(typing)

        required = typing.TypeVar("Required")
        defaulted = typing.TypeVar("Defaulted", default=int)

        class Pair(typing.Generic[required, defaulted]):
            pass

        typing._check_generic_specialization(Pair, (str,))
        with self.assertRaisesRegex(TypeError, "Too few"):
            typing._check_generic_specialization(Pair, ())
        with self.assertRaisesRegex(TypeError, "Too many"):
            typing._check_generic_specialization(Pair, (str, int, bytes))

        unpacked = typing.Unpack[tuple[str, bytes]]
        self.assertEqual(typing._unpack_args(int, unpacked), [int, str, bytes])

        alias = type("Alias", (), {"__parameters__": (defaulted, required)})()
        self.assertEqual(defaulted.__typing_prepare_subst__(alias, (str,)), (str,))
        self.assertEqual(defaulted.__typing_prepare_subst__(alias, ()), (int,))
        with self.assertRaisesRegex(TypeError, "Too few arguments"):
            required.__typing_prepare_subst__(alias, ())
        with self.assertRaises(AttributeError):
            defaulted.__typing_prepare_subst__(object(), ())
        with self.assertRaises(TypeError):
            defaulted.__typing_prepare_subst__(alias, object())

    def test_runtime_constructor_wrappers_cover_optional_keywords(self):
        full_typevar = typing.TypeVar(
            "FullTypeVar",
            bound=object,
            default=int,
            covariant=False,
            contravariant=False,
            infer_variance=True,
        )
        self.assertIs(full_typevar.__bound__, object)
        self.assertIs(full_typevar.__default__, int)
        self.assertTrue(full_typevar.__infer_variance__)

        full_paramspec = typing.ParamSpec(
            "FullParamSpec",
            bound=object,
            default=[str, int],
            covariant=False,
            contravariant=False,
            infer_variance=True,
        )
        self.assertIs(full_paramspec.__bound__, object)
        self.assertEqual(full_paramspec.__default__, [str, int])
        self.assertTrue(full_paramspec.__infer_variance__)

        plain_tuple = typing.TypeVarTuple("PlainTuple")
        default_tuple = typing.TypeVarTuple("DefaultTuple", default=(str, bytes))
        self.assertIs(plain_tuple.__default__, typing.NoDefault)
        self.assertEqual(default_tuple.__default__, (str, bytes))

        nodefault = typing.NoDefault
        self.assertEqual(repr(nodefault), "typing.NoDefault")
        self.assertEqual(nodefault.__reduce__(), "NoDefault")


if __name__ == "__main__":
    unittest.main()
