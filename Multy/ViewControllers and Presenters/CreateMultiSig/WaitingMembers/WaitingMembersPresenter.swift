//
//  WaitingMembersPresenter.swift
//  Multy
//
//  Created by Artyom Alekseev on 04.07.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation

class WaitingMembersPresenter: NSObject {
    var viewController : WaitingMembersViewController?
    
    var walletName: String = "Family"
    var membersAmount: UInt = 2
    var membersJoined = [String]()
    var createWalletPrice = 0.001
    
    func viewControllerViewDidLoad() {
    }
    
    func viewControllerViewWillAppear() {
    }
    
    func viewControllerViewDidLayoutSubviews() {
    }
}
