//
//  ChatAvatarView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

protocol ChatAvatarViewDelegate: class {
    func didTapAvatarView()
}

class ChatAvatarView: UIView {
    
    weak var delegate: ChatAvatarViewDelegate?
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileInitialContainer: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ChatAvatarView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        profileImageView.layer.cornerRadius = self.bounds.height/2
        profileImageView.clipsToBounds = true
        
        profileInitialContainer.layer.cornerRadius = self.bounds.height/2
        profileInitialContainer.clipsToBounds = true
    }
    
    func resetView() {
        profileImageView.isHidden = false
        profileImageView.image = UIImage(named: "profile_avatar")
        
        profileInitialContainer.isHidden = true
    }
    
    func setInitialLabelSize(size: Double) {
        initialsLabel.font = UIFont(name: "Montserrat-Regular", size: size)!
    }
    
    func configureForSenderWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getSenderColorFor(message: message),
            alias: message.senderAlias,
            picture: message.senderPic
        )
    }
    
    func configureForRecipientWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getRecipientColorFor(message: message),
            alias: message.recipientAlias,
            picture: message.recipientPic
        )
    }
    
    func configureForUserWith(
        color: UIColor,
        alias: String?,
        picture: String?,
        image: UIImage? = nil,
        and delegate: ChatAvatarViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        profileImageView.sd_cancelCurrentImageLoad()
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        showInitialsWith(
            alias: alias ?? "Unknown",
            color: color
        )
        
        if let image = image {
            profileInitialContainer.isHidden = true
            profileImageView.isHidden = false
            profileImageView.image = image
        } else if let picture = picture, let url = URL(string: picture) {
            showImageWith(url: url)
        }
    }
    
    func showImageWith(
        url: URL
    ) {
        let transformer = SDImageResizingTransformer(
            size: self.bounds.size,
            scaleMode: .aspectFill
        )
        
        profileImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "profile_avatar"),
            options: [.decodeFirstFrameOnly, .lowPriority],
            context: [.imageTransformer: transformer],
            progress: nil,
            completed: { (image, error, _, _) in
                if (error == nil) {
                    self.profileInitialContainer.isHidden = true
                    self.profileImageView.isHidden = false
                    self.profileImageView.image = image
                }
            }
        )
    }
    
    func showInitialsWith(
        alias: String,
        color: UIColor
    ) {
        profileImageView.image = nil
        
        profileInitialContainer.isHidden = false
        profileInitialContainer.backgroundColor = color
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = alias.getInitialsFromName()
    }
    
    @IBAction func avatarViewButtonTouched() {
        delegate?.didTapAvatarView()
    }
}
