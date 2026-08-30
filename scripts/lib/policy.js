/**
 * Policy gate helpers — manifest.json and src scan paths.
 */
import { join } from "node:path";
import { ROOT, exists, fail, globSync, readText } from "./repo.js";

export async function readManifest() {
  const manifestPath = join(ROOT, "policy", "manifest.json");
  if (!(await exists(manifestPath))) {
    fail(`missing ${manifestPath}`);
  }
  return JSON.parse(await readText(manifestPath));
}

export function srcSourceFiles() {
  return [...globSync("src/**/*.purs"), ...globSync("src/**/*.js")];
}
