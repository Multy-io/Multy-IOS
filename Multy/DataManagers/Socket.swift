//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import SocketIO
import AVFoundation

private typealias MessageHandler = Socket

class Socket: NSObject {
    static let shared = Socket()
    
    var manager : SocketManager
    var socket : SocketIOClient
    
    var isStarted : Bool {
        return socket.status == SocketIOStatus.connected
    }
    override init() {
        manager = SocketManager(socketURL: URL(string: socketUrl)!, config: [.log(false), .compress, .forceWebsockets(true), .reconnectAttempts(3), .forcePolling(false), .secure(false)])
        socket = manager.defaultSocket
    }
    
    func start() {
        if self.manager.status == .connected {
            return
        }
        DataManager.shared.getAccount { (account, error) in
            guard account != nil else {
                return
            }
            
            let header = ["userID": account!.userID,
                "deviceType": "\(account!.deviceType)",
                "jwtToken": account!.token]
            
            self.manager = SocketManager(socketURL: URL(string: socketUrl)!, config: [.log(false), .compress, .forceWebsockets(true), .reconnectAttempts(3), .forcePolling(false), .extraHeaders(header), .secure(false)])
            self.socket = self.manager.defaultSocket
            //SocketIOClient(manager: self.manager, nsp: "")
            
            self.socket.on(clientEvent: .connect) {data, ack in
                print("socket connected")
                self.getExchangeReq()
            }
            
//            self.socket.on(clientEvent: .disconnect) {data, ack in
//                print("socket disconnected")
//            }
            
            self.socket.on("exchangeAll") {data, ack in
//                print("-----exchangeAll: \(data)")
            }

            self.socket.on("exchangeGdax") {data, ack in
                if !(data is NSNull) {
                    DataManager.shared.currencyExchange.update(exchangeDict: data[0] as! NSDictionary)
                }
            }
            
            self.socket.on("TransactionUpdate") { data, ack in
                print("-----TransactionUpdate: \(data)")
                if data.first != nil {
                    let msg = data.first! as! [AnyHashable : Any]
                    NotificationCenter.default.post(name: NSNotification.Name("transactionUpdated"), object: nil, userInfo: msg)
                }
//                NotificationCenter.default.post(name: NSNotification.Name("transactionUpdated"), object: nil)
//                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            
            self.socket.on("currentAmount") {data, ack in
                guard let cur = data[0] as? Double else { return }
                
                self.socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
                    self.socket.emit("update", ["amount": cur + 2.50])
                }
                
                ack.with("Got your currentAmount", "dude")
            }
            
            self.socket.on("message:recieve:\(account!.userID)") {data, ack in
                guard let firstData = data.first as? [AnyHashable : Any] else {
                    return
                }
                
                print("message:recieve:\n\(firstData)")
                
                self.handleMessage(firstData)
            }
            
            self.socket.connect()
        }
    }
    
    func restart() {
        stop()
        start()
    }
    
    func stop() {
        if self.socket.status == .connected{
            self.socket.disconnect()
        }
    }
    
    func getExchangeReq() {
        let abc = NSDictionary(dictionary: ["From": "USD",
                                            "To": "BTC"]).socketRepresentation()
        
        socket.emitWithAck("/getExchangeReq", abc).timingOut(after: 0) { (data) in }
    }
    
    func becomeReceiver(receiverID : String, userCode : String, currencyID : Int, networkID : Int, address : String, amount : String) {
        print("becomeReceiver: userCode = \(userCode)\nreceiverID = \(receiverID)\ncurrencyID = \(currencyID)\nnetworkID = \(networkID)\naddress = \(address)\namount = \(amount)")
        socket.emitWithAck("event:receiver:on",
                           with: [["userid" : receiverID,
                                   "usercode" : userCode,
                                   "currencyid" : currencyID,
                                   "networkid" : networkID,
                                   "address" : address,
                                   "amount" : amount ]]).timingOut(after: 1) { data in
            print(data)
        }
    }
    
    func stopReceive() {
        print("stopReceive")
        
        socket.emitWithAck("receiver:stop", with: []).timingOut(after: 1) { data in
            print(data)
        }
    }
    
    func becomeSender(nearIDs : [String]) {
        print("becomeSender: \(nearIDs)")
        self.socket.on("event:new:receiver") { (data, ack) in
            print(data)
            if data.first != nil {

            }
        }

        socket.emitWithAck("event:sender:check", with: [["ids" : nearIDs]]).timingOut(after: 1) { data in
            print(data)

            if data.first != nil {
                if let _ = data.first! as? String {
                    print("Error case")

                    return
                }

                let requestsData = data.first! as! [Dictionary<String, AnyObject>]

                var newRequests = [PaymentRequest]()
                for requestData in requestsData {
                    let dataDict = requestData
                    
                    let userID = dataDict["userid"] as! String
                    let userCode = dataDict["usercode"] as! String
                    let currencyID = dataDict["currencyid"] as! Int
                    let networkID = dataDict["networkid"] as! Int
                    let address = dataDict["address"] as! String
                    let amount = dataDict["amount"] as! String
                    let blockchain = Blockchain.init(rawValue: UInt32(currencyID))

                    let paymentRequest = PaymentRequest(sendAddress: address, userCode : userCode, currencyID: currencyID, sendAmount: BigInt(amount).cryptoValueString(for: blockchain), networkID: networkID, userID : userID)

                    newRequests.append(paymentRequest)
                    print(dataDict)
                }
                
                let userInfo = ["paymentRequests" : newRequests]
                NotificationCenter.default.post(name: NSNotification.Name("newReceiver"), object: nil, userInfo: userInfo)
            }
        }
    }
    
