import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://adamadamz.github.io/codex-pets/"),
  title: "CodexPets — macOS 动态桌面宠物",
  description:
    "把 Codex 动态宠物带到 macOS 桌面。免费开源、完全离线，支持 Apple Silicon 与 Intel Mac。",
  applicationName: "CodexPets",
  keywords: ["CodexPets", "macOS", "桌面宠物", "开源", "Codex pet"],
  openGraph: {
    title: "CodexPets — 把小宠物放到桌面上",
    description: "免费开源、完全离线的 macOS 动态桌面伙伴。",
    type: "website",
    locale: "zh_CN",
    url: "https://adamadamz.github.io/codex-pets/",
    siteName: "CodexPets",
    images: [
      {
        url: "https://adamadamz.github.io/codex-pets/og.png",
        width: 1731,
        height: 909,
        alt: "CodexPets — 把小宠物放到桌面上",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "CodexPets — 把小宠物放到桌面上",
    description: "免费开源、完全离线的 macOS 动态桌面伙伴。",
    images: ["https://adamadamz.github.io/codex-pets/og.png"],
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
