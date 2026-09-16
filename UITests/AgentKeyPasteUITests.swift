import XCTest
import UIKit

/// Run only on a disposable simulator: this test writes and clears its pasteboard.
/// Preview mode uses an empty in-memory key store; neither connection action is invoked.
@MainActor
final class AgentKeyPasteUITests: XCTestCase {
    func testStandardKeyFieldSupportsTypingAndSystemPaste() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == "IdeaBox Key Paste Verification",
                          "Use the disposable IdeaBox Key Paste Verification simulator for clipboard fixtures.")
        continueAfterFailure = false
        let app = XCUIApplication()
        defer {
            app.terminate()
            UIPasteboard.general.items = []
        }

        let typedKey = "sk-ideabox-ui-test-typed-not-a-real-key"
        let pastedKey = "sk-ideabox-ui-test-pasted-not-a-real-key"
        writeFixture(pastedKey)

        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchEnvironment["IDEABOX_AGENT_PREVIEW"] = "welcome"
        app.launch()

        let settings = app.buttons["agent-settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 6))
        settings.tap()

        let save = app.buttons["agent-save-connection"]
        XCTAssertTrue(save.waitForExistence(timeout: 6))
        XCTAssertFalse(save.isEnabled, "An empty key must not enable saving.")
        let field = app.textFields["agent-api-key"]
        XCTAssertTrue(field.waitForExistence(timeout: 6),
                      "The key must use a standard, directly editable text field.")
        XCTAssertFalse(app.secureTextFields["agent-api-key"].exists)
        XCTAssertFalse(app.buttons["agent-paste-key"].exists,
                       "The standard edit menu should handle paste without another app button.")

        field.tap()
        field.typeText(typedKey)
        assertVisibleKey(typedKey, in: app)
        waitUntilEnabled(save)

        field.tap()
        field.press(forDuration: 1.1)
        let selectAll = editMenuItem(named: ["全选", "Select All"], in: app)
        XCTAssertTrue(selectAll.waitForExistence(timeout: 6),
                      "The ordinary text field must expose the system Select All action.")
        selectAll.tap()

        let paste = editMenuItem(named: ["粘贴", "Paste"], in: app)
        XCTAssertTrue(paste.waitForExistence(timeout: 6),
                      "The selected text must support the system Paste action.")
        paste.tap()
        assertVisibleKey(pastedKey, in: app)
        XCTAssertTrue(save.isEnabled)
        XCTAssertFalse(app.secureTextFields["agent-api-key"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "normal-api-key-input"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func writeFixture(_ value: String) {
        UIPasteboard.general.setItems(
            [["public.utf8-plain-text": value]],
            options: [.localOnly: true]
        )
    }

    private func waitUntilEnabled(_ element: XCUIElement) {
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 6), .completed)
    }

    private func editMenuItem(named labels: [String], in app: XCUIApplication) -> XCUIElement {
        let label = NSPredicate(format: "label IN %@", labels)
        let menuItem = app.menuItems.matching(label).firstMatch
        if menuItem.waitForExistence(timeout: 1) { return menuItem }
        return app.buttons.matching(label).firstMatch
    }

    private func assertVisibleKey(_ expected: String, in app: XCUIApplication) {
        let field = app.textFields["agent-api-key"]
        XCTAssertTrue(field.waitForExistence(timeout: 6))
        let exactKey = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected),
            object: field
        )
        XCTAssertEqual(XCTWaiter.wait(for: [exactKey], timeout: 6), .completed,
                       "Typing and system paste must preserve the exact text entered into the field.")
        XCTAssertEqual(field.value as? String, expected)
    }
}
