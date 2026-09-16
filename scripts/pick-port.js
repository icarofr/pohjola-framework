#!/usr/bin/env bun
/**
 * Pick a local-dev origin port by binding, not by connecting.
 * Unset PORT: try 3000, then 3001, … up to 3099.
 * Set PORT: that port or fail. BASE_URL always follows the bound port.
 *
 * The free test is Bun.serve itself (IPv6 dual-stack `*:port`, same as
 * App.ServerBun). A Node listen on 127.0.0.1 misses leftover `*:port`
 * listeners and then make dev collides with them.
 */

export const PORT_START = 3000;
export const PORT_SPAN = 100;

export function listenFree(port) {
  try {
    const server = Bun.serve({
      port,
      fetch() {
        return new Response("");
      },
    });
    server.stop(true);
    return Promise.resolve(true);
  } catch {
    return Promise.resolve(false);
  }
}

export async function resolvePort(env = process.env, isFree = listenFree) {
  const explicit = env.PORT?.trim() ?? "";
  if (explicit !== "") {
    const port = Number(explicit);
    if (!Number.isInteger(port) || port <= 0) {
      throw new Error(`Invalid PORT: ${explicit}`);
    }
    if (!(await isFree(port))) {
      throw new Error(`Port ${port} is already in use`);
    }
    return { port, baseUrl: `http://localhost:${port}` };
  }

  const last = PORT_START + PORT_SPAN - 1;
  for (let port = PORT_START; port <= last; port++) {
    if (await isFree(port)) {
      if (port !== PORT_START) {
        console.error(`[pohjola] Port ${PORT_START} busy — using ${port}`);
      }
      return { port, baseUrl: `http://localhost:${port}` };
    }
  }

  throw new Error(`No free port in ${PORT_START}–${last}`);
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
