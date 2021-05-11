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
    
    class func checksum(_ data: Data) -> String {
        let hash = SHA256.hash(data: Data(SHA256.hash(data: data)))
        let checksum = Data(hash).subdata(in: Range(0...3))
        return checksum.hexStrng
    }
    
}

extension Data {
    /// A hexadecimal string representation of the bytes.
      var hexStrng: String {
      let hexDigits = Array("0123456789abcdef".utf16)
      var hexChars = [UTF16.CodeUnit]()
      hexChars.reserveCapacity(count * 2)

      for byte in self {
        let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
        hexChars.append(hexDigits[index1])
        hexChars.append(hexDigits[index2])
      }

      return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }
}
