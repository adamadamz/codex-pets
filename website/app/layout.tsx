import type { Metadata, Viewport } from "next";
import "./globals.css";

const siteUrl = "https://adamadamz.github.io/codex-pets/";
const repositoryUrl = "https://github.com/adamadamz/codex-pets";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "CodexPets — 免费开源的 macOS 动态桌面宠物",
    template: "%s · CodexPets",
  },
  description:
    "CodexPets 是免费开源、完全离线的 macOS 动态桌面宠物，支持 macOS 14、Apple Silicon 与 Intel Mac，可导入标准动态宠物包。",
  applicationName: "CodexPets",
  authors: [{ name: "CodexPets Contributors", url: repositoryUrl }],
  creator: "CodexPets Contributors",
  publisher: "CodexPets Contributors",
  category: "Utilities",
  keywords: [
    "CodexPets",
    "macOS 桌面宠物",
    "Mac 动态宠物",
    "桌面伙伴",
    "开源 macOS 应用",
    "离线桌面宠物",
    "animated desktop pet",
    "open source macOS app",
  ],
  alternates: {
    canonical: siteUrl,
    languages: { "zh-CN": siteUrl },
  },
  manifest: `${siteUrl}site.webmanifest`,
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  openGraph: {
    title: "CodexPets — 免费开源的 macOS 动态桌面宠物",
    description: "完全离线，支持 Apple Silicon 与 Intel Mac；导入标准宠物包，把动态伙伴放到桌面上。",
    type: "website",
    locale: "zh_CN",
    url: siteUrl,
    siteName: "CodexPets",
    images: [
      {
        url: `${siteUrl}og-v2.png`,
        width: 1200,
        height: 630,
        alt: "CodexPets — 把小宠物放到 macOS 桌面上",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "CodexPets — 免费开源的 macOS 动态桌面宠物",
    description: "完全离线，支持 Apple Silicon 与 Intel Mac；可导入标准动态宠物包。",
    images: [`${siteUrl}og-v2.png`],
  },
};

export const viewport: Viewport = {
  themeColor: "#f6f1e8",
  colorScheme: "light",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  );
}
