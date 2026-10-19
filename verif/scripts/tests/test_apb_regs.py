"""Run the timer regression against both maintained APB RTL variants."""
from pathlib import Path
import subprocess
import tempfile
import unittest


COURSE = Path(__file__).resolve().parents[2]


class ApbTests(unittest.TestCase):
    def test_zero_strobe_writes(self):
        for variant in ("sb_apb_regs.sv", "sanity/sb_apb_regs.sv"):
            with self.subTest(variant=variant), tempfile.TemporaryDirectory() as tmp:
                binary = Path(tmp) / "simv"
                compiled = subprocess.run(
                    ["iverilog", "-g2012", "-s", "apb_zero_strobe_tb", "-o", str(binary),
                     str(COURSE / "projects/apb_regs/rtl" / variant),
                     str(Path(__file__).with_name("apb_zero_strobe_tb.sv"))],
                    capture_output=True, text=True, timeout=30,
                )
                self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
                result = subprocess.run(["vvp", str(binary)], capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("PASS: APB", result.stdout)


if __name__ == "__main__":
    unittest.main()
