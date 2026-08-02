import assert from "node:assert/strict";
import test from "node:test";

async function render(pathname = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${pathname}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("server-renders the finished CodexPets landing page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>CodexPets/);
  assert.match(html, /把 Codex 的小宠物/);
  assert.match(html, /CodexPets-macOS-universal\.zip/);
  assert.match(html, /首次安装需在“隐私与安全”中允许打开/);
  assert.match(html, /点击“仍要打开”/);
  assert.match(html, /xattr -dr com\.apple\.quarantine \/Applications\/CodexPets\.app/);
  assert.match(html, /不要全局关闭 Gatekeeper/);
  assert.match(html, /不收集使用数据/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton/);
});

test("publishes a plain-language privacy page", async () => {
  const response = await render("/privacy/");
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /隐私很简单/);
  assert.match(html, /不包含广告、统计、崩溃上报或第三方追踪/);
});
