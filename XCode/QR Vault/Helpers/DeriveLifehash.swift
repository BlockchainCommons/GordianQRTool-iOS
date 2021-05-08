//
//  DeriveLifehash.swift
//  QR Vault
//
//  Created by Peter Denton on 5/6/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit
import LibWally
import URKit

class DeriveLifehash {
    
    static func hdkeyLifehash(_ hdKey: String) -> UIImage? {
        var result: [CBOR] = []
        
        guard let ur = try? URDecoder.decode(hdKey.condenseWhitespace()),
              let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
              case let CBOR.map(dict) = decodedCbor else {
            return nil
        }
        
        var keyData:Data!
        var chainCode:Data?
        var chain:UInt = 0
        
        for (key, value) in dict {
            switch key {
            case 3:
                guard case let CBOR.byteString(bs) = value else { fallthrough }
                
                keyData = Data(bs)
            case 4:
                guard case let CBOR.byteString(bs) = value else { fallthrough }
                
                chainCode = Data(bs)
            case 5:
                guard case let CBOR.tagged(_, useInfoCbor) = value else { fallthrough }
                guard case let CBOR.map(map) = useInfoCbor else { fallthrough }
                
                let (type, network) = URHelper.useInfo(map)
                
                if network == "main" {
                    chain = 0
                } else if network == "test" {
                    chain = 1
                }
                
                if type != "btc" {
                    return nil
                }
            default:
                break
            }
        }
        
        result.append(CBOR.byteString(keyData.bytes))
        
        if let chainCode = chainCode {
            result.append(CBOR.byteString(chainCode.bytes))
        } else {
            result.append(CBOR.null)
        }
        
        result.append(CBOR.unsignedInt(UInt64(0)))
        result.append(CBOR.unsignedInt(UInt64(chain)))
        
        return LifeHash.image(Data(result.encode()))
    }
    
    static func urLifehash(_ ur: String) -> UIImage? {
        let processedUr = ur.lowercased().condenseWhitespace()
        switch processedUr {
        case _ where ur.hasPrefix("ur:crypto-hdkey"):
            return hdkeyLifehash(processedUr)
        default:
            return LifeHash.image(processedUr)
        }
    }
    
    static func descriptorLifehash(_ dict: [String:Any]) -> UIImage? {
        guard var descriptor = dict["descriptor"] as? String else {
            return LifeHash.image(dict.description.utf8)
        }
        
        var dictArray = [[String:String]]()
        let descriptorParser = DescriptorParser()
        let descStruct = descriptorParser.descriptor(descriptor)
        
        for keyWithPath in descStruct.keysWithPath {
            let arr = keyWithPath.split(separator: "]")
            
            if arr.count > 1 {
                var xpubString = "\(arr[1].replacingOccurrences(of: "))", with: ""))"
                xpubString = xpubString.replacingOccurrences(of: "/0/*", with: "")
                
                guard let xpub = try? HDKey(base58: xpubString) else {
                    return nil
                }
                
                let dict = ["path":"\(arr[0])]", "key": xpub.description]
                dictArray.append(dict)
            }
        }
        
        dictArray.sort(by: {($0["key"]!) < $1["key"]!})
        
        var sortedKeys = ""
        
        for (i, sortedItem) in dictArray.enumerated() {
            let path = sortedItem["path"]!
            let key = sortedItem["key"]!
            let fullKey = path + key
            sortedKeys += fullKey
            
            if i + 1 < dictArray.count {
                sortedKeys += ","
            }
        }
        
        let arr2 = descriptor.split(separator: ",")
        descriptor = "\(arr2[0])," + sortedKeys + "))"
        
        return LifeHash.image(descriptor)
    }
    
    static func lifehash(_ encryptedData: Data) -> UIImage? {
        guard let decryptedItem = Encryption.decrypt(encryptedData) else {
            return LifeHash.image(encryptedData)
        }
                
        if let dict = try? JSONSerialization.jsonObject(with: decryptedItem, options: []) as? [String : Any] {
            return descriptorLifehash(dict)
        } else if decryptedItem.utf8.lowercased().hasPrefix("ur:") {
            return urLifehash(decryptedItem.utf8.lowercased())
        } else {
            return LifeHash.image(decryptedItem.utf8)
        }
    }
    
}
