//
//  Utilities.swift
//  QR Vault
//
//  Created by Peter on 10/20/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public extension String {
    
    func processed() -> String {
        var result = self.filter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ".contains)
        result = result.condenseWhitespace()
        return result
    }
    
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    var utf8: Data {
        return data(using: .utf8)!
    }
    
}

public extension Data {
    static func random(_ len: Int) -> Data {
        let values = (0 ..< len).map { _ in UInt8.random(in: 0 ... 255) }
        return Data(values)
    }

    var utf8: String {
        String(data: self, encoding: .utf8)!
    }

    var bytes: [UInt8] {
        var b: [UInt8] = []
        b.append(contentsOf: self)
        return b
    }
}

public extension Data {
    /// A hexadecimal string representation of the bytes.
      var hexString: String {
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

public extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        Data(self)
    }
}

