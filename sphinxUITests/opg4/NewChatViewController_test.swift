import XCTest
@testable import sphinx

class NewChatViewControllerTests: XCTestCase {
    
    var sut: NewChatViewController!
    
    override func setUp() {
        super.setUp()
        sut = NewChatViewController.instantiate()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        sut.viewDidLoad()
        
        XCTAssertNotNil(sut.chatViewModel)
        XCTAssertNotNil(sut.chatTableDataSource)
        XCTAssertNotNil(sut.chatMentionAutocompleteDataSource)
    }
    
    func testViewWillAppear() {
        sut.viewWillAppear(false)
        
        XCTAssertNotNil(sut.chatTableDataSource)
    }
    
    func testViewDidAppear() {
        sut.viewDidAppear(false)
        
        XCTAssertNotNil(sut.chat)
    }
    
    func testViewDidDisappear() {
        sut.viewDidDisappear(false)
        
        XCTAssertNotNil(sut.chat)
    }
    
    func testStopPlayingClip() {
        sut.stopPlayingClip()
        
        let podcastPlayerController = PodcastPlayerController.sharedInstance
        XCTAssertFalse(podcastPlayerController.isPlaying)
    }
    
    func testDidToggleKeyboard() {
        sut.didToggleKeyboard()
        
        XCTAssertNotNil(sut.messageMenuData)
    }
    
    func testShouldAdjustTableViewTopInset() {
        sut.shouldAdjustTableViewTopInset()
        
        XCTAssertEqual(sut.chatTableView.contentInset.bottom, Constants.kChatTableContentInset)
    }
    
    func testShowThread() {
        sut.showThread(threadID: "test")
        
        XCTAssertNotNil(sut.navigationController)
    }
    
    func testSetTableViewHeight() {
        sut.setTableViewHeight()
        
        XCTAssertEqual(sut.chatTableViewHeightConstraint.constant, UIScreen.main.bounds.height - (headerView.bounds.height) - (bottomView.bounds.height))
    }
    
    func testSetupLayouts() {
        sut.setupLayouts()
        
        XCTAssertEqual(sut.botWebViewWidthConstraint.constant, ((UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * MessageTableCellState.kBubbleWidthPercentage) - (MessageTableCellState.kLabelMargin * 2))
    }
    
    func testSetupData() {
        sut.setupData()
        
        XCTAssertNotNil(sut.headerView)
        XCTAssertNotNil(sut.bottomView)
    }
    
    func testConfigureThreadHeaderAndBottomView() {
        sut.configureThreadHeaderAndBottomView()
        
        XCTAssertNotNil(sut.headerView)
        XCTAssertNotNil(sut.bottomView)
    }
    
    func testSetDelegates() {
        sut.setDelegates()
        
        XCTAssertNotNil(sut.bottomView)
        XCTAssertNotNil(SphinxSocketManager.sharedInstance.delegate)
    }
}
