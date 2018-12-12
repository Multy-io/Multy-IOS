//
//  QuickexManager.swift
//  Multy
//
//  Created by Alex Pro on 12/10/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation
import Alamofire

typealias QuickexManager = ApiManager

let quickexURL = "https://api.quickex.io/"

extension QuickexManager {
    func marketInfo(currencyPair: String, completion: @escaping(_ answer: Result<NSDictionary, String>) -> ()) {
        //MARK: add chain ID
        
        requestManager.request("\(quickexURL)marketinfo/\(currencyPair)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(let error):
                completion(Result.failure(error.localizedDescription))
                break
            }
        }
    }
    
    func exchange(amountString: String, withdrawalAddress: String, pairString: String, returnAddress: String, tag: String = "", apiKey: String, completion: @escaping(_ answer: Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json"
        ]

        var params: Parameters = [
            "amount":       amountString,
            "withdrawal":   withdrawalAddress,
            "pair":         pairString,
            "returnAddress":returnAddress,
            "apiKey":       apiKey
        ]
        
        if !tag.isEmpty {
            params["destTag"] = tag
        }
        
        requestManager.request("\(quickexURL)sendamount", method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(let error):
                completion(Result.failure(error.localizedDescription))
                break
            }
        }
    }
}
