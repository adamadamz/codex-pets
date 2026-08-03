# CodexPets website

CodexPets 的中文官网，提供产品介绍、隐私说明与 GitHub Release 下载入口，并包含搜索引擎与 AI Agent 可读取的 Canonical、JSON-LD、FAQ、Sitemap、Robots 和 `llms.txt`。

```bash
npm ci
npm run dev
```

生产检查：

```bash
npm test
GITHUB_PAGES=true NEXT_PUBLIC_BASE_PATH=/codex-pets npm run build:pages
```

推送到 `main` 后，GitHub Actions 会把静态导出发布到 GitHub Pages。

搜索与 AI Agent 索引文件位于 `public/`。首页中的版本、分发、隐私和官方关系事实必须与 GitHub Release、隐私政策及当前 PRD 保持一致；性能目标不得写成实测结果。
