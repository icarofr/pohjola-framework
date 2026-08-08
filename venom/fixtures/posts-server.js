// Fixture API for integration tests — stands in for jsonplaceholder.typicode.com
// so venom runs without external network. Test infrastructure only; the repo's
// "no custom JS" rule applies to the app, not to test fixtures.
const http = require("http");

const posts = [
  { userId: 1, id: 1, title: "Post 1", body: "Body 1" },
  { userId: 1, id: 2, title: "Post 2", body: "Body 2" },
  { userId: 1, id: 3, title: "Post 3", body: "Body 3" },
];

const notFound = (res) => {
  res.writeHead(404, { "Content-Type": "application/json" });
  res.end("{}");
};

const ok = (res, body) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
};

http.createServer((req, res) => {
  if (req.method !== "GET") return notFound(res);
  const url = new URL(req.url, "http://localhost");
  if (url.pathname === "/posts") return ok(res, posts);
  if (url.pathname.startsWith("/posts/")) {
    const post = posts.find((p) => p.id === parseInt(url.pathname.split("/")[2], 10));
    return post ? ok(res, post) : notFound(res);
  }
  return notFound(res);
}).listen(4321, "0.0.0.0");
