import type { CSSProperties } from "react";

const repositoryUrl = "https://github.com/adamadamz/codex-pets";
const releasesUrl = `${repositoryUrl}/releases`;
const downloadUrl = `${releasesUrl}/latest/download/CodexPets-macOS-universal.zip`;
const latestReleaseUrl = `${releasesUrl}/tag/v0.1.0-preview.1`;
const siteUrl = "https://adamadamz.github.io/codex-pets/";
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? "";
const homeUrl = `${basePath}/`;
const privacyUrl = `${basePath}/privacy/`;

const petStyle = {
  "--pet-sheet": `url(${basePath}/flower-panda.webp)`,
} as CSSProperties;

const features = [
  {
    number: "01",
    title: "真的会动",
    description:
      "待机、奔跑、挥手、跳跃和注视方向都来自标准 Codex 动态宠物包。",
  },
  {
    number: "02",
    title: "留在你的 Mac",
    description:
      "宠物解析、渲染与配置全部在本机完成；不联网，也不收集使用数据。",
  },
  {
    number: "03",
    title: "像桌面伙伴一样",
    description:
      "拖动、跟随鼠标、点击反馈、全局快捷键和开机启动，都藏在菜单栏里。",
  },
];

const facts = [
  ["当前版本", "v0.1.0-preview.1"],
  ["发布状态", "GitHub Preview；尚未 Apple 公证或上架 Mac App Store"],
  ["系统要求", "macOS 14 或更高版本"],
  ["处理器", "Apple Silicon 与 Intel（Universal）"],
  ["网络与数据", "App 本身不联网，不收集使用数据"],
  ["价格与许可", "免费，MIT 开源许可"],
];

const faqs = [
  {
    question: "CodexPets 是什么？",
    answer:
      "CodexPets 是一个免费开源的 macOS 动态桌面宠物 App。它读取标准宠物包，在桌面边缘显示可拖动、会待机、奔跑、挥手和观察光标方向的动画伙伴。",
  },
  {
    question: "支持哪些 Mac？",
    answer:
      "当前 Preview 需要 macOS 14 或更高版本，发布包是 Universal 构建，同时支持 Apple Silicon 和 Intel Mac。",
  },
  {
    question: "CodexPets 会联网或收集数据吗？",
    answer:
      "App 本身不会联网，不需要账号，也不包含广告、分析、崩溃上报或第三方追踪 SDK。宠物包和偏好只保存在本机。官网与下载由 GitHub 托管，访问时适用 GitHub 自身的隐私政策。",
  },
  {
    question: "为什么首次打开会被 macOS Gatekeeper 拦截？",
    answer:
      "当前 GitHub Preview 使用 ad-hoc 签名，尚未完成 Developer ID 签名与 Apple 公证，因此 Gatekeeper 会显示“Apple 无法验证”。这不等于压缩包损坏；请先尝试打开一次，再到“系统设置 → 隐私与安全”选择“仍要打开”。不要全局关闭 Gatekeeper。",
  },
  {
    question: "如何导入动态宠物？",
    answer:
      "选择一个同时包含 pet.json 和 spritesheet.webp 的目录。CodexPets 会先校验宠物包协议和图集尺寸，再复制到本机的 Application Support 目录。",
  },
  {
    question: "CodexPets 已经在 Mac App Store 上架了吗？",
    answer:
      "还没有。当前可下载版本是 GitHub Preview，尚未经过 Apple 公证，也尚未提交或上架 Mac App Store。App Store 沙盒工程已经准备，但证书、Provisioning Profile、商店名称和最终审核仍未完成。",
  },
  {
    question: "CodexPets 是 OpenAI 官方产品吗？",
    answer:
      "不是。CodexPets 是独立开源项目，与 OpenAI 没有隶属、赞助或背书关系；Codex 是其各自权利人的商标。",
  },
];

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": `${siteUrl}#website`,
      url: siteUrl,
      name: "CodexPets",
      description: "免费开源、完全离线的 macOS 动态桌面宠物。",
      inLanguage: "zh-CN",
    },
    {
      "@type": "SoftwareApplication",
      "@id": `${siteUrl}#software`,
      name: "CodexPets",
      url: siteUrl,
      mainEntityOfPage: siteUrl,
      description:
        "免费开源、完全离线的 macOS 动态桌面宠物，支持导入标准动态宠物包。",
      applicationCategory: "UtilitiesApplication",
      applicationSubCategory: "Desktop customization utility",
      operatingSystem: "macOS 14 or later",
      softwareRequirements: "macOS 14+; Apple Silicon or Intel Mac",
      softwareVersion: "0.1.0-preview.1",
      releaseNotes: latestReleaseUrl,
      downloadUrl,
      installUrl: downloadUrl,
      isAccessibleForFree: true,
      license: "https://opensource.org/license/mit",
      sameAs: [repositoryUrl],
      featureList: [
        "本地导入动态宠物包",
        "待机、奔跑、挥手、跳跃与光标方向注视",
        "拖动、跟随鼠标、点击反馈与全局快捷键",
        "离线运行且不收集使用数据",
      ],
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "CNY",
        availability: "https://schema.org/InStock",
        url: downloadUrl,
      },
    },
    {
      "@type": "FAQPage",
      "@id": `${siteUrl}#faq`,
      url: `${siteUrl}#faq`,
      inLanguage: "zh-CN",
      mainEntity: faqs.map((faq) => ({
        "@type": "Question",
        name: faq.question,
        acceptedAnswer: {
          "@type": "Answer",
          text: faq.answer,
        },
      })),
    },
  ],
};

