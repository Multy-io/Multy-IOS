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
            "type": SocketMessageType.multisigKick.rawValue,
            "from": "",
            "to":"",
            "date": UInt64(Date().timeIntervalSince1970),
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
            "address": DataManager.shared.,
            "invitecode": wallet.multisigWallet!.inviteCode
            ]
        
        let params: NSDictionary = [
            "type": SocketMessageType.multisigLeave.rawValue,
            "from": "",
            "to":"",
            "date": UInt64(Date().timeIntervalSince1970),
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
            "invitecode": ""
            ]
        
        let params: NSDictionary = [
            "type": SocketMessageType.multisigDelete.rawValue,
            "from": "",
            "to":"",
            "date": UInt64(Date().timeIntervalSince1970),
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
            "addresstokick":"", //omitempty
            "walletindex": wallet.walletID,
            "currencyid": wallet.chain,
            "networkid": wallet.chainType
        ]
        
        let paramsForMsgSend: NSDictionary = [
            "type": SocketMessageType.multisigJoin.rawValue,  // it's kinda signature method eg: join:multisig.
            "from": "",              // not requied
            "to":"",                // not requied
            "date": UInt64(Date().timeIntervalSince1970), // time unix
            "status": 0,
            "payload": payloadForJoin
        ]
        
        
        socketManager.sendMsg(params: paramsForMsgSend) { (answerDict, err) in
            completion(answerDict, err)
        }
    }
    
    func validateInviteCode(code: String, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        let payloadForValidate: NSDictionary = [
            "userid": DataManager.shared.apiManager.userID,
            "invitecode": code
        ]
        
        let paramsForMsgSend: NSDictionary = [
            "type": SocketMessageType.multisigCheck.rawValue,  // it's kinda signature method eg: join:multisig.
            "from": "",              // not requied
            "to":"",                // not requied
            "date": UInt64(Date().timeIntervalSince1970), // time unix
            "status": 0,
            "payload": payloadForValidate
        ]
        
        
        socketManager.sendMsg(params: paramsForMsgSend) { (answerDict, err) in
            if err != nil {
                completion(nil, err)
                return
            }
            let payloadDict = answerDict!["payload"] as! NSDictionary
            completion(payloadDict, nil)
        }
    }
}
