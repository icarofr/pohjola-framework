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
        children: [...document.body.children].map((node) => ({
          name: `${node.tagName.toLowerCase()}#${node.id}`,
          sync: node.getAttribute("x-sync"),
          title: node.getAttribute("data-page-title"),
        })),
        wrappers: document.body.querySelectorAll("html,body,script,link,style")
          .length,
      };
    },
    await response.text(),
  );

  expect(parsed.children).toEqual([
    { name: "header#header", sync: "", title: null },
    { name: "main#content", sync: null, title: expect.any(String) },
  ]);
  expect(parsed.wrappers).toBe(0);
});
