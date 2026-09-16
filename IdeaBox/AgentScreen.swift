import SwiftUI

/// Conversational capture stays in the same material language as the library.
struct AgentScreen: View {
    @ObservedObject var coordinator: AgentCoordinator
    @ObservedObject private var connection: AgentConnection
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 42.0
    @ScaledMetric(relativeTo: .footnote) private var manualEntrySize = 13.0
    @Binding private var draft: String
    @StateObject private var speech = SpeechInputController()
    @State private var speechDraft: SpeechInputDraft?
    @State private var speechStartedAt: Date?
    @State private var speechLevels: [Double] = []
    @State private var speechNotice: String?
    @State private var showingSettings = false
    @State private var showingManualCapture = false
    @State private var confirmingClear = false
    @State private var selectedItem: LibraryItem?
    @State private var selectedSearch: AgentToolReceipt?
    @State private var viewingError: String?
    @FocusState private var inputFocused: Bool
    @AccessibilityFocusState private var newConversationFocused: Bool

    init(coordinator: AgentCoordinator, draft: Binding<String>) {
        self.coordinator = coordinator
        self.connection = coordinator.connection
        self._draft = draft
    }

    var body: some View {
        VStack(spacing: 0) {
            navigation
            GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        if coordinator.turns.isEmpty {
                            invitation(artworkHeight: min(210, max(145, viewport.size.height - 395)))
                                .id("agent-start")
                        } else {
                            conversationHeading
                            ForEach(coordinator.turns) { turn in
                                conversationTurn(turn)
                            }
                        }
                        if let error = coordinator.errorMessage { errorNotice(error) }
                        Color.clear.frame(height: 1).id("agent-bottom")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, coordinator.turns.isEmpty ? 20 : 26)
                    .padding(.bottom, 18)
                }
                .overlay(alignment: .top) {
                    if !coordinator.turns.isEmpty {
                        LinearGradient(
                            stops: [
                                .init(color: Loom.paper, location: 0),
                                .init(color: Loom.paper.opacity(0.92), location: 0.18),
                                .init(color: Loom.paper.opacity(0.35), location: 0.62),
                                .init(color: Loom.paper.opacity(0), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 28)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
                .defaultScrollAnchor(coordinator.turns.isEmpty ? .top : .bottom)
                .scrollDismissesKeyboard(.interactively)
                .task {
                    guard !coordinator.turns.isEmpty else { return }
                    await Task.yield()
                    scrollToEnd(proxy, animated: false)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && !coordinator.turns.isEmpty { scrollToEnd(proxy, animated: false) }
                }
                .onChange(of: showingSettings) { _, showing in
                    if !showing && !coordinator.turns.isEmpty { scrollToEnd(proxy, animated: false) }
                }
                .onChange(of: showingManualCapture) { _, showing in
                    if !showing && !coordinator.turns.isEmpty { scrollToEnd(proxy, animated: false) }
                }
                .onChange(of: viewport.size.height) { _, _ in
                    if !coordinator.turns.isEmpty { scrollToEnd(proxy, animated: false) }
                }
                .onChange(of: coordinator.turns.count) { _, count in
                    if count == 0 { proxy.scrollTo("agent-start", anchor: .top) }
                    else { scrollToEnd(proxy) }
                }
                .onChange(of: coordinator.turns.last?.assistantText) { _, _ in
                    if coordinator.isRunning { proxy.scrollTo("agent-bottom", anchor: .bottom) }
                }
                .onChange(of: coordinator.stage) { _, _ in scrollToEnd(proxy) }
                .onChange(of: inputFocused) { _, focused in
                    if focused && !coordinator.turns.isEmpty { scrollToEnd(proxy) }
                }
            }
            }
        }
        .foregroundStyle(Loom.ink)
        .background(Loom.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .tint(Loom.cobalt)
        .sheet(isPresented: $showingSettings) {
            AgentSettingsSheet(connection: connection)
                .presentationDragIndicator(.visible)
                .presentationBackground(Loom.paper)
                .presentationCornerRadius(22)
        }
        .sheet(isPresented: $showingManualCapture) {
            ManualCaptureSheet().environmentObject(appModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Loom.paper)
                .presentationCornerRadius(30)
        }
        .sheet(item: $selectedItem) {
            LibraryDetailSheet(item: $0).environmentObject(appModel)
                .presentationBackground(Loom.paper)
        }
        .sheet(item: $selectedSearch) { receipt in
            searchResults(receipt)
                .presentationDragIndicator(.visible)
                .presentationBackground(Loom.paper)
        }
        .alert("这条记录暂时无法打开", isPresented: Binding(get: { viewingError != nil }, set: { if !$0 { viewingError = nil } })) {
            Button("知道了", role: .cancel) { viewingError = nil }
        } message: { Text(viewingError ?? "") }
        .accessibilityHidden(confirmingClear)
        .allowsHitTesting(!confirmingClear)
        .overlay {
            if confirmingClear {
                NewConversationPrompt(
                    canConfirm: !coordinator.isRunning,
                    onCancel: dismissNewConversation,
                    onConfirm: {
                        coordinator.clearConversation()
                        confirmingClear = false
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.2), value: confirmingClear)
        .onChange(of: draft) { _, value in
            if value.count > 4_000 { draft = String(value.prefix(4_000)) }
        }
        .onChange(of: speech.transcript) { _, text in mergeSpeech(text) }
        .onChange(of: speech.audioLevel) { _, level in
            speechLevels.append(level)
            if speechLevels.count > 32 { speechLevels.removeFirst(speechLevels.count - 32) }
        }
        .onChange(of: speech.phase) { _, phase in
            if phase == .listening { speechStartedAt = Date() }
        }
        .onChange(of: speech.completedSessionID) { _, _ in
            // Every completion is distinct, even repeated permission errors in one render pass.
            if !speech.isActive {
                mergeSpeech(speech.transcript)
                speechDraft = nil
                speechStartedAt = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { preserveSpeechAndStop(); inputFocused = false }
        }
        .onDisappear { preserveSpeechAndStop(); inputFocused = false }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["IDEABOX_AGENT_PREVIEW"] == "settings" {
                showingSettings = true
            }
            #endif
        }
    }

    private var navigation: some View {
        HStack(spacing: 0) {
            Button { preserveSpeechAndStop(); inputFocused = false; dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .light))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }.accessibilityLabel("返回日常织机")
            Spacer(minLength: 8)
            Text(coordinator.turns.isEmpty ? "一段新对话" : "和日常，说说话")
                .font(.subheadline.weight(.medium)).lineLimit(1)
            Spacer(minLength: 8)
            if !coordinator.turns.isEmpty || coordinator.errorMessage != nil {
                Button {
                    preserveSpeechAndStop()
                    inputFocused = false
                    newConversationFocused = false
                    confirmingClear = true
                } label: {
                    HStack(spacing: 6) {
                        NewConversationThreadMark().frame(width: 19, height: 19)
                        Text("新对话").font(.system(.caption, weight: .medium))
                            .fixedSize()
                    }
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(Color(hex: 0xE2E8D4), in: Capsule())
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
                .disabled(coordinator.isRunning)
                .opacity(coordinator.isRunning ? 0.45 : 1)
                .accessibilityLabel("新对话")
                .accessibilityHint("打开确认纸片，确认后清空当前对话")
                .accessibilityIdentifier("agent-new-conversation")
                .accessibilityFocused($newConversationFocused)
            }
            Button { preserveSpeechAndStop(); inputFocused = false; showingSettings = true } label: {
                Image(systemName: "gearshape").font(.system(size: 19, weight: .light))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }.accessibilityLabel("DeepSeek 连接设置")
                .accessibilityIdentifier("agent-settings")
        }
        .buttonStyle(StudioPressStyle())
        .padding(.horizontal, 12).padding(.top, 3)
        .background(Loom.paper)
    }

    private func dismissNewConversation() {
        confirmingClear = false
        newConversationFocused = true
    }

    private func invitation(artworkHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AgentEyebrow(text: "04 / TALK TO LOOM")
                .padding(.bottom, 14)
            Text("说一点，\n织进去。")
                .font(.system(size: titleSize, weight: .semibold))
                .tracking(-1.8).fixedSize(horizontal: false, vertical: true)
            Text("日常、习惯、灵感，都从一句话开始。")
                .font(.subheadline).foregroundStyle(Loom.secondary)
                .padding(.top, 14)
            if !inputFocused {
                AgentThreadArtwork(active: scenePhase == .active && !showingSettings && !showingManualCapture && !confirmingClear && !speech.isActive)
                    .frame(height: artworkHeight).padding(.top, 8)
                    .accessibilityHidden(true)
                AgentEyebrow(text: "A THOUGHT BECOMES A THREAD", color: Loom.secondary)
                    .padding(.top, 4).padding(.bottom, 17)
                Rectangle().fill(Loom.hairline).frame(height: 0.7)
                Text("从这里开始").font(.caption).foregroundStyle(Loom.secondary)
                    .padding(.top, 12).padding(.bottom, 5)
                suggestion("记下今天的小事", number: "01", draft: "帮我记下今天的小事：")
                Rectangle().fill(Loom.hairline).frame(height: 0.6).padding(.leading, 28)
                suggestion("帮我整理一个想法", number: "02", draft: "帮我整理这个想法：")
            } else {
                Text("你可以记一段日常、为习惯打卡，或留下一个链接。")
                    .font(.subheadline).foregroundStyle(Loom.secondary)
                    .padding(.top, 28)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: inputFocused)
    }

    private func suggestion(_ label: String, number: String, draft value: String) -> some View {
        Button {
            preserveSpeechAndStop()
            draft = value
            inputFocused = true
        } label: {
            HStack(spacing: 18) {
                Text(number).font(.system(.caption2, design: .monospaced)).foregroundStyle(Loom.cobalt)
                Text(label).font(.body)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .light))
            }.frame(minHeight: 48).contentShape(Rectangle())
        }.buttonStyle(StudioPressStyle())
    }

