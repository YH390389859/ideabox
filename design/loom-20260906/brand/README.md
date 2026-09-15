# 日常织机 · 品牌记号

四条横线与四条纵线弯曲交织，将「日常织机」收束成一个明确的应用记号。几何直接对应 `IdeaBox/LoomDesign.swift` 中的 `LoomSign`，按每轮横线、纵线的顺序绘制，保持界面、图标和开启动画一致。

- [品牌与小尺寸预览](preview.png)
- [1024 图标 PNG](icon.png) / [可编辑 SVG](icon.svg)
- [透明启动标记 SVG](loom-launch.svg)
- [原生 CoreGraphics 生成脚本](generate.swift)

应用图标使用不透明黄绿 `#D9EB77` 背景，横线墨色 `#202A2B`，纵线同色、不透明度 `0.65`。在标准 256 坐标中将笔画加粗 30%，以画布中心缩放 `0.81`，含笔画的记号视觉宽约 72%。正式图标保持方形，圆角仅用于预览；由系统施加实际圆角。

启动标记 `LoomLaunch.imageset` 提供逻辑尺寸 256 × 256 的透明 1x / 2x / 3x PNG。标记使用钴蓝 `#3555E8`，纵线不透明度 `0.65`，严格保留 `LoomSign` 原控制点、线宽和坐标，不应用图标的加粗或缩放。在 176 pt 显示时与 SwiftUI 标记的几何一致。

全部 18 张 AppIcon 已检查与 Contents.json 的尺寸匹配，均为 sRGB、RGB、无 alpha 通道。全部 3 张 LoomLaunch 为对应尺寸的透明 RGBA PNG。1024 图标背景的原始 RGB 像素确认是 `(217, 235, 119)`。

在项目根目录重新生成：

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift design/loom-20260906/brand/generate.swift
```

旧图标由主线备份于 `.artifacts/loom-20260906/before`。本目录生成器不会修改旧品牌设计目录或 SwiftUI 源码。
