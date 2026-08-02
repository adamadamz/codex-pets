# CodexPets website

CodexPets 的中文官网，提供产品介绍、隐私说明与 GitHub Release 下载入口。

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
