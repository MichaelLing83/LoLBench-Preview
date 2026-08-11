import datetime
import decimal
import io
import unittest

import tomllib


class TomllibPublicApiAugTest(unittest.TestCase):
    def test_load_accepts_binary_file_objects_only(self):
        self.assertEqual(tomllib.load(io.BytesIO(b"answer = 42\n")), {"answer": 42})

        with self.assertRaises(TypeError):
            tomllib.load(io.StringIO("answer = 42\n"))

    def test_loads_accepts_str_and_rejects_bytes(self):
        self.assertEqual(tomllib.loads('name = "Ada"\n'), {"name": "Ada"})

        with self.assertRaises(TypeError):
            tomllib.loads(b'name = "Ada"\n')

    def test_parse_float_callback_is_observed_and_kept_scalar(self):
        seen = []

        def parse_float(text):
            seen.append(text)
            return decimal.Decimal(text)

        parsed = tomllib.loads("low = 1.25\nhigh = 2e3\n", parse_float=parse_float)
        self.assertEqual(parsed, {"low": decimal.Decimal("1.25"), "high": decimal.Decimal("2e3")})
        self.assertEqual(seen, ["1.25", "2e3"])

        for bad_value in ({}, []):
            with self.subTest(bad_value=type(bad_value).__name__):
                with self.assertRaises(ValueError):
                    tomllib.loads("x = 1.0\n", parse_float=lambda _text, value=bad_value: value)

    def test_duplicate_keys_and_frozen_namespaces_are_rejected(self):
        invalid_documents = [
            "a = 1\na = 2\n",
            "tbl = { x = 1, x = 2 }\n",
            "tbl = { x = 1 }\ntbl.y = 2\n",
            "a.b = 1\n[a]\nc = 2\n",
        ]
        for document in invalid_documents:
            with self.subTest(document=document):
                with self.assertRaises(tomllib.TOMLDecodeError):
                    tomllib.loads(document)

    def test_strings_comments_and_booleans_follow_toml_rules(self):
        invalid_documents = [
            's = "first\nsecond"\n',
            's = "\\uD800"\n',
            "x = 1 # bad" + chr(8) + "comment\n",
        ]
        for document in invalid_documents:
            with self.subTest(document=repr(document)):
                with self.assertRaises(tomllib.TOMLDecodeError):
                    tomllib.loads(document)

        self.assertIs(tomllib.loads("enabled = false\n")["enabled"], False)

    def test_arrays_datetimes_dates_and_non_decimal_integers(self):
        parsed = tomllib.loads(
            "values = [1, 2,]\n"
            "ts = 2022-01-01T00:00:00+02:30\n"
            "d = 2022-03-08\n"
            "mask = 0xff\n"
        )

        self.assertEqual(parsed["values"], [1, 2])
        self.assertEqual(parsed["ts"].utcoffset(), datetime.timedelta(hours=2, minutes=30))
        self.assertIsInstance(parsed["d"], datetime.date)
        self.assertNotIsInstance(parsed["d"], datetime.datetime)
        self.assertEqual(parsed["mask"], 255)


if __name__ == "__main__":
    unittest.main()
