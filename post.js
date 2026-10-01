const core = require("@actions/core");
const fs   = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// ── Post-job cleanup ─────────────────────────────────────────────
// Remove any sensitive artefacts that steps may have left behind.

try {
  // 1. Remove the wrapper directory
  const wrapperDir = path.join(process.env.RUNNER_TEMP || "/tmp", ".vault-wrappers");
  if (fs.existsSync(wrapperDir)) {
    fs.rmSync(wrapperDir, { recursive: true, force: true });
  }

  // 2. Wipe the internal repo checkout (if present) to prevent
  //    subsequent steps or post-job hooks from reading source.
  const workspace = process.env.GITHUB_WORKSPACE || ".";
  const internalDir = path.join(workspace, "internal");
  if (fs.existsSync(internalDir)) {
    fs.rmSync(internalDir, { recursive: true, force: true });
  }

  // 3. Clear the MASTER_KEY from the environment file so that
  //    it is not carried into any runner-diagnostic bundle.
  const envFile = process.env.GITHUB_ENV;
  if (envFile && fs.existsSync(envFile)) {
    let content = fs.readFileSync(envFile, "utf8");
    content = content.replace(/^MASTER_KEY=.*$/m, "MASTER_KEY=REDACTED");
    fs.writeFileSync(envFile, content);
  }

  // 4. Overwrite log pad again
  process.stdout.write(" ".repeat(4096));

  core.info("Post job cleanup.");
} catch (err) {
  core.warning("post.js: " + err.message);
}