    private var conversationHeading: some View {
        VStack(alignment: .leading, spacing: 15) {
            AgentEyebrow(text: "04 / A THREAD, KEPT")
            Text(coordinator.isRunning ? "让这一段，慢慢成形。" : latestTurnHasSavedActions ? "这一段，已织好。" : "每一句，都有来处。")
                .font(.system(.title, design: .default, weight: .semibold)).tracking(-1.1)
                .fixedSize(horizontal: false, vertical: true)
            Text(latestTurnHasSavedActions ? "你留下的小事，已经有了自己的位置。" : "你说的话，和它落下的位置。")
                .font(.subheadline).foregroundStyle(Loom.secondary)
        }
    }

    private var latestTurnHasSavedActions: Bool {
        guard let turn = coordinator.turns.last, turn.status == .completed else { return false }
        return coordinator.receipts(for: turn).contains { $0.success && !$0.undone && $0.kind != .search && $0.kind != .error }
    }

    private func conversationTurn(_ turn: AgentTurn) -> some View {
        let receipts = coordinator.receipts(for: turn)
        return VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    AgentEyebrow(text: "YOU", color: Loom.secondary)
                    Spacer()
                    Text(turn.createdAt, format: .dateTime.hour().minute())
                        .font(.system(.caption2, design: .monospaced)).foregroundStyle(Loom.secondary)
                }
                Text(turn.userText).font(.body).lineSpacing(5).textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17).padding(.bottom, 7)
            .background(Color(hex: 0xE7E7DC), in: AgentTornPaper())

            if !receipts.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                        receiptRow(receipt, index: index, last: index == receipts.count - 1)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(x: 7, y: 10)))
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
            }
            if !turn.assistantText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    AgentEyebrow(text: "LOOM")
                    Text(turn.assistantText).font(.body).lineSpacing(6).textSelection(.enabled)
                }
            }
            if turn.status == .pending {
                HStack(spacing: 12) {
                    AgentWeavingProgress(active: scenePhase == .active && !showingSettings && !showingManualCapture && selectedItem == nil && selectedSearch == nil && !speech.isActive)
                        .frame(width: 43, height: 28).accessibilityHidden(true)
                    Text(coordinator.stage.isEmpty ? "正在理一理这根线…" : coordinator.stage)
                        .font(.subheadline).foregroundStyle(Loom.secondary)
                }.frame(minHeight: 36)
            } else if turn.status == .cancelled {
                Label("已停止。已经保存的记录仍会保留。", systemImage: "pause.circle")
                    .font(.caption).foregroundStyle(Loom.secondary)
            }
        }
        .padding(.bottom, 6)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.48, dampingFraction: 0.86),
                   value: receipts.map { "\($0.id):\($0.undone)" })
    }

    private func receiptRow(_ receipt: AgentToolReceipt, index: Int, last: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 22))
                    path.addLine(to: CGPoint(x: 28, y: 22))
                    path.move(to: CGPoint(x: 10, y: 22))
                    path.addLine(to: CGPoint(x: 10, y: geometry.size.height + (last ? -3 : 40)))
                }.stroke(Loom.cobalt.opacity(receipt.undone ? 0.35 : 0.8), lineWidth: 0.9)
                Circle().fill(Loom.paper).overlay(Circle().stroke(Loom.cobalt, lineWidth: 1))
                    .frame(width: 9, height: 9).position(x: 10, y: 22)
                if last {
                    Circle().fill(Loom.cobalt).frame(width: 4, height: 4)
                        .position(x: 10, y: geometry.size.height - 2)
                }
            }.frame(width: 28)
            AgentReceiptCard(receipt: receipt, index: index + 1,
                             canInteract: !coordinator.isRunning,
                             viewAction: { view(receipt) }, undoAction: { coordinator.undo(receipt) })
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func errorNotice(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("这根线暂时停住了", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.medium)).foregroundStyle(Loom.clay)
            Text(message).font(.subheadline).foregroundStyle(Loom.secondary).textSelection(.enabled)
            if coordinator.needsRetry && !coordinator.isRunning {
                HStack(spacing: 18) {
                    Button("重试这一段") { preserveSpeechAndStop(); inputFocused = false; coordinator.retry() }
                    Button("连接设置") { preserveSpeechAndStop(); inputFocused = false; showingSettings = true }
                }.font(.subheadline.weight(.medium)).frame(minHeight: 44).tint(Loom.cobalt)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(Loom.clay.opacity(0.065))
        .overlay(alignment: .leading) { Rectangle().fill(Loom.clay).frame(width: 2) }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle().fill(Loom.ink.opacity(0.7)).frame(height: 0.8)
            if speech.isActive {
                speechControls
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            }
            if let notice = speech.errorMessage ?? speechNotice {
                speechFeedback(notice)
            }
            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    if speech.isActive { speech.finish() } else { startSpeech() }
                } label: {
                    Image(systemName: "mic").font(.system(size: 20, weight: .light))
                        .foregroundStyle(speech.isActive ? Loom.cobalt : Loom.ink)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .disabled(coordinator.isRunning || speech.phase == .finishing)
                .accessibilityLabel(speech.isActive ? "结束语音输入" : "语音输入")
                .accessibilityHint("将声音转成可编辑的文字，完成后自行发送")
                .accessibilityIdentifier("agent-speech-input")
                TextField(coordinator.turns.isEmpty ? "今天有什么想留下？" : "继续留下一根线…", text: $draft, axis: .vertical)
                    .font(.body).lineLimit(1...5).focused($inputFocused)
                    .padding(.vertical, 12)
                    .disabled(speech.isActive)
                    .accessibilityIdentifier("agent-message-input")
                Button {
                    if coordinator.isRunning { coordinator.cancel() } else { send() }
                } label: {
                    Image(systemName: coordinator.isRunning ? "stop.fill" : "arrow.up")
                        .font(.system(size: coordinator.isRunning ? 13 : 21, weight: .light))
                        .foregroundStyle(Loom.paper)
                        .frame(width: 60, height: 44)
                        .background(Loom.ink.opacity(canSend || coordinator.isRunning ? 1 : 0.35), in: ShuttleShape())
                        .contentShape(Rectangle())
                }.buttonStyle(StudioPressStyle())
                    .disabled(speech.isActive || (!coordinator.isRunning && !canSend))
                    .accessibilityLabel(coordinator.isRunning ? "停止生成" : "发送")
                    .accessibilityIdentifier("agent-send")
            }
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("DEEPSEEK").font(.system(.caption2, design: .monospaced)).tracking(1)
                    Circle().fill(connection.isConfigured ? Loom.cobalt : Loom.clay).frame(width: 4, height: 4)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(connection.isConfigured ? "DeepSeek 已配置" : "DeepSeek 尚未配置，可在右上角设置连接")
                Spacer(minLength: 4)
                if draft.count >= 3_500 {
                    Text("\(draft.count)/4000").font(.caption2.monospacedDigit()).lineLimit(1)
                }
                Button {
                    preserveSpeechAndStop()
                    inputFocused = false
                    IdeaAudioController.stopAllPlayback()
                    showingManualCapture = true
                } label: {
                    HStack(spacing: 10) {
                        Text("自己记").font(.system(size: manualEntrySize, weight: .medium))
                        Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .regular))
                    }
                    .foregroundStyle(Loom.ink)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 76, minHeight: 44, alignment: .trailing)
                    .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("自己记")
                .accessibilityHint("直接写文字、录音、留链接或添加习惯，无需连接 AI")
                .accessibilityIdentifier("agent-manual-capture")
            }.foregroundStyle(Loom.secondary)
        }
        .padding(.horizontal, 24).padding(.top, 3).padding(.bottom, 2)
        .background(Loom.paper)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: speech.isActive)
    }

    private var canSend: Bool { !speech.isActive && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var speechControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(Loom.cobalt).frame(width: 5, height: 5)
                Text(speech.phase == .requestingPermission ? "等待授权…" : speech.phase == .finishing ? "正在整理…" : "正在听…")
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier("agent-speech-controls")
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = min(60, max(0, Int(context.date.timeIntervalSince(speechStartedAt ?? context.date))))
                    Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                        .font(.caption.monospacedDigit()).foregroundStyle(Loom.secondary)
                }
                .accessibilityLabel("语音输入计时")
            }
            HStack(spacing: 12) {
                GeometryReader { geometry in
                    Path { path in
                        for index in 0..<32 {
                            let source = index - (32 - speechLevels.count)
                            let level = source >= 0 ? speechLevels[source] : 0
                            let height = max(2, level * geometry.size.height)
                            let x = (CGFloat(index) + 0.5) * geometry.size.width / 32
                            path.move(to: CGPoint(x: x, y: (geometry.size.height - height) / 2))
                            path.addLine(to: CGPoint(x: x, y: (geometry.size.height + height) / 2))
                        }
                    }.stroke(Loom.cobalt, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                }
                .frame(height: 28).accessibilityHidden(true)
                Button("取消") { cancelSpeech() }
                    .font(.subheadline).foregroundStyle(Loom.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("agent-speech-cancel")
                Button { speech.finish() } label: {
                    Text("完成").font(.subheadline.weight(.medium))
                        .foregroundStyle(Loom.paper).padding(.horizontal, 12)
                        .frame(minHeight: 44).background(Loom.ink, in: Capsule())
                }
                .disabled(speech.phase != .listening)
                .accessibilityIdentifier("agent-speech-finish")
            }
            .buttonStyle(StudioPressStyle())
            if let notice = speech.recognitionNotice {
                Text(notice).font(.caption).foregroundStyle(Loom.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(speech.isPreview ? "界面演示 · 不使用麦克风" : speech.usesOnDeviceRecognition ? "在这台设备上转文字 · 完成后由你发送" : "系统语音识别可能联网 · 完成后由你发送")
                .font(.caption2).foregroundStyle(Loom.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 15).padding(.vertical, 12)
        .background(Color(hex: 0xE5EBD5), in: RoundedRectangle(cornerRadius: 12))
    }

    private func speechFeedback(_ notice: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(notice).font(.caption).foregroundStyle(Loom.clay)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("agent-speech-error")
                if speech.requiresSettings {
                    Button("打开系统设置") {
                        preserveSpeechAndStop()
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(.caption.weight(.medium)).frame(minHeight: 44)
                    .accessibilityIdentifier("agent-speech-open-settings")
                }
            }
            Spacer(minLength: 0)
            Button {
                speech.errorMessage = nil
                speechNotice = nil
            } label: {
                Image(systemName: "xmark").font(.system(size: 11))
                    .foregroundStyle(Loom.secondary).frame(width: 44, height: 44)
            }
            .accessibilityLabel("关闭语音提示")
            .accessibilityIdentifier("agent-speech-dismiss-error")
        }
        .buttonStyle(StudioPressStyle())
    }

    private func startSpeech() {
        guard !coordinator.isRunning, !speech.isActive else { return }
        guard draft.count < 3_999 else {
            speechNotice = "这段草稿已经很长，先发送或精简一些再继续说。"
            return
        }
        inputFocused = false
        speechNotice = nil
        speechDraft = SpeechInputDraft(originalText: draft)
        speechLevels = []
        speech.start()
    }

    private func mergeSpeech(_ text: String) {
        guard let speechDraft else { return }
        draft = speechDraft.merging(text)
        if speechDraft.wouldExceedLimit(text) {
            speechNotice = "已达到 4,000 字，先把这一段发送或整理一下。"
            speech.finish()
        }
    }

    private func cancelSpeech() {
        let original = speechDraft?.originalText
        speechDraft = nil
        speech.cancel()
        if let original { draft = original }
        speechNotice = nil
        speechStartedAt = nil
        speechLevels = []
    }

    private func preserveSpeechAndStop() {
        guard speech.isActive || speechDraft != nil else { return }
        mergeSpeech(speech.transcript)
        speechDraft = nil
        speech.suspend()
        speechStartedAt = nil
    }

    private func send() {
        guard canSend else { return }
        guard connection.isConfigured else {
            inputFocused = false
            showingSettings = true
            return
        }
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        inputFocused = false
        let previousTurnCount = coordinator.turns.count
        coordinator.send(message)
        if coordinator.turns.count > previousTurnCount { draft = "" }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, animated: Bool = true) {
        withAnimation(reduceMotion || !animated ? nil : .easeOut(duration: 0.25)) {
            proxy.scrollTo("agent-bottom", anchor: .bottom)
        }
    }

    private func view(_ receipt: AgentToolReceipt) {
        preserveSpeechAndStop()
        if receipt.kind == .search { selectedSearch = receipt; return }
        if receipt.kind == .habit { appModel.activate(tab: .habits); dismiss(); return }
        guard let recordID = receipt.recordID,
              let item = appModel.libraryItems.first(where: { $0.id == recordID }) else {
            viewingError = receipt.undone ? "这次操作已撤回。" : "记录可能已经被删除。"
            return
        }
        selectedItem = item
    }

    private func searchResults(_ receipt: AgentToolReceipt) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AgentEyebrow(text: "FOUND / IN YOUR LOOM")
                    Text(receipt.title).font(.title2.weight(.semibold))
                    Text(receipt.detail).font(.body).foregroundStyle(Loom.secondary).textSelection(.enabled)
                    ForEach(Array(searchMatches(receipt).enumerated()), id: \.offset) { _, match in
                        if let recordID = match.recordID,
                           let item = appModel.libraryItems.first(where: { $0.id == recordID }) {
                            NavigationLink {
                                LibraryDetailSheet(item: item).environmentObject(appModel)
                            } label: {
                                VStack(alignment: .leading, spacing: 9) {
                                    AgentEyebrow(text: match.kind == "clip" ? "LINK" : "DIARY", color: Loom.secondary)
                                    Text(searchTitle(item)).font(.headline).lineLimit(3)
                                    Text(item.dateAdded, format: .dateTime.year().month().day())
                                        .font(.caption).foregroundStyle(Loom.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18).background(Color(hex: 0xFBFAF3))
                            }.buttonStyle(StudioPressStyle())
                        } else if let habitID = match.habitID,
                                  let habit = appModel.habits.first(where: { $0.id == habitID }) {
                            Button {
                                selectedSearch = nil
                                appModel.activate(tab: .habits)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    AgentEyebrow(text: "HABIT", color: Loom.ink)
                                    HStack {
                                        Text(habit.name).font(.headline)
                                        Spacer(minLength: 10)
                                        Image(systemName: "arrow.up.right").font(.subheadline)
                                    }
                                    Text(habit.scheduleDescription).font(.caption)
                                    Text(habitSearchStatus(habit, match: match)).font(.subheadline)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18).background(Loom.acid.opacity(0.8))
                            }.buttonStyle(StudioPressStyle())
                        } else {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(match.title ?? match.name ?? match.content ?? "一条旧记录")
                                    .font(.headline).lineLimit(3)
                                Text("这条记录已不在本机，无法打开。")
                                    .font(.caption).foregroundStyle(Loom.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18).background(Color(hex: 0xE7E7DC))
                        }
                    }
                }.padding(24)
            }
            .background(Loom.paper).foregroundStyle(Loom.ink)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { selectedSearch = nil }
                }
            }
        }.tint(Loom.cobalt)
    }

    private func searchMatches(_ receipt: AgentToolReceipt) -> [AgentSearchMatch] {
        guard let payload = try? JSONDecoder().decode(AgentSearchPayload.self, from: Data(receipt.resultJSON.utf8)) else { return [] }
        return payload.results ?? payload.habits ?? []
    }

    private func habitSearchStatus(_ habit: Habit, match: AgentSearchMatch) -> String {
        guard let day = match.date, let date = AppFormatters.dayKey.date(from: day) else { return "查看习惯记录" }
        let status = !habit.isScheduled(on: date) ? "当天未安排" : habit.isCompleted(on: date) ? "已完成" : "未完成"
        return "\(date.monthDayTitle) · \(status)"
    }

    private func searchTitle(_ item: LibraryItem) -> String {
        switch item { case .clip(let clip): clip.title; case .diary(let diary): diary.content }
    }
}

