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
    
    private class func isMicrosoftAuth(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("ms-msa://code=")
    }
    
    private class func isOtpAuth(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("otpauth")
    }
    
    private class func isLocation(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("https://maps.google.com/maps?")
    }
    
    private class func isWebsite(_ item: String) -> Bool {
        if item.lowercased().condenseWhitespace().hasPrefix("https:") || item.lowercased().condenseWhitespace().hasPrefix("http:") {
            return true
        } else {
            return false
        }
    }
    
    private class func isUrl(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("urlto:")
    }
    
    private class func isEmail(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("mailto:")
    }
    
    private class func isVcard(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("begin:vcard")
    }
    
    private class func isMecard(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("mecard:")
    }
    
    private class func isBizcard(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("bizcard:")
    }
    
    private class func isEvent(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("begin:vevent")
    }
    
    private class func isPhone(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("tel:")
    }
    
    private class func isSms(_ item: String) -> Bool {
        if item.lowercased().condenseWhitespace().hasPrefix("sms:") || item.lowercased().condenseWhitespace().hasPrefix("smsto:") || item.lowercased().condenseWhitespace().hasPrefix("mms:") || item.lowercased().condenseWhitespace().hasPrefix("mmsto:") {
            return true
        } else {
            return false
        }
           
    }
    
    private class func isFeed(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("feed:")
    }
    
    private class func isFacetimeVideo(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("facetime:")
    }
    
    private class func isFacetimeAudio(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("facetime-audio:")
    }
    
    private class func isWifi(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("wifi:")
    }
    
    private class func isIosApp(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("https://itunes.apple.com/")
    }
    
    private class func isBookmark(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("mebkm:")
    }
    
    private class func isBitcoin(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("bitcoin:")
    }
    
    private class func isPayTo(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("payto:")
    }
    
    private class func isIban(_ item: String) -> Bool {
        return item.lowercased().condenseWhitespace().hasPrefix("iban:")
    }
    
    class func parse(_ item: String) -> String {
        let processed = item.lowercased()
        
        if isQuickConnect(processed) {
            return "quick connect"
            
        } else if isMnemonic(processed) {
            return "mnemonic"
            
        } else if processed.hasPrefix("ur:") {
            
            if let ur = try? URDecoder.decode(processed.condenseWhitespace()) {
                return ur.type
            } else {
                return "unknown"
            }
            
        } else if isAccountMap(processed) {
            return "account map"
            
        } else if isPsbt(item.condenseWhitespace()) {
            return "psbt"
            
        } else if isShard(processed.condenseWhitespace()) {
            return "sskr shard"
            
        } else if isIosApp(processed) {
            return "ios app"
            
        } else if isMicrosoftAuth(processed) {
            return "microsoft auth"
            
        } else if isOtpAuth(processed) {
            return "otp auth"
            
        } else if isLocation(processed) {
            return "location"
            
        } else if isWebsite(processed) {
            return "website"
            
        } else if isUrl(processed) {
            return "url"
            
        } else if isEmail(processed) {
            return "email"
            
        } else if isVcard(processed) {
            return "vcard"
            
        } else if isMecard(processed) {
            return "mecard"
            
        } else if isBizcard(processed) {
            return "bizcard"
            
        } else if isEvent(processed) {
            return "event"
            
        } else if isPhone(processed) {
            return "phone"
            
        } else if isSms(processed) {
            return "sms"
            
        } else if isFeed(processed) {
            return "feed"
            
        } else if isFacetimeVideo(processed) {
            return "facetime video"
            
        } else if isFacetimeAudio(processed) {
            return "facetime audio"
            
        } else if isWifi(processed) {
            return "wifi"
            
        } else if isBookmark(processed) {
            return "bookmark"
            
        } else if isBitcoin(processed) {
            return "bitcoin"
            
        } else if isPayTo(processed) {
            return "pay to"
            
        } else if isIban(processed) {
            return "bank account"
            
        } else {
            return "unknown"
            
        }
    }
}
