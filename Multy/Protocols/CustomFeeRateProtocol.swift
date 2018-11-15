//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

protocol CustomFeeRateProtocol: class {
    func customFeeData(firstValue: BigInt?, secValue: BigInt?)
    func setPreviousSelected(index: Int?)
}
