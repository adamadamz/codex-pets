import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
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
  assert.match(html, /rel="canonical" href="https:\/\/adamadamz\.github\.io\/codex-pets\/"/);
  assert.match(html, /property="og:title" content="CodexPets/);
  assert.match(html, /name="twitter:card" content="summary_large_image"/);
  assert.match(html, /把 Codex 的小宠物/);
  assert.match(html, /CodexPets-macOS-universal\.zip/);
  assert.match(html, /首次安装需在“隐私与安全”中允许打开/);
  assert.match(html, /点击“仍要打开”/);
  assert.match(html, /xattr -dr com\.apple\.quarantine \/Applications\/CodexPets\.app/);
  assert.match(html, /不要全局关闭 Gatekeeper/);
  assert.match(html, /不收集使用数据/);
  assert.match(html, /VERIFIABLE PRODUCT FACTS/);
  assert.match(html, /尚未 Apple 公证或上架 Mac App Store/);
  assert.match(html, /CodexPets 是 OpenAI 官方产品吗/);
  assert.match(html, /"@type":"SoftwareApplication"/);
  assert.match(html, /"@type":"FAQPage"/);
  assert.match(html, /"softwareVersion":"0\.1\.0-preview\.1"/);
  assert.doesNotMatch(html, /实测空闲 CPU/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton/);
});

test("publishes a plain-language privacy page", async () => {
  const response = await render("/privacy/");
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /隐私很简单/);
  assert.match(html, /不包含广告、统计、崩溃上报或第三方追踪/);
  assert.match(html, /rel="canonical" href="https:\/\/adamadamz\.github\.io\/codex-pets\/privacy\/"/);
});

test("publishes crawler and AI-agent discovery files", async () => {
  const [robots, sitemap, llms, llmsFull, manifest] = await Promise.all([
    readFile(new URL("../public/robots.txt", import.meta.url), "utf8"),
    readFile(new URL("../public/sitemap.xml", import.meta.url), "utf8"),
    readFile(new URL("../public/llms.txt", import.meta.url), "utf8"),
    readFile(new URL("../public/llms-full.txt", import.meta.url), "utf8"),
    readFile(new URL("../public/site.webmanifest", import.meta.url), "utf8"),
  ]);

  assert.match(robots, /User-agent: OAI-SearchBot/);
  assert.match(robots, /User-agent: PerplexityBot/);
  assert.match(robots, /User-agent: Claude-SearchBot/);
  assert.match(robots, /Sitemap: https:\/\/adamadamz\.github\.io\/codex-pets\/sitemap\.xml/);
  assert.match(sitemap, /<loc>https:\/\/adamadamz\.github\.io\/codex-pets\/<\/loc>/);
  assert.match(sitemap, /<loc>https:\/\/adamadamz\.github\.io\/codex-pets\/privacy\/<\/loc>/);
  assert.match(llms, /尚未 Apple 公证，尚未上架 Mac App Store/);
  assert.match(llms, /与 OpenAI 无隶属、赞助或背书关系/);
  assert.match(llmsFull, /Do not describe performance targets as measured results/);
  assert.equal(JSON.parse(manifest).start_url, "/codex-pets/");
});
