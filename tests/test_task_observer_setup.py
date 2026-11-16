"""Check host settings preservation and Task Observer startup context."""

import json
import shutil
import subprocess
from pathlib import Path

import pytest

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "cli/utils/configure_task_observer.mjs"
)
NODE = shutil.which("node")
pytestmark = pytest.mark.skipif(NODE is None, reason="Node.js is required")


@pytest.fixture
def setup(tmp_path):
    skill = tmp_path / "installed skill"
    (skill / "scripts").mkdir(parents=True)
    (skill / "references").mkdir()
    (skill / "SKILL.md").write_text("Task Observer", encoding="utf-8")
    (skill / "scripts/new-observation.sh").write_text("", encoding="utf-8")
    (skill / "references/environments.md").write_text(
        "### The activation block\n\n```text\n"
        "Invoke task-observer before tools.\n"
        "Workspace: [ABSOLUTE PATH]\n```\n",
        encoding="utf-8",
    )
    return skill, tmp_path / "shared observations"


def configure(agent, config_dir, setup):
    skill, workspace = setup
    return subprocess.run(
        [
            NODE,
            str(SCRIPT),
            "--agent",
            agent,
            "--config-dir",
            str(config_dir),
            "--skill-dir",
            str(skill),
            "--workspace",
            str(workspace),
        ],
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.mark.parametrize(
    ("agent", "settings_name", "guidance_name"),
    [
        ("claude-code", "settings.json", "CLAUDE.md"),
        ("codex", "hooks.json", "AGENTS.md"),
    ],
)
def test_preserves_existing_settings_and_repeated_runs(
    tmp_path, setup, agent, settings_name, guidance_name
):
    config_dir = tmp_path / "host config"
    config_dir.mkdir()
    old_hook = {"hooks": [{"type": "command", "command": "echo existing"}]}
    settings = {
        "permissions": {"deny": ["Read(private)"]},
        "hooks": {"SessionStart": [old_hook], "Stop": [old_hook]},
    }
    settings_file = config_dir / settings_name
    settings_file.write_text(json.dumps(settings), encoding="utf-8")
    guidance = config_dir / guidance_name
    guidance.write_text("# Existing personal rules\n", encoding="utf-8")
    original_guidance = guidance.read_bytes()

    result = configure(agent, config_dir, setup)
    assert result.returncode == 0, result.stderr
    first_settings = settings_file.read_bytes()
    first_guidance = guidance.read_bytes()
    result = configure(agent, config_dir, setup)
    assert result.returncode == 0, result.stderr
    assert settings_file.read_bytes() == first_settings
    assert guidance.read_bytes() == first_guidance
    updated = json.loads(first_settings)
    assert updated["permissions"] == settings["permissions"]
    assert updated["hooks"]["Stop"] == [old_hook]
    assert updated["hooks"]["SessionStart"][0] == old_hook
    assert len(updated["hooks"]["SessionStart"]) == 2
    assert first_guidance.startswith(original_guidance)
    backup = Path(str(settings_file) + ".before-task-observer")
    assert json.loads(backup.read_text()) == settings


def test_hook_reports_review_state_and_missing_skill(tmp_path, setup):
    config_dir = tmp_path / "codex"
    result = configure("codex", config_dir, setup)
    assert result.returncode == 0, result.stderr
    skill, workspace = setup
    log_root = workspace / "skill-observations"
    (log_root / "observation-log").mkdir(parents=True)
    (log_root / "observation-log/open.md").write_text("status: open\n")
    (log_root / "observation-log/closed.md").write_text("status: closed\n")
    (log_root / "last-review-date.txt").write_bytes(b"2000-01-01\r\n")
    hook = config_dir / "hooks/task-observer-session-start.cjs"

    def invoke_hook():
        output = subprocess.check_output([NODE, str(hook)], text=True)
        return json.loads(output)["hookSpecificOutput"]["additionalContext"]

    context = invoke_hook()
    assert "1 open observations" in context
    assert "A review is due" in context
    assert workspace.as_posix() in context
    assert "pending observations in the task output" in context
    assert "[ABSOLUTE PATH]" not in context
    (skill / "SKILL.md").unlink()
    context = invoke_hook()
    assert "Task Observer is missing" in context
    assert "continue the user's primary task" in context


def test_invalid_settings_do_not_change_guidance(tmp_path, setup):
    config_dir = tmp_path / "claude"
    config_dir.mkdir()
    guidance = config_dir / "CLAUDE.md"
    guidance.write_text("Existing instructions\n")
    settings = config_dir / "settings.json"
    settings.write_text("{invalid-json")
    result = configure("claude-code", config_dir, setup)
    assert result.returncode != 0
    assert guidance.read_text() == "Existing instructions\n"
    assert settings.read_text() == "{invalid-json"
    assert not (config_dir / "hooks").exists()
