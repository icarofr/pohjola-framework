/**
 * Shared infrastructure for repo scripts: root discovery, file I/O, glob, subprocess.
 * Use `node:path` for paths and `bun` for I/O/spawn — not a Bun shim.
 */
import { dirname, join, resolve, relative } from "node:path";
import { tmpdir } from "node:os";
import { chmodSync, lstatSync, mkdirSync, readlinkSync, symlinkSync } from "node:fs";
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
  const dir = join(tmpdir(), `${prefix}${crypto.randomUUID()}`);
  await write(join(dir, ".keep"), "");
  await file(join(dir, ".keep")).delete();
  return dir;
}

const COPY_BATCH = 64;

/**
 * Copy a file tree with Glob + Bun.write(Bun.file) — clonefile/copy_file_range.
 *
 * `onlyFiles: true` silently excludes symlinks (verified: Bun.Glob treats
 * them as neither files nor directories under that flag), which drops the
 * entire node_modules/.bin/* tree — every package's CLI entry point is a
 * symlink. Bun.write also does not preserve the source file's permission
 * bits, which drops the executable bit on the underlying target scripts
 * those symlinks point to. Both silently broke `bun x <tool>` inside a
 * copy (empty stdout/stderr, exit 1) without any error naming the cause —
 * found via a real failure, not by inspection. Symlinks are recreated as
 * symlinks (not flattened to their target's content) so relative-path
 * targets (as node_modules/.bin entries use) keep resolving correctly;
 * regular files get their exact source mode re-applied after the copy.
 */
export async function cpRecursive(src, dest) {
  const pending = [];
  for (const relPath of new Glob("**/*").scanSync({
    cwd: src,
    dot: true,
    onlyFiles: false,
  })) {
    const srcPath = join(src, relPath);
    const destPath = join(dest, relPath);
    const st = lstatSync(srcPath);
    if (st.isDirectory()) continue;
    if (st.isSymbolicLink()) {
      mkdirSync(dirname(destPath), { recursive: true });
      symlinkSync(readlinkSync(srcPath), destPath);
      continue;
    }
    pending.push(write(destPath, file(srcPath)).then(() => chmodSync(destPath, st.mode)));
    if (pending.length >= COPY_BATCH) {
      await Promise.all(pending);
      pending.length = 0;
    }
  }
  await Promise.all(pending);
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
