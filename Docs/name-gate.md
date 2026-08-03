# CodexPets / FuzzOrbit 名称门禁

> 核验日期：2026-08-03（Asia/Shanghai）  
> 外部候选名：`FuzzOrbit` / `Fuzz Orbit`  
> 当前开源项目名：`CodexPets`  
> 目标市场与语言：美国（英语）、中国大陆（简体中文）  
> 产品类别：macOS Utilities；本地桌面宠物播放器与 Codex v2 宠物制作工具  
> 结论：**Conditional Go**

## 1. 结论与限制

`FuzzOrbit` 可继续作为可逆的外部工作名，用于 v0.2 原型、内部文档和未发布草案；目前不能声称该名称已获 Apple 或法律清除。

在门禁升级为 `Pass` 前：

- 不在 App Store Connect 提交或公开宣称正式商店名称；
- 不创建或迁移生产 Bundle ID、StoreKit 产品 ID、App Group、Keychain Group；
- 不最终定稿商店截图、广告、正式域名、支持邮箱或公开投放资产；
- 当前 `com.decodegroup.codexpets` 仅视为既有工程标识，不把它当作已清除的生产品牌证明；
- v0.2 的代码审查、原型实现、无签名构建和定向测试可以继续。

阻塞项负责人：项目所有者负责 App Store Connect 名称占位、域名购买决定和法律近似审查；合格中国商标顾问负责 CNIPA 近似检索。

## 2. App Store 检索

数据源：Apple Search API，查询时间 `2026-08-03T01:26Z`，实体 `macSoftware`，上限 50。

| 店面 | 查询 | resultCount | 精确同名 |
|---|---:|---:|---|
| US | `FuzzOrbit` | 0 | 无 |
| US | `Fuzz Orbit` | 2 | 无 |
| CN | `FuzzOrbit` | 0 | 无 |
| CN | `Fuzz Orbit` | 0 | 无 |
| US | `CodexPets` | 16 | 无 |
| US | `Codex Pets` | 33 | 无 |
| CN | `CodexPets` | 0 | 无 |
| CN | `Codex Pets` | 3 | 无 |

可复现查询：

- `https://itunes.apple.com/search?term=FuzzOrbit&country=us&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=Fuzz%20Orbit&country=us&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=FuzzOrbit&country=cn&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=Fuzz%20Orbit&country=cn&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=CodexPets&country=us&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=Codex%20Pets&country=us&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=CodexPets&country=cn&entity=macSoftware&limit=50`
- `https://itunes.apple.com/search?term=Codex%20Pets&country=cn&entity=macSoftware&limit=50`

无精确同名只代表这次公开查询没有返回精确 `trackName`；它不代表 App Store Connect 可以占位，也不代表名称或商标已清除。

## 3. 公开 Web 与类别混淆

公开 Web 初筛使用 Bing RSS 搜索，查询包括 `"FuzzOrbit"`、`"Fuzz Orbit"`、`"FuzzOrbit" app`、`"FuzzOrbit" software`、`"CodexPets"` 和 `"Codex Pets"`。

- `FuzzOrbit`：本次结果未识别到同名软件或桌面宠物产品；搜索结果相关性很低，因此只能作为弱初筛证据。
- `Codex Pets`：已存在多个同类或相邻生态站点与仓库，包括 `https://www.codexpets.app/`、`https://codexpets.org/gallery`、`https://codex-pet.org/zh/codex-pets/` 和 `https://github.com/YaKun9/codex-pets`。
- `Codex` 本身属于 OpenAI 产品/商标语境；当前仓库已经声明“独立开源项目，与 OpenAI 无隶属或背书关系”。该免责声明不能产生品牌权利，也不能消除同类生态混淆。

因此，`CodexPets` 不作为未受限的生产品牌候选；它只保留为当前项目和兼容性描述。公开营销如继续使用，仍需单独评估描述性使用、混淆和平台政策风险。

## 4. 域名与社交标识

