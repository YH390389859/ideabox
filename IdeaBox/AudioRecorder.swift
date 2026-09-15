import AVFoundation
import Combine
import Foundation

/// Owns an actual microphone recording or audio player. Unsaved recordings live in tmp.
@MainActor
final class IdeaAudioController: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    enum Phase { case idle, requestingPermission, recording, paused, ready }

    private static weak var activePlaybackController: IdeaAudioController?

    static func stopAllPlayback() {
        activePlaybackController?.stopPlayback()
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var samples: [CGFloat] = []
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var playbackDuration: TimeInterval = 0
    @Published private(set) var playbackURL: URL?
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var temporaryURL: URL?
    private var permissionRequest = UUID()
    private var interruptionSubscription: AnyCancellable?

    override init() {
        super.init()
        interruptionSubscription = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let kind = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      kind == AVAudioSession.InterruptionType.began.rawValue else { return }
                self?.finishRecording()
                self?.stopPlayback()
            }
    }

    func beginRecording() async {
        guard phase == .idle else { return }
        Self.stopAllPlayback()
        errorMessage = nil
        phase = .requestingPermission
        let request = UUID()
        permissionRequest = request
        let allowed = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard request == permissionRequest, phase == .requestingPermission else { return }
        guard allowed else {
            phase = .idle
            errorMessage = "需要麦克风权限才能录音。请在系统设置中允许 IdeaBox 使用麦克风。"
            return
        }
        do {
            Self.stopAllPlayback()
            stopPlayback()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ideabox-\(UUID().uuidString).m4a")
            temporaryURL = url
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord(), recorder.record() else {
                throw CocoaError(.fileWriteUnknown)
            }
            self.recorder = recorder
            samples = []
            duration = 0
            phase = .recording
            startTimer()
        } catch {
            cancelRecording()
            deactivateSession()
            errorMessage = "无法开始录音：\(error.localizedDescription)"
        }
    }

    func togglePause() {
        guard let recorder else { return }
        switch phase {
        case .recording:
            duration = recorder.currentTime
            recorder.pause()
            phase = .paused
        case .paused:
            if recorder.record() { phase = .recording }
            else { errorMessage = "无法继续录音，请保存当前录音后重试。" }
        default: break
        }
    }

    func finishRecording() {
        guard phase == .recording || phase == .paused else { return }
        if let recorder { duration = max(duration, recorder.currentTime) }
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        phase = .ready
        deactivateSession()
    }

    func saveRecording(to directory: URL) -> (fileName: String, duration: Int)? {
        finishRecording()
        stopPlayback()
        guard phase == .ready, let temporaryURL, duration > 0 else { return nil }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = "\(UUID().uuidString).m4a"
            try FileManager.default.moveItem(at: temporaryURL, to: directory.appendingPathComponent(name))
            self.temporaryURL = nil
            phase = .idle
            return (name, max(1, Int(duration.rounded())))
        } catch {
            errorMessage = "录音未能保存，请重试：\(error.localizedDescription)"
            return nil
        }
    }

    func previewRecording() {
        guard phase == .ready, let temporaryURL else { return }
        togglePlayback(url: temporaryURL)
    }

    func togglePlayback(url: URL) {
        errorMessage = nil
        if playbackURL == url, let player {
            if isPlaying {
                player.pause()
                isPlaying = false
                timer?.invalidate()
                timer = nil
                deactivateSession()
            } else {
                do {
                    claimPlayback()
                    try AVAudioSession.sharedInstance().setActive(true)
                    guard player.play() else { throw CocoaError(.fileReadCorruptFile) }
                    isPlaying = true
                    startTimer()
                } catch {
                    stopPlayback()
                    errorMessage = "暂时无法播放：\(error.localizedDescription)"
                }
            }
            return
        }
        stopPlayback()
        do {
            claimPlayback()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            self.player = player
            playbackURL = url
            playbackDuration = player.duration
            playbackTime = 0
            guard player.play() else { throw CocoaError(.fileReadCorruptFile) }
            isPlaying = true
            startTimer()
        } catch {
            stopPlayback()
            errorMessage = "无法播放这段录音：\(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        let ownedPlayback = Self.activePlaybackController === self
        if ownedPlayback { Self.activePlaybackController = nil }
        player?.stop()
        player = nil
        isPlaying = false
        playbackTime = 0
        playbackDuration = 0
        playbackURL = nil
        if phase != .recording && phase != .paused {
            timer?.invalidate()
            timer = nil
            if ownedPlayback { deactivateSession() }
        }
    }

    private func claimPlayback() {
        if let previous = Self.activePlaybackController, previous !== self {
            previous.stopPlayback()
        }
        Self.activePlaybackController = self
    }

    func suspend() {
        permissionRequest = UUID()
        if phase == .requestingPermission { phase = .idle }
        finishRecording()
        stopPlayback()
    }

    func cancelRecording() {
        suspend()
        recorder?.stop()
        recorder = nil
        if let temporaryURL { try? FileManager.default.removeItem(at: temporaryURL) }
        temporaryURL = nil
        samples = []
        duration = 0
        phase = .idle
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        if phase == .recording, let recorder {
            duration = recorder.currentTime
            recorder.updateMeters()
            // These bars are measured input power; silence stays close to the baseline.
            let power = CGFloat(pow(10, recorder.averagePower(forChannel: 0) / 20))
            samples.append(min(1, max(0, power * 3)))
            if samples.count > 44 { samples.removeFirst(samples.count - 44) }
        }
        if let player { playbackTime = player.currentTime }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let completedPlayer = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player,
                  ObjectIdentifier(current) == completedPlayer else { return }
            self.stopPlayback()
            if !flag { self.errorMessage = "录音播放中断，请重试。" }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in
            self?.finishRecording()
            self?.errorMessage = "录音过程中出现问题，请检查当前录音后重试。"
        }
    }
}
