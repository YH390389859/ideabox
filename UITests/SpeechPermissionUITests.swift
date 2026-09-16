import UIKit
import XCTest

/// Exercises a real iOS speech-permission denial only on a disposable simulator.
/// The preview library and key store remain isolated; speech itself is not mocked.
@MainActor
final class SpeechPermissionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        #if targetEnvironment(simulator)
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.name
        try XCTSkipUnless(deviceName == "IdeaBox Speech Permission Verification",
                          "Real permission changes are allowed only on the dedicated disposable simulator.")
        #else
        throw XCTSkip("This test must not change permissions on a physical device.")
        #endif
    }

    func testRealSpeechPermissionDenialKeepsDraftAcrossRetriesAndNavigation() throws {
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        // welcome isolates user data without selecting either speech fixture.
        app.launchEnvironment["IDEABOX_AGENT_PREVIEW"] = "welcome"
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["agent-speech-input"].waitForExistence(timeout: 10))

        let original = "Keep this text when speech permission is denied."
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        input.tap()
        input.typeText(original)
        app.buttons["agent-speech-input"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let appAlert = app.alerts.firstMatch
        let systemAlert = springboard.alerts.firstMatch
        let permissionAppeared = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in appAlert.exists || systemAlert.exists },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [permissionAppeared], timeout: 12), .completed,
                       "A fresh disposable simulator must show the real speech authorization prompt.")
        let permission = appAlert.exists ? appAlert : systemAlert
        let promptText = ([permission.label] + permission.staticTexts.allElementsBoundByIndex.map(\.label))
            .joined(separator: " ")
        XCTAssertTrue(promptText.localizedCaseInsensitiveContains("speech")
                      || promptText.contains("语音识别") || promptText.contains("語音辨識"),
                      "The only prompt this test handles is speech recognition authorization.")
        let deny = permission.buttons.matching(NSPredicate(
            format: "label IN %@",
            ["不允许", "不允許", "Don't Allow", "Don’t Allow"] as NSArray
        )).firstMatch
        XCTAssertTrue(deny.waitForExistence(timeout: 6))
        deny.tap()

        let error = app.descendants(matching: .any)
            .matching(identifier: "agent-speech-error").firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["agent-speech-open-settings"].isHittable)
        assertDraft(original)
        XCTAssertFalse(appAlert.exists)
        XCTAssertFalse(systemAlert.exists,
                       "Denying speech recognition must stop before requesting microphone access.")

        for _ in 0..<2 {
            // Keep the existing error visible between identical permission failures.
            app.buttons["agent-speech-input"].tap()
            XCTAssertTrue(error.waitForExistence(timeout: 6))
            XCTAssertTrue(input.isEnabled)
            XCTAssertTrue(app.buttons["agent-speech-open-settings"].isHittable)
            XCTAssertFalse(appAlert.exists)
            XCTAssertFalse(systemAlert.exists)
            assertDraft(original)
        }

        input.tap()
        input.typeText(" Still editable.")
        let editedDraft = input.value as? String ?? ""
        XCTAssertTrue(editedDraft.contains("Still editable."))
        XCTAssertEqual(editedDraft.replacingOccurrences(of: " Still editable.", with: ""), original)
        app.buttons["agent-manual-capture"].tap()
        let manualPicker = app.descendants(matching: .any)
            .matching(identifier: "manual-capture-picker").firstMatch
        XCTAssertTrue(manualPicker.waitForExistence(timeout: 6))
        app.buttons["返回对话"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        assertDraft(editedDraft)
        XCTAssertTrue(input.isEnabled)
        XCTAssertTrue(app.buttons["agent-send"].isEnabled)
        XCTAssertFalse(app.buttons["agent-save-connection"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "speech-permission-real"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let details = XCTAttachment(string: "Real iOS speech-recognition permission was denied on the dedicated disposable simulator. Microphone permission was not requested, no audio was captured, and no speech-recognition or DeepSeek request was made.")
        details.name = "speech-permission-real-description"
        details.lifetime = .keepAlways
        add(details)
    }

    private var input: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
    }

    private func assertDraft(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected), object: input
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 6), .completed,
                       "Permission failures and navigation must preserve all keyboard edits to the draft.",
                       file: file, line: line)
    }
}
