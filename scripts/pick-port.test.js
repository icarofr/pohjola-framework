import { expect, test } from "bun:test";
import { PORT_START, listenFree, resolvePort } from "./pick-port.js";

test("listenFree matches Bun.serve dual-stack, not IPv4-only", async () => {
  const blocker = Bun.serve({
    port: 3098,
    fetch() {
      return new Response("busy");
    },
  });
  try {
    expect(await listenFree(3098)).toBe(false);
  } finally {
    blocker.stop(true);
  }
});

test("explicit PORT wins when free", async () => {
  const r = await resolvePort({ PORT: "3013" }, async () => true);
  expect(r).toEqual({ port: 3013, baseUrl: "http://localhost:3013" });
});

test("explicit PORT fails when busy", async () => {
  await expect(resolvePort({ PORT: "3000" }, async () => false)).rejects.toThrow(
    /already in use/,
  );
});

test("increments past busy 3000 and 3001", async () => {
  const r = await resolvePort({}, async (port) => port === 3002);
  expect(r).toEqual({ port: 3002, baseUrl: "http://localhost:3002" });
});

test("BASE_URL follows the bound port, not Makefile's default", async () => {
  const r = await resolvePort(
    { BASE_URL: "http://localhost:3000" },
    async (port) => port === PORT_START + 1,
  );
  expect(r.baseUrl).toBe("http://localhost:3001");
});

test("exhausted range throws", async () => {
  await expect(resolvePort({}, async () => false)).rejects.toThrow(/No free port/);
});
