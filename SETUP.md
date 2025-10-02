# 收藏日历 - 开发环境配置指南

## 系统要求

- macOS 13.0+ (Ventura或更新版本)
- Xcode 15.0+
- iOS 15.0+ 设备或模拟器

## 安装步骤

### 1. 安装 Xcode

如果您还没有安装 Xcode，请从 Mac App Store 下载：

```bash
# 或通过命令行工具检查是否已安装
xcode-select --version
```

### 2. 打开项目

```bash
# 进入项目目录
cd /Users/echonull/project/ideabox

# 使用 Xcode 打开项目
open IdeaBox.xcodeproj
```

### 3. 配置签名

1. 在 Xcode 中，选择项目导航器中的 `IdeaBox` 项目
2. 选择 `IdeaBox` target
3. 在 "Signing & Capabilities" 标签页中：
   - 选择您的开发团队
   - 或勾选 "Automatically manage signing"

### 4. 选择目标设备

在 Xcode 工具栏中：
- 点击设备选择器
- 选择一个 iOS 模拟器（推荐：iPhone 15 Pro）
- 或连接真实的 iOS 设备

### 5. 运行应用

点击 Xcode 左上角的运行按钮 ▶️ 或按快捷键：
```
⌘ + R
```

## 项目结构说明

```
IdeaBox/
├── IdeaBoxApp.swift              # 应用程序入口点
├── ContentView.swift             # 主视图控制器
├── Models/                       # 数据模型层
│   ├── EventItem.swift          # 事件项目数据模型
│   └── DayItem.swift            # 日期项目数据模型
├── Views/                        # 视图组件层
│   ├── WeekCalendarView.swift   # 周日历视图
│   ├── DateHeaderView.swift     # 日期标题视图
│   ├── TimelineView.swift       # 时间轴视图
│   └── BottomNavigationBar.swift # 底部导航栏
├── Assets.xcassets/              # 资源文件
│   ├── AppIcon.appiconset/      # 应用图标
│   └── AccentColor.colorset/    # 主题色
├── Info.plist                    # 应用配置文件
└── IdeaBox.xcodeproj/           # Xcode 项目文件
```

## 常见问题

### Q: 编译失败，提示找不到某些文件

**A:** 确保所有文件都在正确的位置。尝试清理构建文件夹：
```
在 Xcode 菜单中选择：Product > Clean Build Folder
或使用快捷键：⇧ + ⌘ + K
```

### Q: 模拟器运行缓慢

**A:** 尝试以下方法：
1. 选择较小的设备模拟器（如 iPhone SE）
2. 关闭其他占用资源的应用
3. 重启模拟器

### Q: 真机调试提示"Untrusted Developer"

**A:** 在 iOS 设备上：
```
设置 > 通用 > VPN与设备管理 > 开发者App > 信任此开发者
```

### Q: 如何修改应用显示名称

**A:** 编辑 `Info.plist` 文件中的 `CFBundleDisplayName` 字段

## 调试技巧

### 使用 Xcode Previews

每个视图文件底部都有 `#Preview` 宏，可以快速预览单个组件：

1. 打开任意 View 文件
2. 点击右上角的 "Resume" 按钮
3. 实时查看视图变化

### 启用 Debug View Hierarchy

运行应用后：
```
Debug > View Debugging > Capture View Hierarchy
```

这将显示应用的视图层级结构，方便调试布局问题。

### 性能分析

```
Product > Profile (⌘ + I)
选择 Time Profiler 或 Leaks 工具
```

## 下一步

完成基础设置后，您可以：

1. ✅ 浏览代码了解项目结构
2. ✅ 修改示例数据查看不同效果
3. ✅ 添加新功能或自定义样式
4. ✅ 阅读 [README.md](README.md) 了解更多功能特性

## 获取帮助

如果遇到问题：
1. 查看 Xcode 的错误提示
2. 检查控制台日志
3. 参考 [Swift 官方文档](https://developer.apple.com/swift/)
4. 参考 [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)

---

祝您开发愉快！🎉

