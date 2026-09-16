import SwiftUI

struct AgentSettingsSheet: View {
    @ObservedObject var connection: AgentConnection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var apiKey = ""
    @State private var model = ""
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var statusSucceeded = false
    @State private var confirmingRemoval = false
    @State private var connectionTask: Task<Void, Never>?
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case key, model }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .light))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("返回对话")
                Spacer()
                Text("连接设置").font(.subheadline.weight(.medium))
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }.padding(.horizontal, 12).padding(.top, 12)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    AgentEyebrow(text: "05 / THE QUIET ENGINE").padding(.bottom, 24)
                    Text("接上你的灵感。")
                        .font(.system(.largeTitle, design: .default, weight: .semibold)).tracking(-1.2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("用你自己的 DeepSeek，陪你记下生活。")
                        .font(.subheadline).foregroundStyle(Loom.secondary).padding(.top, 15)
                    providerPlate.padding(.top, 27).padding(.bottom, 32)
                    keyField
                    modelField.padding(.top, 28)
                    actions.padding(.top, 26)
                    if let statusMessage {
                        Label(statusMessage, systemImage: statusSucceeded ? "checkmark.circle" : "exclamationmark.circle")
                            .font(.subheadline).lineSpacing(4)
                            .foregroundStyle(statusSucceeded ? Loom.olive : Loom.clay)
                            .padding(.top, 18)
                            .accessibilityIdentifier("agent-connection-status")
                    }
                    privacyNote.padding(.top, 23)
                    if connection.isConfigured {
                        Button("移除本机密钥", role: .destructive) { confirmingRemoval = true }
                            .font(.subheadline).foregroundStyle(Loom.clay)
                            .frame(maxWidth: .infinity).frame(minHeight: 44).padding(.top, 18)
                            .disabled(isWorking)
                    }
                }.padding(.horizontal, 24).padding(.top, 25).padding(.bottom, 32)
            }.scrollDismissesKeyboard(.interactively)
        }
        .background(Loom.paper.ignoresSafeArea()).foregroundStyle(Loom.ink).tint(Loom.cobalt)
        .buttonStyle(StudioPressStyle())
        .overlay {
            if scenePhase != .active {
                Loom.paper.ignoresSafeArea().overlay {
                    VStack(spacing: 18) {
                        LoomSign().frame(width: 48, height: 48)
                        Text("你的密钥，只留给你。 ").font(.subheadline).foregroundStyle(Loom.secondary)
                    }
                }
            }
        }
        .confirmationDialog("移除这台 iPhone 上的密钥？", isPresented: $confirmingRemoval, titleVisibility: .visible) {
            Button("移除密钥", role: .destructive) { removeKey() }
        } message: { Text("日记、习惯、收藏和对话会保留。下次使用 AI 时，需要重新填写密钥。") }
        .onAppear {
            model = connection.model
            if connection.isConfigured {
                do { apiKey = try connection.readKey() }
                catch { statusMessage = error.localizedDescription; statusSucceeded = false }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Temporary system UI must not interrupt the input or its editing menu.
            // The privacy overlay still covers the key whenever the scene is inactive.
            if phase == .background { focusedField = nil }
        }
        .onDisappear {
            connectionTask?.cancel()
            connectionTask = nil
            apiKey = ""
        }
    }

    private var providerPlate: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 15) {
                providerMark
                providerCopy.fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 10) {
                providerMark
                providerCopy
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: 0xE7E9DA))
    }

    private var providerMark: some View {
        Canvas { context, size in
                for strand in 0..<16 {
                    let d = Double(strand) * 1.6
                    var thread = Path()
                    thread.move(to: CGPoint(x: 4 + d, y: 57))
                    thread.addCurve(to: CGPoint(x: 104 + d, y: 28), control1: CGPoint(x: 39 + d, y: 2), control2: CGPoint(x: 73 + d, y: 91))
                    context.stroke(thread, with: .color(Loom.cobalt.opacity(0.65)), lineWidth: 0.65)
                }
                var shuttleContext = context
                shuttleContext.translateBy(x: 43, y: 27)
                shuttleContext.fill(ShuttleShape().path(in: CGRect(x: 0, y: 0, width: 55, height: 25)), with: .color(Loom.acid))
                var slot = Path()
                slot.move(to: CGPoint(x: 56, y: 39.5)); slot.addLine(to: CGPoint(x: 86, y: 39.5))
                context.stroke(slot, with: .color(Loom.ink.opacity(0.7)), lineWidth: 0.7)
        }.frame(width: 136, height: 78).accessibilityHidden(true)
    }

    private var providerCopy: some View {
        VStack(alignment: .leading, spacing: 9) {
                AgentEyebrow(text: "POWERED BY", color: Loom.secondary)
                Text("DeepSeek").font(.system(.title2, design: .default, weight: .semibold))
                HStack(spacing: 6) {
                    Circle().fill(connection.isConfigured ? Loom.cobalt : Loom.clay).frame(width: 5, height: 5)
                    Text(connection.isConfigured ? "密钥已保存在本机" : "等待连接")
                        .font(.caption).foregroundStyle(Loom.secondary)
                }
        }
    }

    private var keyField: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("API KEY").font(.caption.weight(.semibold)).tracking(1.2)
                Spacer()
                Text("仅储存在本机").font(.caption).foregroundStyle(Loom.secondary)
            }
            TextField("填写或粘贴 DeepSeek API Key", text: $apiKey)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .keyboardType(.asciiCapable).textContentType(nil)
                .submitLabel(.done)
                .focused($focusedField, equals: .key)
                .onSubmit { focusedField = nil }
                .privacySensitive().padding(.horizontal, 16).frame(minHeight: 54)
                .accessibilityIdentifier("agent-api-key")
                .background(Color(hex: 0xFBFAF3), in: RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0xC6CDBC), lineWidth: 0.8))
        }
    }

    private var modelField: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("模型").font(.subheadline.weight(.medium))
                Spacer()
                Text("可编辑").font(.caption).foregroundStyle(Loom.secondary)
            }
            HStack(spacing: 0) {
                TextField("填写可用的模型名称", text: $model)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .keyboardType(.asciiCapable).focused($focusedField, equals: .model)
                    .padding(.leading, 16).frame(minHeight: 54)
                    .accessibilityIdentifier("agent-model")
                Button { focusedField = .model } label: {
                    Image(systemName: "pencil").font(.system(size: 16, weight: .light))
                        .foregroundStyle(Loom.secondary).frame(width: 48, height: 54).contentShape(Rectangle())
                }.accessibilityLabel("编辑模型名称")
            }
            .background(Color(hex: 0xFBFAF3), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0xC6CDBC), lineWidth: 0.8))
            Text("填写你账号可用的模型名称。")
                .font(.caption).foregroundStyle(Loom.secondary)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button { connect(save: true) } label: {
                HStack {
                    Spacer()
                    if isWorking { ProgressView().tint(Loom.paper).padding(.trailing, 6) }
                    Text(isWorking ? "正在连接…" : "保存并连接").font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 15, weight: .light))
                }
                .foregroundStyle(Loom.paper).padding(.horizontal, 18).frame(minHeight: 52)
                .background(Loom.ink.opacity(fieldsValid && !isWorking ? 1 : 0.5), in: RoundedRectangle(cornerRadius: 3))
            }.disabled(!fieldsValid || isWorking).accessibilityIdentifier("agent-save-connection")
            Button("测试连接") { connect(save: false) }
                .font(.subheadline.weight(.medium)).foregroundStyle(Loom.cobalt)
                .frame(maxWidth: .infinity).frame(minHeight: 48)
                .disabled(!fieldsValid || isWorking)
                .accessibilityIdentifier("agent-test-connection")
        }
    }

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 17) {
            Rectangle().fill(Loom.hairline).frame(height: 0.7)
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "info.circle").font(.caption).padding(.top, 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("密钥通过 iOS Keychain 安全储存。")
                    Text("对话消息与必要的记录上下文会发送至 DeepSeek；日常数据继续保存在本机。")
                }.font(.caption).lineSpacing(4)
            }.foregroundStyle(Loom.secondary)
        }
    }

    private var fieldsValid: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func connect(save: Bool) {
        guard fieldsValid, !isWorking else { return }
        focusedField = nil
        let enteredKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        statusMessage = nil
        statusSucceeded = false
        if save {
            do { try connection.save(apiKey: enteredKey, model: enteredModel) }
            catch { statusMessage = error.localizedDescription; return }
        }
        isWorking = true
        connectionTask = Task { @MainActor in
            defer { isWorking = false }
            do {
                try await connection.test(apiKey: enteredKey, model: enteredModel)
                try Task.checkCancellation()
                statusSucceeded = true
                statusMessage = save ? "连接成功，密钥和模型已保存。可以回去说一点了。" : "连接测试成功。当前填写的设置还需要点击「保存并连接」才会保存。"
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                statusSucceeded = false
                statusMessage = (save ? "设置已保存，但连接测试未通过：" : "连接测试未通过：") + error.localizedDescription
            }
        }
    }

    private func removeKey() {
        do {
            try connection.removeKey()
            apiKey = ""
            statusSucceeded = true
            statusMessage = "已移除本机密钥。你的日常记录会继续保留。"
        } catch {
            statusSucceeded = false
            statusMessage = error.localizedDescription
        }
    }
}
