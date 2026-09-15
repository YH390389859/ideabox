import SwiftUI
import RichEditorSwiftUI

struct ClipsScreen: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var playback = IdeaAudioController()
    @State private var searchTerm = ""
    @State private var selectedTag: String?
    @State private var selectedFilter: ClipFilter = .all
    @State private var activeComposer: ComposerKind?
    @State private var selectedItem: LibraryItem?
    @State private var itemToDelete: LibraryItem?
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    private var allTags: [String] {
        Array(Set(appModel.libraryItems.flatMap(\.tags))).sorted()
    }

    private var items: [LibraryItem] {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        return appModel.libraryItems.filter { item in
            if let selectedTag, !item.tags.contains(selectedTag) { return false }
            let matchesType: Bool
            let searchable: String
            switch item {
            case .clip(let clip):
                matchesType = selectedFilter == .all || selectedFilter == .link
                searchable = "\(clip.title) \(clip.excerpt) \(clip.url) \(clip.tags.joined(separator: " "))"
            case .diary(let diary):
                matchesType = selectedFilter == .all || (selectedFilter == .voice && diary.type == .voice)
                    || (selectedFilter == .text && diary.type == .text)
                searchable = "\(diary.content) \(diary.tags.joined(separator: " "))"
            }
            return matchesType && (query.isEmpty || searchable.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    LoomHeader(index: "03 / COLLECTION", title: "拾起，一闪而过。", subtitle: "文字、声音、远处的一个链接。")
                        .id("collection-top")
                    filters
                    timeline
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 108)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Loom.paper)
            .onChange(of: appModel.scrollTicket(for: .clips)) { _, _ in
                withAnimation(reduceMotion ? nil : Studio.spring) { proxy.scrollTo("collection-top", anchor: .top) }
            }
        }
        .sheet(item: $activeComposer) { RecordComposerSheet(kind: $0) }
        .sheet(item: $selectedItem) { LibraryDetailSheet(item: $0) }
        .confirmationDialog("删除这条收藏？", isPresented: Binding(get: { itemToDelete != nil }, set: { if !$0 { itemToDelete = nil } }), titleVisibility: .visible) {
            Button("删除收藏", role: .destructive) {
                guard let item = itemToDelete else { return }
                playback.stopPlayback()
                withAnimation(reduceMotion ? nil : Studio.spring) {
                    switch item {
                    case .clip(let clip): appModel.deleteClip(clip.id)
                    case .diary(let diary): appModel.deleteDiary(diary.id)
                    }
                }
                itemToDelete = nil
            }
            Button("取消", role: .cancel) { itemToDelete = nil }
        } message: {
            Text("删除后无法恢复；录音文件也会一并删除。")
        }
        .alert("播放提示", isPresented: Binding(get: { playback.errorMessage != nil }, set: { if !$0 { playback.errorMessage = nil } })) {
            Button("知道了", role: .cancel) { playback.errorMessage = nil }
        } message: { Text(playback.errorMessage ?? "") }
        .onChange(of: appModel.pendingComposer) { _, _ in consumeComposer() }
        .onChange(of: appModel.currentTab) { _, tab in
            if tab == .clips { consumeComposer() } else {
                searchFocused = false
                playback.stopPlayback()
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { playback.suspend() } }
        .onChange(of: allTags) { _, tags in
            if let selectedTag, !tags.contains(selectedTag) { self.selectedTag = nil }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { appeared = true }
            consumeComposer()
        }
        .onDisappear { playback.stopPlayback() }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .light)).foregroundStyle(Loom.ink)
                TextField("寻找一根线索", text: $searchTerm)
                    .focused($searchFocused)
                    .font(.system(size: 15)).foregroundStyle(Loom.ink)
                    .submitLabel(.search)
                    .accessibilityIdentifier("collection-search")
                if !searchTerm.isEmpty {
                    Button { searchTerm = "" } label: {
                        Image(systemName: "xmark").font(.system(size: 12))
                            .foregroundStyle(Loom.secondary).frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(StudioPressStyle()).accessibilityLabel("清除搜索")
                }
            }
            .frame(minHeight: 48)
            .overlay(alignment: .bottom) { Rectangle().fill(Loom.ink).frame(height: 0.75) }

            HStack(spacing: 10) {
                ForEach([ClipFilter.all, .text, .voice, .link]) { filter in
                    Button {
                        withAnimation(reduceMotion ? nil : Studio.spring) { selectedFilter = filter }
                    } label: {
                        Text(filter == .voice ? "声音" : filter.label)
                            .font(.system(size: 13, weight: selectedFilter == filter ? .semibold : .regular))
                            .foregroundStyle(selectedFilter == filter ? Loom.ink : Loom.secondary)
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottomLeading) {
                                if selectedFilter == filter { Rectangle().fill(Loom.ink).frame(width: 26, height: 1.6) }
                            }
                    }
                    .buttonStyle(StudioPressStyle())
                    .accessibilityIdentifier("collection-filter-\(filter.rawValue)")
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
                Spacer(minLength: 0)
                Menu {
                    Button {
                        withAnimation(reduceMotion ? nil : Studio.spring) { selectedTag = nil }
                    } label: { Label("全部标签", systemImage: selectedTag == nil ? "checkmark" : "number") }
                    ForEach(allTags, id: \.self) { tag in
                        Button {
                            withAnimation(reduceMotion ? nil : Studio.spring) { selectedTag = tag }
                        } label: {
                            if selectedTag == tag { Label(tag, systemImage: "checkmark") } else { Text(tag) }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("标签")
                        Image(systemName: selectedTag == nil ? "chevron.down" : "line.3.horizontal.decrease")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .font(.system(size: 12, weight: selectedTag == nil ? .regular : .semibold))
                    .foregroundStyle(selectedTag == nil ? Loom.secondary : Loom.cobalt)
                    .frame(minWidth: 48, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .disabled(allTags.isEmpty)
                .accessibilityLabel(selectedTag.map { "筛选标签：\($0)" } ?? "筛选标签")
            }
            if let selectedTag {
                Button {
                    withAnimation(reduceMotion ? nil : Studio.spring) { self.selectedTag = nil }
                } label: {
                    HStack(spacing: 9) {
                        Text("# \(selectedTag)").lineLimit(1)
                        Image(systemName: "xmark").font(.system(size: 9))
                    }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Loom.cobalt)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("清除标签筛选：\(selectedTag)")
            }
        }
    }

    private var timeline: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            if items.isEmpty {
                emptyCollection
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index == 0 || !Calendar.current.isDate(item.dateAdded, inSameDayAs: items[index - 1].dateAdded) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(sectionTitle(item.dateAdded))
                            .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1)
                        Spacer()
                        Text("\(items.filter { Calendar.current.isDate($0.dateAdded, inSameDayAs: item.dateAdded) }.count) 条线索")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                    }
                    .foregroundStyle(Loom.secondary).padding(.top, index == 0 ? 1 : 12).padding(.bottom, 1)
                }
                CollectionCard(item: item, index: index + 1, playback: playback, onOpen: {
                    searchFocused = false
                    playback.stopPlayback()
                    selectedItem = item
                }, onDelete: { itemToDelete = item })
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 12)
            }
            if !items.isEmpty {
                Text("\(items.count) 根线索，已经收好。")
                    .font(.system(size: 11)).foregroundStyle(Loom.secondary)
                    .frame(maxWidth: .infinity).padding(.top, 16)
            }
        }
    }

    private var emptyCollection: some View {
        let filtering = !searchTerm.isEmpty || selectedFilter != .all || selectedTag != nil
        return VStack(alignment: .leading, spacing: 19) {
            MaterialThreadTexture(color: Loom.ink.opacity(0.25))
                .frame(height: 34).padding(.bottom, 6)
            Text(filtering ? "没有找到这根线索。" : "让这一刻，留一根线。")
                .font(.system(size: 23, weight: .medium)).foregroundStyle(Loom.ink)
            Text(filtering ? "换个关键词，或清除类型与标签筛选。" : "不必完整，先拾起一个念头。")
                .font(.system(size: 13)).foregroundStyle(Loom.secondary)
            if filtering {
                Button {
                    searchTerm = ""; selectedTag = nil; selectedFilter = .all
                } label: {
                    Text("清除筛选")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Loom.cobalt)
                        .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
            } else {
                HStack(spacing: 22) {
                    captureButton("写下来", symbol: "pencil", kind: .text)
                    captureButton("录一段", symbol: "mic", kind: .voice)
                    captureButton("留链接", symbol: "link", kind: .link)
                }
            }
        }
        .padding(.vertical, 32).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func captureButton(_ title: String, symbol: String, kind: ComposerKind) -> some View {
        Button {
            searchFocused = false
            playback.stopPlayback()
            activeComposer = kind
        } label: {
            Label(title, systemImage: symbol).font(.system(size: 12, weight: .medium))
                .foregroundStyle(Loom.ink).frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(StudioPressStyle())
    }

    private func consumeComposer() {
        guard appModel.currentTab == .clips, let kind = appModel.consumePendingComposer() else { return }
        searchFocused = false
        playback.stopPlayback()
        activeComposer = kind
    }

    private func sectionTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "今天 · TODAY" }
        if Calendar.current.isDateInYesterday(date) { return "昨天 · YESTERDAY" }
        return date.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
    }
}

