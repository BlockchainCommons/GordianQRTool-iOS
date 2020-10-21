//
//  Parser.swift
//  QR Vault
//
//  Created by Peter on 10/20/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally
import URKit

class Parser {
    
    private class func isQuickConnect(_ item: String) -> Bool {
        guard let _ = URLComponents(string: item)?.host,
            let _ = URLComponents(string: item)?.port,
            let _ = URLComponents(string: item)?.password,
            let _ = URLComponents(string: item)?.user,
            item.hasPrefix("btcstandup://") || item.hasPrefix("btcrpc://") || item.hasPrefix("clightning-rpc://") else {
                return false
        }
        
        return true
    }
    
    private class func isMnemonic(_ item: String) -> Bool {
        guard let _ = BIP39Mnemonic(item.processed()) else { return false }
        
        return true
    }
    
    private class func isAccountMap(_ item: String) -> Bool {
        guard let data = item.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
            let _ = dict["descriptor"] as? String,
            let _ = dict["blockheight"] as? Int else {
                return false
        }
        
        return true
    }
    
    private class func isShard(_ item: String) -> Bool {
        guard let hexData = Data(item), let _ = URHelper.shardToUr(data: hexData) else { return false }
        
        return true
    }
    
    class func parse(_ item: String) -> String {
        if isQuickConnect(item) {
            return "Quick Connect"
            
        } else if isMnemonic(item) {
            return "Mnemonic"
            
        } else if item.hasPrefix("ur:") {
            if let ur = try? URDecoder.decode(item) {
                return ur.type
                
            } else {
                return ""
                
            }
            
        } else if isAccountMap(item) {
            return "Account Map"
            
        } else if isShard(item) {
            return "SSKR Shard"
            
        } else {
            return ""
            
        }
    }
}
