import XCTest

/// These flows use an isolated preview library and an empty in-memory key store.
/// They never enter a key, perform a model request, or alter the user's library.
@MainActor
final class AgentUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMissingKeyOpensSettingsAndKeepsDraft() throws {
        launch("welcome")
        defer { app.terminate() }
        capture("welcome")

        let message = "Today I read for 30 minutes."
        let input = app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        input.tap()
        input.typeText(message)
        let send = app.buttons["agent-send"]
        XCTAssertTrue(send.isEnabled)
        send.tap()

        let save = app.buttons["agent-save-connection"]
        XCTAssertTrue(save.waitForExistence(timeout: 6), "Sending without a key should open connection settings.")
        XCTAssertFalse(save.isEnabled, "An empty key must not be saved or sent.")
        XCTAssertFalse(app.buttons["agent-test-connection"].isEnabled, "An empty key must not trigger a connection test.")
        XCTAssertTrue(app.textFields["agent-api-key"].exists)
        capture("settings")

        app.buttons["返回对话"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 6))
        XCTAssertEqual(input.value as? String, message, "Opening settings must retain the unsent draft.")
        XCTAssertTrue(app.buttons["agent-send"].isEnabled)
    }

    func testRealDiaryReceiptCanBeUndone() throws {
        launch("receipts")
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["阅读 30 分钟"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["agent-manual-capture"].isHittable,
                      "Manual capture must remain available in an existing conversation.")
        capture("receipts")

        let diaryUndo = app.buttons["撤回：留下一段日常"]
        reveal(diaryUndo)
        XCTAssertTrue(app.staticTexts["留白，是为了让重要的事发生。"].exists,
                      "The diary card must display the content actually returned by the local tool.")
        diaryUndo.tap()

        XCTAssertTrue(app.staticTexts["已撤回"].waitForExistence(timeout: 6))
        XCTAssertFalse(diaryUndo.exists, "An undone operation must no longer offer the same undo action.")
        XCTAssertFalse(app.buttons["查看：留下一段日常"].exists,
                       "An undone diary must not offer a stale record link.")
        capture("undone")
    }

    func testUnifiedCaptureKeepsManualRecordingAvailableWithoutKey() throws {
        launch("welcome")
        defer { app.terminate() }
        app.buttons["返回日常织机"].tap()

        let openAgent = app.buttons["open-agent"]
        XCTAssertTrue(openAgent.waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["global-create"].exists,
                       "Home should offer one capture entry, without a competing plus button.")
        capture("navigation-home")

        openAgent.tap()
        XCTAssertTrue(app.buttons["agent-settings"].waitForExistence(timeout: 6))
        let manualCapture = app.buttons["agent-manual-capture"]
        XCTAssertTrue(manualCapture.isHittable,
                      "Manual capture must be visible before entering a key or focusing the input.")
        capture("navigation-agent")

        let message = "Keep this draft while I write a note."
        let input = app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
        input.tap()
        input.typeText(message)
        XCTAssertTrue(manualCapture.isHittable,
                      "Opening the keyboard must not hide manual capture.")
        manualCapture.tap()

        let picker = app.descendants(matching: .any).matching(identifier: "manual-capture-picker").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 6),
                      "Manual capture must open without requiring a DeepSeek key.")
        for kind in ["text", "voice", "link", "habit"] {
            XCTAssertTrue(app.buttons["manual-capture-\(kind)"].isHittable,
                          "Every manual capture type must be visible and selectable.")
        }
        capture("navigation-manual")

        app.buttons["返回对话"].tap()
        XCTAssertTrue(manualCapture.waitForExistence(timeout: 6))
        XCTAssertEqual(input.value as? String, message,
                       "Closing the manual picker must retain the unsent conversation draft.")

        manualCapture.tap()
        let writeNote = app.buttons["manual-capture-text"]
        XCTAssertTrue(writeNote.waitForExistence(timeout: 6))
        writeNote.tap()
        let closeEditor = app.buttons["关闭编辑器"]
        XCTAssertTrue(closeEditor.waitForExistence(timeout: 6),
                      "The text option must open the existing local editor.")
        XCTAssertTrue(app.buttons["composer-save"].exists)
        closeEditor.tap()

        XCTAssertTrue(input.waitForExistence(timeout: 6))
        XCTAssertTrue(manualCapture.isHittable,
                      "Closing the editor must return to the conversation.")
        XCTAssertEqual(input.value as? String, message,
                       "Visiting a local editor must not discard the unsent conversation draft.")
        XCTAssertTrue(app.buttons["agent-send"].isEnabled)
        capture("navigation-draft")
    }

    func testReturningToLongConversationKeepsLatestMessageAndDraft() throws {
        launch("scroll")
        defer { app.terminate() }

        let latestMessage = "这是最后一条消息，回到这里继续。"
        assertMessageVisibleAboveComposer(latestMessage)

        app.buttons["返回日常织机"].tap()
        let collection = app.buttons["tab-clips"]
        XCTAssertTrue(collection.waitForExistence(timeout: 6))
        collection.tap()
        app.buttons["open-agent"].tap()
        assertMessageVisibleAboveComposer(latestMessage)

        let input = app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
        let draft = "Keep this thought for when I come back."
        input.tap()
        input.typeText(draft)
        assertMessageVisibleAboveComposer(latestMessage)

        app.buttons["agent-settings"].tap()
        XCTAssertTrue(app.buttons["agent-save-connection"].waitForExistence(timeout: 6))
        app.buttons["返回对话"].tap()
        assertMessageVisibleAboveComposer(latestMessage)
        XCTAssertEqual(input.value as? String, draft,
                       "Returning from settings must preserve the draft and the end of the conversation.")

        app.buttons["返回日常织机"].tap()
        XCTAssertTrue(app.buttons["open-agent"].waitForExistence(timeout: 6))
        app.buttons["open-agent"].tap()
        assertMessageVisibleAboveComposer(latestMessage)
        XCTAssertEqual(input.value as? String, draft,
                       "Closing and reopening the conversation must preserve its unsent draft.")

        XCUIDevice.shared.press(.home)
        app.activate()
        assertMessageVisibleAboveComposer(latestMessage)
        XCTAssertEqual(input.value as? String, draft,
                       "Returning to the app must preserve the unsent draft.")
        capture("conversation-return-bottom")
    }

    func testCustomNewConversationConfirmsAndPreservesDraft() throws {
        launch("scroll")
        defer { app.terminate() }

        let latestMessage = "这是最后一条消息，回到这里继续。"
        assertMessageVisibleAboveComposer(latestMessage)
        let newConversation = app.buttons["agent-new-conversation"]
        let entryReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: newConversation
        )
        XCTAssertEqual(XCTWaiter.wait(for: [entryReady], timeout: 6), .completed)
        XCTAssertEqual(newConversation.label, "新对话")
        capture("new-conversation-entry")

        let input = app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
        let draft = "Keep this thought for my next conversation."
        input.tap()
        input.typeText(draft)
        newConversation.tap()

        let title = app.staticTexts["agent-new-conversation-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 6))
        XCTAssertEqual(title.label, "再起一线")
        let keyboardDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.keyboards.firstMatch
        )
        XCTAssertEqual(XCTWaiter.wait(for: [keyboardDismissed], timeout: 6), .completed,
                       "Opening the confirmation should dismiss the draft keyboard.")
        XCTAssertEqual(app.sheets.count, 0,
                       "Starting a new conversation should use the app's custom confirmation, without a native action sheet.")
        // The custom view deliberately exposes the modal accessibility trait,
        // which iOS can classify as an alert even though it is our own layout.
        XCTAssertFalse(app.buttons["清空对话，重新开始"].exists)
        XCTAssertTrue(app.buttons["agent-new-conversation-cancel"].isHittable)
        XCTAssertTrue(app.buttons["agent-new-conversation-close"].isHittable)
        XCTAssertTrue(app.buttons["agent-new-conversation-confirm"].isHittable)
        capture("new-conversation-confirmation")

        app.buttons["agent-new-conversation-cancel"].tap()
        assertAbsent(title)
        assertMessageVisibleAboveComposer(latestMessage)
        XCTAssertEqual(input.value as? String, draft,
                       "Continuing the current conversation must preserve the unsent draft.")

        newConversation.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 6))
        app.buttons["agent-new-conversation-close"].tap()
        assertAbsent(title)
        assertMessageVisibleAboveComposer(latestMessage)
        XCTAssertEqual(input.value as? String, draft,
                       "Closing the confirmation must preserve the conversation and its draft.")

        newConversation.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 6))
        app.buttons["agent-new-conversation-confirm"].tap()
        assertAbsent(title)
        XCTAssertTrue(app.staticTexts["一段新对话"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["说一点，\n织进去。"].exists)
        XCTAssertFalse(app.staticTexts[latestMessage].exists,
                       "Confirming must remove the previous conversation from the screen.")
        XCTAssertFalse(newConversation.exists,
                       "An empty conversation must not offer another reset action.")
        XCTAssertEqual(input.value as? String, draft,
                       "Starting a new conversation must keep the user's unsent draft.")
    }

    private func assertAbsent(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let dismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 6), .completed,
                       "The custom confirmation should dismiss after the chosen action.",
                       file: file, line: line)
    }

    private func launch(_ state: String) {
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchEnvironment["IDEABOX_AGENT_PREVIEW"] = state
        app.launch()
        XCTAssertTrue(app.buttons["agent-settings"].waitForExistence(timeout: 6),
                      "The isolated agent preview should be visible after launch.")
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<5 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "The requested receipt action should be reachable by scrolling.")
    }

    private func assertMessageVisibleAboveComposer(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let message = app.staticTexts[text]
        let input = app.descendants(matching: .any).matching(identifier: "agent-message-input").firstMatch
        let settings = app.buttons["agent-settings"]
        // Accessibility can retain an off-screen text element. Verify its actual
        // bounds, including the keyboard-reduced viewport, without scrolling it in.
        let visible = NSPredicate { _, _ in
            guard message.exists, input.exists, settings.exists else { return false }
            let messageFrame = message.frame
            let screenFrame = self.app.frame
            return !messageFrame.isEmpty
                && screenFrame.intersects(messageFrame)
                && messageFrame.minY >= settings.frame.maxY
                && messageFrame.maxY <= input.frame.minY
        }
        let result = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: visible, object: nil)],
            timeout: 6
        )
        XCTAssertEqual(result, .completed,
                       "The latest message should remain fully visible above the composer without a manual scroll.",
                       file: file, line: line)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
