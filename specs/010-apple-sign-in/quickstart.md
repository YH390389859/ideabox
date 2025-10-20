# Quickstart: Firebase 邮箱登录系统

**Feature**: Firebase Authentication (Email/Password)  
**Date**: 2025-10-20  
**Estimated Setup Time**: 30-45 minutes

---

## Overview

本指南将引导您完成 Firebase 邮箱登录系统的配置、安装和首次运行。按照以下步骤操作，您将能够在本地开发环境中运行完整的认证功能。

---

## Prerequisites (前置条件)

在开始之前，请确保您已经准备好以下内容：

### 必需工具

- ✅ **macOS** 12.0+ (Monterey or later)
- ✅ **Xcode** 15.0+ (含 Swift 5.9+)
- ✅ **Command Line Tools** 已安装
- ✅ **Git** (用于版本控制)

### 账号准备

- ✅ **Google Account** (用于创建 Firebase 项目)
- ❌ **Apple Developer Account** (Phase 1 不需要付费账号)

### 验证安装

```bash
# 检查 Xcode 版本
xcodebuild -version
# 应输出: Xcode 15.0 或更高

# 检查 Swift 版本
swift --version
# 应输出: Swift 5.9 或更高

# 检查 Git
git --version
# 应输出: git version 2.x.x
```

---

## Step 1: Firebase 项目配置 (15 分钟)

### 1.1 创建 Firebase 项目

1. **访问 Firebase Console**
   - 打开 https://console.firebase.google.com
   - 使用您的 Google 账号登录

2. **创建新项目**
   ```
   点击 "添加项目"
   项目名称: ideabox (或您喜欢的名称)
   项目 ID: ideabox-xxxxx (自动生成)
   位置: (保持默认)
   ```

3. **Google Analytics 配置**
   ```
   选择: "现在不启用 Google Analytics"
   (Phase 1 不需要分析功能)
   ```

4. **等待项目创建**
   - 大约 30-60 秒
   - 创建完成后进入项目控制台

### 1.2 添加 iOS 应用

1. **在 Firebase 项目主页**
   ```
   点击 iOS 图标 (第一个平台)
   ```

2. **注册应用**
   ```
   iOS Bundle ID: com.yourcompany.ideabox
   (必须与 Xcode 项目中的 Bundle ID 一致)
   
   应用昵称 (可选): IdeaBox
   App Store ID (可选): (留空)
   ```
   
   **重要**: 在 Xcode 中查看 Bundle ID：
   ```
   1. 打开 IdeaBox.xcodeproj
   2. 选择项目 -> Target "IdeaBox"
   3. General 标签页 -> Identity -> Bundle Identifier
   4. 复制 Bundle ID 到 Firebase 表单
   ```

3. **下载配置文件**
   ```
   点击 "下载 GoogleService-Info.plist"
   将文件保存到桌面或下载文件夹
   ```

4. **完成注册**
   ```
   点击 "下一步"
   可以跳过 "添加 Firebase SDK" 步骤 (稍后手动添加)
   点击 "继续前往控制台"
   ```

### 1.3 启用 Email/Password 认证

1. **在 Firebase Console 中**
   ```
   左侧菜单 -> Build -> Authentication
   点击 "开始使用"
   ```

2. **启用 Email/Password 登录方式**
   ```
   Sign-in method 标签页
   在 "本机提供方" 列表中找到 "电子邮件地址/密码"
   点击右侧的编辑图标 (铅笔)
   ```

3. **配置选项**
   ```
   ✅ 启用 "电子邮件地址/密码"
   ❌ 不启用 "电子邮件链接 (无密码登录)" (暂不需要)
   点击 "保存"
   ```

4. **验证设置**
   ```
   确认 "电子邮件地址/密码" 状态为 "已启用"
   ```

### 1.4 配置邮件模板 (可选)

