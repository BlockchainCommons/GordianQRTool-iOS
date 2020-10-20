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
    
    class func encrypt(_ data: Data) -> Data? {
        guard let key = KeyChain.load(key: "privateKey") else { return nil }
        
        return try? ChaChaPoly.seal(data, using: SymmetricKey(data: key)).combined
    }
    
    class func decrypt(_ data: Data) -> Data? {
        guard let key = KeyChain.load(key: "privateKey") else { return nil }
        
        return try? ChaChaPoly.open(ChaChaPoly.SealedBox(combined: data), using: SymmetricKey(data: key))
    }
    
}
