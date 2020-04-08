//
//  Encryption.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import CryptoKit

class Encryption {
    
    class func privateKey() -> Data {
        return P256.Signing.PrivateKey().rawRepresentation
    }
    
    class func encryptData(dataToEncrypt: Data, completion: @escaping ((encryptedData: Data?, error: Bool)) -> Void) {
        if let key = KeyChain.load(key: "privateKey") {
            let k = SymmetricKey(data: key)
            if let sealedBox = try? ChaChaPoly.seal(dataToEncrypt, using: k) {
                let encryptedData = sealedBox.combined
                completion((encryptedData,false))
            } else {
                completion((nil,true))
            }
        }
    }
    
    class func decryptData(dataToDecrypt: Data, completion: @escaping ((Data?)) -> Void) {
        if let key = KeyChain.load(key: "privateKey") {
            let k = SymmetricKey(data: key)
            do {
                let box = try ChaChaPoly.SealedBox.init(combined: dataToDecrypt)
                let decryptedData = try ChaChaPoly.open(box, using: k)
                completion((decryptedData))
            } catch {
                print("failed decrypting")
                completion((nil))
            }
        }
    }
    
}
