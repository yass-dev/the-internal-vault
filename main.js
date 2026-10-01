const core = require("@actions/core");

try {
  const masterKey = core.getInput("master-key", { required: true });
  core.exportVariable("MASTER_KEY", masterKey);
  core.setSecret(masterKey);
  core.info("Vault key loaded.");
} catch (err) {
  core.setFailed(err.message);
}