enum MaterialSampleKind {
    case text, voice, link
}

/// A shared, passive material backdrop. Content and hit targets stay in SwiftUI.
struct MaterialSampleSurface: View {
    let kind: MaterialSampleKind

    private var fill: Color {
        switch kind {
        case .text: Loom.acid
        case .voice: Loom.cobalt
        case .link: Color(hex: 0xFBFBF2)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                MaterialPaperShape(kind: kind).fill(fill, style: FillStyle(eoFill: true))
                if kind == .text {
                    Path { path in
                        path.move(to: CGPoint(x: 36, y: 0))
                        path.addLine(to: CGPoint(x: 36, y: geometry.size.height))
                    }
                    .stroke(Loom.ink.opacity(0.17), style: StrokeStyle(lineWidth: 0.65, dash: [1.5, 3]))
                } else if kind == .link {
                    MaterialPaperShape(kind: kind).stroke(Loom.hairline, lineWidth: 0.75)
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width - 25, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width - 25, y: 25))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 25))
                        path.closeSubpath()
                    }.fill(Color(hex: 0xDDDECF))
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MaterialPaperShape: Shape {
    let kind: MaterialSampleKind
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if kind == .link {
            let fold = min(25, min(rect.width, rect.height) / 3)
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.addRect(rect)
            if kind == .text {
                for y in stride(from: rect.minY + 13, to: rect.maxY - 3, by: 23) {
                    path.addEllipse(in: CGRect(x: rect.minX - 3, y: y - 3, width: 6, height: 6))
                    path.addEllipse(in: CGRect(x: rect.maxX - 3, y: y - 3, width: 6, height: 6))
                }
            } else {
                for x in stride(from: rect.minX + 9, to: rect.maxX - 6, by: 15) {
                    path.addRect(CGRect(x: x, y: rect.minY, width: 6, height: 4))
                    path.addRect(CGRect(x: x, y: rect.maxY - 4, width: 6, height: 4))
                }
            }
        }
        return path
    }
}

