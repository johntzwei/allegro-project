// Enable user-level Task Observer guidance and a SessionStart hook.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

const { values } = parseArgs({ options: {
  agent: { type: "string" },
  "config-dir": { type: "string" },
  "skill-dir": { type: "string" },
  workspace: { type: "string" },
} });
if (!["claude-code", "codex"].includes(values.agent)) {
  throw new Error("Use --agent claude-code or --agent codex");
}
const claude = values.agent === "claude-code";
const configDir = path.resolve(values["config-dir"] || (claude
  ? process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), ".claude")
  : process.env.CODEX_HOME || path.join(os.homedir(), ".codex")));
const candidates = claude ? [path.join(configDir, "skills/task-observer")]
  : [path.join(os.homedir(), ".agents/skills/task-observer"),
    path.join(configDir, "skills/task-observer")];
const skillDir = path.resolve(values["skill-dir"] || candidates.find((p) =>
  fs.existsSync(path.join(p, "SKILL.md"))) || candidates[0]);
if (!fs.existsSync(path.join(skillDir, "scripts/new-observation.sh"))) {
  throw new Error(`Install the complete task-observer skill at ${skillDir}`);
}
const reference = fs.readFileSync(
  path.join(skillDir, "references/environments.md"), "utf8",
);
const upstream = reference.match(
  /### The activation block\s+```text\s*([\s\S]*?)```/,
);
if (!upstream || !upstream[1].includes("[ABSOLUTE PATH]")) {
  throw new Error("Task Observer's activation template needs review");
}
const hooksDir = path.join(configDir, "hooks");
const ownConfig = path.join(hooksDir, "task-observer.json");
const previous = fs.existsSync(ownConfig)
  ? JSON.parse(fs.readFileSync(ownConfig, "utf8")) : {};
const existingRoot = [".claude", ".codex"].map((name) =>
  path.join(os.homedir(), name)).find((p) =>
  fs.existsSync(path.join(p, "skill-observations")));
const workspace = path.resolve(values.workspace ||
  process.env.TASK_OBSERVER_WORKSPACE || previous.workspace ||
  existingRoot || path.join(os.homedir(), ".task-observer"));
const portable = (p) => p.replaceAll("\\", "/");
const activation = upstream[1].trim()
  .replaceAll("[ABSOLUTE PATH]", portable(workspace)) + `

This user-level default applies to interactive and automated sessions.
Keep existing host permissions and approval requirements.
If logging is unavailable in a restricted or unattended run, include
pending observations in the task output and continue the primary task.
Never apply a proposed skill change without the user's approval.
`;
const start = "<!-- task-observer:managed:start -->";
const end = "<!-- task-observer:managed:end -->";
const instructionFile = path.join(configDir,
  claude ? "CLAUDE.md" : "AGENTS.md");
let guidance = fs.existsSync(instructionFile)
  ? fs.readFileSync(instructionFile, "utf8") : "";
const block = `${start}\n## Task Observer (always on)\n\n` +
  activation.trim() + `\n${end}`;
if (guidance.includes(start) || guidance.includes(end)) {
  if (guidance.split(start).length !== 2 ||
      guidance.split(end).length !== 2 ||
      guidance.indexOf(start) > guidance.indexOf(end)) {
    throw new Error("Repair the incomplete Task Observer guidance block");
  }
  const before = guidance.split(start)[0];
  const after = guidance.split(end)[1];
  guidance = before + block + after;
} else {
  guidance += (guidance ? (guidance.endsWith("\n") ? "\n" : "\n\n") : "") +
    block + "\n";
}
const settingsFile = path.join(configDir,
  claude ? "settings.json" : "hooks.json");
const settings = fs.existsSync(settingsFile)
  ? JSON.parse(fs.readFileSync(settingsFile, "utf8").replace(/^\uFEFF/, ""))
  : {};
if (!settings || typeof settings !== "object" || Array.isArray(settings)) {
  throw new Error(`Expected a JSON object in ${settingsFile}`);
}
settings.hooks ??= {};
if (typeof settings.hooks !== "object" || Array.isArray(settings.hooks)) {
  throw new Error(`Expected a hooks object in ${settingsFile}`);
}
const hookPath = path.join(hooksDir, "task-observer-session-start.cjs");
const shellQuote = (p) => "'" + portable(p).replaceAll("'", "'\\''") + "'";
const command = `${shellQuote(process.execPath)} ${shellQuote(hookPath)}`;
const handler = { type: "command", command, timeout: 10 };
if (!claude && process.platform === "win32") {
  const psQuote = (p) => "'" + portable(p).replaceAll("'", "''") + "'";
  handler.commandWindows =
    `& ${psQuote(process.execPath)} ${psQuote(hookPath)}`;
}
let found = false;
const groups = settings.hooks.SessionStart || [];
if (!Array.isArray(groups)) {
  throw new Error("SessionStart must be an array");
}
settings.hooks.SessionStart = groups.map((group) => ({
  ...group,
  hooks: group.hooks.flatMap((entry) => {
    if (!entry.command?.includes("task-observer-session-start.cjs")) {
      return [entry];
    }
    if (found) return [];
    found = true;
    return [handler];
  }),
})).filter((group) => group.hooks.length);
if (!found) settings.hooks.SessionStart.push({ hooks: [handler] });

function writeChanged(destination, content) {
  const exists = fs.existsSync(destination);
  if (exists && fs.readFileSync(destination, "utf8") === content) return;
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  const backup = destination + ".before-task-observer";
  if (exists && !fs.existsSync(backup)) fs.copyFileSync(destination, backup);
  const temporary = destination + `.tmp-${process.pid}`;
  fs.writeFileSync(temporary, content, { mode: 0o600 });
  fs.renameSync(temporary, destination);
}
const sourceDir = path.dirname(fileURLToPath(import.meta.url));
// Validate everything before changing existing host configuration.
fs.mkdirSync(workspace, { recursive: true, mode: 0o700 });
writeChanged(hookPath, fs.readFileSync(
  path.join(sourceDir, "task_observer_session_start.cjs"), "utf8",
));
writeChanged(ownConfig, JSON.stringify({
  agent: values.agent, skillDir, workspace, activation,
}, null, 2) + "\n");
writeChanged(instructionFile, guidance);
writeChanged(settingsFile, JSON.stringify(settings, null, 2) + "\n");
console.log(`Task Observer default enabled for ${values.agent}`);
console.log(`Shared observation workspace: ${workspace}`);
if (!claude) {
  console.log("Review and trust the new hook with /hooks in Codex.");
}