private struct AgentSearchPayload: Decodable {
    let results: [AgentSearchMatch]?
    let habits: [AgentSearchMatch]?
}

private struct AgentSearchMatch: Decodable {
    let kind: String
    let recordID: UUID?
    let habitID: UUID?
    let date: String?
    let title: String?
    let content: String?
    let name: String?
    enum CodingKeys: String, CodingKey {
        case kind, date, title, content, name
        case recordID = "record_id"
        case habitID = "habit_id"
    }
}

struct AgentEyebrow: View {
    let text: String
    var color: Color = Loom.cobalt
    var body: some View {
        Text(text).font(.system(.caption2, design: .monospaced)).tracking(1.15)
            .foregroundStyle(color).fixedSize(horizontal: false, vertical: true)
    }
}

private struct AgentReceiptCard: View {
    let receipt: AgentToolReceipt
    let index: Int
    let canInteract: Bool
    let viewAction: () -> Void
    let undoAction: () -> Void

    private var isHabit: Bool { receipt.kind == .habit }
    private var diaryPayload: AgentDiaryReceiptPayload? {
        guard receipt.kind == .diary, receipt.success, !receipt.undone else { return nil }
        return try? JSONDecoder().decode(AgentDiaryReceiptPayload.self, from: Data(receipt.resultJSON.utf8))
    }
    private var headline: String {
        if let content = diaryPayload?.content, !content.isEmpty { return content }
        return receipt.title
    }
    private var supportingText: String {
        if diaryPayload?.content != nil {
            if let day = diaryPayload?.date, let date = AppFormatters.dayKey.date(from: day) {
                return "\(date.monthDayTitle) · 已存入日常"
            }
            return "已存入日常"
        }
        return receipt.detail
    }
    private var surface: Color {
        if receipt.undone { return Color(hex: 0xE7E7DC) }
        if !receipt.success { return Color(hex: 0xF0E0D5) }
        return isHabit ? Loom.acid : Color(hex: 0xFBFAF3)
    }
    private var label: String {
        switch receipt.kind {
        case .diary: "DIARY"
        case .habit: "HABIT"
        case .clip: "LINK"
        case .search: "FOUND"
        case .error: "NOTICE"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                AgentEyebrow(text: String(format: "%02d / %@", index, label), color: isHabit ? Loom.ink : Loom.secondary)
                Spacer(minLength: 5)
                Image(systemName: receipt.undone ? "arrow.uturn.backward.circle" : receipt.success ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(receipt.success ? Loom.ink : Loom.clay)
            }.padding(.trailing, isHabit ? 0 : 14)
            Text(headline).font(.system(.title3, weight: .semibold)).lineSpacing(4).lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
                .strikethrough(receipt.undone, color: Loom.secondary)
            if !isHabit && !supportingText.isEmpty {
                Text(supportingText).font(.subheadline).lineSpacing(3)
                    .foregroundStyle(Loom.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !isHabit { Rectangle().fill(Loom.hairline).frame(height: 0.6) }
            HStack(spacing: 8) {
                Text(receipt.undone ? "已撤回" : isHabit ? receipt.detail : receipt.success ? "已完成" : "未执行")
                    .font(.caption).foregroundStyle(isHabit && !receipt.undone ? Loom.ink : Loom.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if receipt.success && !receipt.undone && receipt.kind != .error {
                    Button("查看", action: viewAction).accessibilityLabel("查看：\(receipt.title)")
                        .frame(minWidth: 44, minHeight: 44)
                }
                if receipt.success && receipt.canUndo && !receipt.undone {
                    Button("撤回", action: undoAction).accessibilityLabel("撤回：\(receipt.title)")
                        .frame(minWidth: 44, minHeight: 44).disabled(!canInteract)
                }
            }.font(.caption.weight(.medium)).buttonStyle(StudioPressStyle()).padding(.vertical, -8)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: AgentReceiptPaper(folded: !isHabit))
        .overlay(alignment: .topTrailing) {
            if !isHabit {
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: 0, y: 23))
                    path.addLine(to: CGPoint(x: 23, y: 23))
                    path.closeSubpath()
                }.fill(Color(hex: 0xDDDCCF)).frame(width: 23, height: 23).accessibilityHidden(true)
            }
        }
        .overlay(alignment: .leading) {
            if isHabit {
                VStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in Circle().fill(Loom.paper).frame(width: 5, height: 5) }
                }.offset(x: -2.5).accessibilityHidden(true)
            }
        }
    }
}