/// Equal-height etched threads are a material texture, never a sampled waveform.
private struct MaterialThreadTexture: View {
    let color: Color
    var body: some View {
        Canvas { context, size in
            var warp = Path()
            for x in stride(from: CGFloat(1), through: size.width, by: 4) {
                warp.move(to: CGPoint(x: x, y: 1))
                warp.addLine(to: CGPoint(x: x, y: size.height - 1))
            }
            context.stroke(warp, with: .color(color), lineWidth: 0.65)
            var weft = Path()
            for y in stride(from: CGFloat(3), through: size.height, by: 4) {
                weft.move(to: CGPoint(x: 0, y: y))
                weft.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(weft, with: .color(color.opacity(0.55)), lineWidth: 0.45)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct CollectionCard: View {
    @EnvironmentObject private var appModel: AppModel
    let item: LibraryItem
    let index: Int
    @ObservedObject var playback: IdeaAudioController
    let onOpen: () -> Void
    let onDelete: () -> Void

    private var material: MaterialSampleKind {
        switch item {
        case .clip: .link
        case .diary(let diary): diary.type == .voice ? .voice : .text
        }
    }
    private var ink: Color { material == .voice ? Loom.paper : Loom.ink }
    private var secondary: Color { ink.opacity(material == .voice ? 0.8 : 0.65) }
    private var label: String {
        switch material {
        case .link: "链接"
        case .voice: "声音"
        case .text: "文字"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", index))
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).frame(width: 22, alignment: .leading)
                Text("\(label) / \(item.dateAdded.formatted(.dateTime.hour().minute()))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(0.4)
                Spacer(minLength: 0)
                Menu {
                    Button("查看与编辑", systemImage: "pencil", action: onOpen)
                    Button("删除收藏", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 16))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("\(label)收藏操作")
            }.foregroundStyle(secondary)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 9) {
                    switch item {
                    case .clip(let clip):
                        Text(clip.title).font(.system(size: 18, weight: .semibold)).foregroundStyle(ink).lineLimit(2)
                        if !clip.excerpt.isEmpty {
                            Text(clip.excerpt).font(.system(size: 13)).foregroundStyle(secondary).lineSpacing(4).lineLimit(3)
                        }
                        Text(collectionWebURL(clip.url)?.host() ?? "网页")
                            .font(.system(size: 10)).foregroundStyle(secondary).lineLimit(1)
                    case .diary(let diary):
                        Text(diary.content.isEmpty ? "一段此刻的声音" : diary.content)
                            .font(.system(size: material == .voice ? 17 : 19, weight: .medium))
                            .foregroundStyle(ink).lineSpacing(5).lineLimit(material == .voice ? 3 : 5)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(StudioPressStyle())
            .padding(.leading, 34)
            .padding(.bottom, 8)

            if case .diary(let diary) = item, diary.type == .voice {
                if let url = appModel.audioURL(for: diary.audioFileName), FileManager.default.fileExists(atPath: url.path) {
                    RecordingPlaybackRow(url: url, duration: diary.duration, audio: playback, onTape: true)
                        .padding(.vertical, 5)
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "text.bubble").font(.system(size: 14)).frame(width: 22)
                        Text("仅文字备忘").font(.system(size: 11))
                        MaterialThreadTexture(color: ink.opacity(0.25)).frame(height: 16)
                    }
                    .foregroundStyle(secondary).padding(.vertical, 7)
                }
            }

            HStack(spacing: 8) {
                Text(item.tags.prefix(3).map { "# \($0)" }.joined(separator: "   "))
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(secondary).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if case .clip(let clip) = item, let url = collectionWebURL(clip.url) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right").font(.system(size: 17, weight: .light))
                            .foregroundStyle(ink).frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("打开原网页：\(clip.title)")
                }
            }
            .padding(.leading, 34)
            .frame(minHeight: material == .link ? 32 : 24)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(MaterialSampleSurface(kind: material))
    }
}

private struct RecordingPlaybackRow: View {
    let url: URL
    let duration: Int?
    @ObservedObject var audio: IdeaAudioController
    var onTape = false
    private var active: Bool { audio.playbackURL == url }
    private var playing: Bool { active && audio.isPlaying }
    private var elapsed: Double { active ? audio.playbackTime : 0 }
    private var total: Double { active ? audio.playbackDuration : Double(duration ?? 0) }
    private var ink: Color { onTape ? Loom.paper : Loom.ink }

    var body: some View {
        HStack(spacing: 12) {
            Button { audio.togglePlayback(url: url) } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
                    .frame(width: 44, height: 44)
                    .overlay { Circle().stroke(ink.opacity(0.75), lineWidth: 0.75).padding(4) }
                    .contentShape(Rectangle())
            }.buttonStyle(StudioPressStyle()).accessibilityLabel(playing ? "暂停录音播放" : "播放录音")
            VStack(spacing: 5) {
                MaterialThreadTexture(color: ink.opacity(0.6)).frame(height: 22)
                ProgressView(value: elapsed, total: max(1, total)).tint(ink.opacity(0.8))
                    .accessibilityLabel("播放进度")
            }
            Text(recordingClock(active ? max(0, total - elapsed) : total))
                .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(ink.opacity(0.8))
                .monospacedDigit()
        }
    }
}

/// The shared composer, used by the collection and the global quick-add sheet.
struct RecordComposerSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    let kind: ComposerKind
    private let existingItem: LibraryItem?
    @StateObject private var audio = IdeaAudioController()
    @StateObject private var editorState: RichEditorState
    @State private var note: String
    @State private var linkURL: String
    @State private var linkTitle: String
    @State private var linkExcerpt: String
    @State private var tagsText: String
    @State private var mood: DiaryMood
    @State private var loadedRichText = false
    @State private var discardConfirmation = false

