# 对话式日常记录

先完成 [Agent 三屏设计图](../design/agent-20260915/blueprint.png)，再实现 SwiftUI 页面；入口调整和语音输入也分别先完成 [新版入口设计图](../design/navigation-20260915/blueprint.png) 与 [语音输入三屏设计图](../design/voice-input-20260915/blueprint.png)。新对话入口与「再起一线」确认纸片也先完成 [两屏设计图](../design/new-conversation-20260915/blueprint.png)。设计源为各目录的 SVG，沿用项目既有矢量设计体系输出 PNG；布局与交互说明见 [语音输入说明](../design/voice-input-20260915/design-notes.md) 与 [新对话说明](../design/new-conversation-20260915/design-notes.md)。

## 使用

首页底部保留「今天 / 习惯 / 收集」三个浏览页面与单个梭形「说一点」记录入口。点击「说一点」进入对话，右上角齿轮打开 DeepSeek 设置。在手机里填写自己的 API Key 和账号可用的模型名称，点击「保存并连接」。默认模型为 `deepseek-flash`；可按账号权限修改。测试连接会发起一次很短的模型请求。

API Key 使用普通文本输入框，默认显示输入内容，支持直接输入、系统长按粘贴、选择及替换。没有额外的粘贴按钮或密码显示切换。点击「保存并连接」时会清理首尾空白；设置页在 App 非活跃时由隐私遮罩覆盖，密钥仍使用 Keychain 保存。

在 Mac 复制后按 `⌘V` 无效时，还需检查模拟器的剪贴板同步。本机 Xcode 27 的 DeviceHub 使用 `Edit → Use Shared Clipboard`；`Edit → Send Clipboard` 可将 Mac 当前剪贴板传入选中的设备，再在输入框内粘贴。曾实际发现 Mac 有文本而 iPhone 模拟器剪贴板为空，显式同步后两端一致。下文的自动化粘贴测试只覆盖设备内部的系统编辑菜单，不覆盖 Mac 剪贴板同步或 DeviceHub 的快捷键转发。

对话输入框下方始终显示「自己记 ↗」。点击后打开手动记录选项，可写文字、录声音、留链接或添加习惯，不需要 API Key，离线时也可使用。关闭手动编辑器后回到原对话，保留未发送的输入草稿。文字支持富文本、标签与心情，链接支持标题和备注，记录可继续编辑或删除。

返回对话时显示最新消息，键盘出现和 App 回到前台时也会保持底部可见。未发送草稿由首页持有，在本次 App 运行中关闭、重新打开对话仍保留；这不代表草稿已经保存为日常记录或支持 App 重启恢复。

已有对话或需要处理对话错误时，顶部直接显示暖绿色「新对话」入口，点击后展开自绘的「再起一线」纸片。纸片明确说明：将清空本机当前对话，已保存的日常、习惯和收集仍会保留。只有「清空并开始」执行清空；「继续这段对话」、右上角关闭与点击遮罩均只取消确认，原对话和未发送草稿保留。确认后未发送草稿也继续保留，用户可以修改后再发出。模型生成过程中暂不开放新对话操作，避免打断正在执行的工具。

打开纸片会收起键盘、停止听写并保留已识别文字。纸片使用一次性的蓝线延展与轻微浮入，支持系统「减弱动态效果」；内容较高时可纵向滚动，关闭按钮与两个操作提供至少 44 pt 点击区域。

例如：「今天阅读打卡完成了。再记下：留白也很重要。」Agent 会根据实际习惯名称与完成条件执行打卡，并保存你指定的文字。如果习惯或日期不明确，会先询问。每个成功的操作都有真实回执，可查看原记录，或撤回仍未被修改的本次操作。

目前提供文字与语音输入、日记保存、明确完成状态的习惯打卡、HTTP(S) 链接收藏、本地检索和撤回。现有保存录音功能保留；Agent 暂未接入网页抓取、数量型习惯、定时提醒或跨设备同步。已有正文可从回执的「查看」进入原编辑器修改。

