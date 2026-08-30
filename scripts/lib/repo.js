/**
 * Shared infrastructure for repo scripts: root discovery, file I/O, glob, subprocess.
 * Use `node:path` for paths and `bun` for I/O/spawn — not a Bun shim.
 */
import { dirname, join, resolve, relative } from "node:path";
import { tmpdir } from "node:os";
import { cp } from "node:fs/promises";
import { file, write, spawnSync, Glob, $ } from "bun";

const ROOT_MARKER = "spago.yaml";

export { join, resolve, dirname, relative } from "node:path";

async function findRepoRoot(startDir) {
  let dir = resolve(startDir);
  for (;;) {
    if (await file(join(dir, ROOT_MARKER)).exists()) {
      return dir;
    }
    const parent = dirname(dir);
    if (parent === dir) {
      throw new Error(`repo root not found (missing ${ROOT_MARKER})`);
    }
    dir = parent;
  }
}

/** Repo root (directory containing spago.yaml), resolved from scripts/lib/. */
export const ROOT = await findRepoRoot(import.meta.dir);

export function rel(path) {
  return relative(ROOT, path);
}

export function ok(message) {
  console.log(`  ✓ ${message}`);
}

export function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

export async function exists(path) {
  return file(path).exists();
}

export async function readText(path) {
  const f = file(path);
  if (!(await f.exists())) {
    throw new Error(`missing ${path}`);
  }
  return f.text();
}

export async function writeText(path, content) {
  await write(path, content);
}

export function globSync(pattern, cwd = ROOT) {
  const g = new Glob(pattern);
  return [...g.scanSync({ cwd, dot: false })].map((relPath) => join(cwd, relPath));
}

/** Run argv; inherit stdio. Exits on failure unless throwOnError. */
export function run(cmd, options = {}) {
  const proc = spawnSync(cmd, {
    cwd: options.cwd ?? ROOT,
    stdout: "inherit",
    stderr: "inherit",
    stdin: "inherit",
    env: options.env ?? process.env,
  });
  if (proc.exitCode !== 0) {
    if (options.throwOnError) {
      throw new Error(`command failed (${proc.exitCode}): ${cmd.join(" ")}`);
    }
    process.exit(proc.exitCode ?? 1);
  }
  return proc;
}

export async function mkdtemp(prefix = "pohjola-") {
  // GNU mktemp treats -t as --tmpdir; macOS -t is a name prefix. Use an
  // explicit TEMPLATE with XXXXXX so both accept the same invocation.
  const template = join(tmpdir(), `${prefix}XXXXXX`);
  const proc = await $`mktemp -d ${template}`.quiet().nothrow();
  if (proc.exitCode !== 0) {
    throw new Error(`mktemp failed: ${proc.stderr.toString()}`);
  }
  return proc.stdout.toString().trim();
}

export async function cpRecursive(src, dest) {
  // `cp -R src dest` into an existing directory nests as dest/basename(src).
  // Generator fixtures mkdtemp first, so copy the tree itself (Node/Bun fs.cp).
  await cp(src, dest, { recursive: true });
}

export async function rmRecursive(target) {
  const proc = await $`rm -rf ${target}`.quiet().nothrow();
  if (proc.exitCode !== 0) {
    throw new Error(`rm failed: ${target}`);
  }
}

export function listDir(dir) {
  return [...new Glob("*").scanSync({ cwd: dir })].sort();
}
