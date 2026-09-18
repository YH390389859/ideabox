# IdeaBox · 日常织机

把习惯、日记与灵感收藏放在一起的原生 iPhone 应用。这一版以「织」组织整个体验：习惯成为经线，完成记录留下织结，文字、声音与链接成为可以抽出来阅读的材料。

界面采用暖纸白 `#F3F0E8`、墨色 `#202A2B`、钴蓝 `#3555E8`、黄绿 `#D9EB77` 与朱砂 `#C96C50`。大号日期、细标尺、平面文字导航和梭形「说一点」按钮构成主界面；内容以织片、打孔纸、磁带和折角薄纸呈现。

## 预览视频

[观看 iPhone 17 应用预览（2026-09-18，约 1 分 27 秒）](docs/previews/ideabox-iphone17-20260918.mp4)

预览保留完整演示时长；连接设置中涉及 API Key 的画面已遮挡。

## 三个页面

- **今天：今天，织一点。** 日期、真实完成进度和近期灵感围绕一块悬浮织片展开。每束经线对应当天安排中的真实习惯，颜色与习惯 UUID 稳定关联，近七天的完成记录形成历史织结。点击线端标签可打卡或撤销，通过「全部」进入完整习惯列表。
- **习惯：把日子，织起来。** 固定习惯名称，横向浏览一周。每天一列、每个习惯一行，完成显示织结与勾，未完成显示空环，未安排日及未来日期不可打卡。日格宽度为 44 pt，可横向滚动；支持前后周、回今天、历史补卡、频率设置和创建、编辑、删除。
- **收集：拾起，一闪而过。** 文字使用黄绿打孔纸，声音使用钴蓝磁带，链接使用折角薄纸。搜索、类型与标签筛选保持可见；详情、编辑菜单、播放与外链按钮分别操作。磁带上的等高刻纹是材料纹理，录制时的波形才来自实时麦克风音量。

底部由「今天 / 习惯 / 收集」三个浏览页面和单个梭形「说一点」记录入口组成。对话输入框下方始终显示「自己记 ↗」，可打开写文字、录声音、留链接与新增习惯选项。手动记录无需 API Key，离线可用；关闭编辑器后回到原对话并保留输入草稿。文字支持富文本、标签与心情，链接支持标题和备注，记录可继续编辑或删除。

## 说一点，织进去

「说一点」打开对话式 Agent。填写自己的 DeepSeek API Key 后，可以用一句话记录日常、完成习惯、收集链接或检索已有内容。原话是一张纸条，实际保存的操作成为穿在线上的回执，可以查看和撤回。回复通过 SSE 逐步出现，工具由 iPhone 本地执行。

已有对话时，顶部直接显示暖绿色「新对话」按钮。点击后展开「再起一线」确认纸片，只有选择「清空并开始」才清除本机的当前对话；已保存的日常、习惯和收集不删除，未发送草稿保留。选择「继续这段对话」、关闭或点击遮罩只收起纸片。

输入框左侧的麦克风支持语音转文字，无需 DeepSeek Key 即可听写。识别结果实时追加到原草稿，点击「完成」后可修改，再手动发送；「取消」恢复听写前的草稿。单次听写最长 60 秒，完成时立即停麦，最多等待 3 秒收尾。返回对话时显示最新消息，切换页面或进入后台会停止听写并保留已识别文字；未发送草稿在本次 App 运行中的页面往返间保留。

密钥保存在 iOS Keychain；模型可编辑，默认 `deepseek-flash`。App 直接连接 DeepSeek，无需先搭建后端。对话及必要的记录上下文会发送给 DeepSeek。见 [使用、架构与验证说明](docs/agent.md)、[Agent 先行设计稿](design/agent-20260915/blueprint.png)、[新版入口设计稿](design/navigation-20260915/blueprint.png) 和 [语音输入设计稿](design/voice-input-20260915/blueprint.png)。

