// Copyright DApps Platform Inc. All rights reserved.

import BigInt
import Foundation

struct Balance: BalanceProtocol {

    let value: BigInt

    init(value: BigInt) {
        self.value = value
    }

    var isZero: Bool {
        return value.isZero
    }

    //commented
    var amountShort: String {
        return "0" //EtherNumberFormatter.short.string(from: value)
    }

    var amountFull: String {
        return "0" //EtherNumberFormatter.full.string(from: value)
    }
}