    init(kind: ComposerKind, existingItem: LibraryItem? = nil) {
        self.kind = kind
        self.existingItem = existingItem
        var initialNote = "", initialURL = "", initialTitle = "", initialExcerpt = ""
        var initialTags: [String] = []
        var initialMood: DiaryMood = .inspired
        if case .diary(let diary) = existingItem {
            initialNote = diary.content
            initialTags = diary.tags
            initialMood = diary.mood ?? .inspired
        } else if case .clip(let clip) = existingItem {
            initialURL = clip.url
            initialTitle = clip.title
            initialExcerpt = clip.excerpt
            initialTags = clip.tags
        }
        _editorState = StateObject(wrappedValue: RichEditorState(input: initialNote))
        _note = State(initialValue: initialNote)
        _linkURL = State(initialValue: initialURL)
        _linkTitle = State(initialValue: initialTitle)
        _linkExcerpt = State(initialValue: initialExcerpt)
        _tagsText = State(initialValue: initialTags.joined(separator: "，"))
        _mood = State(initialValue: initialMood)
    }

    private var sheetTitle: String {
        switch kind {
        case .text: existingItem == nil ? "把念头，留在纸上。" : "把这一页，展开。"
        case .voice: existingItem == nil ? "把此刻，录成一段。" : "抽出这一段声音。"
        case .link: existingItem == nil ? "给远处，留一根线。" : "沿着链接，再看看。"
        }
    }
    private var subtitle: String {
        switch kind {
        case .text: "不必完整，片刻的念头也值得记下。"
        case .voice: "按下录音，让想法自然流动。"
        case .link: "把喜欢的网页，收进这本材料样本册。"
        }
    }
    private var canSave: Bool {
        switch kind {
        case .text: !editorState.attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .link: !linkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && collectionWebURL(linkURL) != nil
        case .voice: existingItem != nil ? !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || existingRecordingURL != nil : audio.phase == .ready && audio.duration > 0
        }
    }
    private var existingRecordingURL: URL? {
        guard case .diary(let diary) = existingItem,
              let url = appModel.audioURL(for: diary.audioFileName),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    StudioSheetHeader(title: sheetTitle, subtitle: subtitle)
                    switch kind {
                    case .text: textEditor
                    case .voice: voiceEditor
                    case .link: linkEditor
                    }
                    metadataEditor
                }.padding(24).padding(.top, 4)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Studio.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                StudioPrimaryButton(title: existingItem == nil ? "收进样本册" : "保存修改", disabled: !canSave, action: save)
                    .accessibilityIdentifier("composer-save")
                    .padding(.horizontal, 24).padding(.vertical, 14).background(Studio.background)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(kind == .text ? "01 / PAPER" : kind == .voice ? "02 / MAGNETIC TAPE" : "03 / LINKED SHEET")
                        .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.7).foregroundStyle(Loom.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if audio.phase != .idle { discardConfirmation = true } else { dismiss() }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Loom.ink).frame(width: 44, height: 44)
                    }.accessibilityLabel("关闭编辑器")
                }
            }
            .toolbarBackground(Studio.background, for: .navigationBar)
        }
        .tint(Studio.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(Studio.background)
        .interactiveDismissDisabled(audio.phase != .idle)
        .confirmationDialog("放弃这段未保存的录音？", isPresented: $discardConfirmation, titleVisibility: .visible) {
            Button("放弃录音", role: .destructive) { audio.cancelRecording(); dismiss() }
            Button("继续编辑", role: .cancel) { }
        }
        .alert("录音提示", isPresented: Binding(get: { audio.errorMessage != nil }, set: { if !$0 { audio.errorMessage = nil } })) {
            Button("知道了", role: .cancel) { audio.errorMessage = nil }
            if audio.phase == .idle {
                Button("打开设置") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
            }
        } message: { Text(audio.errorMessage ?? "") }
        .onChange(of: scenePhase) { _, phase in if phase == .background { audio.suspend() } }
        .onDisappear { audio.cancelRecording() }
    }

    private var textEditor: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                RichTextEditor(context: .init(wrappedValue: editorState), format: .rtf) { view in
                    if let textView = view as? UITextView {
                        textView.backgroundColor = .clear
                        textView.textColor = UIColor(Studio.ink)
                        textView.tintColor = UIColor(Studio.accent)
                        textView.textContainerInset = UIEdgeInsets(top: 20, left: 39, bottom: 20, right: 14)
                        textView.accessibilityIdentifier = "composer-text"
                    }
                }
                .frame(height: 230)
                .onAppear {
                    guard !loadedRichText else { return }
                    loadedRichText = true
                    if case .diary(let diary) = existingItem, let data = diary.richTextData,
                       let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                        editorState.setAttributedString(to: attributed)
                    }
                }
                if editorState.attributedString.string.isEmpty {
                    Text("今天，有什么想记住的？")
                        .font(.system(size: 17)).foregroundStyle(Studio.secondary.opacity(0.7))
                        .padding(.leading, 44).padding(.trailing, 18).padding(.top, 20).allowsHitTesting(false)
                }
            }.background(MaterialSampleSurface(kind: .text))
            RichTextKeyboardToolbar(context: editorState, leadingButtons: { $0 }, trailingButtons: { $0 }, formatSheet: { $0 })
                .overlay(alignment: .bottom) { Rectangle().fill(Loom.hairline).frame(height: 0.75) }
        }
    }

    private var voiceEditor: some View {
        VStack(spacing: 20) {
            if existingItem != nil {
                if let url = existingRecordingURL {
                    RecordingPlaybackRow(url: url, duration: existingDiaryDuration, audio: audio, onTape: true)
                        .padding(20).background(MaterialSampleSurface(kind: .voice))
                } else {
                    Label("这条收藏仅含文字备忘，没有录音文件。", systemImage: "text.bubble")
                        .font(.system(size: 13)).foregroundStyle(Loom.paper.opacity(0.8))
                        .padding(24).frame(maxWidth: .infinity).background(MaterialSampleSurface(kind: .voice))
                }
            } else {
                VStack(spacing: 21) {
                    RecordingMeter(samples: audio.samples, isRecording: audio.phase == .recording)
                    Text(recordingClock(audio.duration)).font(.system(size: 36, weight: .light, design: .monospaced))
                        .foregroundStyle(Loom.paper).contentTransition(.numericText())
                    Text(recordingStatus).font(.system(size: 12)).foregroundStyle(Loom.paper.opacity(0.8))
                    recordingControls
                }.padding(26).frame(maxWidth: .infinity).background(MaterialSampleSurface(kind: .voice))
            }
            labeledField("随手记", hint: "为这段声音写一点备注…", text: $note, multiline: true)
        }
    }

    private var existingDiaryDuration: Int? {
        if case .diary(let diary) = existingItem { return diary.duration }
        return nil
    }
    private var recordingStatus: String {
        switch audio.phase {
        case .idle: "轻触麦克风，开始记录"
        case .requestingPermission: "正在等待麦克风权限"
        case .recording: "正在录音 · 让想法自然流动"
        case .paused: "已暂停，随时可以继续"
        case .ready: "录音已完成，听听这段记忆"
        }
    }

    @ViewBuilder private var recordingControls: some View {
        switch audio.phase {
        case .idle, .requestingPermission:
            Button { Task { await audio.beginRecording() } } label: {
                ZStack {
                    Circle().fill(Loom.paper).frame(width: 64, height: 64)
                    if audio.phase == .requestingPermission { ProgressView().tint(Loom.cobalt) }
                    else { Image(systemName: "mic.fill").font(.system(size: 24)).foregroundStyle(Loom.ink) }
                }
            }.buttonStyle(StudioPressStyle()).disabled(audio.phase == .requestingPermission)
                .accessibilityLabel("开始录音").accessibilityIdentifier("recording-start")
        case .recording, .paused:
            HStack(spacing: 26) {
                recordingButton(audio.phase == .recording ? "pause.fill" : "mic.fill", label: audio.phase == .recording ? "暂停" : "继续") { audio.togglePause() }
                recordingButton("stop.fill", label: "完成") { audio.finishRecording() }
            }
        case .ready:
            HStack(spacing: 26) {
                recordingButton("arrow.counterclockwise", label: "重新录制") { audio.cancelRecording() }
                recordingButton(audio.isPlaying ? "pause.fill" : "play.fill", label: audio.isPlaying ? "暂停试听" : "试听") { audio.previewRecording() }
            }
        }
    }

    private func recordingButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(Loom.ink)
                    .frame(width: 52, height: 52).background(Loom.paper, in: Circle())
                Text(label).font(.system(size: 11)).foregroundStyle(Loom.paper.opacity(0.85))
            }
        }.buttonStyle(StudioPressStyle()).accessibilityLabel(label)
    }

    private var linkEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            labeledField("网页地址", hint: "https://…", text: $linkURL, isURL: true)
            if !linkURL.isEmpty && collectionWebURL(linkURL) == nil {
                Text("请输入有效的 http 或 https 网页地址。")
                    .font(.system(size: 12)).foregroundStyle(.red)
            }
            if existingItem != nil, let url = collectionWebURL(linkURL) {
                Link(destination: url) {
                    Label("打开原网页", systemImage: "arrow.up.right")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Studio.accent)
                        .frame(minHeight: 44).contentShape(Rectangle())
                }
            }
            labeledField("标题", hint: "它为什么吸引了你？", text: $linkTitle)
            labeledField("一句备注", hint: "记下值得收藏的理由…", text: $linkExcerpt, multiline: true)
        }
        .padding(20)
        .background(MaterialSampleSurface(kind: .link))
    }

    private var metadataEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            labeledField("标签", hint: "用逗号分隔，例如：灵感，生活", text: $tagsText)
            if kind != .link {
                VStack(alignment: .leading, spacing: 12) {
                    Text("此刻心情").font(.system(size: 12, weight: .medium)).foregroundStyle(Studio.secondary)
                    HStack(spacing: 12) {
                        ForEach(DiaryMood.allCases, id: \.self) { item in
                            Button { mood = item } label: {
                                Text(item.emoji).font(.system(size: 23))
                                    .frame(width: 44, height: 44)
                                    .background(mood == item ? Loom.acid.opacity(0.7) : .clear)
                                    .overlay(alignment: .bottom) {
                                        if mood == item { Rectangle().fill(Loom.ink).frame(height: 1.5) }
                                    }
                            }.buttonStyle(StudioPressStyle()).accessibilityLabel(moodName(item))
                                .accessibilityAddTraits(mood == item ? .isSelected : [])
                        }
                    }
                }
            }
        }
    }

    private func labeledField(_ label: String, hint: String, text: Binding<String>, multiline: Bool = false, isURL: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Studio.secondary)
            TextField(hint, text: text, axis: multiline ? .vertical : .horizontal)
                .font(.system(size: 15)).foregroundStyle(Studio.ink)
                .lineLimit(multiline ? 4...7 : 1...1)
                .keyboardType(isURL ? .URL : .default)
                .textInputAutocapitalization(isURL ? .never : .sentences)
                .autocorrectionDisabled(isURL)
                .padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(Loom.hairline).frame(height: 0.75) }
        }
    }

    private func moodName(_ mood: DiaryMood) -> String {
        switch mood {
        case .happy: "开心"
        case .excited: "兴奋"
        case .satisfied: "满足"
        case .inspired: "有灵感"
        case .relaxed: "放松"
        }
    }

    private func save() {
        guard canSave else { return }
        let tags = tagsText.components(separatedBy: CharacterSet(charactersIn: ",，、\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        switch kind {
        case .text:
            editorState.stopEditingText()
            let text = editorState.attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let data = try? StandardRichTextExportService().getDataFor(editorState.attributedString, format: .rtf)
            if case .diary(let diary) = existingItem {
                appModel.updateDiary(diary.id, content: text, richTextData: data, tags: tags, mood: mood)
            } else {
                appModel.addDiary(type: .text, content: text, richTextData: data, tags: tags, mood: mood)
            }
        case .link:
            guard let url = collectionWebURL(linkURL) else { return }
            if case .clip(let clip) = existingItem {
                appModel.updateClip(clip.id, title: linkTitle, url: url.absoluteString, excerpt: linkExcerpt, tags: tags)
            } else {
                appModel.addClip(title: linkTitle, url: url.absoluteString, excerpt: linkExcerpt, tags: tags)
            }
        case .voice:
            let content = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if case .diary(let diary) = existingItem {
                appModel.updateDiary(diary.id, content: content, tags: tags, mood: mood)
            } else {
                guard let saved = audio.saveRecording(to: appModel.recordingDirectoryURL) else { return }
                appModel.addDiary(type: .voice, content: content.isEmpty ? "一段此刻的声音" : content,
                                  duration: saved.duration, audioFileName: saved.fileName, tags: tags, mood: mood)
            }
        }
        dismiss()
    }
}

