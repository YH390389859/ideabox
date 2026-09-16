import Foundation

/// Allows one system-service attempt when local recognition fails before producing any words.
enum SpeechRecognitionRecovery {
    static func shouldRetryOnSystem(
        domain: String,
        code: Int,
        isOnDevice: Bool,
        isListening: Bool,
        hasTranscript: Bool,
        hasRetried: Bool
    ) -> Bool {
        guard isOnDevice, isListening, !hasTranscript, !hasRetried else { return false }

        switch (domain, code) {
        case ("kLSRErrorDomain", 102), ("kLSRErrorDomain", 300),
             ("kAFAssistantErrorDomain", 1101):
            return true
        default:
            return false
        }
    }
}
