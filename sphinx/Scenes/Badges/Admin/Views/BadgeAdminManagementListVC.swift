//
//  BadgeManagementListVC.swift
//  sphinx
//
//  Created by James Carucci on 12/27/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit


class BadgeAdminManagementListVC: UIViewController{
    
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var badgeTableView: UITableView!
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    var viewDidLayout : Bool = false
    
    
    private var rootViewController: RootViewController!
    var badgeManagementListDataSource : BadgeAdminManagementListDataSource?
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeManagementListViewController.instantiate() as! BadgeAdminManagementListVC
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        setupBadgeTable()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.viewDidLayout = true
        })
        
    }
    
    func setupBadgeTable(){
        viewTitle.textColor = UIColor.Sphinx.Text
        navBarView.backgroundColor = UIColor.Sphinx.Body
        badgeManagementListDataSource = BadgeAdminManagementListDataSource(vc: self)
        badgeManagementListDataSource?.setupDataSource()
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showBadgeDetail(badge:Badge){
        let badgeDetailVC = BadgeAdminDetailVC.instantiate(rootViewController: rootViewController)
        if let valid_detailVC = badgeDetailVC as? BadgeAdminDetailVC{
            valid_detailVC.associatedBadge = badge
        }
        self.navigationController?.pushViewController(badgeDetailVC, animated: true)
    }
    
    func showErrorMessage(){
        AlertHelper.showAlert(title: "Error Retrieving Badge List", message: "")
    }
}