查询时间：`2026-08-03T01:27Z`。

| 标识 | 结果 | 数据源 |
|---|---|---|
| `fuzzorbit.com` | 无 RDAP 记录（HTTP 404） | `https://rdap.verisign.com/com/v1/domain/fuzzorbit.com` |
| `fuzzorbit.app` | 无 RDAP 记录（HTTP 404） | `https://pubapi.registry.google/rdap/domain/fuzzorbit.app` |
| GitHub `fuzzorbit` | HTTP 404 | `https://github.com/fuzzorbit` |
| X `fuzzorbit` | HTTP 404 | `https://x.com/fuzzorbit` |

RDAP 或公开页面 404 不等于“可注册/可占用”。购买和创建账号前必须即时复查，并同时确认支持邮箱域名。

## 5. 商标初筛与限制

美国官方来源：USPTO Trademark Search，`https://tmsearch.uspto.gov/search/search-results`，查询时间 `2026-08-03T01:31Z`。

- Wordmark `FuzzOrbit`：官方结果显示 Live 0、Dead 0，未发现精确记录。
- Wordmark `Fuzz Orbit`：系统按词项返回 1,117 条宽泛结果；其中存在多个 live `ORBIT` 软件相关记录，至少包括第 009/042 类的序列号 `90199815`（Ommo Technologies, Inc.）和 `90211922`（Andrew M. Matuschak）。这些不是 `FuzzOrbit` 精确同名，但说明 `ORBIT` 在目标软件类别中拥挤，必须做组合词、读音、外观和商品/服务近似分析。
- 本次未完成律师级相似性意见；“精确无结果”不得表述为“商标已清除”。

中国大陆：CNIPA 官方检索入口本次自动访问失败，未形成可复核结果；第 009、042 类及中文音译/近似词检索仍待合格中国商标顾问完成。

## 6. 候选集合

为满足首轮发现范围，检查了 13 个候选/变体：`FuzzOrbit`、`Fuzz Orbit`、`PetOrbit`、`OrbitFuzz`、`SpriteNest`、`PixelPaws`、`Petloom`、`SpriteMates`、`Pawsprite`、`DeskCritter`、`MascotForge`、`SpriteBuddy`、`PetAtlas`。

- `PetAtlas`：US App Store 已有精确同名 `PetAtlas`（Brent Gaddis），拒绝。
- `PetOrbit`：`.com` 与 `.app` 均有 RDAP 记录，不优先。
- `PixelPaws`、`Petloom`、`Pawsprite`、`MascotForge`、`SpriteBuddy`：`.com` 已注册；名称也偏描述性，本轮不选。
- `OrbitFuzz`、`SpriteNest`、`SpriteMates`、`DeskCritter`：仅完成发现级初筛，未进行完整 Web/商标相似性检索，不能替代候选名重新门禁。
- `FuzzOrbit`：保留为当前外部工作名；因 USPTO 中 `ORBIT` 软件类记录拥挤、CNIPA/法律复核和 Apple 名称占位未完成，结论保持 `Conditional Go`。

## 7. 门禁摘要

```text
Name gate: Conditional Go
Candidate: FuzzOrbit（工作名）；CodexPets（现有开源项目名，不作为已清除品牌）
App Store: US/CN 的 FuzzOrbit / Fuzz Orbit 无精确同名；未验证 App Store Connect 占位
Web/category: FuzzOrbit 未见明确同类冲突；Codex Pets 已存在多个同类生态站点/仓库
Domain: fuzzorbit.com / .app 无 RDAP 记录，未购买、不可宣称可用
Trademark: USPTO 精确 FuzzOrbit 无结果，但 ORBIT 在 009/042 类拥挤；CNIPA 与法律近似审查未完成
Apple account: pending
Allowed next step: prototype / internal development / reversible draft assets
Blockers: App Store Connect 名称占位、CNIPA 检索、US/CN 法律近似审查、域名即时复查与购买
```
