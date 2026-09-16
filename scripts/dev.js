#!/usr/bin/env bun
/**
 * Local-dev supervisor — one process group, one rebuild graph.
 *
 * CSS stays a file in POHJOLA_DEV (no Spago). PureScript rebuilds when a
 * non-generated .purs file changes. static/ copies into dist/. Bun --watch
 * reloads output/App.Main.
 */
import { spawn } from "node:child_process";
import { watch } from "node:fs";
import { join } from "node:path";
import { ROOT, run } from "./lib/repo.js";
import { resolvePort } from "./pick-port.js";

const DIST_DIR = join(ROOT, "dist");
const CSS_OUT = join(DIST_DIR, "css/styles.css");
const SRC_DIR = join(ROOT, "src");
const STATIC_DIR = join(ROOT, "static");

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

function isGeneratedStyles(filename) {
  return filename != null && filename.replaceAll("\\", "/").endsWith("Layout/Styles.purs");
}

async function main() {
  const noServer = process.argv.includes("--no-server");
  const { port, baseUrl } = noServer
    ? { port: 0, baseUrl: "" }
    : await resolvePort();
  const env = {
    ...process.env,
    PORT: noServer ? process.env.PORT : String(port),
    BASE_URL: noServer ? process.env.BASE_URL : baseUrl,
    POHJOLA_DEV: "1",
  };

  console.log("[pohjola] Building CSS (Tailwind + embed)…");
  buildCss();
  syncStatic();
  console.log("[pohjola] Building PureScript…");
  spagoBuild();

  if (noServer) {
    console.log("\n[pohjola] Watchers only — no server (Ctrl+C to stop)\n");
  } else {
    console.log(`\n[pohjola] Dev server → ${baseUrl}`);
    console.log("[pohjola] CSS file + live-reload on; Spago on .purs (Ctrl+C to stop)\n");
  }

  const children = [];
  let stopping = false;

  function startChild(cmd, args) {
    const child = spawn(cmd, args, {
      cwd: ROOT,
      stdio: "inherit",
      env,
      detached: true,
    });
    child.on("exit", (code, signal) => {
      if (stopping) return;
      if (signal) {
        stopping = true;
        process.kill(process.pid, signal);
      } else if (code && code !== 0) {
        stopping = true;
        process.exit(code);
      }
    });
    children.push(child);
    return child;
  }

  function killTree(child, signal) {
    if (!child.pid) return;
    try {
      process.kill(-child.pid, signal);
    } catch {
      try {
        child.kill(signal);
      } catch {
        /* already gone */
      }
    }
  }

  startChild("bun", [
    "x",
    "@tailwindcss/cli",
    "-i",
    "css/input.css",
    "-o",
    CSS_OUT,
    "--watch",
  ]);

  let staticTimer;
  watch(STATIC_DIR, { recursive: true }, () => {
    clearTimeout(staticTimer);
    staticTimer = setTimeout(() => {
      console.log("[pohjola] static/ changed — syncing dist/");
      syncStatic();
    }, 100);
  });

  let psTimer;
  watch(SRC_DIR, { recursive: true }, (_event, filename) => {
    if (!filename?.endsWith(".purs") || isGeneratedStyles(filename)) return;
    clearTimeout(psTimer);
    psTimer = setTimeout(() => {
      console.log("[pohjola] PureScript changed — rebuilding…");
      spagoBuild();
    }, 100);
  });

  if (!noServer) {
    startChild("bun", [
      "--watch",
      "--eval",
      "import('./output/App.Main/index.js').then(m => m.main())",
    ]);
  }

  const shutdown = (signal) => {
    if (stopping) return;
    stopping = true;
    for (const child of children) {
      killTree(child, signal);
    }
    process.exit(0);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
