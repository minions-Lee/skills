#!/usr/bin/env node
/**
 * launchd launcher - called by launchd instead of /bin/bash
 * Runs the full RSS digest pipeline via run.sh
 */
const { spawnSync } = require("child_process");
const path = require("path");

const scriptDir = path.dirname(__filename);
const runSh = path.join(scriptDir, "run.sh");

const result = spawnSync("/bin/bash", [runSh, "pipeline"], {
  stdio: "inherit",
  env: { ...process.env },
});

process.exit(result.status ?? 1);