## 语音输入

轻点输入框左侧麦克风，首次使用时按系统提示允许语音识别与麦克风权限。听写不需要 DeepSeek API Key；浅暖绿状态区显示实时声量、经过时间和「取消 / 完成」，文字实时出现在原输入框中。每次更新替换本次听写片段，保留原草稿，避免把重复的中间识别结果叠加进去。

听写时暂时停用文本编辑与发送，避免识别更新和键盘输入互相覆盖。点击「完成」立即停止麦克风，最多等待 3 秒接收最终文字和标点，然后保留为可编辑草稿。单次听写最多 60 秒，输入总长度最多 4,000 字。点击「取消」恢复听写前的原稿。听写不会自动发送，用户检查、修改后再点击梭形发送按钮。

切换到设置、手动记录、离开对话或进入后台时，停止麦克风并保留已识别文字。权限未允许时提供系统设置入口；没有听清或识别暂不可用时提示原因，已有草稿保持可用。

识别使用 Apple Speech，本版默认中文，系统首选语言为英语时使用英语。优先在设备端执行；设备或语言不支持设备端识别时，系统可能联网并把音频发送给 Apple，界面会提示当前方式。音频只用于本次识别，不写入 App 录音文件，也不会作为音频发送给 DeepSeek。用户发送后，转写文字按普通对话内容交给 DeepSeek。

本地资源或识别器初始化失败、且尚未产生文字时，会自动尝试一次不强制本地的系统识别，并提示重新说一遍。这并不保证系统选择远程服务。切换不重置 60 秒上限，旧尝试的回调不能修改新尝试；已有转写、权限错误、取消或完成后不会重试。

2026-09-16 在当前 iPhone 17 / iOS 27（24A5355p）模拟器复现真实故障：麦克风引擎启动后，Speech 返回 `kLSRErrorDomain / 300`。系统日志进一步显示中文模型的 `AssetData/mini.json` 无法打开；下载目录中只有 Restore/Cryptex 资源包。解除本地识别限制后，系统仍选择同一份不可加载资源并返回 300。因此此模拟器的真实转写尚未恢复，不能将草稿与界面测试通过视为识别成功。应用会明确提示当前模拟器未能加载语音识别，允许继续输入文字；应在可用的模拟器运行时或真机继续验收。诊断日志仅记录语言、识别模式、错误域及错误码，不记录音频、转写或密钥。

此次验证通过草稿合并测试、62 项回退策略断言，以及 3 条界面检查（两条现有模拟听写流程、一条临时真实服务失败检查）。真实检查确认两次启动均只回退一次、错误原因可见、旧草稿保留并恢复编辑；它验证故障处理，不代表语音转写成功。临时诊断代码与运行结果保存在忽略提交的 `.artifacts/date-speech-fix-20260916`，正式测试不会自动启动日常模拟器的麦克风。

「自己记 → 录一段」与收集中的声音记录用于保存可播放的音频；这里的麦克风用于把话转换成文字草稿。两种入口继续保留各自用途。

## 数据路径