private struct AgentDiaryReceiptPayload: Decodable {
    let content: String?
    let date: String?
}

private struct AgentTornPaper: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 5))
        let teeth = max(1, Int(rect.width / 17))
        let step = rect.width / CGFloat(teeth)
        for index in (0..<teeth).reversed() {
            path.addLine(to: CGPoint(x: CGFloat(index) * step + step / 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: CGFloat(index) * step, y: rect.maxY - 5))
        }
        path.closeSubpath()
        return path
    }
}

private struct AgentReceiptPaper: Shape {
    var folded: Bool
    func path(in rect: CGRect) -> Path {
        let fold: CGFloat = folded ? 23 : 0
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: fold))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// An indeterminate shuttle: motion indicates work without inventing progress.
private struct AgentWeavingProgress: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var epoch = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !active || reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSince(epoch)
            Canvas { context, size in
                let center = size.width / 2 + sin(time * 2) * 9
                for strand in 0..<4 {
                    let y = size.height / 2 + Double(strand - 2) * 2
                    var thread = Path()
                    thread.move(to: CGPoint(x: 1, y: y + 4))
                    thread.addCurve(to: CGPoint(x: size.width - 1, y: y - 4),
                                    control1: CGPoint(x: size.width * 0.34, y: y - 7),
                                    control2: CGPoint(x: size.width * 0.65, y: y + 7))
                    context.stroke(thread, with: .color(Loom.cobalt.opacity(0.55)), lineWidth: 0.65)
                }
                var shuttleContext = context
                shuttleContext.translateBy(x: center - 11, y: size.height / 2 - 5.5)
                shuttleContext.fill(ShuttleShape().path(in: CGRect(x: 0, y: 0, width: 22, height: 11)), with: .color(Loom.acid))
                var slit = Path()
                slit.move(to: CGPoint(x: center - 5, y: size.height / 2))
                slit.addLine(to: CGPoint(x: center + 5, y: size.height / 2))
                context.stroke(slit, with: .color(Loom.ink), lineWidth: 0.6)
            }
        }
    }
}

