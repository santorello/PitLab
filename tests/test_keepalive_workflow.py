from pathlib import Path
import unittest


WORKFLOW = Path(__file__).parents[1] / ".github" / "workflows" / "main.yml"


class KeepaliveWorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_issue_body_does_not_escape_the_run_block(self) -> None:
        self.assertNotIn("\nRun: $RUN_URL", self.workflow)

    def test_keepalive_is_scheduled_daily(self) -> None:
        self.assertIn('- cron: "17 6 * * *"', self.workflow)

    def test_inline_run_value_has_no_unquoted_yaml_colon(self) -> None:
        notify_line = next(
            line for line in self.workflow.splitlines() if "gh issue create" in line
        )
        self.assertNotIn(" Run: ", notify_line)


if __name__ == "__main__":
    unittest.main()