- `ContentView.swift`：持有未发送草稿，使对话在本次 App 运行中的页面往返间保持内容。
- `AgentScreen.swift`：原话纸条、流式回复、操作回执、线束动画和输入区；打开对话与键盘变化时定位最新消息，输入区提供麦克风、听写状态和固定可见的「自己记」手动路径。
- `NewConversationPrompt.swift`：自绘新对话标记、确认纸片和一次性织线动画；提供取消、明确清空、辅助功能模态与紧凑高度滚动布局。
- `SpeechInputController.swift`：Apple Speech 与 `AVAudioEngine` 音频流、麦克风和识别权限、实时音量、60 秒上限、完成收尾及后台 / 音频中断时的资源释放。
- `SpeechInputDraft.swift`：合并实时转写与原草稿，保证中间结果替换、原文保留及按 Unicode 字符计算的长度上限。
- `SpeechRecognitionRecovery.swift`：明确限定本地识别失败后的一次回退条件；纯策略测试涵盖错误分类、已有文字、完成状态与重复回退限制。
- `ManualCaptureSheet.swift`：四种手动记录入口，在同一个 sheet 中打开现有编辑器，关闭后返回原对话。
- `AgentSettingsSheet.swift` / `AgentConnection.swift`：模型设置与 Keychain。API Key 使用本机、解锁可访问的钥匙串项，不进入源码、UserDefaults、对话 JSON 或日志。
- `DeepSeekClient.swift`：原生 `URLSession` POST 与 SSE 解析。工具参数必须完整结束、拼装和验证后才交给执行层。
- `AgentCoordinator.swift`：多轮模型与工具交互、取消、恢复和本地对话历史。每次请求附带最近 12 个用户回合、当前日期、习惯目录与操作状态，按需检索记录。
- `AgentContext.swift`：为发给模型的上下文设置总大小预算；长检索结果提供明确截断标志，保留完整的本地回执。超限时先移除旧回合，再压缩已完成的工具轮次，保持调用与结果完整配对。
- `AgentTools.swift` / `AppModel.swift`：本地工具白名单、参数校验、幂等操作和撤回。业务数据与操作日志一起原子保存到 `library.json`，兼容旧版 schema 1。对话单独保存为 `agent-conversation.json`。

模型运行在 DeepSeek 云端，调度和工具执行在 App 内；手机直接连接 `https://api.deepseek.com/chat/completions`。发送的对话、习惯目录及必要的检索结果会离开设备，完整业务库仍保存在本机。没有自建代理服务器，也没有内置共享密钥。

仅在成功保存之后报告成功。断网前已保存的记录与回执保留，续接同一轮不会重复写入。断流、取消或截断的工具参数不会执行。若原记录后来被手动修改，撤回会拒绝覆盖新修改。清空对话不会删除已经保存的日常记录。

## 验证

新对话样式已通过 iPhone 17 原生 UI 回归：自绘确认纸片打开时收起键盘，取消与关闭均保留旧对话和草稿，确认后进入空对话且继续保留未发送草稿；同时复测了返回长对话保持最新消息的流程。已检查 [入口截图](screenshots/new-conversation-entry.png) 和 [确认纸片截图](screenshots/new-conversation-confirmation.png)，截图使用隔离预览数据。

同一取消、关闭、确认流程也已在 375 pt 的临时 iPhone SE 3 模拟器通过，并检查入口与确认层截图：文字无截断，三处操作可达。测试仅操作临时预览会话。

运行 `bash scripts/test-agent.sh` 验证原数据回归、工具写入与撤回、SSE 协议，以及注入模拟模型响应的完整工具循环。测试使用临时目录和测试凭据，不需要真实 API Key，不接触用户数据。真实 DeepSeek 账号鉴权、余额、模型权限和回答质量，需要在 App 填写 Key 后通过连接测试及实际对话验证。

`IdeaBox` scheme 也包含 `IdeaBoxUITests` 原生界面测试：无密钥时打开设置且保留草稿、真实回执撤回、首页对话与手动创建入口。可在 Xcode 执行 Test，或对指定模拟器运行 `xcodebuild test -parallel-testing-enabled NO`。上一版的这三条流程已在 iPhone 17 模拟器通过。此前入口重排重新构建并通过两条原生测试：无 Key 时「自己记」常驻可用，键盘展开时可达，关闭选项页或文字编辑器后保留草稿；已有对话中手动入口和回执撤回仍可用。已逐张检查新版首页、对话页及手动选项页截图。

API Key 改用普通文本框后，已通过直接输入、系统「全选 → 粘贴」精确替换、无 Key 打开设置并保留对话草稿两条界面测试。`AgentKeyPasteUITests` 仅在名为 `IdeaBox Key Paste Verification` 的临时模拟器中运行，其他设备会跳过；测试只写入并清除虚构剪贴板文本，不触发保存或网络连接。

