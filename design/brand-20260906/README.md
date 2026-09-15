# IdeaBox 品牌图标

用一个柔软的敞口容器承接一颗圆润的灵感星，配上一粒鼠尾草绿新芽。延续应用的暖白、淡紫与安静留白，让「随手收集，每日成长」成为容易识别的品牌记忆。

- [设计预览](brand-preview.png)：展示正式图标、颜色和小尺寸效果。预览中的圆角仅模拟系统呈现。
- [应用图标 SVG](app-icon.svg)：1024 画布，完整方形、不透明暖白背景，不预裁系统圆角。
- [1024 PNG](app-icon-1024.png)：sRGB、RGB，无 alpha 通道。
- [品牌标记 SVG](brand-mark.svg)：256 × 256 透明画布，启动图与分层动效的标准坐标。
- [可复现生成脚本](generate.swift)：使用 CoreGraphics 绘制矢量几何，直接生成完整 iPhone/iPad/App Store 图标和启动资源。

色值：背景 `#F7F6F2`，灵感星 `#7770DD`，容器外沿 `#D7D3F4`，内壁 `#B8B1E9`，正面 `#9992E6 → #7770DD`，新芽 `#A9C3AD`。所有颜色按 sRGB 导出。

应用图标以 256 坐标为基准，围绕 `(128, 128)` 缩放 `1.04`，主体占画布宽度 65%。启动用的 `BrandMark` 与 `BrandBox`、`BrandSpark`、`BrandSeed` 保持同一个 `viewBox="0 0 256 256"`，便于静态启动页无缝衔接分层动画。BrandMark 提供 1x、2x、3x 透明 PNG，三个动画层使用保留矢量精度的 SVG imageset。

在项目根目录重新生成：

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift design/brand-20260906/generate.swift
```

已检查全部 18 张 AppIcon 与 Contents.json 的尺寸一致，均为无 alpha 的 RGB PNG；3 张 BrandMark 是对应分辨率的透明 RGBA PNG。旧图标完整备份于 `before/AppIcon.appiconset`。

## 启动体验

`IdeaBox/AppLaunchView.swift` 与 `IdeaBox/LaunchAtmosphere.swift` 实现约 3.28 秒的原生启动编排。初始帧与静态启动页使用同样的 176 pt 标记尺寸、全屏中心上移 40 pt 的位置与暖白背景，随后品牌标记舒展到 242 pt。

- 0.2–0.9 秒：柔和环境色显现，偏心轨迹徐徐绘出，盒子分层透视打开。
- 0.5–1.7 秒：文字、声音、链接三张微型卡片沿不同贝塞尔曲线飞入盒口，前后层正确遮挡。
- 1.4–2.4 秒：灵感星从盒中弹起，细线涟漪和星点余辉散开，盒面光泽轻轻扫过。
- 1.8–2.7 秒：品牌字标逐字显现，副标题跟随落定。
- 2.72–3.28 秒：柔和揭示已经准备好的首页。

所有轨迹与光点由一条有限时间轴驱动，位置确定，无随机闪烁。提供跳过按钮。新增 `BrandBoxBack` / `BrandBoxFront` SVG 保留原始 256 画布，使内容卡片能够真正进入盒口后方。

动画仅在新进程启动时播放，从后台返回不重播。系统开启“减少动态效果”时改用约 0.22 秒淡化；切到后台或动画任务取消时直接结束，不阻挡应用使用。

最新构建日志和实际启动录像保存在 `.artifacts/launch-cinematic-20260906/`，最终演示为 `launch-preview.mp4`，原始录像为 `launch.mov`。桌面图标截图仍位于 `.artifacts/brand-20260906/home-icon.png`。已通过模拟器构建与整个 App 的资源签名校验，并查看 iPhone 17 模拟器启动录像的关键帧：静态品牌页、分层动画和首页正常衔接。
