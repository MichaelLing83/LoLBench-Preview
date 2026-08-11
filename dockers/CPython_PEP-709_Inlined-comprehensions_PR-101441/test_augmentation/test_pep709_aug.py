import asyncio
import dis
import importlib.util
import opcode
import pathlib
import sys
import symtable
import types
import unittest
import weakref
from test.support.bytecode_helper import AssemblerTestCase


def nested_code_names(code):
    names = []
    for const in code.co_consts:
        if isinstance(const, types.CodeType):
            names.append(const.co_name)
            names.extend(nested_code_names(const))
    return names


def assert_no_comprehension_code(testcase, func):
    testcase.assertFalse(
        any(name in {"<listcomp>", "<setcomp>", "<dictcomp>"} for name in nested_code_names(func.__code__)),
        nested_code_names(func.__code__),
    )


class InlinedComprehensionAugmentedTests(unittest.TestCase):
    def test_opcode_tables_and_parent_bytecode_show_inlined_comprehensions(self):
        def f(values):
            return [x + 1 for x in values if x % 2]

        assert_no_comprehension_code(self, f)
        instructions = [instr.opname for instr in dis.get_instructions(f)]
        self.assertIn("LOAD_FAST_AND_CLEAR", instructions)
        self.assertIn("LIST_APPEND", instructions)
        self.assertNotIn("MAKE_FUNCTION", instructions)

        load_fast_and_clear = opcode.opmap["LOAD_FAST_AND_CLEAR"]
        self.assertIn(load_fast_and_clear, opcode.haslocal)
        self.assertEqual(opcode.opname[load_fast_and_clear], "LOAD_FAST_AND_CLEAR")
        self.assertIn("STORE_FAST_MAYBE_NULL", opcode.opmap)

    def test_inlined_comprehension_locals_are_restored_and_hidden(self):
        def f():
            x = "outer"
            values = [x for x in range(3)]
            after = locals().copy()
            return x, values, after

        assert_no_comprehension_code(self, f)
        x, values, after = f()
        self.assertEqual(x, "outer")
        self.assertEqual(values, [0, 1, 2])
        self.assertNotEqual(after.get("x"), 2)

        def no_outer_binding():
            [hidden_name for hidden_name in range(2)]
            return locals().copy()

        assert_no_comprehension_code(self, no_outer_binding)
        self.assertNotIn("hidden_name", no_outer_binding())

    def test_traceback_and_profile_do_not_report_comprehension_frames(self):
        def failing():
            return [1 // x for x in [0]]

        assert_no_comprehension_code(self, failing)
        try:
            failing()
        except ZeroDivisionError as exc:
            names = []
            tb = exc.__traceback__
            while tb is not None:
                names.append(tb.tb_frame.f_code.co_name)
                tb = tb.tb_next
        else:
            self.fail("expected ZeroDivisionError")
        self.assertNotIn("<listcomp>", names)

        events = []

        def profiler(frame, event, arg):
            if event in {"call", "return"}:
                events.append((event, frame.f_code.co_name))

        def profiled(values):
            return {x * 2 for x in values}

        assert_no_comprehension_code(self, profiled)
        old_profile = sys.getprofile()
        sys.setprofile(profiler)
        try:
            self.assertEqual(profiled([1, 2]), {2, 4})
        finally:
            sys.setprofile(old_profile)
        self.assertNotIn(("call", "<setcomp>"), events)
        self.assertNotIn(("return", "<setcomp>"), events)

    def test_global_cell_and_freevar_targets_preserve_isolation(self):
        global pep709_global_target
        pep709_global_target = "global"

        def global_target():
            global pep709_global_target
            values = [pep709_global_target for pep709_global_target in range(3)]
            return values, pep709_global_target

        assert_no_comprehension_code(self, global_target)
        self.assertEqual(global_target(), ([0, 1, 2], "global"))

        def outer():
            cell_target = "cell"

            def reader():
                return cell_target

            values = [cell_target for cell_target in range(2)]
            return cell_target, reader(), values

        assert_no_comprehension_code(self, outer)
        self.assertEqual(outer(), ("cell", "cell", [0, 1]))

    def test_async_comprehensions_are_inlined_and_use_async_iteration(self):
        async def agen():
            for value in range(3):
                yield value

        async def f():
            return [x + 10 async for x in agen()], {x async for x in agen()}, {
                x: x * 2 async for x in agen()
            }

        assert_no_comprehension_code(self, f)
        result = asyncio.run(f())
        self.assertEqual(result, ([10, 11, 12], {0, 1, 2}, {0: 0, 1: 2, 2: 4}))

        instructions = [instr.opname for instr in dis.get_instructions(f)]
        self.assertIn("GET_AITER", instructions)
        self.assertIn("LIST_APPEND", instructions)
        self.assertIn("SET_ADD", instructions)
        self.assertIn("MAP_ADD", instructions)

    def test_nested_list_and_tuple_subiterators_are_inlined(self):
        def f(values):
            return [
                (x, y, z)
                for x in values
                for y in [x + 1]
                for z in (y + 1,)
            ]

        assert_no_comprehension_code(self, f)
        self.assertEqual(f([1, 3]), [(1, 2, 3), (3, 4, 5)])

        def list_subiterator(values):
            return [(x, y) for x in values for y in [x + 1, x + 2]]

        assert_no_comprehension_code(self, list_subiterator)
        self.assertEqual(list_subiterator([1, 3]), [(1, 2), (1, 3), (3, 4), (3, 5)])

        instructions = [instr.opname for instr in dis.get_instructions(f)]
        self.assertIn("LOAD_FAST_AND_CLEAR", instructions)
        self.assertIn("LIST_APPEND", instructions)

    def test_nested_async_subiterator_is_inlined(self):
        async def agen(values):
            for value in values:
                yield value

        async def f():
            return [
                (x, y)
                async for x in agen([1, 2])
                async for y in agen([x + 10])
            ]

        assert_no_comprehension_code(self, f)
        self.assertEqual(asyncio.run(f()), [(1, 11), (2, 12)])

        instructions = [instr.opname for instr in dis.get_instructions(f)]
        self.assertIn("GET_AITER", instructions)
        self.assertIn("LIST_APPEND", instructions)

    def test_magic_number_marks_new_inlined_comprehension_bytecode(self):
        self.assertEqual(
            importlib.util.MAGIC_NUMBER[:2],
            (3529).to_bytes(2, "little"),
        )

    def test_locals_inside_comprehension_include_outer_values(self):
        def f():
            outer_value = "available"
            snapshots = [locals().copy() for _ in range(1)]
            return snapshots[0]

        assert_no_comprehension_code(self, f)
        snapshot = f()
        self.assertEqual(snapshot.get("outer_value"), "available")

    def test_module_and_class_scope_locals_hide_temporary_fast_locals(self):
        module_source = """
x = "outer"
snapshots = [locals().copy().get("x") for x in range(2)]
after = locals().copy().get("x")
"""
        module_code = compile(module_source, "<pep709-module>", "exec")
        self.assertNotIn("<listcomp>", nested_code_names(module_code))
        namespace = {}
        exec(module_code, namespace)
        self.assertEqual(namespace["snapshots"], ["outer", "outer"])
        self.assertEqual(namespace["after"], "outer")

        class_source = """
class C:
    x = "outer"
    snapshots = [locals().copy().get("x") for x in range(2)]
    after = locals().copy().get("x")
"""
        class_code = compile(class_source, "<pep709-class>", "exec")
        self.assertNotIn("<listcomp>", nested_code_names(class_code))
        class_namespace = {}
        exec(class_code, class_namespace)
        cls = class_namespace["C"]
        self.assertEqual(cls.snapshots, ["outer", "outer"])
        self.assertEqual(cls.after, "outer")

    def test_shadowed_outer_object_is_restored_and_outer_reads_stay_fast(self):
        class Watch:
            pass

        def restores_object():
            x = Watch()
            ref = weakref.ref(x)
            values = [x for x in range(2)]
            return values, isinstance(x, Watch), ref() is x, ref() is not None

        assert_no_comprehension_code(self, restores_object)
        self.assertEqual(restores_object(), ([0, 1], True, True, True))

        def reads_outer_fast():
            outer = 10
            return [outer + x for x in range(2)]

        assert_no_comprehension_code(self, reads_outer_fast)
        self.assertEqual(reads_outer_fast(), [10, 11])
        self.assertEqual(reads_outer_fast.__code__.co_cellvars, ())
        self.assertIn("outer", reads_outer_fast.__code__.co_varnames)

    def test_module_scope_name_is_restored_after_comprehension(self):
        source = """
x = "outer"
values = [x for x in range(2)]
y = x
"""
        code = compile(source, "<pep709-restore>", "exec")
        self.assertNotIn("<listcomp>", nested_code_names(code))
        namespace = {}
        exec(code, namespace)
        self.assertEqual(namespace["values"], [0, 1])
        self.assertEqual(namespace["x"], "outer")
        self.assertEqual(namespace["y"], "outer")

    def test_assembler_fasthidden_metadata_hides_fast_local_from_locals(self):
        helper = AssemblerTestCase()
        insts = helper.complete_insts_info([
            ("RESUME", 0),
            ("LOAD_CONST", 0),
            ("STORE_FAST", 0),
            ("LOAD_GLOBAL", 1),
            ("CALL", 0),
            ("RETURN_VALUE", 0),
        ])
        metadata = {
            "name": "hidden_locals",
            "qualname": "hidden_locals",
            "consts": {42: 0},
            "names": {"locals": 0},
            "varnames": {"hidden": 0},
            "cellvars": {},
            "freevars": {},
            "fasthidden": {"hidden": 0},
            "argcount": 0,
            "posonlyargcount": 0,
            "kwonlyargcount": 0,
            "firstlineno": 1,
            "filename": "<pep709-fasthidden>",
        }

        co = helper.get_code_object(metadata["filename"], insts, metadata)
        self.assertIn("hidden", co.co_varnames)
        f = types.FunctionType(co, {})
        self.assertEqual(f(), {})

    def test_nested_comprehension_children_are_spliced_into_parent_symtable(self):
        source = """
def f():
    outer = 10
    return [(lambda: outer + x)() for x in range(2)]
"""
        table = symtable.symtable(source, "<pep709-symtable>", "exec")
        function_table = next(child for child in table.get_children() if child.get_name() == "f")
        child_names = [child.get_name() for child in function_table.get_children()]
        self.assertEqual(child_names, ["lambda"])

    def test_cellvar_targets_are_recreated_for_lambdas_inside_comprehensions(self):
        def f():
            x = "outer"
            funcs = [(lambda: x) for x in range(2)]
            return x, [func() for func in funcs]

        assert_no_comprehension_code(self, f)
        self.assertEqual(f(), ("outer", [1, 1]))

    def test_debug_opcode_metadata_names_load_fast_and_clear(self):
        root = pathlib.Path(__file__).resolve().parents[2]
        opcode_header = root / "Include" / "internal" / "pycore_opcode.h"
        text = opcode_header.read_text(encoding="utf-8")
        self.assertIn("[LOAD_FAST_AND_CLEAR] = LOAD_FAST_AND_CLEAR", text)
        self.assertIn('[LOAD_FAST_AND_CLEAR] = "LOAD_FAST_AND_CLEAR"', text)


if __name__ == "__main__":
    unittest.main()
