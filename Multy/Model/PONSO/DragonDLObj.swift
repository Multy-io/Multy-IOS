//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

class DragonDLObj: NSObject {
    
    var chainID = Int()
    var chaintType = Int()
    var browserURL = String()
    
    func blockchain() -> BlockchainType {
        return BlockchainType(blockchain: Blockchain(UInt32(self.chainID)), net_type: self.chaintType)
    }
}
