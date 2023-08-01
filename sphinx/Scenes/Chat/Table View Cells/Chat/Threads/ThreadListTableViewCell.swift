//
//  NewThreadOnlyMessageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/18/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ThreadListTableViewCell: UITableViewCell {

    @IBOutlet weak var originalMessageAvatarView: ChatAvatarView!
    @IBOutlet weak var originalMessageSenderAliasLabel: UILabel!
    @IBOutlet weak var originalMessageDateLabel: UILabel!
    @IBOutlet weak var originalMessageTextLabel: UILabel!
    
    @IBOutlet weak var reply1Container: UIView!
    @IBOutlet weak var reply1AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply2Container: UIView!
    @IBOutlet weak var reply2AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply3Container: UIView!
    @IBOutlet weak var reply3AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply4Container: UIView!
    @IBOutlet weak var reply4AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply5Container: UIView!
    @IBOutlet weak var reply5AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply6Container: UIView!
    @IBOutlet weak var reply6AvatarView: ChatAvatarView!
    @IBOutlet weak var reply6CountContainer: UIView!
    @IBOutlet weak var reply6CountLabel: UILabel!
    
    @IBOutlet weak var repliesCountLabel: UILabel!
    @IBOutlet weak var lastReplyDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    func setupViews() {
        reply1Container.layer.cornerRadius = reply1Container.frame.height / 2
        reply2Container.layer.cornerRadius = reply2Container.frame.height / 2
        reply3Container.layer.cornerRadius = reply3Container.frame.height / 2
        reply4Container.layer.cornerRadius = reply4Container.frame.height / 2
        reply5Container.layer.cornerRadius = reply5Container.frame.height / 2
        reply6Container.layer.cornerRadius = reply6Container.frame.height / 2
        
        reply6CountContainer.layer.cornerRadius = reply6CountContainer.frame.height / 2
        
        reply1AvatarView.setInitialLabelSize(size: 12)
        reply2AvatarView.setInitialLabelSize(size: 12)
        reply3AvatarView.setInitialLabelSize(size: 12)
        reply4AvatarView.setInitialLabelSize(size: 12)
        reply5AvatarView.setInitialLabelSize(size: 12)
        reply6AvatarView.setInitialLabelSize(size: 12)
    }
    
    func configureWith(
        threadCellState: ThreadTableCellState
    ) {
        var mutableThreadCellState = threadCellState
        
        guard let threadLayoutState = mutableThreadCellState.threadMessagesState else {
            return
        }
        
        let originalMessageSenderInfo = threadLayoutState.orignalThreadMessage.senderInfo
        
        originalMessageTextLabel.text = threadLayoutState.orignalThreadMessage.text
        originalMessageDateLabel.text = threadLayoutState.orignalThreadMessage.timestamp
        originalMessageSenderAliasLabel.text = originalMessageSenderInfo.1
        
        originalMessageAvatarView.configureForUserWith(
            color: originalMessageSenderInfo.0,
            alias: originalMessageSenderInfo.1,
            picture: originalMessageSenderInfo.2
        )
        
        repliesCountLabel.text = "\(threadLayoutState.repliesCount) replies"
        lastReplyDateLabel.text = threadLayoutState.lastReplyTimestamp
        
        let threadPeople = threadLayoutState.threadPeople

        if (threadPeople.count > 0) {
            reply1Container.isHidden = false

            let reply1SenderInfo = threadLayoutState.threadPeople[0].senderIndo

            reply1AvatarView.configureForUserWith(
                color: reply1SenderInfo.0,
                alias: reply1SenderInfo.1,
                picture: reply1SenderInfo.2
            )
        } else {
            reply1Container.isHidden = true
        }

        if (threadPeople.count > 1) {
            reply2Container.isHidden = false

            let reply2SenderInfo = threadLayoutState.threadPeople[1].senderIndo

            reply2AvatarView.configureForUserWith(
                color: reply2SenderInfo.0,
                alias: reply2SenderInfo.1,
                picture: reply2SenderInfo.2
            )
        } else {
            reply2Container.isHidden = true
        }

        if (threadPeople.count > 2) {
            reply3Container.isHidden = false

            let reply3SenderInfo = threadLayoutState.threadPeople[2].senderIndo

            reply3AvatarView.configureForUserWith(
                color: reply3SenderInfo.0,
                alias: reply3SenderInfo.1,
                picture: reply3SenderInfo.2
            )
        } else {
            reply3Container.isHidden = true
        }

        if (threadPeople.count > 3) {
            reply4Container.isHidden = false

            let reply4SenderInfo = threadLayoutState.threadPeople[3].senderIndo

            reply4AvatarView.configureForUserWith(
                color: reply4SenderInfo.0,
                alias: reply4SenderInfo.1,
                picture: reply4SenderInfo.2
            )
        } else {
            reply4Container.isHidden = true
        }

        if (threadPeople.count > 4) {
            reply5Container.isHidden = false

            let reply5SenderInfo = threadLayoutState.threadPeople[4].senderIndo

            reply5AvatarView.configureForUserWith(
                color: reply5SenderInfo.0,
                alias: reply5SenderInfo.1,
                picture: reply5SenderInfo.2
            )
        } else {
            reply5Container.isHidden = true
        }

        if (threadPeople.count > 5) {
            reply6Container.isHidden = false

            let reply6SenderInfo = threadLayoutState.threadPeople[5].senderIndo

            reply6AvatarView.configureForUserWith(
                color: reply6SenderInfo.0,
                alias: reply6SenderInfo.1,
                picture: reply6SenderInfo.2
            )
        } else {
            reply6Container.isHidden = true
        }

        if threadLayoutState.threadPeopleCount > 6 {
            reply6CountContainer.isHidden = false
            reply6CountLabel.text = "+\(threadLayoutState.threadPeopleCount-6)"
        } else {
            reply6CountContainer.isHidden = true
        }
    }
}
