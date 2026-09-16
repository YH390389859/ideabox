import SwiftUI

struct ContentView: View {
    var allowsAmbientMotion = true
    @StateObject private var appModel: AppModel
    @StateObject private var agent: AgentCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var navigation
    @State private var showingAgent = false
    @State private var agentDraft = ""

    init(allowsAmbientMotion: Bool = true) {
        self.allowsAmbientMotion = allowsAmbientMotion
        #if DEBUG
        let preview = ProcessInfo.processInfo.environment["IDEABOX_AGENT_PREVIEW"]
        let model = preview == nil ? AppModel() : AppModel(storageURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentPreview-\(UUID())/library.json"))
        #else
        let model = AppModel()
        #endif
        _appModel = StateObject(wrappedValue: model)
        #if DEBUG
        let previewConnection = preview == nil ? nil : AgentConnection(storage: AgentPreviewKeyStorage(),
            preferences: UserDefaults(suiteName: "IdeaBox.AgentPreview")!)
        let coordinator = AgentCoordinator(appModel: model, connection: previewConnection)
        if preview == "receipts" { coordinator.loadPreviewConversation() }
        if preview == "scroll" || preview == "speech" { coordinator.loadScrollPreviewConversation() }
        _showingAgent = State(initialValue: preview != nil)
        #else
        let coordinator = AgentCoordinator(appModel: model)
        #endif
        _agent = StateObject(wrappedValue: coordinator)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Loom.paper.ignoresSafeArea()
            ZStack {
                page(.dashboard) { DashboardScreen(allowsAmbientMotion: allowsAmbientMotion) }
                page(.habits) { HabitsScreen() }
                page(.clips) { ClipsScreen() }
            }
            .environmentObject(appModel)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: appModel.currentTab)
            navigationBar
        }
        .tint(Loom.cobalt)
        .fullScreenCover(isPresented: $showingAgent) {
            AgentScreen(coordinator: agent, draft: $agentDraft).environmentObject(appModel)
        }
    }

    private func page<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(appModel.currentTab == tab ? 1 : 0)
            .offset(x: reduceMotion || appModel.currentTab == tab ? 0 : 12)
            .allowsHitTesting(appModel.currentTab == tab)
            .accessibilityHidden(appModel.currentTab != tab)
    }

    private var navigationBar: some View {
        VStack(spacing: 10) {
            Rectangle().fill(Loom.hairline).frame(height: 0.8)
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    let selected = appModel.currentTab == tab
                    Button {
                        if selected { appModel.requestScrollToTop(for: tab) }
                        appModel.activate(tab: tab)
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            Text(title(for: tab)).font(.system(size: 14, weight: selected ? .semibold : .regular))
                                .foregroundStyle(selected ? Loom.ink : Loom.secondary)
                            ZStack {
                                Color.clear.frame(width: 29, height: 2)
                                if selected {
                                    Rectangle().fill(Loom.ink).frame(width: 29, height: 2)
                                        .matchedGeometryEffect(id: "index", in: navigation)
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 48).contentShape(Rectangle())
                    }
                    .buttonStyle(StudioPressStyle())
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("tab-\(tab.rawValue)")
                }
                Button {
                    IdeaAudioController.stopAllPlayback()
                    showingAgent = true
                } label: {
                    HStack(spacing: 8) {
                        Text("说一点").font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium))
                    }.foregroundStyle(Loom.paper)
                        .frame(width: 108, height: 48).background(Loom.ink, in: ShuttleShape())
                        .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("说一点，织进去：对话记录日常")
                .accessibilityIdentifier("open-agent")
            }
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 6)
        .background(Loom.paper.ignoresSafeArea(edges: .bottom))
        .animation(reduceMotion ? nil : Studio.spring, value: appModel.currentTab)
        .sensoryFeedback(.selection, trigger: appModel.currentTab)
    }

    private func title(for tab: AppTab) -> String {
        switch tab { case .dashboard: "今天"; case .habits: "习惯"; case .clips: "收集" }
    }
}

#Preview { ContentView() }