const structuredDataJson = JSON.stringify(structuredData).replace(/</g, "\\u003c");

export default function Home() {
  return (
    <main>
      <script
        id="codexpets-structured-data"
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: structuredDataJson }}
      />
      <nav className="site-nav" aria-label="主导航">
        <a className="brand" href={`${homeUrl}#top`} aria-label="CodexPets 首页">
          <span className="brand-mark" aria-hidden="true">✦</span>
          <span>CodexPets</span>
          <span className="brand-badge">OPEN PREVIEW</span>
        </a>
        <div className="nav-links">
          <a href="#features">功能</a>
          <a href="#install">安装</a>
          <a href="#faq">问答</a>
          <a href={privacyUrl}>隐私</a>
          <a className="nav-github" href={repositoryUrl}>GitHub ↗</a>
        </div>
      </nav>

      <section className="hero section-shell" id="top">
        <div className="hero-copy">
          <p className="eyebrow">macOS 14+ · Apple Silicon & Intel · 开源</p>
          <h1>
            把 Codex 的小宠物，
            <span>放到桌面上。</span>
          </h1>
          <p className="hero-lede">
            一个轻量、离线的 macOS 桌面伙伴。导入标准动态宠物包，让它在屏幕边缘奔跑、挥手，静静陪你工作。
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={downloadUrl}>
              <span>下载 macOS Preview</span>
              <span aria-hidden="true">↓</span>
            </a>
            <a className="button button-secondary" href={repositoryUrl}>
              查看源代码 <span aria-hidden="true">↗</span>
            </a>
          </div>
          <p className="release-note">
            v0.1 Preview · 免费开源 · 首次安装需在“隐私与安全”中允许打开
          </p>
          <a className="gatekeeper-link" href="#install-help">
            看到“Apple 无法验证”？查看正确打开方式 ↓
          </a>
        </div>

        <div className="hero-visual" aria-label="花花熊猫桌面宠物预览">
          <div className="orbit orbit-one" />
          <div className="orbit orbit-two" />
          <div className="desktop-card">
            <div className="desktop-toolbar">
              <div className="traffic-lights" aria-hidden="true">
                <span />
                <span />
                <span />
              </div>
              <span>专注模式 · 42 min</span>
            </div>
            <div className="desktop-body">
              <div className="code-lines" aria-hidden="true">
                <span className="line line-wide" />
                <span className="line line-mid" />
                <span className="line line-short" />
                <span className="line line-wide" />
                <span className="line line-mid" />
              </div>
              <div className="pet-shadow" />
              <div className="pet-sprite" style={petStyle} aria-hidden="true" />
              <div className="pet-status">
                <span className="status-dot" /> 花花熊猫正在陪你
              </div>
            </div>
          </div>
          <p className="visual-caption">你的宠物，由你导入。你的数据，只留在本机。</p>
        </div>
      </section>

      <section className="proof-strip" aria-label="产品信息">
        <div><strong>0</strong><span>网络请求</span></div>
        <div><strong>9 + 16</strong><span>动作与注视方向</span></div>
        <div><strong>&lt; 1%</strong><span>目标空闲 CPU</span></div>
        <div><strong>100%</strong><span>Swift 原生</span></div>
      </section>

      <section className="features section-shell" id="features">
        <div className="section-heading">
          <p className="eyebrow">A SMALL COMPANION, DONE RIGHT</p>
          <h2>不打扰，但一直在。</h2>
          <p>没有账号、云端或订阅。只有一只真正属于你的桌面宠物。</p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.number}>
              <span className="feature-number">{feature.number}</span>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="package-section section-shell">
        <div className="package-copy">
          <p className="eyebrow">CODEX PET PACKAGE</p>
          <h2>两份文件，孵化一只动态宠物。</h2>
          <p>
            CodexPets 读取标准的 <code>pet.json</code> 和 <code>spritesheet.webp</code>。
            选择已有宠物，也可以把你制作的新宠物包导入进来。
          </p>
          <a className="text-link" href={`${repositoryUrl}#用法`}>查看宠物包与使用说明 →</a>
        </div>
        <div className="package-window" aria-label="宠物包文件结构示例">
          <div className="package-title"><span>⌄</span> flower-panda</div>
          <div className="package-file"><span>{"{}"}</span> pet.json <em>动作与版本</em></div>
          <div className="package-file"><span>▦</span> spritesheet.webp <em>动态精灵图</em></div>
          <div className="package-result"><span>✓</span> 已通过 v2 协议校验</div>
        </div>
      </section>

      <section className="install section-shell" id="install">
        <div className="section-heading install-heading">
          <p className="eyebrow">INSTALL PREVIEW</p>
          <h2>三步，把它带回桌面。</h2>
        </div>
        <ol className="install-steps">
          <li>
            <span className="step-number">1</span>
            <div><h3>下载并解压</h3><p>从 GitHub Release 下载 Universal 安装包。</p></div>
          </li>
          <li>
            <span className="step-number">2</span>
            <div><h3>拖入“应用程序”</h3><p>把 CodexPets.app 移到 Applications 文件夹。</p></div>
          </li>
          <li>
            <span className="step-number">3</span>
            <div><h3>在系统设置允许</h3><p>先尝试打开一次，然后前往“隐私与安全”，点击“仍要打开”。</p></div>
          </li>
        </ol>
        <div className="gatekeeper-help" id="install-help">
          <div className="gatekeeper-copy">
            <p className="eyebrow">APPLE 无法验证 CODEXPETS？</p>
            <h3>App 没坏，是 Gatekeeper 在拦截。</h3>
            <ol>
              <li>在警告窗口点击“完成”，不要选择“移到废纸篓”。</li>
              <li>打开“系统设置 → 隐私与安全”，向下找到安全性区域。</li>
              <li>在“CodexPets 已被阻止”旁点击“仍要打开”，再确认一次。</li>
            </ol>
            <p className="gatekeeper-note">
              当前开源 Preview 使用 ad-hoc 签名，尚未完成 Developer ID 签名与 Apple 公证。
            </p>
          </div>
          <div className="terminal-card">
            <span>可选 · 只解除 CodexPets 的隔离标记</span>
            <code>xattr -dr com.apple.quarantine /Applications/CodexPets.app</code>
            <code>open /Applications/CodexPets.app</code>
            <p>请先把 App 移到“应用程序”。不要全局关闭 Gatekeeper。</p>
          </div>
        </div>
        <div className="install-actions">
          <a className="button button-primary" href={downloadUrl}>下载 Preview ↓</a>
          <a className="text-link" href={releasesUrl}>查看所有版本 ↗</a>
        </div>
      </section>

      <section className="facts section-shell" id="facts" aria-labelledby="facts-title">
        <div className="section-heading facts-heading">
          <p className="eyebrow">VERIFIABLE PRODUCT FACTS</p>
          <h2 id="facts-title">一眼看清当前版本。</h2>
          <p>
            以下信息与 GitHub Release、隐私政策和发布清单保持一致，便于用户和搜索型 AI Agent 准确引用。
          </p>
        </div>
        <dl className="facts-list">
          {facts.map(([term, value]) => (
            <div key={term}>
              <dt>{term}</dt>
              <dd>{value}</dd>
            </div>
          ))}
        </dl>
        <p className="facts-source">
          事实来源：<a href={latestReleaseUrl}>最新 Release</a> · <a href={privacyUrl}>隐私政策</a> · <a href={`${repositoryUrl}/blob/main/Docs/PRD_MacApp_for_Codex_v2.1.md`}>产品规格</a>
        </p>
      </section>

      <section className="faq section-shell" id="faq" aria-labelledby="faq-title">
        <div className="section-heading faq-heading">
          <p className="eyebrow">DIRECT ANSWERS</p>
          <h2 id="faq-title">关于 CodexPets 的常见问题。</h2>
          <p>简短、可核验的答案；不把 Preview 描述成已经过 Apple 验证的正式版本。</p>
        </div>
        <div className="faq-grid">
          {faqs.map((faq) => (
            <article className="faq-card" key={faq.question}>
              <h3>{faq.question}</h3>
              <p>{faq.answer}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="open-source section-shell">
        <div>
          <p className="eyebrow">FREE & OPEN SOURCE</p>
          <h2>透明、可读，也欢迎一起改进。</h2>
          <p>MIT 许可开源。你可以检查每一行代码、提交问题，或为下一只宠物贡献想法。</p>
        </div>
        <a className="button button-light" href={repositoryUrl}>在 GitHub 查看源码 ↗</a>
      </section>

      <footer className="site-footer section-shell">
        <div className="footer-brand">
          <span className="brand-mark" aria-hidden="true">✦</span>
          <strong>CodexPets</strong>
          <span>一只安静的 macOS 桌面伙伴。</span>
        </div>
        <div className="footer-links">
          <a href={repositoryUrl}>GitHub</a>
          <a href={releasesUrl}>Releases</a>
          <a href={privacyUrl}>隐私</a>
          <a href={`${basePath}/llms.txt`}>AI 索引</a>
        </div>
        <p className="disclaimer">
          独立开源项目，与 OpenAI 无隶属或背书关系。Codex 是其各自权利人的商标。
        </p>
      </footer>
    </main>
  );
}
