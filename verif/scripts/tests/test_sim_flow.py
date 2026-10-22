"""Exercise make run using simulator transcripts, without a commercial license."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


COURSE = Path(__file__).resolve().parents[2]
PASS = "UVM_INFO @ 200: reporter [RESULT] *** TEST PASSED ***\n"
CLEAN = "UVM_ERROR : 0\nUVM_FATAL : 0\n"


class RunTests(unittest.TestCase):
    def run_make(self, log, exit_code):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            simulator = root / "simulator.py"
            simulator.write_text(f"import sys\nsys.stdout.write({log!r})\nsys.exit({exit_code})\n")
            stamp = root / ".built"
            stamp.touch()
            result = subprocess.run(
                ["make", "--no-print-directory", "run", "SIM=vcs", "TEST=fifo_hello_test",
                 f"PYTHON={sys.executable}", f"BUILD={root / 'build'}", f"STAMP={stamp}", "DEPS=",
                 f'RUN_TMPL="{sys.executable}" "{simulator}"'],
                cwd=COURSE / "projects/sync_fifo", capture_output=True, text=True, timeout=30,
            )
            saved = root / "build/runs/fifo_hello_test_s1/sim.log"
            self.assertTrue(saved.exists(), result.stdout + result.stderr)
            self.assertEqual(saved.read_text(), log)
            return result

    def test_clean_runs_pass(self):
        for prefix in ("", "# "):
            with self.subTest(prefix=prefix):
                log = "".join(prefix + line + "\n" for line in (PASS + CLEAN).splitlines())
                result = self.run_make(log, 0)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_failed_or_incomplete_runs_fail(self):
        cases = {
            "nonzero exit after pass": (PASS + CLEAN, 1),
            "UVM error count": (PASS + "UVM_ERROR : 1\nUVM_FATAL : 0\n", 0),
            "UVM fatal count": (PASS + "UVM_ERROR : 0\nUVM_FATAL : 1\n", 0),
            "fatal after clean summary": (PASS + CLEAN + "UVM_FATAL @ 201: reporter [FINAL] failed\n", 0),
            "Questa error after summary": (PASS + CLEAN + "# UVM_ERROR @ 201: reporter [FINAL] failed\n", 0),
            "missing summary": (PASS, 0),
            "missing pass": (CLEAN, 0),
            "fatal after pass with failed exit": (PASS + "UVM_FATAL @ 201: reporter [FINAL] failed\n", 1),
        }
        for name, (log, exit_code) in cases.items():
            with self.subTest(name=name):
                result = self.run_make(log, exit_code)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
