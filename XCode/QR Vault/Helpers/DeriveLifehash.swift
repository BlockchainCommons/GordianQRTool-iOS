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

class DeriveLifehash {
    
    static func lifehash(_ encryptedData: Data) -> UIImage? {
        
        guard let decryptedItem = Encryption.decrypt(encryptedData) else { return nil }
        
        guard let dict = try? JSONSerialization.jsonObject(with: decryptedItem, options: []) as? [String : Any] else { return nil }
              
        guard var descriptor = dict["descriptor"] as? String else { return nil }
        
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
    
}
