#!/usr/bin/env bun
/**
 * Pick a local dev port. Default: 3000, then 3001 when 3000 is busy.
 * Honors PORT when set (no fallback). Prints port or shell export lines.
 */
import net from "node:net";

const FALLBACKS = [3000, 3001];

function portFree(port) {
  return new Promise((resolve) => {
    const socket = net.connect({ port, host: "127.0.0.1" });
    socket.setTimeout(250);
    socket.once("connect", () => {
      socket.destroy();
      resolve(false);
    });
    socket.once("timeout", () => {
      socket.destroy();
      resolve(true);
    });
    socket.once("error", () => resolve(true));
  });
}

export async function resolvePort(env = process.env) {
  const explicit = env.PORT?.trim() ?? "";
  if (explicit !== "") {
    const port = Number(explicit);
    if (!Number.isInteger(port) || port <= 0) {
      throw new Error(`Invalid PORT: ${explicit}`);
    }
    if (!(await portFree(port))) {
      throw new Error(`Port ${port} is already in use`);
    }
    const baseUrl = env.BASE_URL?.trim() || `http://localhost:${port}`;
    return { port, baseUrl };
  }

  for (const port of FALLBACKS) {
    if (await portFree(port)) {
      if (port !== FALLBACKS[0]) {
        console.error(`[pohjola] Port ${FALLBACKS[0]} busy — using ${port}`);
      }
      return { port, baseUrl: `http://localhost:${port}` };
    }
  }

  throw new Error(`Ports ${FALLBACKS.join(" and ")} are already in use`);
}

async function main() {
  const { port, baseUrl } = await resolvePort();
  if (process.argv.includes("--export")) {
    console.log(`export PORT=${port}`);
    console.log(`export BASE_URL=${baseUrl}`);
  } else {
    console.log(String(port));
  }
}

if (import.meta.main) {
  main().catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
}
