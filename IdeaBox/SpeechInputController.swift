import AVFoundation
import Combine
import Foundation
import OSLog
import Speech
import UIKit

/// Transcribes a single, bounded microphone session. Audio is never written to a file.
@MainActor
final class SpeechInputController: ObservableObject {
    private static let logger = Logger(subsystem: "com.example.IdeaBox", category: "SpeechInput")
    enum Phase: Equatable { case idle, requestingPermission, listening, finishing }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var transcript = ""
    @Published private(set) var audioLevel: Double = 0
    @Published private(set) var usesOnDeviceRecognition = false
    @Published private(set) var requiresSettings = false
    @Published private(set) var completedSessionID: UUID?
    @Published private(set) var recognitionNotice: String?
    @Published var errorMessage: String?

    var isActive: Bool { phase != .idle }
    var isPreview: Bool {
        #if DEBUG
        ["speech", "speech-error"].contains(ProcessInfo.processInfo.environment["IDEABOX_AGENT_PREVIEW"] ?? "")
        #else
        false
        #endif
    }

    private let locale: Locale
    private var currentSessionID: UUID?
    private var recognitionAttemptID: UUID?
    private var didRetryOnSystem = false
    private var recognizer: SFSpeechRecognizer?
    private var session: SpeechRecognitionSession?
    private var permissionTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?
    private var finishingTask: Task<Void, Never>?
    #if DEBUG
    private var previewTask: Task<Void, Never>?
    #endif
    private var subscriptions = Set<AnyCancellable>()