| Agent 画面 | 产物 |
|---|---|
| 首页单一记录入口 | [navigation-home.png](docs/screenshots/navigation-home.png) |
| 手动记录选项 | [navigation-manual.png](docs/screenshots/navigation-manual.png) |
| 自定义新对话入口 | [new-conversation-entry.png](docs/screenshots/new-conversation-entry.png) |
| 再起一线确认纸片 | [new-conversation-confirmation.png](docs/screenshots/new-conversation-confirmation.png) |
| 返回长对话，保持最新消息 | [conversation-return-bottom.png](docs/screenshots/conversation-return-bottom.png) |
| 听写中（模拟识别结果） | [speech-listening-fixture.png](docs/screenshots/speech-listening-fixture.png) |
| 听写完成后编辑（模拟识别结果） | [speech-draft-fixture.png](docs/screenshots/speech-draft-fixture.png) |
| 对话首页 | [agent-welcome.png](docs/screenshots/agent-welcome.png) |
| 操作回执示例 | [agent-receipts.png](docs/screenshots/agent-receipts.png) |
| DeepSeek 设置 | [agent-settings.png](docs/screenshots/agent-settings.png) |
| 撤回状态 | [agent-undone.png](docs/screenshots/agent-undone.png) |
| 375 pt 小屏 | [agent-compact.png](docs/screenshots/agent-compact.png) |
| 原生线束动画 | [agent-motion.mp4](docs/screenshots/agent-motion.mp4) |

截图使用隔离的预览数据；回执通过本地工具创建，尚未使用真实 DeepSeek Key 发起模型对话。

上一版 Agent 的数据、SSE、上下文预算和多轮工具测试通过；3 条原生界面测试通过，并已检查 iPhone 17 与 iPhone SE 3 布局。此前入口重排已通过 iPhone 17 构建及两条原生界面测试：无 Key 手动记录往返与草稿保留、已有对话中的常驻入口与回执撤回；新版截图已检查。

## 织面与动效

`WovenArtwork.swift` 使用 SwiftUI Canvas 绘制经纬线、透视曲面与历史结点。轻拖织面可改变张力和倾角，松手后柔和回弹；对应习惯完成状态变化时，相关经线短暂收紧。实际打卡按钮由 SwiftUI 叠层提供清楚的点击区域与无障碍标签。

新开屏由 `AppLaunchView.swift` 编排：交织标记展开，梭子往返穿线，织片逐渐形成，品牌字样依次显现，再过渡到首页。总时长约 2.6 秒，支持跳过；返回前台不重播。开屏中的织片为品牌动画，首页织片绑定用户记录。

系统开启「减少动态效果」时，持续变形、拖拽透视与复杂开屏停用，改为短暂淡化。首页织面在隐藏页面或非活跃场景停止持续绘制；开屏进入后台时直接结束剩余编排。切换页面会收起收集页搜索键盘。

## 数据与录音

- 本地 JSON 持久化；首次提供示例，已有记录、UUID 与录音文件沿用，不因视觉更新重新播种。
- 损坏文件会备份；未知新版本的数据文件不会被覆盖。存储错误和恢复文件状态在界面中明确提示。
- `AVAudioRecorder` / `AVAudioPlayer` 实现真实录音、暂停、继续、试听与保存；多个播放实例互斥，开始录音前停止播放，取消后清理未保存文件。
- Agent 语音输入使用 Apple Speech 与麦克风音频流，把语音转成可编辑草稿，不保存音频文件；「收集 / 自己记 → 录一段」仍用于保存可播放的录音。语音输入优先使用设备端识别，设备或语言不支持时可能联网并向 Apple 发送识别音频。
- 缺少音频文件的旧示例显示「仅文字备忘」，不提供虚假播放按钮或时长。
- 网页地址仅接受有效的 HTTP / HTTPS 链接。

内容保存在 App 沙盒的 `Application Support/IdeaBox`，包括 `library.json`、`agent-conversation.json` 与 `Recordings`。应用没有账户或云同步；AI 为用户自带 Key 的 DeepSeek 服务。录音需要麦克风授权，语音输入还需语音识别授权，首次点击麦克风时申请。真实语音识别质量、设备端识别可用性和音频中断应在真机验收。习惯副标题反映计划频率，不代表已实现定时提醒。

## 设计源文件

日常织机最初先完成三屏设计图，再进入原生开发：

