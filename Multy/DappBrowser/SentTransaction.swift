// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import TrustCore
import BigInt

struct SentTransaction {
    let id: String
    let original: SignTransaction
    let data: Data
}

extension SentTransaction {
    static func from(transaction: SentTransaction) -> Transaction {
        return Transaction(
            id: transaction.id,
            blockNumber: 0,
            from: "----",//transaction.original.account.address.description,
            to: transaction.original.to?.description ?? "",
            value: "",// transaction.original.value.description,//COMMENTED
            gas: "",//transaction.original.gasLimit.description,//COMMENTED
            gasPrice: "",//transaction.original.gasPrice.description,//COMMENTED
            gasUsed: "",
            nonce: 0,// Int(transaction.original.nonce),
            date: Date(),
            coin: Coin(coinType: 1)// transaction.original.account.coin
            
//            localizedOperations: [transaction.original.localizedObject].compactMap { $0 },
//            state: .pending
        )
    }
}