    init(locale: Locale? = nil) {
        self.locale = locale ?? Locale(identifier: Locale.preferredLanguages.first?.hasPrefix("en") == true ? "en-US" : "zh-CN")
        if !isPreview {
            usesOnDeviceRecognition = SFSpeechRecognizer(locale: self.locale)?.supportsOnDeviceRecognition == true
        }
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      type == AVAudioSession.InterruptionType.began.rawValue else { return }
                self?.suspend()
            }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.suspend() }
            .store(in: &subscriptions)
    }

    deinit {
        permissionTask?.cancel()
        durationTask?.cancel()
        finishingTask?.cancel()
        #if DEBUG
        previewTask?.cancel()
        #endif
        session?.cancel()
    }

    func start() {
        guard !isActive else { return }
        let id = UUID()
        currentSessionID = id
        errorMessage = nil
        requiresSettings = false
        recognitionNotice = nil
        didRetryOnSystem = false
        phase = .requestingPermission
        transcript = ""
        audioLevel = 0
        #if DEBUG
        if isPreview {
            beginPreview(id: id)
            return
        }
        #endif
        permissionTask = Task { [weak self] in
            let authorization = await Self.speechAuthorization()
            guard !Task.isCancelled, self?.currentSessionID == id else { return }
            guard authorization == .authorized else {
                self?.requiresSettings = authorization == .denied
                self?.complete(id: id, error: authorization == .restricted
                              ? "这台设备限制了语音识别，你仍可以直接输入文字。"
                              : "请在系统设置中允许 IdeaBox 使用语音识别。")
                return
            }
            let microphoneAllowed = await Self.microphoneAuthorization()
            guard !Task.isCancelled, let self, self.currentSessionID == id else { return }
            guard microphoneAllowed else {
                self.requiresSettings = true
                self.complete(id: id, error: "请在系统设置中允许 IdeaBox 使用麦克风。")
                return
            }
            self.beginCapture(id: id)
        }
    }

    /// Stops the microphone immediately; final punctuation and words may arrive for up to 3 seconds.
    func finish() {
        guard let id = currentSessionID else { return }
        if phase == .requestingPermission {
            cancel()
            return
        }
        guard phase == .listening else { return }
        phase = .finishing
        audioLevel = 0
        durationTask?.cancel()
        durationTask = nil
        session?.finish()
        finishingTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(3)) }
            catch { return }
            guard let self, self.currentSessionID == id else { return }
            self.complete(id: id, error: self.transcript.isEmpty ? "没有听清，点麦克风再试一次。" : nil)
        }
    }

    /// Discards this session, including any pending permission or recognition callbacks.
    func cancel() {
        let cancelledID = currentSessionID
        currentSessionID = nil
        releaseResources()
        phase = .idle
        transcript = ""
        errorMessage = nil
        requiresSettings = false
        if let cancelledID { completedSessionID = cancelledID }
    }

    /// Leaving the foreground keeps words already recognized but never keeps the microphone running.
    func suspend() {
        guard let id = currentSessionID else { return }
        if phase == .requestingPermission { cancel() }
        else { complete(id: id, error: transcript.isEmpty ? "语音输入已中断，可以再试一次。" : nil) }
    }

    private func beginCapture(id: UUID) {
        guard currentSessionID == id, phase == .requestingPermission else { return }
        startRecognition(id: id, requireOnDevice: nil)
        if currentSessionID == id { startDurationLimit(id: id) }
    }

    private func startRecognition(id: UUID, requireOnDevice: Bool?) {
        guard currentSessionID == id else { return }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            complete(id: id, error: "系统语音识别暂时不可用，请稍后重试。")
            return
        }
        self.recognizer = recognizer
        usesOnDeviceRecognition = requireOnDevice ?? recognizer.supportsOnDeviceRecognition
        let attemptID = UUID()
        recognitionAttemptID = attemptID
        Self.logger.notice("Starting speech: locale=\(self.locale.identifier, privacy: .public), onDevice=\(self.usesOnDeviceRecognition)")
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = usesOnDeviceRecognition
        let sink = SpeechAudioSink(request: request) { [weak self] level in
            Task { @MainActor [weak self] in
                guard let self, self.currentSessionID == id, self.recognitionAttemptID == attemptID,
                      self.phase == .listening else { return }
                self.audioLevel = self.audioLevel * 0.3 + level * 0.7
            }
        }
        let session = SpeechRecognitionSession(sink: sink)
        self.session = session
        do {
            IdeaAudioController.stopAllPlayback()
            try session.startAudio()
            session.task = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
                // Speech objects stay on their callback queue; only value snapshots cross to the UI.
                let text = result?.bestTranscription.formattedString
                let final = result?.isFinal == true
                let failure = error.map { SpeechRecognitionFailure(error: $0 as NSError) }
                Task { @MainActor [weak self] in
                    guard self?.recognitionAttemptID == attemptID else { return }
                    self?.receive(text: text, isFinal: final, failure: failure, id: id)
                }
            }
            phase = .listening
        } catch {
            let failure = error as NSError
            Self.logger.error("Audio startup failed: domain=\(failure.domain, privacy: .public), code=\(failure.code)")
            complete(id: id, error: "无法启动麦克风，请确认麦克风可用后重试。")
        }
    }

    private func startDurationLimit(id: UUID) {
        durationTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(60)) }
            catch { return }
            guard let self, self.currentSessionID == id else { return }
            self.finish()
        }
    }

    #if DEBUG
    /// Isolated UI fixtures exercise the production cancellation and draft paths without audio access.
    private func beginPreview(id: UUID) {
        if ProcessInfo.processInfo.environment["IDEABOX_AGENT_PREVIEW"] == "speech-error" {
            requiresSettings = true
            complete(id: id, error: "请在系统设置中允许 IdeaBox 使用语音识别。")
            return
        }
        phase = .listening
        audioLevel = 0.15
        startDurationLimit(id: id)
        previewTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(450)) }
            catch { return }
            guard let self, self.currentSessionID == id, self.phase == .listening else { return }
            self.receive(text: "傍晚走过河边。", isFinal: false, failure: nil, id: id)
            self.audioLevel = 0.38
            do { try await Task.sleep(for: .milliseconds(700)) }
            catch { return }
            guard self.currentSessionID == id, self.phase == .listening else { return }
            self.receive(text: "傍晚走过河边，风很轻。想把这个瞬间记下来。", isFinal: false, failure: nil, id: id)
            self.audioLevel = 0.62
        }
    }
    #endif

    private func receive(text: String?, isFinal: Bool, failure: SpeechRecognitionFailure?, id: UUID) {
        guard currentSessionID == id, phase == .listening || phase == .finishing else { return }
        if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            transcript = text
        }
        if let failure {
            Self.logger.error("Recognition failed: domain=\(failure.domain, privacy: .public), code=\(failure.code), onDevice=\(self.usesOnDeviceRecognition)")
            if SpeechRecognitionRecovery.shouldRetryOnSystem(
                domain: failure.domain, code: failure.code, isOnDevice: usesOnDeviceRecognition,
                isListening: phase == .listening, hasTranscript: !transcript.isEmpty,
                hasRetried: didRetryOnSystem
            ) {
                didRetryOnSystem = true
                // Invalidate callbacks before cancelling; the user session and its time limit stay intact.
                recognitionAttemptID = nil
                session?.cancel()
                session = nil
                recognizer = nil
                audioLevel = 0
                recognitionNotice = "已重新连接语音识别，请再说一遍。"
                startRecognition(id: id, requireOnDevice: false)
                return
            }
            requiresSettings = failure.requiresSettings
            // A service error after partial recognition must not erase usable words.
            let message = transcript.isEmpty ? failure.message : "识别已停止，已保留听到的文字。"
            complete(id: id, error: message)
        } else if isFinal {
            complete(id: id, error: transcript.isEmpty ? "没有听清，点麦克风再试一次。" : nil)
        }
    }

    private func complete(id: UUID, error: String?) {
        guard currentSessionID == id else { return }
        currentSessionID = nil
        releaseResources()
        errorMessage = error
        phase = .idle
        completedSessionID = id
    }

    private func releaseResources() {
        recognitionAttemptID = nil
        recognitionNotice = nil
        permissionTask?.cancel()
        permissionTask = nil
        durationTask?.cancel()
        durationTask = nil
        finishingTask?.cancel()
        finishingTask = nil
        #if DEBUG
        previewTask?.cancel()
        previewTask = nil
        #endif
        session?.cancel()
        session = nil
        recognizer = nil
        audioLevel = 0
    }

    private static func speechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            // TCC invokes this on a background queue; it must not inherit MainActor isolation.
            SFSpeechRecognizer.requestAuthorization { @Sendable status in continuation.resume(returning: status) }
        }
    }

    private static func microphoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { @Sendable allowed in continuation.resume(returning: allowed) }
        }
    }
}

