#!/usr/bin/env bun
/**
 * Development server — one command for CSS embed, static sync, Spago, and Bun.
 *
 * Replaces the old make dev shell soup: Tailwind changes re-embed into
 * App.Layout.Styles so inlined CSS stays current without `make css` by hand.
 */
import { spawn } from "node:child_process";
import { watch } from "node:fs";
import { join } from "node:path";
import { ROOT, run } from "./lib/repo.js";
import { resolvePort } from "./pick-port.js";

const DIST_DIR = join(ROOT, "dist");
const CSS_OUT = join(DIST_DIR, "css/styles.css");
const SRC_DIR = join(ROOT, "src");

function syncStatic() {
  run([
    "bash",
    "-c",
    `mkdir -p "${DIST_DIR}/css" && cp -r static/assets static/images "${DIST_DIR}/" 2>/dev/null || true && cp static/favicon.svg "${DIST_DIR}/" 2>/dev/null || true`,
  ]);
}

function buildCss() {
  run([
    "bun",
    "x",
    "@tailwindcss/cli",
    "-i",
    "css/input.css",
    "-o",
    CSS_OUT,
    "--minify",
  ]);
  run(["bun", "scripts/embed-css.js"]);
}

function spagoBuild() {
  run(["bun", "spago", "build", "--pure", "--strict"]);
}

function startChild(cmd, args, env) {
  const child = spawn(cmd, args, {
    cwd: ROOT,
    stdio: "inherit",
    env,
  });
  child.on("exit", (code, signal) => {
    if (signal) process.kill(process.pid, signal);
    else if (code && code !== 0) process.exit(code);
  });
  return child;
}

async function main() {
  const { port, baseUrl } = await resolvePort();
  const env = { ...process.env, PORT: String(port), BASE_URL: baseUrl };

  console.log("[pohjola] Building CSS (Tailwind + embed)…");
  buildCss();
  syncStatic();
  console.log("[pohjola] Building PureScript…");
  spagoBuild();

  console.log(`\n[pohjola] Dev server → ${baseUrl}`);
  console.log("[pohjola] Tailwind + Spago watchers active (Ctrl+C to stop)\n");

  const children = [];

  children.push(
    startChild("bun", ["x", "@tailwindcss/cli", "-i", "css/input.css", "-o", CSS_OUT, "--watch"], env),
  );

  let cssTimer;
  watch(CSS_OUT, () => {
    clearTimeout(cssTimer);
    cssTimer = setTimeout(() => {
      console.log("[pohjola] CSS changed — re-embedding…");
      run(["bun", "scripts/embed-css.js"], { env });
      spagoBuild();
    }, 150);
  });

  let psTimer;
  watch(SRC_DIR, { recursive: true }, (_event, filename) => {
    if (filename?.endsWith(".purs")) {
      clearTimeout(psTimer);
      psTimer = setTimeout(() => spagoBuild(), 100);
    }
  });

  children.push(
    startChild(
      "bun",
      ["--watch", "--eval", "import('./output/App.Main/index.js').then(m => m.main())"],
      env,
    ),
  );

  const shutdown = (signal) => {
    for (const child of children) child.kill(signal);
    process.exit(0);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
