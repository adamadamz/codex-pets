# CodexPets SEO、AEO 与 AI Agent 搜索策略

> 更新日期：2026-08-03  
> 范围：`https://adamadamz.github.io/codex-pets/`

## 1. 术语与目标

- **SEO**：让传统搜索引擎正确索引首页、隐私页和下载关系。
- **AEO**：让搜索结果和问答系统直接取得简短、明确、可核验的答案。
- **AI Agent Search Optimization（本项目简称 ASO）**：让 ChatGPT、Perplexity、Claude、Gemini 等具备搜索能力的 Agent 更容易发现、理解和引用产品事实。行业中也常称 AISO、GEO 或 LLMO；这里不是 App Store Optimization。

优化只能提高被发现和正确引用的可能性，不能保证任何搜索引擎、模型或 Agent 收录、排序或回答。

## 2. 已实施的机器可读入口

- 首页与隐私页使用绝对 Canonical URL。
- 首页提供 Open Graph、X Card、标题、描述、关键词、作者与索引策略。
- `/codex-pets/robots.txt` 记录通用爬虫以及主要搜索型 AI User-Agent 的允许策略。由于当前是 GitHub Pages 子路径站点，标准爬虫首先读取域名根路径 `/robots.txt`；根路径目前返回 404，按 Robots 协议等同于没有禁止规则。若将来使用独立域名，应把同一文件发布到域名根路径。
- `sitemap.xml` 列出首页和隐私页。
- `SoftwareApplication`、`WebSite` 与 `FAQPage` JSON-LD 描述产品实体、版本、系统、下载、许可和问答。
- `llms.txt` 提供短版事实与 canonical sources；`llms-full.txt` 提供长版产品参考。
- `site.webmanifest` 明确产品名称、语言和 GitHub Pages 路径范围。

`llms.txt` 是新兴约定，不替代 HTML、Canonical、Robots、Sitemap 和 JSON-LD。

## 3. 内容层策略

首页新增“可核验产品事实”和常见问题，统一回答：

1. CodexPets 是什么；
2. 支持的 macOS 与 CPU 架构；
3. 是否联网、收集数据或包含追踪；
4. Gatekeeper 拦截的真实原因与安全打开方式；
5. 动态宠物包的导入格式；
6. Apple 公证与 Mac App Store 的当前状态；
7. 与 OpenAI 的关系。

这些答案同时存在于可见 HTML 和 JSON-LD 中，避免只给爬虫展示、用户却看不到的内容。

## 4. 事实来源优先级

1. GitHub Release：版本、文件、校验和与发布日期；
2. 官网隐私政策：联网、收集与托管边界；
3. `PRD_MacApp_for_Codex_v2.1.md`：产品能力与发布门禁；
4. GitHub 源码：实现与许可。

不得把性能目标写成实测结果，不得把 GitHub Preview 写成 Apple 已验证版本，不得声称已经上架 Mac App Store。

## 5. 后续持续优化

- 每次发布同步更新首页 JSON-LD、`llms.txt`、`llms-full.txt` 和 Sitemap 的版本与日期。
- 获得 Developer ID 公证或 Mac App Store 上架后，再同步修改 Gatekeeper 与分发状态。
- 在 Google Search Console 和 Bing Webmaster Tools 提交 Sitemap，并用其官方验证方式确认所有权。
- 用真实搜索查询观察品牌词、`macOS 桌面宠物`、`开源 Mac 桌面宠物` 和英文长尾词的展现；不使用虚假外链或关键词堆砌。
- 如果未来增加英文页面，为每个语言版本提供独立 URL、`hreflang`、Canonical 和对应 Sitemap。
