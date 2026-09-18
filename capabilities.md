# Booply — 配置文档

生成时间：2026-09-18

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强/上架项**。不配置它们，App 下载后仍可正常使用所有核心功能（儿童流、月龄引擎、家长舱、回执、里程碑、本地 AI 降级）。配置后可获得完整商业闭环。

### 🔵 IAP StoreKit 配置（必须 — 否则无法产生收入）

**影响功能**：不创建 IAP 产品，付费墙按钮将无法完成购买（免费层不受影响）

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → **Booply**（需先创建 App 记录，Bundle ID `com.zzoutuo.Booply`）
2. 左侧 **Features** → **In-App Purchases** → **"+"** 创建订阅组，组名 `Booply Pro`
3. 在组内创建 2 个自动续订订阅：

| 产品 | Reference Name | Product ID | 价格 | 试用 |
|------|---------------|-----------|------|------|
| 月付 | Booply Pro Monthly | `booply.pro.monthly` | $3.99/月 | 7 天免费试用 |
| 年付（主推） | Booply Pro Annual | `booply.pro.yearly` | $19.99/年 | 7 天免费试用 |

4. 在 **Features → In-App Purchases** 页面底部另创建 1 个非消耗型（Non-Consumable）：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 买断 | Booply BYO Lifetime | `booply.lifetime.byo` | $14.99 一次性 |

5. 每个产品的 Display Name 与 Description 从 `price.md` 直接复制（已校验 ≤35/≤55 字符）
6. 月付与年付开启 **Family Sharing**；本地化语言选 English (U.S.)
7. ⚠️ 产品创建后需等待 Apple 生效（通常 1-2 小时），之后在 Xcode 中用 Sandbox 账号走一遍购买/恢复/取消
8. 代码侧已就绪：`PurchaseManager.swift` 中三个 Product ID 已硬编码一致，无需改代码

---

### 🟡 Capabilities 增强配置（可选 — Pro 的 iCloud 同步）

#### iCloud CloudKit 容器

**增强功能**：Pro 用户的里程碑/回执跨设备同步
**不配置的影响**：App 使用本地 SwiftData 存储，一切功能正常，仅无跨设备同步
**当前状态**：代码已优雅降级——设置页开关存在，未配置时提示"使用本地存储"

**已自动配置部分**：
- ✅ 代码已实现优雅降级（`CockpitView.swift` 检测 `ubiquityIdentityToken`）
- ✅ Team JP4TN5PTS3 已配置在所有 target

**如需启用，请手动配置**：
1. 用 Xcode 打开 `Booply.xcodeproj` → 选中 Booply target → **Signing & Capabilities**
2. 点击 **"+ Capability"** → 添加 **iCloud** → 勾选 **CloudKit**
3. 点击 Containers 下的 **"+"**，创建容器 `iCloud.com.zzoutuo.Booply`
4. ⚠️ 配置完成后重新 Build 验证

---

### 🟢 App Store Connect 审核信息配置（必须 — 防 Guideline 2.1(a) 拒审）

**影响功能**：不配置则审核员可能无法理解订阅/AI 结构，增加拒审风险

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. 将项目根目录 `app_review_info.md` 的内容分别粘贴到 **Demo Account** 与 **Notes** 字段
3. Notes 中已包含：儿童锁通过方法（角落长按 1.5 秒 + 两道算术题）、三个产品 ID 与价格、BYO Key 模式声明、COPPA 零采集声明
4. ⚠️ **Privacy Policy URL** 填：`https://asunnyboy861.github.io/Booply/privacy.html`
5. ⚠️ App Description 末尾或 EULA 字段包含 Terms 链接：`https://asunnyboy861.github.io/Booply/terms.html`

---

### 🟣 上线后可选项（不阻塞提审）

| 项目 | 说明 | 操作时机 |
|------|------|----------|
| GLM 代理 Worker 部署 | Pro 用户免配置使用 GLM 视觉/周报（BYO 用户不受影响） | 部署 Cloudflare Worker（指南第七章代码）→ `wrangler secret put ZAI_API_KEY` → 把 Worker URL 填入 `AIServices.swift` 的 `GLMProxy.url` |
| Landing Page App Store ID | 当前为 "Coming Soon" 占位 | App Store Connect 创建 App 后，把 `docs/index.html` 中 `[APP_STORE_ID]` 替换为 Apple ID 数字 |
| 命名验证五步清单 | 指南第〇章：ASC 占用检查 / 商标检索等 | 提审前完成 |

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| In-App Purchase | StoreKit 2 无需 entitlement 文件，产品 ID 已对齐 price.md | ✅ 已配置 |
| Photo Library | 家长侧相册权限描述已写入 Info.plist（仅家长主动添加照片） | ✅ 已配置 |
| Development Team | JP4TN5PTS3 全 target 已配置 | ✅ 已配置 |
| Bundle ID | 已修正为 com.zzoutuo.Booply | ✅ 已配置 |
| 儿童模块隔离 | Kid 文件夹零 Network import、零外链、零广告（COPPA） | ✅ 已实现 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers：`https://feedback-board.iocompile67692.workers.dev/api/feedback` | ✅ 已部署并接入 |
| 政策页面 | GitHub Pages 已上线（privacy/support/terms/landing 全部 200） | ✅ 已部署 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 23 个 Swift 文件，MVVM，30/30 功能落地 | ✅ 已完成 |
| 购买体系 | PurchaseManager + 透明价格墙 + 两键取消 | ✅ 已完成 |
| AI 模块 | Apple Intelligence 回执（iOS 26+ 端侧）+ 本地模板降级 + BYO Keychain | ✅ 已完成 |
| 联系客服 | 7 主题磁贴 + 全必填校验 + 成功/失败反馈 | ✅ 已完成 |
| 单元测试 | 月龄引擎/里程碑阈值/购买档位 15 个用例 | ✅ 全部通过 |
| QA 迭代 | 12 项问题修复（含 Vortex API/并发隔离），双端真机化验证 | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能**：App 默认使用 Apple Intelligence（端侧，免费零配置）生成回执文案；不可用时自动降级本地模板，回执永不为空。买断用户可在 **Settings → AI Configuration** 输入自己的 Z.ai API Key（存 Keychain），解锁照片标记与周报的无限使用。这是用户操作，非开发者配置。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/Booply（main 已推送） | ✅ 已完成 |
| GitHub Pages | https://asunnyboy861.github.io/Booply/ | ✅ 已上线 |
| App Store 元数据 | keytext.md 已生成并通过 16/16 校验 | ✅ 已完成 |
| 定价配置 | price.md 已生成（3 产品 + 免费层） | ✅ 已完成 |
| 审核信息 | app_review_info.md 已生成 | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，内容已重组到上方 Section 一/二。

### Analysis

关键词检测命中：订阅/购买/买断 → In-App Purchase；iCloud 私有库/多设备同步 → iCloud (CloudKit)；照片/相册 → Photo Library；儿童侧零网络 → 无网络能力（设计使然）。未命中：推送、HealthKit、定位、相机、Sign in with Apple。

### No Configuration Needed

- Push Notifications — 未使用
- HealthKit — 未使用
- Location — 未使用
- Camera — 未使用（仅相册读取）
- Sign in with Apple — 未使用（零账号架构）
- Guided Access — 系统功能，App 仅提供可选帮助页

### Verification

- 构建成功（配置后）：✅ iPhone 17 / iPad Pro 13" (M5) 双端 BUILD SUCCEEDED
- 单元测试：✅ 15/15 通过
- Entitlements：✅ 当前范围无需 entitlements 文件
