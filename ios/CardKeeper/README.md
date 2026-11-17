# 卡管家 · iOS App（可出 IPA）

信用卡账单 / 活动 / 提醒管理 App，SwiftUI 编写，iOS 16+。

```
CardKeeper/
├── CardKeeper.xcodeproj/          # Xcode 工程（已配好 target / scheme / 图标）
├── CardKeeper/                    # 全部源码
│   ├── CardKeeperApp.swift        # 入口 + TabView
│   ├── Models.swift               # 数据模型 + Store + 演示数据
│   ├── Theme.swift                # 配色 / 格式化 / 通用组件 / 卡面
│   ├── HomeView.swift             # 首页：总览 + 卡片横滑 + 提醒
│   ├── BillsView.swift            # 账单：筛选 + 汇总 + 按日明细
│   ├── ActivitiesView.swift       # 活动：打卡 / 记一笔 / 详情 / 添加表单
│   ├── StatsView.swift            # 统计：环形图 / 趋势 / 额度 / 排行
│   ├── ProfileView.swift          # 我的：提醒开关 / 卡片编辑
│   ├── Notifier.swift             # 本地通知（还款 + 活动提醒）
│   └── Assets.xcassets            # App 图标 + 强调色
└── .github/workflows/build-ipa.yml # 云端自动出 IPA
```

## 为什么这里不能直接给你 IPA

IPA 内部是链接了 Apple iOS SDK 的 arm64 二进制，**必须用 macOS + Xcode 编译**。
本环境是 Linux，没有 iOS SDK，无法产出真正可安装的 IPA。

因此提供两条**都能拿到 IPA** 的路径，选一条即可：

---

## 路径 A（推荐）：GitHub 云端构建，不需要 Mac

1. 注册 / 登录 [github.com](https://github.com)，新建一个**公开仓库**（如 `cardkeeper`）；
2. 把 `CardKeeper` 文件夹里的所有内容（含隐藏的 `.github`）上传到仓库根目录；
   - 网页端拖拽上传即可，注意把 `.github/workflows/build-ipa.yml` 传上去；
3. 打开仓库的 **Actions** 页签 → 左侧 **Build IPA** → 右上 **Run workflow**；
4. 构建约 2–3 分钟，完成后在该次运行页面底部的 **Artifacts** 下载 `CardKeeper-unsigned-ipa`，
   解压得到 `CardKeeper-unsigned.ipa`（未签名）；
5. 签名安装（见下方「签名与安装」）。

> 每次改动代码 push 上去都会自动重新构建。

## 路径 B：有 Mac / 借一台 Mac

1. 把 `CardKeeper` 文件夹拷到 Mac，双击 `CardKeeper.xcodeproj` 打开；
2. 选中项目 → **Signing & Capabilities** → 勾选 Automatically manage signing，选择你的 Team
   （没有付费账号时，用免费 Apple ID 在 Xcode → Settings → Accounts 登录即可）；
3. iPhone 用数据线连接，信任电脑，顶部选择你的手机 → **Run（⌘R）** 直接安装调试；
4. 或 **Product → Archive → Distribute App → Custom / Development** 导出已签名 IPA。

---

## 签名与安装（针对未签名 IPA）

| 工具 | 平台 | 说明 |
|---|---|---|
| **Sideloadly** | Windows / Mac | 最简单。IPA 拖进去 + 填自己的 Apple ID → 签名 → 安装。免费账号 7 天有效期，最多 3 台设备 |
| **AltStore / SideStore** | iOS | 手机端自签 + 自动续签 |
| **TrollStore** | iOS 14.0–16.6.1（部分版本） | 永久签名，可直接装未签名 IPA |
| **付费开发者账号** | — | 签名后 1 年有效 |

如果 Sideloadly 报 bundle id 冲突，在它的选项里把 Bundle ID 改成
`com.你的名字.cardkeeper` 再签即可。

## 功能对照

| 功能 | 实现位置 |
|---|---|
| 账单日 / 还款日管理（增删改） | ProfileView（卡片管理）+ Models |
| 还款倒计时 / 本期应还 | Models 计算属性 + HomeView 卡面 |
| 账单明细与总额 | BillsView（按卡筛选 + 按日分组） |
| 可视化 | StatsView（自绘环形图 / 柱状图，无第三方依赖） |
| 活动自定义（次数 / 金额 / 单次） | ActivitiesView + ActivityEditorView |
| 打卡确认完成 | Store.toggleStep / checkNextStep / setDone |
| 消息提醒 | Notifier：还款提前 N 天每月循环提醒 + 活动按周期提醒（UserNotifications 本地通知，数据不出设备） |
| 数据持久化 | UserDefaults + Codable，首次启动自动载入演示数据，「我的 → 重置演示数据」可还原 |

## 二次开发提示

- 改 App 名字：`project.pbxproj` 里 `INFOPLIST_KEY_CFBundleDisplayName`；
- 改 Bundle ID：`PRODUCT_BUNDLE_IDENTIFIER`（签名前改成自己的）；
- 最低系统：iOS 16.0（在 target 的 `IPHONEOS_DEPLOYMENT_TARGET`）；
- 通知需要授权：首次启动会弹出，也可在系统设置里手动开启。
