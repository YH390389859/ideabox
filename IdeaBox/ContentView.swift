import SwiftUI

struct ContentView: View {
    var allowsAmbientMotion = true
    @StateObject private var appModel = AppModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var navigation
    @State private var showingCreate = false
    @State private var showingHabit = false
    @State private var composer: ComposerKind?
    @State private var pendingCreation: CreationDestination?

    private enum CreationDestination {
        case habit
        case record(ComposerKind)
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
        .sheet(isPresented: $showingCreate, onDismiss: presentSelectedCreation) {
            creationMenu
                .presentationDetents([.height(460)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
                .presentationBackground(Loom.paper)
        }
        .sheet(isPresented: $showingHabit) {
            HabitEditorSheet().environmentObject(appModel)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
                .presentationBackground(Loom.paper)
        }
        .sheet(item: $composer) { kind in
            RecordComposerSheet(kind: kind).environmentObject(appModel)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(22)
                .presentationBackground(Loom.paper)
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
                    showingCreate = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 18, weight: .light))
                        Text("拾起").font(.system(size: 13, weight: .medium))
                    }.foregroundStyle(Loom.paper)
                        .frame(width: 110, height: 48).background(Loom.ink, in: ShuttleShape())
                        .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("拾起：新建文字、语音、链接或习惯")
                .accessibilityIdentifier("global-create")
            }
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 6)
        .background(Loom.paper.ignoresSafeArea(edges: .bottom))
        .animation(reduceMotion ? nil : Studio.spring, value: appModel.currentTab)
        .sensoryFeedback(.selection, trigger: appModel.currentTab)
    }

    private var creationMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            LoomHeader(index: "CAPTURE / PICK UP A THREAD", title: "这一刻，留下什么？", subtitle: "一段话，一个声音，远处的一个链接。")
                .padding(.bottom, 6)
            creationOption("写下来", detail: "TEXT / 一点念头", symbol: "pencil.line", kind: .text, surface: .text)
            creationOption("录一段", detail: "VOICE / 此刻的声音", symbol: "waveform", kind: .voice, surface: .voice)
            creationOption("留链接", detail: "LINK / 通向别处", symbol: "arrow.up.right", kind: .link, surface: .link)
            Button {
                pendingCreation = .habit
                showingCreate = false
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus").font(.system(size: 17, weight: .light))
                    Text("添加一根习惯的线").font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 12))
                }.foregroundStyle(Loom.ink).frame(height: 48).contentShape(Rectangle())
            }.buttonStyle(StudioPressStyle()).padding(.top, 2)
        }.padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 20)
    }

    private func creationOption(_ title: String, detail: String, symbol: String, kind: ComposerKind, surface: MaterialSampleKind) -> some View {
        Button { openComposer(kind) } label: {
            HStack(spacing: 15) {
                Image(systemName: symbol).font(.system(size: 20, weight: .light)).frame(width: 24)
                Text(title).font(.system(size: 16, weight: .medium))
                Spacer()
                Text(detail).font(.system(size: 8, design: .monospaced))
            }
            .foregroundStyle(kind == .voice ? .white : Loom.ink)
            .padding(.horizontal, 22).frame(height: 62)
            .background(MaterialSampleSurface(kind: surface))
            .contentShape(Rectangle())
        }.buttonStyle(StudioPressStyle())
    }

    private func openComposer(_ kind: ComposerKind) {
        IdeaAudioController.stopAllPlayback()
        pendingCreation = .record(kind)
        showingCreate = false
    }
    private func presentSelectedCreation() {
        guard let destination = pendingCreation else { return }
        pendingCreation = nil
        switch destination {
        case .habit: showingHabit = true
        case .record(let kind): composer = kind
        }
    }
    private func title(for tab: AppTab) -> String {
        switch tab { case .dashboard: "今天"; case .habits: "习惯"; case .clips: "收集" }
    }
}

#Preview { ContentView() }
