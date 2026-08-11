import configparser
import datetime
import decimal
import io
import json
import unittest


class StdlibStabilityAugTest(unittest.TestCase):
    def test_json_parse_float_callback_is_unchanged(self):
        seen = []

        def parse_float(text):
            seen.append(text)
            return decimal.Decimal(text)

        parsed = json.loads('{"low": 1.25, "items": [2.5]}', parse_float=parse_float)
        self.assertEqual(parsed, {"low": decimal.Decimal("1.25"), "items": [decimal.Decimal("2.5")]})
        self.assertEqual(seen, ["1.25", "2.5"])

    def test_configparser_defaults_and_interpolation_are_unchanged(self):
        parser = configparser.ConfigParser()
        parser.read_file(
            io.StringIO(
                "[DEFAULT]\n"
                "root = /srv/app\n"
                "\n"
                "[service]\n"
                "path = %(root)s/bin\n"
                "enabled = yes\n"
            )
        )

        self.assertEqual(parser.get("service", "path"), "/srv/app/bin")
        self.assertTrue(parser.getboolean("service", "enabled"))
        self.assertEqual(parser.sections(), ["service"])

    def test_datetime_fromisoformat_timezone_offsets_are_unchanged(self):
        dt = datetime.datetime.fromisoformat("2022-01-01T00:00:00+02:30")
        self.assertEqual(dt.utcoffset(), datetime.timedelta(hours=2, minutes=30))

        negative = datetime.datetime.fromisoformat("2022-01-01T00:00:00-07:00")
        self.assertEqual(negative.utcoffset(), -datetime.timedelta(hours=7))


if __name__ == "__main__":
    unittest.main()
