//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

extension DataManager {
    func kickFromMultisigWith(wallet: UserWalletRLM, addressToKick: String, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        let payload: NSDictionary = [
            "userid": DataManager.shared.apiManager.userID,
            "address": wallet.address,
            "addressto": addressToKick
        ]
        
        let params: NSDictionary = [
            "type": SocketMessageType.multisigKick,
            "from": "",
            "to":"",
            "date": Date().timeIntervalSince1970,
            "status": 0,
            "payload": payload
        ]
        
        
        socketManager.sendMsg(params: params) { (answerDict, err) in
            completion(answerDict, err)
        }
    }
    
    func leaveFromMultisigWith(wallet: UserWalletRLM, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        let payload: NSDictionary = [
            "userid": DataManager.shared.apiManager.userID,
            "address": wallet.address,
            ]
        
        let params: NSDictionary = [
            "type": SocketMessageType.multisigLeave,
            "from": "",
            "to":"",
            "date": Date().timeIntervalSince1970,
            "status": 0,
            "payload": payload
        ]
        
        
        socketManager.sendMsg(params: params) { (answerDict, err) in
            completion(answerDict, err)
        }
    }
    
    func deleteMultisigWith(wallet: UserWalletRLM, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        let payload: NSDictionary = [
            "userid": DataManager.shared.apiManager.userID,
            "address": wallet.address,
            ]
        
        let params: NSDictionary = [
            "type": SocketMessageType.multisigDelete,
            "from": "",
            "to":"",
            "date": Date().timeIntervalSince1970,
            "status": 0,
            "payload": payload
        ]
        
        
        socketManager.sendMsg(params: params) { (answerDict, err) in
            completion(answerDict, err)
        }
    }
    
    func joinToMultisigWith(wallet: UserWalletRLM, inviteCode: String, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        let payloadForJoin: NSDictionary = [
            "userid": DataManager.shared.apiManager.userID,
            "address": wallet.address,
            "invitecode": inviteCode,
            "addresstokik":"", //omitempty
            "walletindex": wallet.walletID,
            "currencyid": wallet.chain,
            "networkid": wallet.chainType
        ]
        
        let paramsForMsgSend: NSDictionary = [
            "type": SocketMessageType.multisigJoin,  // it's kinda signature method eg: join:multisig.
            "from": "",              // not requied
            "to":"",                // not requied
            "date": Date().timeIntervalSince1970, // time unix
            "status": 0,
            "payload": payloadForJoin
        ]
        
        
        socketManager.sendMsg(params: paramsForMsgSend) { (answerDict, err) in
            completion(answerDict, err)
        }
    }
}
