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
        guard let _ = try? BIP39Mnemonic(words: item.processed()) else { return false }
        
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
        guard let hexData = Data(base64Encoded: item), let _ = URHelper.shardToUr(data: hexData) else { return false }
        
        return true
    }
    
    private class func isPsbt(_ item: String) -> Bool {
        guard let _ = try? PSBT(psbt: item, network: .mainnet) else {
            
            guard let _ = try? PSBT(psbt: item, network: .testnet) else {
                
                return false
            }
            
            return true
        }
        
        return true
    }
    
    class func parse(_ item: String) -> String {
        let processed = item.lowercased()
        
        if isQuickConnect(processed) {
            return "Quick Connect"
            
        } else if isMnemonic(processed) {
            return "Mnemonic"
            
        } else if processed.hasPrefix("ur:") {
            if let ur = try? URDecoder.decode(processed) {
                return ur.type
            } else {
                return ""
            }
            
        } else if isAccountMap(processed) {
            return "Account Map"
            
        } else if isPsbt(item) {
            return "PSBT"
            
        } else if isShard(processed) {
            return "SSKR Shard"
            
        } else {
            return ""
            
        }
    }
}
