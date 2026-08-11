import os
import pathlib
import pickle
import shutil
import sys
import tempfile
import unittest
from datetime import datetime, timedelta
from unittest import mock

from test.test_zoneinfo import _support as zoneinfo_support
from test.test_zoneinfo import test_zoneinfo as zoneinfo_fixture


PY_ZONEINFO, C_ZONEINFO = zoneinfo_support.get_modules()


class ZoneInfoAugTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tempdir = pathlib.Path(tempfile.mkdtemp(prefix="zoneinfo-aug-"))
        cls.data = zoneinfo_fixture.ZoneInfoData(
            zoneinfo_fixture.ZONEINFO_JSON, cls.tempdir / "tzdb"
        )
        cls.zone_builder = zoneinfo_fixture.WeirdZoneTest(
            methodName="test_one_zone_dst"
        )

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tempdir)

    def tearDown(self):
        for _name, module in self._modules():
            module.ZoneInfo.clear_cache()
            module.reset_tzpath([str(self.data.tzpath)])

    def _modules(self):
        return (("py", PY_ZONEINFO), ("c", C_ZONEINFO))

    def _configure(self, module, tzpath=None):
        module.ZoneInfo.clear_cache()
        module.reset_tzpath(tzpath if tzpath is not None else [str(self.data.tzpath)])
        module.ZoneInfo.clear_cache()

    def _copy_zone(self, key, destination):
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(self.data.path_from_key(key), destination)

    def test_constructor_cache_and_targeted_clear_cache_contracts(self):
        for name, module in self._modules():
            with self.subTest(module=name):
                self._configure(module)
                zone = module.ZoneInfo

                utc_first = zone("UTC")
                utc_second = zone("UTC")
                self.assertIs(utc_first, utc_second)

                uncached_utc = zone.no_cache("UTC")
                self.assertIsNot(uncached_utc, utc_first)
                self.assertEqual(uncached_utc.key, "UTC")

                los_angeles_first = zone("America/Los_Angeles")
                zone.clear_cache(only_keys=["UTC"])

                utc_third = zone("UTC")
                los_angeles_second = zone("America/Los_Angeles")
                self.assertIsNot(utc_third, utc_first)
                self.assertIs(los_angeles_second, los_angeles_first)

    def test_from_file_and_no_cache_pickle_contracts(self):
        for name, module in self._modules():
            with self.subTest(module=name), zoneinfo_support.set_zoneinfo_module(module):
                self._configure(module)
                zone = module.ZoneInfo

                primary = zone("UTC")
                uncached = zone.no_cache("UTC")
                roundtrip = pickle.loads(pickle.dumps(uncached))
                self.assertIsNot(roundtrip, uncached)
                self.assertIsNot(roundtrip, primary)

                with open(self.data.path_from_key("UTC"), "rb") as f:
                    from_file = zone.from_file(f, key="UTC")

                with self.assertRaises(pickle.PicklingError):
                    pickle.dumps(from_file)

    def test_tzpath_order_env_reset_and_key_validation(self):
        first = self.tempdir / "order-a"
        second = self.tempdir / "order-b"
        key = "Aug/Zone"
        self._copy_zone("UTC", first / key)
        self._copy_zone("America/Los_Angeles", second / key)

        escaped_root = self.tempdir / "escape"
        self._copy_zone("UTC", escaped_root / "outside" / "UTC")
        (escaped_root / "tz").mkdir(parents=True, exist_ok=True)

        for name, module in self._modules():
            with self.subTest(module=name):
                self._configure(module, [str(first), str(second)])
                loaded = module.ZoneInfo(key)
                self.assertEqual(
                    datetime(2020, 1, 1, tzinfo=loaded).utcoffset(), timedelta(0)
                )

                with mock.patch.dict(
                    os.environ,
                    {"PYTHONTZPATH": os.pathsep.join([str(second), str(first)])},
                ):
                    module.reset_tzpath()
                    self.assertEqual(module.TZPATH, (str(second), str(first)))

                module.reset_tzpath([str(first)])
                self.assertEqual(module.TZPATH, (str(first),))

                module.reset_tzpath([str(escaped_root / "tz")])
                module.ZoneInfo.clear_cache()
                with self.assertRaises(ValueError):
                    module.ZoneInfo("../outside/UTC")

    def test_tzdata_fallback_uses_zoneinfo_package_namespace(self):
        package_root = self.tempdir / "fake-tzdata"
        resource = package_root / "tzdata" / "zoneinfo" / "Aug" / "Fallback"
        self._copy_zone("UTC", resource)
        for init_path in [
            package_root / "tzdata" / "__init__.py",
            package_root / "tzdata" / "zoneinfo" / "__init__.py",
            package_root / "tzdata" / "zoneinfo" / "Aug" / "__init__.py",
        ]:
            init_path.parent.mkdir(parents=True, exist_ok=True)
            init_path.write_text("", encoding="utf-8")

        old_path = list(sys.path)
        sys.path.insert(0, str(package_root))
        try:
            for module_name in list(sys.modules):
                if module_name == "tzdata" or module_name.startswith("tzdata."):
                    del sys.modules[module_name]

            for name, module in self._modules():
                with self.subTest(module=name):
                    self._configure(module, [])
                    loaded = module.ZoneInfo("Aug/Fallback")
                    self.assertEqual(
                        datetime(2020, 1, 1, tzinfo=loaded).utcoffset(),
                        timedelta(0),
                    )
        finally:
            sys.path[:] = old_path
            for module_name in list(sys.modules):
                if module_name == "tzdata" or module_name.startswith("tzdata."):
                    del sys.modules[module_name]

    def test_future_tzif_rules_dst_and_fold_semantics(self):
        dst = zoneinfo_fixture.ZoneOffset(
            "DST", zoneinfo_fixture.ONE_H, zoneinfo_fixture.ONE_H
        )
        dst_only_file = self.zone_builder.construct_zone(
            [zoneinfo_fixture.ZoneTransition(datetime(1970, 1, 1), dst, dst)],
            "STD0DST-1,0/0,J365/25",
        )

        for name, module in self._modules():
            with self.subTest(module=name):
                self._configure(module)
                los_angeles = module.ZoneInfo("America/Los_Angeles")

                summer = datetime(2040, 7, 1, 12, tzinfo=los_angeles)
                winter = datetime(2040, 1, 1, 12, tzinfo=los_angeles)
                self.assertEqual(summer.utcoffset(), -timedelta(hours=7))
                self.assertEqual(summer.dst(), timedelta(hours=1))
                self.assertEqual(winter.utcoffset(), -timedelta(hours=8))
                self.assertEqual(winter.dst(), timedelta(0))

                fold_first = datetime(
                    2020, 11, 1, 1, 30, fold=0, tzinfo=los_angeles
                )
                fold_second = datetime(
                    2020, 11, 1, 1, 30, fold=1, tzinfo=los_angeles
                )
                self.assertEqual(fold_first.utcoffset(), -timedelta(hours=7))
                self.assertEqual(fold_second.utcoffset(), -timedelta(hours=8))
                self.assertEqual(fold_first.dst(), timedelta(hours=1))
                self.assertEqual(fold_second.dst(), timedelta(0))

                dst_only_file.seek(0)
                dst_zone = module.ZoneInfo.from_file(dst_only_file, key="Aug/DST")
                for dt in [
                    datetime(1900, 3, 1, tzinfo=dst_zone),
                    datetime(2010, 11, 3, tzinfo=dst_zone),
                    datetime(2040, 1, 1, tzinfo=dst_zone),
                ]:
                    with self.subTest(module=name, dt=dt):
                        self.assertEqual(dt.utcoffset(), timedelta(hours=1))
                        self.assertEqual(dt.dst(), timedelta(hours=1))

    def test_string_representation_and_not_found_keyerror_contract(self):
        for name, module in self._modules():
            with self.subTest(module=name):
                self._configure(module)
                zone = module.ZoneInfo("Pacific/Kiritimati")
                self.assertEqual(str(zone), "Pacific/Kiritimati")
                self.assertIn("Pacific/Kiritimati", repr(zone))

                try:
                    module.ZoneInfo("Invalid/Zone")
                except KeyError as exc:
                    self.assertIsInstance(exc, module.ZoneInfoNotFoundError)
                else:
                    self.fail("ZoneInfoNotFoundError was not raised")

    def test_reset_tzpath_uses_sysconfig_default_when_environment_unset(self):
        expected = ("/opt/zoneinfo", "/srv/share/zoneinfo")
        old_env = os.environ.pop("PYTHONTZPATH", None)
        try:
            for name, module in self._modules():
                with self.subTest(module=name):
                    with mock.patch(
                        "sysconfig.get_config_var",
                        return_value=os.pathsep.join(expected),
                    ):
                        module.reset_tzpath()
                    self.assertEqual(module.TZPATH, expected)
        finally:
            if old_env is not None:
                os.environ["PYTHONTZPATH"] = old_env


if __name__ == "__main__":
    unittest.main()
