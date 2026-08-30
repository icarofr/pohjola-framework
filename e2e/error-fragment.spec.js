import { test, expect } from "@playwright/test";

test("upstream render failure still returns the exact fragment shell", async ({
  page,
}) => {
  const response = await page.request.get("/en/posts/1", {
    headers: { "x-alpine-request": "true" },
  });
  expect(response.status()).toBe(500);

  const parsed = await page.evaluate(
    async (html) => {
      const document = new DOMParser().parseFromString(html, "text/html");
      return {
        hasDrawer:
          document.body.children.length === 1 &&
          document.body.children[0].classList.contains("drawer"),
        hasHeader: Boolean(document.body.querySelector("header#header[x-sync]")),
        hasMain: Boolean(document.body.querySelector("main#content")),
        wrappers: document.body.querySelectorAll("html,body,script,link,style")
          .length,
      };
    },
    await response.text(),
  );

  expect(parsed.hasDrawer).toBe(true);
  expect(parsed.hasHeader).toBe(true);
  expect(parsed.hasMain).toBe(true);
  expect(parsed.wrappers).toBe(0);
});