1. **自定义验证邮件**
   ```
   Authentication -> Templates 标签页
   选择 "电子邮件地址验证"
   可以自定义：
   - 发件人名称
   - 主题
   - 邮件正文
   ```

2. **推荐设置**
   ```
   发件人名称: IdeaBox
   主题: 验证您的 IdeaBox 邮箱
   ```

---

## Step 2: Xcode 项目配置 (10 分钟)

### 2.1 添加 GoogleService-Info.plist

1. **在 Finder 中找到下载的文件**
   ```
   GoogleService-Info.plist
   ```

2. **添加到 Xcode 项目**
   ```
   1. 在 Xcode 中打开 IdeaBox.xcodeproj
   2. 在项目导航器中右键点击 "IdeaBox" 文件夹
   3. 选择 "Add Files to "IdeaBox"..."
   4. 选择 GoogleService-Info.plist 文件
   5. ✅ 勾选 "Copy items if needed"
   6. ✅ 勾选 "IdeaBox" target
   7. 点击 "Add"
   ```

3. **验证添加成功**
   ```
   在项目导航器中应该能看到 GoogleService-Info.plist
   点击文件，确认右侧 Target Membership 中 IdeaBox 被勾选
   ```

### 2.2 添加 Firebase SDK (Swift Package Manager)

1. **在 Xcode 中**
   ```
   File -> Add Package Dependencies...
   ```

2. **搜索 Firebase**
   ```
   在搜索框输入: https://github.com/firebase/firebase-ios-sdk
   点击 "Add Package"
   ```

3. **选择版本**
   ```
   Dependency Rule: Up to Next Major Version
   最低版本: 10.0.0
   点击 "Add Package"
   ```

4. **选择产品**
   ```
   ✅ FirebaseAuth
   ✅ FirebaseFirestore
   ❌ 其他产品暂不需要
   Target: IdeaBox
   点击 "Add Package"
   ```

5. **等待下载和集成**
   - 大约 2-5 分钟
   - 完成后 Xcode 左侧会显示 "firebase-ios-sdk" package

### 2.3 初始化 Firebase

1. **编辑 IdeaBoxApp.swift**
   ```swift
   import SwiftUI
   import FirebaseCore  // 新增这一行
   
   @main
   struct IdeaBoxApp: App {
       init() {
           FirebaseApp.configure()  // 新增这一行
       }
       
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   ```

2. **保存文件** (⌘S)

### 2.4 验证配置

1. **构建项目**
   ```
   ⌘B (Build)
   应该成功编译，无错误
   ```

2. **运行项目**
   ```
   ⌘R (Run)
   选择模拟器: iPhone 15 Pro (或任意 iOS 15+ 模拟器)
   ```

3. **检查控制台输出**
   ```
   应该看到类似以下输出：
   "[Firebase/Core] Version xxxx - Build xxx"
   "[Firebase/Auth] Version xxxx"
   ```

如果看到这些输出，说明 Firebase 配置成功！ ✅

---

## Step 3: 测试 Firebase 连接 (5 分钟)

### 3.1 创建测试文件

在 `IdeaBox/` 目录下创建 `FirebaseTest.swift`：

```swift
import Foundation
import FirebaseAuth

class FirebaseTest {
    static func testConnection() {
        print("🔥 Testing Firebase connection...")
        
        // Test 1: Firebase is initialized
        if FirebaseApp.app() != nil {
            print("✅ Firebase initialized successfully")
        } else {
            print("❌ Firebase not initialized")
            return
        }
        
        // Test 2: Auth service is available
        let auth = Auth.auth()
        print("✅ Auth service available")
        print("   Current user: \(auth.currentUser?.uid ?? "None")")
        
        // Test 3: Try to create a test user (will fail, but should connect)
        Task {
            do {
                _ = try await auth.createUser(withEmail: "test@example.com", password: "Test123456")
                print("✅ Test user created")
            } catch let error as NSError {
                // Expected to fail if user already exists
                if error.domain == "FIRAuthErrorDomain" {
                    print("✅ Firebase connection working (error is expected)")
                } else {
                    print("❌ Unexpected error: \(error.localizedDescription)")
                }
            }
        }
    }
}
```