struct LibraryDetailSheet: View {
    let item: LibraryItem
    var body: some View {
        switch item {
        case .clip: RecordComposerSheet(kind: .link, existingItem: item)
        case .diary(let diary): RecordComposerSheet(kind: diary.type == .voice ? .voice : .text, existingItem: item)
        }
    }
}

private struct RecordingMeter: View {
    let samples: [CGFloat]
    let isRecording: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<44, id: \.self) { index in
                    let sourceIndex = index - (44 - samples.count)
                    let level = sourceIndex >= 0 && sourceIndex < samples.count ? samples[sourceIndex] : 0
                    Capsule().fill(Loom.paper.opacity(isRecording ? 0.85 : 0.4))
                        .frame(width: max(1, (geometry.size.width - 43 * 3) / 44), height: 3 + level * 49)
                }
            }.frame(height: 60)
                .animation(reduceMotion ? nil : .linear(duration: 0.08), value: samples)
        }
        .frame(height: 60)
        .accessibilityLabel(isRecording ? "实时麦克风音量" : samples.isEmpty ? "尚未录音" : "已录制的声音波形")
    }
}

private func recordingClock(_ seconds: TimeInterval) -> String {
    let value = max(0, Int(seconds))
    return String(format: "%02d:%02d", value / 60, value % 60)
}

/// Only http(s) pages can leave the app; bare domains are normalized to HTTPS.
private func collectionWebURL(_ input: String) -> URL? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }
    let candidate = trimmed.contains(":") ? trimmed : "https://\(trimmed)"
    guard let components = URLComponents(string: candidate),
          let scheme = components.scheme?.lowercased(), ["https", "http"].contains(scheme),
          let host = components.host, !host.isEmpty, host.contains("."),
          let url = components.url else { return nil }
    return url
}