    func stopSend() {
        print("stopSend")
        
        socket.emitWithAck("sender:stop", with: []).timingOut(after: 1) { data in
            print(data)
        }
    }
    
    
    // ================================== MULTI SIG TEST =================================================== //
    
    func sendMsg(params: NSDictionary, completion: @escaping(_ answer: NSDictionary?, _ error: Error?) -> ()) {
        print("SOCKET Emit message:send with params: \n\(params)")
        socket.emitWithAck("message:send", with: [params]).timingOut(after: 1) { data in
            print("answer: \n \(data)")
            let answer = data.first!
            if answer is String {
                let err = NSError(domain: "", code: 555, userInfo: ["Error": "No Ack"]) as Error
                completion(nil, err) // FIX IT: completion(nil, error)
                
                return
            }
            
            let dict = answer as! NSDictionary
            completion(dict, nil)
        }
    }
    
    
    
//    func txSend(params : [String: Any]) {
//        print("txSend : \(params)")
//
//        socket.emitWithAck("event:sendraw", with: [params]).timingOut(after: 1) { data in
//            print(data)
//
//            if let response = data.first! as? String {
//                var isSuccess = false
//                if response.hasPrefix("success") {
//                    isSuccess = true
//                }
//                let userInfo = ["data" : isSuccess]
//                NotificationCenter.default.post(name: NSNotification.Name("sendResponse"), object: nil, userInfo: userInfo)
//            }
//        }
//    }
}

extension MessageHandler {
    private func handleMessage(_ data: [AnyHashable : Any]) {
        let msgType : Int = data["type"] as! Int
        let messageType = SocketMessageType(rawValue: msgType)
        
        guard messageType != nil else {
            return
        }
        
        switch SocketMessageType(rawValue: msgType)!  {
        case SocketMessageType.multisigJoin:
            let payload = data["payload"] as! [AnyHashable : Any]
            let inviteCode = payload["inviteCode"] as! String
            let userInfo = ["inviteCode" : inviteCode]
            
            NotificationCenter.default.post(name: NSNotification.Name("msMembersUpdated"), object: nil, userInfo: userInfo)
            break
            
        case SocketMessageType.multisigLeave:
            let payload = data["payload"] as! [AnyHashable : Any]
            let inviteCode = payload["inviteCode"] as! String
            let userInfo = ["inviteCode" : inviteCode]
            
            NotificationCenter.default.post(name: NSNotification.Name("msMembersUpdated"), object: nil, userInfo: userInfo)
            break
            
        case SocketMessageType.multisigDelete:
            let inviteCode = data["payload"] as! String
            NotificationCenter.default.post(name: NSNotification.Name("msWalletDeleted"), object: nil, userInfo: ["inviteCode" : inviteCode])
            break
            
        case SocketMessageType.multisigKick:
            let payload = data["payload"] as! [AnyHashable : Any]
            let multisig = payload["multisig"] as? [AnyHashable : Any]
            
            guard multisig != nil else {
                return
            }
            let inviteCode = multisig!["inviteCode"] as! String
            var userInfo = ["inviteCode" : inviteCode]
            if let kickedAddress = payload["kickedAddress"] as? String {
                userInfo["kickedAddress"] = kickedAddress
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("msMembersUpdated"), object: nil, userInfo: userInfo)
            break
        case SocketMessageType.multisigCheck:
            break
        case SocketMessageType.multisigView:
            break
        case SocketMessageType.multisigDecline:
            break
        case SocketMessageType.multisigWalletDeploy:
            let payload = data["payload"] as? [AnyHashable : Any]
            
            guard payload != nil else {
                return
            }
            
            let inviteCode = payload!["inviteCode"] as? String
            let statusCode = payload!["deployStatus"] as? Int
            
            guard inviteCode != nil, inviteCode!.isEmpty == false, statusCode != nil, statusCode == DeployStatus.deployed.rawValue else {
                return
            }
            
            let userInfo = ["inviteCode" : inviteCode!]
            
            NotificationCenter.default.post(name: NSNotification.Name("msWalletUpdated"), object: nil, userInfo: userInfo)
            break
        case SocketMessageType.multisigTxPaymentRequest:
            handlePaymentRequestMessage(data)
            break
        case SocketMessageType.multisigTxIncoming:
            handlePaymentRequestMessage(data)
            break
        case SocketMessageType.multisigTxConfirm:
            handlePaymentRequestMessage(data)
            break
        case SocketMessageType.multisigTxRevoke:
            handlePaymentRequestMessage(data)
            break
        }
    }
    
    private func handlePaymentRequestMessage(_ data : [AnyHashable : Any]) {
        let userInfo = ["transaction" : data]
        
        NotificationCenter.default.post(name: NSNotification.Name("msTransactionUpdated"), object: nil, userInfo: userInfo)
    }
}
