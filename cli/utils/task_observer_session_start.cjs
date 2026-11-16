// Inject Task Observer activation and review state without changing logs.
const fs = require("node:fs");
const path = require("node:path");

const config = JSON.parse(
  fs.readFileSync(path.join(__dirname, "task-observer.json"), "utf8"),
);
const skillFile = path.join(config.skillDir, "SKILL.md");
const writer = path.join(config.skillDir, "scripts", "new-observation.sh");
let message;
if (!fs.existsSync(skillFile) || !fs.existsSync(writer)) {
  message = `Task Observer is missing at ${config.skillDir}. ` +
    "Report the activation failure; continue the user's primary task.";
} else {
  const observations = path.join(config.workspace, "skill-observations");
  const log = path.join(observations, "observation-log");
  const files = fs.existsSync(log) ? fs.readdirSync(log) : [];
  const open = files.filter((name) => name.endsWith(".md")).filter((name) =>
    /^status: open\s*$/m.test(fs.readFileSync(path.join(log, name), "utf8")),
  ).length;
  const reviewFile = path.join(observations, "last-review-date.txt");
  const last = fs.existsSync(reviewFile)
    ? fs.readFileSync(reviewFile, "utf8").trim() : "never";
  const cutoff = new Date(Date.now() - 7 * 86400000)
    .toISOString().slice(0, 10);
  const due = open > 0 && (last === "never" || last <= cutoff);
  message = config.activation + "\n\n" +
    `Load the installed skill from ${skillFile}.\n` +
    "Make the first tool call a batch that probes the pinned workspace " +
    "and loads Task Observer; run its Session Start Protocol.\n" +
    `${open} open observations in ${observations}; last review: ${last}.` +
    (due ? " A review is due; offer it." : "");
}
console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: message,
  },
}));