private struct SpeechRecognitionFailure: Sendable {
    let domain: String
    let code: Int
    let message: String
    let requiresSettings: Bool

    init(error: NSError) {
        domain = error.domain
        code = error.code
        requiresSettings = (error.domain == "kAFAssistantErrorDomain" && error.code == 1700)
            || (error.domain == "kLSRErrorDomain" && error.code == 201)
        if requiresSettings {
            message = "请在系统设置中检查语音识别和听写权限。"
        } else if error.domain == "kLSRErrorDomain", [102, 300].contains(error.code) {
            #if targetEnvironment(simulator)
            message = "当前模拟器未能加载语音识别。请在真机上验证，或先直接输入文字。"
            #else
            message = "系统语音识别未能启动，请稍后重试。你仍可以直接输入文字。"
            #endif
        } else if error.domain == "kAFAssistantErrorDomain", error.code == 1110 {
            message = "没有听清，点麦克风再试一次。"
        } else if error.domain == NSURLErrorDomain {
            message = "语音识别连接中断，请检查网络后重试。"
        } else {
            message = "语音识别暂时中断，请再试一次。"
        }
    }
}

/// The audio callback and teardown share only this locked sink, never actor-isolated UI state.
private final class SpeechAudioSink: @unchecked Sendable {
    private let lock = NSLock()
    private let request: SFSpeechAudioBufferRecognitionRequest
    private let levelChanged: @Sendable (Double) -> Void
    private var ended = false
    private var framesSinceMeter = 0

    init(request: SFSpeechAudioBufferRecognitionRequest, levelChanged: @escaping @Sendable (Double) -> Void) {
        self.request = request
        self.levelChanged = levelChanged
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        guard !ended else { lock.unlock(); return }
        request.append(buffer)
        framesSinceMeter += Int(buffer.frameLength)
        var level: Double?
        if framesSinceMeter >= Int(buffer.format.sampleRate / 15), let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 {
            framesSinceMeter = 0
            var sum: Double = 0
            for index in 0..<Int(buffer.frameLength) { sum += Double(samples[index] * samples[index]) }
            let rms = sqrt(sum / Double(buffer.frameLength))
            level = min(1, max(0, (20 * log10(max(rms, 0.000_001)) + 55) / 45))
        }
        lock.unlock()
        if let level { levelChanged(level) }
    }

    func end() {
        lock.lock()
        defer { lock.unlock() }
        guard !ended else { return }
        ended = true
        request.endAudio()
    }
}

/// Accessed only by the main actor; Sendable also permits synchronous cleanup from owner deinit.
/// The tap captures the independently locked sink, never this resource owner.
private final class SpeechRecognitionSession: @unchecked Sendable {
    let engine = AVAudioEngine()
    let sink: SpeechAudioSink
    var task: SFSpeechRecognitionTask?
    private var hasTap = false
    private var ownsAudioSession = false

    init(sink: SpeechAudioSink) { self.sink = sink }

    func startAudio() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [])
        try audioSession.setActive(true)
        ownsAudioSession = true
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { @Sendable [sink] buffer, _ in sink.append(buffer) }
        hasTap = true
        engine.prepare()
        try engine.start()
    }

    func finish() {
        stopAudio()
        task?.finish()
    }

    func cancel() {
        stopAudio()
        task?.cancel()
        task = nil
    }

    private func stopAudio() {
        engine.stop()
        if hasTap {
            engine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
        sink.end()
        if ownsAudioSession {
            ownsAudioSession = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
