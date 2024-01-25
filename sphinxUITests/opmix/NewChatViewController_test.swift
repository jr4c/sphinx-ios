import XCTest
@testable import sphinx

class NewChatViewControllerTests: XCTestCase {

    var sut: NewChatViewController!
    var window: UIWindow!

    override func setUp() {
        super.setUp()
        
        window = UIWindow()
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "NewChatViewController") as! NewChatViewController
        _ = sut.view
        window.addSubview(sut.view)
    }

    override func tearDown() {
        sut = nil
        window = nil
        super.tearDown()
    }

    func testNewChatViewController_instantiatesWithCorrectInitializationParameters() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        XCTAssertEqual(sut.contact?.id, contactId)
        XCTAssertEqual(sut.chat?.id, chatId)
        XCTAssertEqual(sut.threadUUID, threadUUID)
        XCTAssertNotNil(sut.chatViewModel)
        XCTAssertEqual(sut.chatViewModel.contact?.id, contactId)
        XCTAssertEqual(sut.chatViewModel.chat?.id, chatId)
        XCTAssertEqual(sut.chatViewModel.threadUUID, threadUUID)
        XCTAssertNotNil(sut.chatListViewModel)
    }

    func testNewChatViewController_viewDidLoad_setsUpLayoutsAndData() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut.bottomView)
        XCTAssertNotNil(sut.headerView)
        XCTAssertNotNil(sut.chatTableView)
        XCTAssertNotNil(sut.newMsgsIndicatorView)
        XCTAssertNotNil(sut.botWebView)
        XCTAssertNotNil(sut.botWebViewWidthConstraint)
        XCTAssertNotNil(sut.chatTableViewHeightConstraint)
        XCTAssertNotNil(sut.mentionsAutocompleteTableView)
        XCTAssertNotNil(sut.webAppContainerView)
        XCTAssertNotNil(sut.chatTableHeaderHeightConstraint)

        XCTAssertTrue(sut.viewMode == .Standard)
        XCTAssertTrue(sut.isThread)

        XCTAssertNotNil(sut.contactResultsController)
        XCTAssertNotNil(sut.chatResultsController)

        XCTAssertNotNil(sut.chatViewModel)
        XCTAssertNotNil(sut.chatTableDataSource)
        XCTAssertNotNil(sut.chatMentionAutocompleteDataSource)

        XCTAssertNotNil(sut.messageBubbleHelper)
        XCTAssertNil(sut.webAppVC)

        XCTAssertTrue(sut.popOnSwipeEnabled)

        XCTAssertNotNil(sut.messageMenuData)
        XCTAssertNil(sut.messageMenuData?.messageId)
        XCTAssertNil(sut.messageMenuData?.indexPath)
        XCTAssertNil(sut.messageMenuData?.bubbleRect)

        XCTAssertEqual(sut.preferredScreenEdgesDeferringSystemGestures, [.bottom, .right])
    }

    func testNewChatViewController_viewWillAppear_checksRouteAndStartsListeningToResultsController() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()
        sut.viewWillAppear(true)

        XCTAssertTrue(sut.headerView.checkRouteCalled)
        XCTAssertTrue(sut.chatTableDataSource?.isListeningToResultsController)
    }

    func testNewChatViewController_viewDidAppear_fetchesTribeData() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)

        XCTAssertTrue(sut.fetchTribeDataCalled)
    }

    func testNewChatViewController_viewDidDisappear_savesSnapshotCurrentStateAndStopsListeningToResultsController() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()
        sut.viewDidDisappear(true)

        XCTAssertTrue(sut.chatTableDataSource?.saveSnapshotCurrentStateCalled)
        XCTAssertFalse(sut.chatTableDataSource?.isListeningToResultsController)

        XCTAssertEqual(sut.chat?.ongoingMessage?.text, sut.bottomView.getMessage())

        XCTAssertNil(SphinxSocketManager.sharedInstance.delegate)

        XCTAssertTrue(sut.stopPlayingClipCalled)
    }

    func testNewChatViewController_stopPlayingClip_pausesPlayingClip() {
        let podcastPlayerController = PodcastPlayerController.sharedInstance
        sut.stopPlayingClip()

        XCTAssertTrue(podcastPlayerController.isPaused)
    }

    func testNewChatViewController_didToggleKeyboard_showsMessageMenuForCorrectParameters() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        let messageMenuData = MessageTableCellState.MessageMenuData(
            messageId: "message-123",
            indexPath: IndexPath(row: 0, section: 0),
            bubbleRect: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        sut.messageMenuData = messageMenuData
        sut.didToggleKeyboard()

        XCTAssertEqual(sut.messageMenuData, nil)
    }

    func testNewChatViewController_shouldAdjustTableViewTopInset_updatesTableViewContentInset() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.shouldAdjustTableViewTopInset()

        XCTAssertEqual(sut.chatTableView.contentInset.bottom, Constants.kChatTableContentInset + UIScreen.main.bounds.height)
        XCTAssertEqual(sut.chatTableView.verticalScrollIndicatorInsets.bottom, Constants.kChatTableContentInset + UIScreen.main.bounds.height)
    }

    func testNewChatViewController_showThread_navigatesToNewChatViewControllerWithCorrectParameters() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        let newChatVC = sut.showThread(threadID: "new-thread-456") as! NewChatViewController

        XCTAssertEqual(newChatVC.contact?.id, contactId)
        XCTAssertEqual(newChatVC.chat?.id, chatId)
        XCTAssertEqual(newChatVC.threadUUID, "new-thread-456")
        XCTAssertNotNil(newChatVC.chatViewModel)
        XCTAssertEqual(newChatVC.chatViewModel.contact?.id, contactId)
        XCTAssertEqual(newChatVC.chatViewModel.chat?.id, chatId)
        XCTAssertEqual(newChatVC.chatViewModel.threadUUID, "new-thread-456")
        XCTAssertNotNil(newChatVC.chatListViewModel)
    }

    func testNewChatViewController_setTableViewHeight_updatesTableViewHeightConstraint() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.setTableViewHeight()

        XCTAssertEqual(sut.chatTableViewHeightConstraint.constant, UIScreen.main.bounds.height - (sut.getWindowInsets().bottom + sut.getWindowInsets().top) - (sut.headerView.bounds.height) - (sut.bottomView.bounds.height))
    }

    func testNewChatViewController_setupLayouts_setsUpCorrectLayouts() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.setupLayouts()

        XCTAssertTrue(sut.headerView.superview?.bringSubviewToFront(sut.headerView))
        XCTAssertTrue(sut.bottomView.addShadow(location: .top, color: UIColor.black, opacity: 0.1))
        XCTAssertTrue(sut.headerView.addShadow(location: .bottom, color: UIColor.black, opacity: 0.1))
        XCTAssertEqual(sut.botWebViewWidthConstraint.constant, ((UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * MessageTableCellState.kBubbleWidthPercentage) - (MessageTableCellState.kLabelMargin * 2))
        XCTAssertTrue(sut.botWebView.layoutIfNeeded())
    }

    func testNewChatViewController_setupData_setsUpCorrectData() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.setupData()

        XCTAssertTrue(sut.headerView.configureHeaderWith(chat: sut.chat, contact: sut.contact, andDelegate: sut, searchDelegate: sut))
        XCTAssertTrue(sut.configurePinnedMessageView())
        XCTAssertTrue(sut.configureThreadHeaderAndBottomView())
        XCTAssertTrue(sut.bottomView.updateFieldStateFrom(sut.chat))
        XCTAssertTrue(sut.showPendingApprovalMessage())
    }

    func testNewChatViewController_configureThreadHeaderAndBottomView_showsThreadHeaderViewAndSetsUpForThreads() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.configureThreadHeaderAndBottomView()

        XCTAssertTrue(sut.headerView.showThreadHeaderView())
        XCTAssertTrue(sut.bottomView.setupForThreads(with: sut))
    }

    func testNewChatViewController_setDelegates_setsDelegatesCorrectly() {
        let contactId: Int? = 1
        let chatId: Int? = 2
        let threadUUID: String? = "thread-123"
        let chatListViewModel: ChatListViewModel? = ChatListViewModel()

        sut = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel,
            threadUUID: threadUUID
        )

        sut.loadViewIfNeeded()

        sut.setDelegates()

        XCTAssertTrue(sut.bottomView.setDelegates(messageFieldDelegate: sut, searchDelegate: sut))
        XCTAssertTrue(SphinxSocketManager.sharedInstance.setDelegate(delegate: sut))
    }
}
