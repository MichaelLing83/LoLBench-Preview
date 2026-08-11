import datetime
import pickle
import sysconfig
import unittest


class ZoneInfoStabilityAugTest(unittest.TestCase):
    def test_datetime_fixed_timezone_arithmetic_is_unchanged(self):
        fixed = datetime.timezone(-datetime.timedelta(hours=5), "EST")
        start = datetime.datetime(2020, 3, 8, 1, 30, tzinfo=fixed)
        later = start + datetime.timedelta(hours=2, minutes=15)

        self.assertEqual(later.utcoffset(), -datetime.timedelta(hours=5))
        self.assertEqual(
            later.astimezone(datetime.timezone.utc),
            datetime.datetime(2020, 3, 8, 8, 45, tzinfo=datetime.timezone.utc),
        )

    def test_datetime_fold_flag_is_preserved_for_plain_datetime(self):
        first = datetime.datetime(2020, 11, 1, 1, 30, fold=0)
        second = first.replace(fold=1)

        self.assertEqual(first.fold, 0)
        self.assertEqual(second.fold, 1)
        self.assertEqual(second.replace(minute=45).fold, 1)
        self.assertEqual(first, second)

    def test_pickle_roundtrip_for_builtin_timezone_is_unchanged(self):
        fixed = datetime.timezone(datetime.timedelta(hours=5, minutes=30), "IST")
        dt = datetime.datetime(2020, 1, 2, 3, 4, 5, tzinfo=fixed)
        restored = pickle.loads(pickle.dumps(dt))

        self.assertEqual(restored, dt)
        self.assertEqual(restored.tzname(), "IST")
        self.assertEqual(restored.utcoffset(), datetime.timedelta(hours=5, minutes=30))

    def test_sysconfig_public_paths_are_unchanged(self):
        paths = sysconfig.get_paths()

        self.assertIn("stdlib", paths)
        self.assertIsInstance(paths["stdlib"], str)
        self.assertTrue(paths["stdlib"])
        self.assertIsInstance(sysconfig.get_config_var("prefix"), str)


if __name__ == "__main__":
    unittest.main()
