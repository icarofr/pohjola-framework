#!/usr/bin/env bun
/**
 * Run an agent eval.
 *
 * Usage:
 *   bun evals/run-eval.js <name>           # show the prompt
 *   bun evals/run-eval.js <name> --check   # run assertions
 *   bun evals/run-eval.js                  # list available evals
 */
import { join } from "node:path";
import { Glob } from "bun";
import { exists, readText, run } from "../scripts/lib/repo.js";

const EVALS_ROOT = join(import.meta.dir, "evals");

function listEvals() {
  const g = new Glob("*/PROMPT.md");
  return [...g.scanSync({ cwd: EVALS_ROOT })]
    .map((p) => p.replace(/\/PROMPT\.md$/, ""))
    .sort();
}

const args = process.argv.slice(2);

if (args.length < 1) {
  console.log("Available evals:");
  for (const name of listEvals()) {
    console.log(`  ${name}`);
  }
  process.exit(0);
}

const evalName = args[0];
const checkMode = args[1] === "--check";
const evalDir = join(EVALS_ROOT, evalName);

if (!(await exists(join(evalDir, "PROMPT.md")))) {
  console.error(`Eval not found: ${evalName}`);
  console.error(`Available: ${listEvals().join(" ")}`);
  process.exit(1);
}

if (checkMode) {
  console.log(`Checking: ${evalName}`);
  console.log("");
  const checkJs = join(evalDir, "check.js");
  const checkSh = join(evalDir, "check.sh");
  if (await exists(checkJs)) {
    run(["bun", checkJs]);
  } else if (await exists(checkSh)) {
    run(["bash", checkSh]);
  } else {
    console.error(`No check.js or check.sh in ${evalDir}`);
    process.exit(1);
  }
}

const promptPath = join(evalDir, "PROMPT.md");
console.log("=== Prompt ===");
console.log("");
console.log(await readText(promptPath));
console.log("");
console.log("=== Instructions ===");
console.log("1. Read the prompt above");
console.log("2. Implement the change in this repo");
console.log(`3. Run: bun evals/run-eval.js ${evalName} --check`);
console.log("4. All checks must pass. Fix and re-check if any fail.");
console.log("5. Then run: make check");