### 3.2 运行测试

1. **在 `IdeaBoxApp.swift` 的 `init()` 中添加测试调用**
   ```swift
   init() {
       FirebaseApp.configure()
       #if DEBUG
       FirebaseTest.testConnection()  // 新增这一行
       #endif
   }
   ```

2. **运行应用** (⌘R)

3. **查看控制台输出**
   ```
   期望看到：
   🔥 Testing Firebase connection...
   ✅ Firebase initialized successfully
   ✅ Auth service available
      Current user: None
   ✅ Firebase connection working (error is expected)
   ```

4. **清理测试代码**
   ```swift
   // 测试成功后，可以删除或注释掉测试调用
   // FirebaseTest.testConnection()
   ```

---

## Step 4: 创建基础认证结构 (5 分钟)

### 4.1 创建文件夹结构

在 Xcode 项目导航器中创建以下文件夹：

```
IdeaBox/
└── Authentication/           # 新建 Group
    ├── Models/               # 新建 Group
    ├── Services/             # 新建 Group
    ├── ViewModels/           # 新建 Group
    └── Views/                # 新建 Group
        └── Components/       # 新建 Group
```

**操作步骤**：
1. 右键点击 `IdeaBox` 文件夹
2. New Group
3. 命名为 `Authentication`
4. 重复步骤创建子文件夹

### 4.2 创建基础 Model

在 `Authentication/Models/` 中创建 `AuthError.swift`：

```swift
import Foundation

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case networkError
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "邮箱格式不正确"
        case .wrongPassword:
            return "邮箱或密码错误"
        case .networkError:
            return "网络连接失败"
        case .unknown(let error):
            return "发生未知错误：\(error?.localizedDescription ?? "未知")"
        }
    }
}
```

### 4.3 验证结构

```
确认项目结构如下：
IdeaBox/
├── Authentication/
│   ├── Models/
│   │   └── AuthError.swift ✅
│   ├── Services/
│   ├── ViewModels/
│   └── Views/
│       └── Components/
├── IdeaBoxApp.swift ✅
└── GoogleService-Info.plist ✅
```

---

## Step 5: 运行示例认证流程 (可选，5 分钟)

### 5.1 创建简单的注册测试

在 `ContentView.swift` 中添加测试按钮：

```swift
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase 认证测试")
                .font(.title)
            
            TextField("邮箱", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .padding(.horizontal)
            
            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Button("注册") {
                Task {
                    await signUp()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Text(message)
                .foregroundColor(message.contains("成功") ? .green : .red)
                .padding()
        }
    }
    
    func signUp() async {
        do {
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )
            message = "注册成功！用户 ID: \(result.user.uid)"
        } catch {
            message = "注册失败：\(error.localizedDescription)"
        }
    }
}
```

### 5.2 测试注册流程

1. **运行应用** (⌘R)
2. **输入测试数据**
   ```
   邮箱: test@example.com
   密码: Test123456
   ```
3. **点击注册**
4. **查看结果**
   - 成功：显示 "注册成功！用户 ID: xxx"
   - 失败：显示错误信息

5. **在 Firebase Console 中验证**
   ```
   Authentication -> Users 标签页
   应该能看到新注册的用户
   ```

6. **清理测试代码**
   ```swift
   // 测试完成后，将 ContentView 恢复到原始状态
   // 或保留作为参考
   ```

---

## Verification Checklist (验证清单)

完成以上步骤后，请确认以下项目：

### Firebase 配置
- [x] Firebase 项目已创建
- [x] iOS 应用已添加到 Firebase
- [x] GoogleService-Info.plist 已下载并添加到 Xcode
- [x] Email/Password 认证已启用

