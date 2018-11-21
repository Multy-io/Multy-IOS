//
//  AccountType.swift
//  Multy
//
//  Created by Alex Pro on 11/20/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation
import CoreGraphics

typealias BricksViewInfoDelegate = AccountType

enum AccountType: Int, CaseIterable {
    case
    multy =     0,
    metamask =  1
    
    init(typeID: Int) {
        if typeID >= AccountType.allCases.count || typeID < 0 {
            self = .multy
        } else {
            self = AccountType(rawValue: typeID)!
        }
    }
    
    var seedPhraseWordsCount: Int {
        switch self {
        case .multy:
            return 15
        case .metamask:
            return 12
        }
    }
    
    var seedPhraseScreens: Int {
        switch self {
        case .multy:
            return 5
        case .metamask:
            return 4
        }
    }
}

extension BricksViewInfoDelegate {
    var segmentsCountUp: Int {
        switch self {
        case .multy:
            return 7
        case .metamask:
            return 6
        }
    }
    
    var segmentsCountDown: Int {
        switch self {
        case .multy:
            return 8
        case .metamask:
            return 6
        }
    }
    
    var upperSizes: [CGFloat] {
        switch self {
        case .multy:
            return [0, 35, 79, 107, 151, 183, 218, 253]
        case .metamask:
            return [0, 35, 79, 107, 151, 218, 253]
        }
    }
    
    var downSizes: [CGFloat] {
        switch self {
        case .multy:
            return [0, 23, 40, 53, 81, 136, 153, 197, 249]
        case .metamask:
            return [0, 23, 40, 81, 153, 197, 252]
        }
    }
}
