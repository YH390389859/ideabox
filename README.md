# IdeaBox · 日常织机

把习惯、日记与灵感收藏放在一起的原生 iPhone 应用。这一版以「织」组织整个体验：习惯成为经线，完成记录留下织结，文字、声音与链接成为可以抽出来阅读的材料。

界面采用暖纸白 `#F3F0E8`、墨色 `#202A2B`、钴蓝 `#3555E8`、黄绿 `#D9EB77` 与朱砂 `#C96C50`。大号日期、细标尺、平面文字导航和梭形「拾起」按钮构成主界面；内容以织片、打孔纸、磁带和折角薄纸呈现。

## 三个页面

- **今天：今天，织一点。** 日期、真实完成进度和近期灵感围绕一块悬浮织片展开。每束经线对应当天安排中的真实习惯，颜色与习惯 UUID 稳定关联，近七天的完成记录形成历史织结。点击线端标签可打卡或撤销，通过「全部」进入完整习惯列表。
- **习惯：把日子，织起来。** 固定习惯名称，横向浏览一周。每天一列、每个习惯一行，完成显示织结与勾，未完成显示空环，未安排日及未来日期不可打卡。日格宽度为 44 pt，可横向滚动；支持前后周、回今天、历史补卡、频率设置和创建、编辑、删除。
- **收集：拾起，一闪而过。** 文字使用黄绿打孔纸，声音使用钴蓝磁带，链接使用折角薄纸。搜索、类型与标签筛选保持可见；详情、编辑菜单、播放与外链按钮分别操作。磁带上的等高刻纹是材料纹理，录制时的波形才来自实时麦克风音量。

底部「拾起」提供写文字、录声音、留链接与新增习惯入口。文字支持富文本、标签与心情，链接支持标题和备注，记录可继续编辑或删除。

## 织面与动效

`WovenArtwork.swift` 使用 SwiftUI Canvas 绘制经纬线、透视曲面与历史结点。轻拖织面可改变张力和倾角，松手后柔和回弹；对应习惯完成状态变化时，相关经线短暂收紧。实际打卡按钮由 SwiftUI 叠层提供清楚的点击区域与无障碍标签。

新开屏由 `AppLaunchView.swift` 编排：交织标记展开，梭子往返穿线，织片逐渐形成，品牌字样依次显现，再过渡到首页。总时长约 2.6 秒，支持跳过；返回前台不重播。开屏中的织片为品牌动画，首页织片绑定用户记录。

系统开启「减少动态效果」时，持续变形、拖拽透视与复杂开屏停用，改为短暂淡化。首页织面在隐藏页面或非活跃场景停止持续绘制；开屏进入后台时直接结束剩余编排。切换页面会收起收集页搜索键盘。

## 数据与录音

- 本地 JSON 持久化；首次提供示例，已有记录、UUID 与录音文件沿用，不因视觉更新重新播种。
- 损坏文件会备份；未知新版本的数据文件不会被覆盖。存储错误和恢复文件状态在界面中明确提示。
- `AVAudioRecorder` / `AVAudioPlayer` 实现真实录音、暂停、继续、试听与保存；多个播放实例互斥，开始录音前停止播放，取消后清理未保存文件。
- 缺少音频文件的旧示例显示「仅文字备忘」，不提供虚假播放按钮或时长。
- 网页地址仅接受有效的 HTTP / HTTPS 链接。

内容保存在 App 沙盒的 `Application Support/IdeaBox`，包括 `library.json` 与 `Recordings`。应用目前没有账户、云同步或远端 AI 服务。录音需要麦克风授权；真实设备录入质量和音频中断应在真机验收。习惯副标题反映计划频率，不代表已实现定时提醒。

## 设计源文件

本轮先完成三屏设计图，再进入原生开发：

- [blueprint.svg](design/loom-20260906/blueprint.svg)：可编辑的 1500 × 1150 三屏布局板，每屏按 402 × 874 pt 设计。
- [blueprint.png](design/loom-20260906/blueprint.png)：同源 3000 × 2300 完整预览。
- [design-notes.md](design/loom-20260906/design-notes.md)：逐屏尺寸、配色、状态、交互与动效规范。
- [product-direction.md](design/loom-20260906/product-direction.md)：设计方向与功能边界。
- [brand](design/loom-20260906/brand/README.md)：新交织图标、静态启动资源及生成脚本。

设计板由 `generate-blueprint.py` 生成 SVG，再由 `render-blueprint.swift` 按完整画布输出 PNG。设计图中的日期、文字与数量为布局示例，运行界面使用实际数据。

本轮已在 iPhone 17（402 pt）与 iPhone SE 3（375 pt）模拟器检查三页布局，并录制原生开屏。带签名的 Debug 构建、Swift 6 数据回归测试均通过。截图与录屏如下：

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
xcrun swiftc -swift-version 6 IdeaBox/AppModel.swift Tests/AppModelTests.swift \
  -o /tmp/IdeaBoxModelTests
/tmp/IdeaBoxModelTests
```

测试覆盖连续打卡、计划频率、CRUD 与重启保留、旧数据兼容、损坏恢复、未知版本保护和录音文件路径安全。测试使用独立临时目录，不读写模拟器中的用户数据。

Debug 构建可通过 `SIMCTL_CHILD_IDEABOX_PREVIEW_TAB` 选择截图初始页，支持 `dashboard`、`habits`、`clips`。例如，将 `SIMULATOR_UDID` 替换成已启动模拟器的标识：

```sh
SIMCTL_CHILD_IDEABOX_PREVIEW_TAB=clips \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcrun simctl launch --terminate-running-process SIMULATOR_UDID com.example.IdeaBox
```

正常启动进入今天页。初始页参数只影响 Debug 导航，不改用户数据。

## 源码入口

- `LoomDesign.swift`：日常织机配色、标题、梭形与交织标记。
- `DesignSystem.swift`：共享排版、表单与按钮反馈。
- `WovenArtwork.swift`：由习惯记录驱动的 Canvas 织面与张力交互。
- `AppLaunchView.swift`：织造开屏、跳过与生命周期处理。
- `ContentView.swift`：平面导航和统一创建入口。
- `DashboardScreen.swift`、`HabitsScreen.swift`、`ClipsScreen.swift`：三屏及相关编辑流程；收藏材料背景可复用。
- `AppModel.swift`：数据、排期、统计和持久化。
- `AudioRecorder.swift`：真实音频生命周期与跨实例播放互斥。
