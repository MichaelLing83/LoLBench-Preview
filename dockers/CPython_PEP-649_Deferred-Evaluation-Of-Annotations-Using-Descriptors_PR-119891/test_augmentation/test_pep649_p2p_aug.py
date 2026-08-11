from fractions import Fraction
import math
import statistics
import unittest


class PEP649P2PAugTest(unittest.TestCase):
    def test_math_fsum_preserves_small_residual(self):
        self.assertEqual(math.fsum([1e100, 1.0, -1e100]), 1.0)

    def test_statistics_mean_preserves_fraction_type(self):
        self.assertEqual(
            statistics.mean([Fraction(1, 3), Fraction(2, 3)]),
            Fraction(1, 2),
        )
