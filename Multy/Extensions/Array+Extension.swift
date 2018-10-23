//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

extension Array where Element == UInt8 {
    var data: Data {
        return Data(bytes:(self))
    }
    
    var nsData: NSData {
        return NSData(bytes: self, length: self.count)
    }
}


extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        let array = Array(self) as! [T]
        return array
    }
}