本次语音输入的纯草稿合并测试 `Tests/SpeechInputTests.swift` 已通过，覆盖分段识别更新替换、取消 / 空结果时原稿保留、空白分隔和 Unicode 字符上限。该测试不申请权限、不录音，也不能作为真实语音识别成功的证据。麦克风权限流程、中文识别准确度、设备端识别可用性、静音、音频中断和后台停麦仍需在真实设备验证。

本次滚动与语音界面回归已在 iPhone 模拟器通过 3 / 3 条原生测试：

- `AgentUITests.testReturningToLongConversationKeepsLatestMessageAndDraft`：打开长对话、从收集页返回、键盘展开、设置往返、关闭后重新打开、App 回到前台，最后消息均在输入区上方可见，未发送草稿保留。
- `SpeechInputUITests.testSpeechPreviewRevisesDraftAndSupportsCancelFinishAndManualCapture`：空 Key 下可以进入听写；中间转写结果正确替换；取消恢复原稿；完成后不自动发送；键盘可编辑；听写中打开手动记录会结束听写并保留文字。
- `SpeechInputUITests.testSpeechPermissionPreviewPreservesDraftAndAllowsKeyboardFallback`：重复注入相同权限错误后仍保留草稿、允许键盘输入，手动记录往返与重新打开对话后编辑结果保留。

两条 `SpeechInputUITests` 使用模拟识别回调及权限错误，不申请真实权限、不使用麦克风，也不调用 Apple Speech 服务。附件带有 `synthetic-recognition-fixture` 标记；它们验证原生界面与草稿状态衔接，不代表系统权限拒绝流程或真实语音识别已经验收。

另在独立临时 iPhone SE 3 模拟器通过 `SpeechPermissionUITests.testRealSpeechPermissionDenialKeepsDraftAcrossRetriesAndNavigation`：显示真正的 iOS 语音识别授权弹窗，拒绝后没有闪退，多次重试、继续打字及手动记录往返均保留草稿。该测试发现并验证修复了权限回调继承主线程隔离导致的崩溃；权限回调现显式标记为 `@Sendable`。录音会话同时改为 `.record / .measurement` 支持的无额外选项配置。此测试在拒绝语音权限后停止，不申请麦克风权限、不录音、不验证实际识别效果，也不修改日常使用的模拟器权限。

已检查 [返回长对话截图](screenshots/conversation-return-bottom.png)、[听写状态截图](screenshots/speech-listening-fixture.png) 和 [转写后草稿截图](screenshots/speech-draft-fixture.png)；后两张的文字来自明确标注的模拟识别结果。

Debug 构建通过 `SIMCTL_CHILD_IDEABOX_AGENT_PREVIEW` 选择下列状态；使用 Xcode 的 Launch Environment 时，变量名为 `IDEABOX_AGENT_PREVIEW`。

| 值 | 初始画面与行为 |
|---|---|
| `welcome` | 空对话页 |
| `receipts` | 通过真实本地工具创建的示例回执 |
| `settings` | 自动打开 DeepSeek 设置 |
| `scroll` | 预置长对话，用于检查返回时最后消息的位置；麦克风仍使用真实权限与识别路径 |
| `speech` | 预置长对话；点击麦克风后注入分段转写与音量，界面标注「界面演示 · 不使用麦克风」 |
| `speech-error` | 空对话页；每次点击麦克风后注入同一条权限错误，用于检查错误重试与草稿保留 |

所有预览使用独立临时业务库及空的预览密钥存储，加载预览本身不发起 DeepSeek 请求。仅 `speech` 与 `speech-error` 替换真实语音路径，不申请权限、不采集音频，不能用来验收实际识别效果。正常启动不设置此变量，使用用户自己的本地数据和 Keychain。

协议依据：[DeepSeek Tool Calls](https://api-docs.deepseek.com/guides/tool_calls/)、[Chat Completions](https://api-docs.deepseek.com/api/create-chat-completion/)、[模型与价格](https://api-docs.deepseek.com/quick_start/pricing/)、[Apple Keychain](https://developer.apple.com/documentation/security/keychain-services)。本版显式关闭模型的 thinking 模式。
