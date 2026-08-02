# Contributing to CodexPets

感谢你愿意帮助 CodexPets 变得更好。

## 开始之前

- 新功能或明显改变交互的提案，请先开 Issue 说明用户场景。
- 修复应尽量小，并保持 App 离线、无遥测、无第三方运行时依赖。
- 不要提交真实用户数据、签名证书、Apple 凭据或宠物素材，除非你拥有明确的再分发权。

## 本地检查

需要 macOS 14+、Xcode 26.x 与 XcodeGen：

```bash
xcodegen generate
xcodebuild \
  -project CodexPets.xcodeproj \
  -scheme CodexPets \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/CodexPetsDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

官网位于 `website/`：

```bash
cd website
npm ci
npm test
GITHUB_PAGES=true NEXT_PUBLIC_BASE_PATH=/codex-pets npm run build:pages
```

提交 Pull Request 时，请说明改动、原因、用户影响与完成的检查。
