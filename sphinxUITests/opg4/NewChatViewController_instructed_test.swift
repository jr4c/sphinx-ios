import XCTest

class NewChatViewControllerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testImageMessageTap() {
        let imageMessage = app.images["imageMessageIdentifier"]
        XCTAssertTrue(imageMessage.exists)
        imageMessage.tap()
        XCTAssertTrue(app.otherElements["fullScreenImageView"].exists)
    }

    func testPaymentMessageImageTap() {
        let paymentImage = app.images["paymentImageIdentifier"]
        XCTAssertTrue(paymentImage.exists)
        paymentImage.tap()
        XCTAssertFalse(app.otherElements["fullScreenImageView"].exists)
    }

    func testVideoMessageTap() {
        let videoMessage = app.images["videoMessageIdentifier"]
        XCTAssertTrue(videoMessage.exists)
        videoMessage.tap()
        XCTAssertTrue(app.otherElements["fullScreenVideoPlayer"].exists)
    }

    func testPlusButtonTap() {
        let plusButton = app.buttons["plusButtonIdentifier"]
        XCTAssertTrue(plusButton.exists)
        plusButton.tap()
        XCTAssertTrue(app.otherElements["bottomMenu"].exists)
    }


    override func tearDown() {
        app = nil
        super.tearDown()
    }
}