- [blueprint.svg](design/loom-20260906/blueprint.svg)：可编辑的 1500 × 1150 三屏布局板，每屏按 402 × 874 pt 设计。
- [blueprint.png](design/loom-20260906/blueprint.png)：同源 3000 × 2300 完整预览。
- [design-notes.md](design/loom-20260906/design-notes.md)：逐屏尺寸、配色、状态、交互与动效规范。
- [product-direction.md](design/loom-20260906/product-direction.md)：设计方向与功能边界。
- [brand](design/loom-20260906/brand/README.md)：新交织图标、静态启动资源及生成脚本。

入口重排的 [设计图](design/navigation-20260915/blueprint.png)、[可编辑 SVG](design/navigation-20260915/blueprint.svg) 与 [交互说明](design/navigation-20260915/design-notes.md) 位于 `design/navigation-20260915`。

语音输入同样先完成 [三屏设计图](design/voice-input-20260915/blueprint.png)，再开发原生界面；[可编辑 SVG](design/voice-input-20260915/blueprint.svg)、[交互说明](design/voice-input-20260915/design-notes.md) 及生成脚本位于 `design/voice-input-20260915`，展示正常输入、听写中与转写后编辑三个状态。

新对话入口与确认层先完成 [两屏设计图](design/new-conversation-20260915/blueprint.png)，再替换原生菜单和确认样式；[可编辑 SVG](design/new-conversation-20260915/blueprint.svg)、[交互说明](design/new-conversation-20260915/design-notes.md) 及生成脚本位于 `design/new-conversation-20260915`。确认纸片中的旧线收束、蓝线延展只播放一次；开启「减弱动态效果」时使用短暂淡化。

设计板由 `generate-blueprint.py` 生成 SVG，再由 `render-blueprint.swift` 按完整画布输出 PNG。设计图中的日期、文字与数量为布局示例，运行界面使用实际数据。

日常织机首版已在 iPhone 17（402 pt）与 iPhone SE 3（375 pt）模拟器检查三页布局，并录制原生开屏。带签名的 Debug 构建、Swift 6 数据回归测试均通过。截图与录屏如下：

| 产物 | 路径 |
|---|---|
| 今天页 | [01-today.png](docs/screenshots/01-today.png) |
| 习惯页 | [02-habits.png](docs/screenshots/02-habits.png) |
| 收集页 | [03-collection.png](docs/screenshots/03-collection.png) |
| 375 pt 小屏布局 | [04-compact.png](docs/screenshots/04-compact.png) |
| 织造开屏录屏 | [launch-preview.mp4](docs/screenshots/launch-preview.mp4) |

## 运行与构建

使用 Xcode 打开 `IdeaBox/IdeaBox.xcodeproj`，选择 `IdeaBox` scheme 与 iPhone 模拟器运行。最低 iOS 17，Swift 6；富文本编辑器已保存在 `IdeaBox/Vendor`，无需另行拉取远端依赖。

当前工作机的 Xcode 位于 `/Applications/Xcode-beta.app`。终端命令通过 `DEVELOPER_DIR` 选择该 Xcode，避免使用默认的 Command Line Tools。新增源文件或修改配置后，先重新生成工程：

```sh
xcodegen generate --spec IdeaBox/project.yml
```

模拟器构建保留 Xcode 默认的本地签名，或明确使用 ad-hoc 签名；静态启动页资源也需要随应用一起签名：

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project IdeaBox/IdeaBox.xcodeproj \
  -scheme IdeaBox -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build-loom-20260906 \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
```

不要通过 `CODE_SIGNING_ALLOWED=NO` 关闭整个 App 的签名；此项目的模拟器启动资源验收使用完整本地签名。真机运行时，在 Xcode 的 Signing & Capabilities 中选择自己的开发团队，并按需要调整 Bundle Identifier。

## 数据测试

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcrun swiftc -swift-version 6 IdeaBox/AppModel.swift IdeaBox/AgentTools.swift Tests/AppModelTests.swift \
  -o /tmp/IdeaBoxModelTests
/tmp/IdeaBoxModelTests
```

