#!/usr/bin/env bun
/**
 * Eval 10: UI archetypes — delegates to canonical policy enforcement.
 */
import { ROOT, run } from "../../../scripts/lib/repo.js";

process.chdir(ROOT);

console.log("Eval 10: UI archetypes & theme (policy tier)");
console.log("");

run(["make", "gate"]);
run(["bun", "scripts/verify-theme.js"]);

console.log("");
console.log("Running tests (includes PolicySpec behavioral checks)...");
run(["make", "test"]);

console.log("");
console.log("Eval 10 OK");
