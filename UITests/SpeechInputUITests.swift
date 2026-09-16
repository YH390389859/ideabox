import XCTest

/// Integration fixtures deliver synthetic recognition callbacks to the production
/// draft and cancellation UI. They use no microphone, speech service, or API key.
@MainActor
final class SpeechInputUITests: XCTestCase {
    private var app: XCUIApplication!
    private let transcript = "傍晚走过河边，风很轻。想把这个瞬间记下来。"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSpeechPreviewRevisesDraftAndSupportsCancelFinishAndManualCapture() throws {
        launch("speech")
        defer { app.terminate() }

        let original = "A thought worth keeping."
        input.tap()
        input.typeText(original)
        let microphone = app.buttons["agent-speech-input"]
        XCTAssertTrue(microphone.isEnabled,
                      "Speech input must be available even with an empty DeepSeek key store.")
        microphone.tap()
        XCTAssertTrue(speechControls.waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["agent-send"].isEnabled,
                       "Listening must not send an unfinished transcript to the model.")
        XCTAssertFalse(input.isEnabled)
        assertDraft(original + "\n" + transcript)
        captureFixture("speech-listening")

        app.buttons["agent-speech-cancel"].tap()
        assertAbsent(speechControls)
        assertDraft(original)
        XCTAssertTrue(input.isEnabled,
                      "Canceling speech must restore the original editable draft.")

        microphone.tap()
        XCTAssertTrue(speechControls.waitForExistence(timeout: 6))
        assertDraft(original + "\n" + transcript)
        app.buttons["agent-speech-finish"].tap()
        assertAbsent(speechControls)
        assertDraft(original + "\n" + transcript)
        XCTAssertTrue(input.isEnabled)
        XCTAssertTrue(app.buttons["agent-send"].isEnabled)
        XCTAssertFalse(app.buttons["agent-save-connection"].exists,
                       "Finishing recognition must leave text for review without sending or opening API settings.")
        captureFixture("speech-draft")

        input.tap()
        input.typeText(" Edited.")
        let editedDraft = input.value as? String ?? ""
        XCTAssertTrue(editedDraft.contains("Edited."),
                      "Recognized text must remain editable with the normal keyboard.")
        XCTAssertEqual(editedDraft.replacingOccurrences(of: " Edited.", with: ""),
                       original + "\n" + transcript,
                       "Keyboard editing must preserve the original text and the recognized transcript.")

        microphone.tap()
        XCTAssertTrue(speechControls.waitForExistence(timeout: 6))
        let preservedDraft = editedDraft + "\n" + transcript
        assertDraft(preservedDraft)
        app.buttons["agent-manual-capture"].tap()
        let manualPicker = app.descendants(matching: .any)
            .matching(identifier: "manual-capture-picker").firstMatch
        XCTAssertTrue(manualPicker.waitForExistence(timeout: 6))
        app.buttons["返回对话"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        assertAbsent(speechControls)
        assertDraft(preservedDraft)
        XCTAssertTrue(input.isEnabled)
        XCTAssertTrue(app.buttons["agent-send"].isEnabled,
                      "Leaving speech for manual capture must stop recognition and keep the heard text.")
    }

    func testSpeechPermissionPreviewPreservesDraftAndAllowsKeyboardFallback() throws {
        launch("speech-error")
        defer { app.terminate() }

        let original = "Keep this draft if permission is denied."
        input.tap()
        input.typeText(original)
        app.buttons["agent-speech-input"].tap()

        let error = app.descendants(matching: .any)
            .matching(identifier: "agent-speech-error").firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["agent-speech-open-settings"].isHittable,
                      "A permission failure must offer a route to the system's permission settings.")
        XCTAssertTrue(app.buttons["agent-speech-dismiss-error"].isHittable)
        assertAbsent(speechControls)
        assertDraft(original)
        XCTAssertTrue(input.isEnabled)
        captureFixture("speech-error")

        // Retry with the existing error still present. The next denial has the
        // same message and final phase, but must still release its draft snapshot.
        app.buttons["agent-speech-input"].tap()
        XCTAssertTrue(error.waitForExistence(timeout: 6))
        assertAbsent(speechControls)
        assertDraft(original)
        input.tap()
        input.typeText(" Continue typing.")
        let editedDraft = input.value as? String ?? ""
        XCTAssertTrue(editedDraft.contains("Continue typing."),
                      "Declining speech permissions must not prevent ordinary text entry.")
        XCTAssertEqual(editedDraft.replacingOccurrences(of: " Continue typing.", with: ""), original)
        XCTAssertTrue(app.buttons["agent-send"].isEnabled)
        XCTAssertFalse(app.buttons["agent-save-connection"].exists)

        app.buttons["agent-manual-capture"].tap()
        let manualPicker = app.descendants(matching: .any)
            .matching(identifier: "manual-capture-picker").firstMatch
        XCTAssertTrue(manualPicker.waitForExistence(timeout: 6))
        app.buttons["返回对话"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        assertDraft(editedDraft)

        app.buttons["agent-speech-dismiss-error"].tap()
        assertAbsent(error)
        assertDraft(editedDraft)
        app.buttons["返回日常织机"].tap()
        XCTAssertTrue(app.buttons["open-agent"].waitForExistence(timeout: 6))
        app.buttons["open-agent"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        assertDraft(editedDraft)
    }

    private var input: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
    }

    private var speechControls: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "agent-speech-controls").firstMatch
    }

    private func launch(_ fixture: String) {
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchEnvironment["IDEABOX_AGENT_PREVIEW"] = fixture
        app.launch()
        XCTAssertTrue(app.buttons["agent-speech-input"].waitForExistence(timeout: 6))
        XCTAssertTrue(input.waitForExistence(timeout: 6))
    }

    private func assertDraft(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected), object: input
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 6), .completed,
                       "Revised recognition results must replace the current transcript once and preserve the original draft.",
                       file: file, line: line)
    }

    private func assertAbsent(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 6), .completed,
                       "The speech overlay should close after finishing, canceling, or dismissing the error.",
                       file: file, line: line)
    }

    private func captureFixture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(name)-synthetic-recognition-fixture"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let description = XCTAttachment(string: "Synthetic speech UI fixture: no microphone audio was captured and no actual speech recognition service was called.")
        description.name = "\(name)-fixture-description"
        description.lifetime = .keepAlways
        add(description)
    }
}