### Xcode 配置
- [x] Firebase SDK 已通过 SPM 添加
- [x] FirebaseAuth 和 FirebaseFirestore 已选中
- [x] Firebase.configure() 已在 App init() 中调用
- [x] 项目可以成功编译和运行

### 测试验证
- [x] Firebase 连接测试通过
- [x] 可以创建测试用户
- [x] 用户出现在 Firebase Console 中

### 项目结构
- [x] Authentication/ 文件夹结构已创建
- [x] AuthError.swift 已创建
- [x] 准备好开始实现其他组件

---

## Next Steps (下一步)

✅ 恭喜！您已经完成了 Firebase 邮箱登录系统的基础配置。

现在可以开始实现核心功能：

1. **运行 `/tasks` 命令**
   ```
   生成详细的实施任务列表
   ```

2. **按照 TDD 原则开始开发**
   ```
   - 编写测试
   - 实现功能
   - 重构代码
   ```

3. **参考文档**
   - [data-model.md](./data-model.md) - 数据模型定义
   - [contracts/](./contracts/) - 服务契约
   - [plan.md](./plan.md) - 实施计划

---

## Troubleshooting (故障排查)

### 问题 1: 无法下载 Firebase SDK

**症状**: Xcode 显示 "Failed to resolve dependencies"

**解决方案**:
```
1. 检查网络连接
2. Xcode -> Preferences -> Accounts
3. 确认 Apple ID 已登录
4. 尝试重新添加 Package
5. 如果仍失败，尝试手动下载：
   https://github.com/firebase/firebase-ios-sdk/releases
```

### 问题 2: GoogleService-Info.plist 找不到

**症状**: 运行时崩溃 "Could not locate configuration file"

**解决方案**:
```
1. 确认文件在项目导航器中可见
2. 选中文件，查看右侧 "Target Membership"
3. 确认 "IdeaBox" target 已勾选
4. Clean Build Folder (⌘⇧K) 并重新构建
```

### 问题 3: Firebase.configure() 崩溃

**症状**: App 启动时崩溃

**解决方案**:
```
1. 确认 GoogleService-Info.plist 已正确添加
2. 确认文件名没有被修改
3. 确认 Bundle ID 匹配
4. 重新下载 GoogleService-Info.plist
```

### 问题 4: Email 已存在错误

**症状**: 注册时报错 "The email address is already in use"

**解决方案**:
```
1. 使用不同的邮箱地址
2. 或在 Firebase Console 中删除已存在的用户：
   Authentication -> Users -> 找到用户 -> 删除
```

### 问题 5: 网络错误

**症状**: "Network error occurred"

**解决方案**:
```
1. 检查 Mac 网络连接
2. 检查模拟器网络设置
3. 尝试使用手机热点
4. 检查防火墙设置
```

---

## Additional Resources (额外资源)

### Firebase 文档
- [Firebase iOS 快速入门](https://firebase.google.com/docs/ios/setup)
- [Firebase Authentication 文档](https://firebase.google.com/docs/auth/ios/start)
- [Firebase Firestore 文档](https://firebase.google.com/docs/firestore/quickstart)

### Swift/iOS 资源
- [Swift 异步编程](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

### 社区支持
- [Firebase Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)
- [Swift Forums](https://forums.swift.org)
- [iOS Developers Slack](https://ios-developers.io)

---

## Summary

您已经完成：

✅ Firebase 项目创建和配置  
✅ iOS 应用注册  
✅ Firebase SDK 集成  
✅ 认证服务启用  
✅ 基础项目结构搭建  
✅ 连接测试验证

**估计总时间**: 30-45 分钟

**下一步**: 运行 `/tasks` 命令生成实施任务，开始 TDD 开发流程。

---

**Last Updated**: 2025-10-20  
**Questions?** 查看 [plan.md](./plan.md) 或参考 [troubleshooting](#troubleshooting)

Good luck! 🚀