测试覆盖连续打卡、计划频率、CRUD 与重启保留、旧数据兼容、损坏恢复、未知版本保护和录音文件路径安全。测试使用独立临时目录，不读写模拟器中的用户数据。

完整 Agent 检查：`bash scripts/test-agent.sh`。这包含本地工具、SSE 和注入测试响应的多轮对话验证；真实 DeepSeek 连接需在 App 中填写密钥后验证。

语音输入的纯草稿合并测试 `Tests/SpeechInputTests.swift` 已通过，覆盖分段识别替换、原稿保留、空结果与 Unicode 字数限制；`Tests/SpeechRecognitionRecoveryTests.swift` 验证本地启动失败的一次回退条件。两者均已纳入 `scripts/test-agent.sh`，不验证 Apple Speech 的真实识别效果。当前 iOS 27 模拟器实际返回错误 300，系统无法加载语音模型文件，回退后仍失败；此环境的真实转写尚未恢复，详见 [语音故障记录](docs/agent.md#语音输入)。

本次滚动与语音界面回归已通过 3 / 3 条原生测试：长对话在页面往返、键盘展开和返回前台后保持最后消息与草稿；听写取消、完成、编辑及手动记录往返；重复权限错误后的原稿保留、继续输入与重新打开对话。两条语音测试使用注入的识别结果和权限错误，不调用麦克风或 Apple Speech 服务，也不代表真实系统权限或识别验证通过。

另在独立临时 iPhone SE 3 模拟器通过 1 条真实系统权限测试：拒绝 iOS 语音识别授权后不闪退，多次重试、编辑和页面往返仍保留草稿。共 4 条相关界面测试通过。真实权限测试不申请麦克风权限、不录音，不代表实际语音转写已验收。

Debug 构建可通过 `SIMCTL_CHILD_IDEABOX_PREVIEW_TAB` 选择截图初始页，支持 `dashboard`、`habits`、`clips`。例如，将 `SIMULATOR_UDID` 替换成已启动模拟器的标识：

```sh
SIMCTL_CHILD_IDEABOX_PREVIEW_TAB=clips \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcrun simctl launch --terminate-running-process SIMULATOR_UDID com.example.IdeaBox
```

正常启动进入今天页。初始页参数只影响 Debug 导航，不改用户数据。

Agent 的 Debug 截图状态通过 `SIMCTL_CHILD_IDEABOX_AGENT_PREVIEW` 选择：`welcome`、`receipts`、`settings`，以及本次新增的 `scroll`（长对话）、`speech`（长对话与模拟听写）、`speech-error`（模拟权限错误）。其中 `speech` 和 `speech-error` 点击麦克风后使用固定测试结果，不申请权限、不录音；`scroll` 只预置长对话，麦克风仍走真实权限与识别路径。各状态使用隔离数据与空的预览密钥存储，正常运行不设置这个变量。详见 [Agent 验证与预览说明](docs/agent.md#验证)。

## 源码入口

- `LoomDesign.swift`：日常织机配色、标题、梭形与交织标记。
- `DesignSystem.swift`：共享排版、表单与按钮反馈。
- `WovenArtwork.swift`：由习惯记录驱动的 Canvas 织面与张力交互。
- `AppLaunchView.swift`：织造开屏、跳过与生命周期处理。
- `ContentView.swift`：三个浏览页面的平面导航和单个「说一点」入口。
- `AgentScreen.swift`：对话、真实操作回执、保持最新消息可见的滚动行为及文字 / 语音输入区。
- `NewConversationPrompt.swift`：新对话织线标记、自绘确认纸片、明确的清空操作与可取消路径。
- `SpeechInputController.swift`：Apple Speech、按需权限申请、实时音量、识别状态及麦克风生命周期。
- `SpeechInputDraft.swift`：将本次识别结果合并进已有草稿，保持原文及 4,000 字上限。
- `DashboardScreen.swift`、`HabitsScreen.swift`、`ClipsScreen.swift`：三屏及相关编辑流程；收藏材料背景可复用。
- `AppModel.swift`：数据、排期、统计和持久化。
- `AudioRecorder.swift`：真实音频生命周期与跨实例播放互斥。