/// Slow independent strands replace a chatbot avatar; the drawing stops off screen.
struct AgentThreadArtwork: View {
    var active = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var epoch = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !active || reduceMotion || scenePhase != .active)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSince(epoch)
            Canvas { context, size in
                let scale = min(size.width / 354, size.height / 264)
                context.translateBy(x: (size.width - 354 * scale) / 2, y: (size.height - 264 * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                let phase = sin(time * 0.34) * 0.10
                for strand in 0..<41 {
                    let s = Double(strand - 20) / 20
                    var path = Path()
                    for sample in 0..<250 {
                        let t = 0.1 + Double(sample) * 2 * .pi / 260
                        let point = CGPoint(
                            x: 178 + 117 * cos(t) + s * 21 * cos(2 * t + 0.65 + phase),
                            y: 122 + 63 * sin(2 * t + phase) + 32 * sin(t) + s * (12 * cos(t) - 5 * sin(3 * t)))
                        if sample == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                    context.stroke(path, with: .color(Loom.cobalt.opacity(strand % 5 == 0 ? 0.84 : 0.54)), lineWidth: strand % 5 == 0 ? 0.82 : 0.58)
                }
                var loose = Path()
                loose.move(to: CGPoint(x: 28, y: 170))
                loose.addCurve(to: CGPoint(x: 124, y: 217), control1: CGPoint(x: -9, y: 215), control2: CGPoint(x: 78, y: 238))
                loose.addCurve(to: CGPoint(x: 265, y: 237), control1: CGPoint(x: 198, y: 185), control2: CGPoint(x: 252, y: 196))
                loose.addCurve(to: CGPoint(x: 335, y: 249), control1: CGPoint(x: 275, y: 263), control2: CGPoint(x: 310, y: 257))
                context.stroke(loose, with: .color(Loom.cobalt.opacity(0.8)), lineWidth: 0.8)
                for strand in 0..<7 {
                    let d = Double(strand) * 0.65
                    var clay = Path()
                    clay.move(to: CGPoint(x: 42 + d, y: 75 + d))
                    clay.addCurve(to: CGPoint(x: 193 + d, y: 163 + d), control1: CGPoint(x: 93 + d, y: 32 + d), control2: CGPoint(x: 107 + d, y: 164 + d))
                    clay.addCurve(to: CGPoint(x: 304 + d, y: 91 + d), control1: CGPoint(x: 239 + d, y: 164 + d), control2: CGPoint(x: 252 + d, y: 113 + d))
                    context.stroke(clay, with: .color(Loom.clay.opacity(0.76)), lineWidth: 0.62)
                }
                var shuttleContext = context
                shuttleContext.translateBy(x: 244 + sin(time * 0.34) * 4, y: 155 + cos(time * 0.34) * 3)
                shuttleContext.rotate(by: .degrees(-30))
                shuttleContext.fill(ShuttleShape().path(in: CGRect(x: 0, y: 0, width: 73, height: 29)), with: .color(Loom.acid))
                var slot = Path()
                slot.move(to: CGPoint(x: 16, y: 14.5)); slot.addLine(to: CGPoint(x: 55, y: 14.5))
                shuttleContext.stroke(slot, with: .color(Loom.ink.opacity(0.7)), lineWidth: 0.75)
                shuttleContext.fill(Path(ellipseIn: CGRect(x: 53, y: 12, width: 5, height: 5)), with: .color(Loom.paper))
            }
        }.accessibilityHidden(true)
    }
}
