const repositoryUrl = "https://github.com/adamadamz/codex-pets";
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? "";
const homeUrl = `${basePath}/`;

export default function PrivacyPage() {
  return (
    <main className="privacy-page">
      <nav className="site-nav privacy-nav" aria-label="隐私页导航">
        <a className="brand" href={homeUrl}>
          <span className="brand-mark" aria-hidden="true">✦</span>
          <span>CodexPets</span>
        </a>
        <div className="nav-links">
          <a href={homeUrl}>返回首页</a>
          <a className="nav-github" href={repositoryUrl}>GitHub ↗</a>
        </div>
      </nav>

      <article className="privacy-content">
        <p className="eyebrow">PRIVACY POLICY · 2026-08-02</p>
        <h1>隐私很简单：<br />不收集。</h1>
        <p className="privacy-intro">
          CodexPets 是完全离线运行的开源 macOS 应用。它不需要账号，不连接分析服务，也不会把你的宠物包或使用数据发送到任何服务器。
        </p>

        <section className="privacy-block">
          <h2>我们不收集什么</h2>
          <ul>
            <li>不收集身份、设备、位置或使用行为数据；</li>
            <li>不包含广告、统计、崩溃上报或第三方追踪 SDK；</li>
            <li>不上传你导入的图片、图集、宠物配置或文件路径。</li>
          </ul>
        </section>

        <section className="privacy-block">
          <h2>本机保存的内容</h2>
          <p>
            当前宠物、交互偏好与导入的宠物包会保存在你的 Mac 的 Application Support 目录中，仅供应用在本机恢复状态。卸载应用不会自动删除这些文件，你可以自行移除。
          </p>
        </section>

        <section className="privacy-block">
          <h2>官网与 GitHub</h2>
          <p>
            本官网托管在 GitHub Pages，下载由 GitHub Releases 提供。访问这些页面时，GitHub 可能依据其自身隐私政策处理必要的网络日志；CodexPets 项目不会额外植入分析脚本。
          </p>
        </section>

        <section className="privacy-block">
          <h2>问题与变更</h2>
          <p>
            如果未来加入任何联网或数据处理能力，我们会先在源代码与本页中明确更新。你可以通过 GitHub Issues 提问或报告问题。
          </p>
          <a className="text-link" href={`${repositoryUrl}/issues`}>前往 GitHub Issues →</a>
        </section>
      </article>
    </main>
  );
}
