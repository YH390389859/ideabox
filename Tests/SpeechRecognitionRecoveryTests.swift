import Foundation

@main
struct SpeechRecognitionRecoveryTests {
    static func main() {
        let recoverableErrors = [
            ("kLSRErrorDomain", 102),
            ("kLSRErrorDomain", 300),
            ("kAFAssistantErrorDomain", 1101)
        ]

        // Every recoverable failure must still respect cancellation, existing words, and retry limits.
        for (domain, code) in recoverableErrors {
            for isOnDevice in [false, true] {
                for isListening in [false, true] {
                    for hasTranscript in [false, true] {
                        for hasRetried in [false, true] {
                            let actual = SpeechRecognitionRecovery.shouldRetryOnSystem(
                                domain: domain,
                                code: code,
                                isOnDevice: isOnDevice,
                                isListening: isListening,
                                hasTranscript: hasTranscript,
                                hasRetried: hasRetried
                            )
                            let expected = isOnDevice && isListening && !hasTranscript && !hasRetried
                            precondition(actual == expected,
                                         "Recovery must preserve the session boundary for \(domain)/\(code)")
                        }
                    }
                }
            }
        }

        let nonrecoverableErrors = [
            ("kLSRErrorDomain", 201), // Dictation disabled.
            ("kLSRErrorDomain", 301), // Request canceled.
            ("kAFAssistantErrorDomain", 1700), // Authorization denied.
            ("kAFAssistantErrorDomain", 1110), // No speech detected.
            ("kAFAssistantErrorDomain", 1100), // Another request is active.
            ("kAFAssistantErrorDomain", 1107), // Speech process interrupted.
            ("kAFAssistantErrorDomain", 203), // Unclassified recognition failure.
            (NSURLErrorDomain, NSURLErrorNotConnectedToInternet),
            (NSURLErrorDomain, NSURLErrorTimedOut),
            ("kAFAssistantErrorDomain", 102), // Codes never match across domains.
            ("kAFAssistantErrorDomain", 300),
            ("kLSRErrorDomain", 1101),
            ("UnknownSpeechErrorDomain", 300),
            ("", 0)
        ]
        for (domain, code) in nonrecoverableErrors {
            precondition(!SpeechRecognitionRecovery.shouldRetryOnSystem(
                domain: domain,
                code: code,
                isOnDevice: true,
                isListening: true,
                hasTranscript: false,
                hasRetried: false
            ), "Do not restart recording for \(domain)/\(code)")
        }

        print("PASS: 48 local-recovery state combinations and 14 nonrecoverable errors")
    }
}
