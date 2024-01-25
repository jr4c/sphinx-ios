import XCTest

class NewChatViewControllerUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testTappingOnImageMessageOpensFullScreenImageViewer() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let imageMessageCell = tablesQuery.cells.element(boundBy: 0)
        imageMessageCell.tap()
        app.sheets.collectionViews.buttons["Close"].tap()
    }

    func testTappingOnImageOnPaymentMessageDoesNothing() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let paymentMessageCell = tablesQuery.staticTexts["Payment message"].tap()
        let image = paymentMessageCell.otherElements.matching(identifier: "imageView").element
        image.tap()
        XCTAssertTrue(app.sheets.element.exists == false)
    }

    func testTappingOnVideoMessageOpensFullScreenVideoPlayer() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let videoMessageCell = tablesQuery.cells.element(boundBy: 2)
        videoMessageCell.tap()
        app.buttons["Done"].tap()
    }

    func testTappingOnPlusButtonOpensBottomMenuAnimated() {
        let app = XCUIApplication()
        let plusButton = app.buttons["+"]
        plusButton.tap()
        XCTAssertTrue(app.tables.element.exists)
        plusButton.tap()
        XCTAssertFalse(app.tables.element.exists)
    }

    func testSwipingLeftOnTextMessageShowsReplyingView() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let textMessageCell = tablesQuery.cells.element(boundBy: 3)
        textMessageCell.swipeLeft()
        XCTAssertTrue(app.textFields["Reply to this message..."].exists)
        textMessageCell.swipeLeft()
        XCTAssertFalse(app.textFields["Reply to this message..."].exists)
    }

    func testTappingOnCallMessageJoinsJitsiCall() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let callMessageCell = tablesQuery.cells.element(boundBy: 4)
        callMessageCell.tap()
        XCTAssertTrue(app.alerts.element.exists)
        app.alerts.buttons["Join"].tap()
        XCTAssertFalse(app.alerts.element.exists)
    }

    func testLongPressingAnyMessageRowShowsMessageMenu() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let textMessageCell = tablesQuery.cells.element(boundBy: 3)
        textMessageCell.press(forDuration: 2)
        XCTAssertTrue(app.navigationBars["Message Menu"].exists)
        app.navigationBars["Message Menu"].buttons["Cancel"].tap()
        XCTAssertFalse(app.navigationBars["Message Menu"].exists)
    }

    func testTappingArrowDownScrollsChatToBottom() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let scrollToBottomButton = app.buttons["Scroll to bottom"]
        scrollToBottomButton.tap()
        XCTAssertTrue(tablesQuery.cells.element(boundBy: 9).exists)
    }

    func testTappingBellIconShowsNotificationAndChangesIcon() {
        let app = XCUIApplication()
        let bellIcon = app.navigationBars["Chat"].buttons["Bell"]
        bellIcon.tap()
        XCTAssertTrue(app.alerts.element.exists)
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(bellIcon.exists)
        XCTAssertTrue(bellIcon.image.isEqual(UIImage(named: "bell_muted")))
    }

    func testTappingOnMessageFieldExpandsKeyboardAndSetsFocus() {
        let app = XCUIApplication()
        let messageField = app.textFields["Type your message..."]
        messageField.tap()
        XCTAssertTrue(app.keyboards.element.exists)
        XCTAssertTrue(messageField.isFocused)
    }

    func testTypingInFieldExpandsFieldHeight() {
        let app = XCUIApplication()
        let messageField = app.textFields["Type your message..."]
        messageField.tap()
        messageField.typeText("This is a long message that should expand the field height")
        XCTAssertTrue(messageField.frame.height > 44)
    }

    func testMessageFieldIsLimitedTo1000Characters() {
        let app = XCUIApplication()
        let messageField = app.textFields["Type your message..."]
        messageField.tap()
        (1...1000).forEach { _ in messageField.typeText("a") }
        XCTAssertTrue(messageField.value as? String == "a".repeated(1000))
        messageField.typeText("b")
        XCTAssertTrue(messageField.value as? String == "a".repeated(1000))
    }

}
