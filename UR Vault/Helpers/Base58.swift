//
//  Base58.swift
//  UR Vault
//
//  Created by Peter Denton on 6/7/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public class Base58 {

    public class func encode(_ input: [UInt8]) -> String {
        var size = Int(ceil(log(256.0)/log(58)*Double(input.count))) + 1
        var data = Data(count: size)
// ---------------------------------------------------------------------------------
// MARK: This was working but throwing a warning:
//
//        data.withUnsafeMutableBytes {(bytes: UnsafeMutablePointer<Int8>)->Void in
//            b58enc(bytes, &size, input, input.count)
//        }
//
// ---------------------------------------------------------------------------------
// MARK: This is expiramental to silence the warning:
        
        data.withUnsafeMutableBytes { (rawMutableBufferPointer) in
            let bufferPointer = rawMutableBufferPointer.bindMemory(to: Int8.self)
            if let address = bufferPointer.baseAddress {
                b58enc(address, &size, input, input.count)
            }
        }
// ---------------------------------------------------------------------------------
        let r = data.subdata(in: 0..<(size - 1))
        return String(data: r, encoding: .utf8) ?? ""
    }

    public class func decode(_ str: String) -> [UInt8] {
        guard validate(str) else { return [] }

        let c = Array(str.utf8).map{ Int8($0) }
        let csize = Int(ceil(Double(c.count)*log(58.0)/log(256.0)))
        var data = Data(count: csize)
        var size = csize
// ---------------------------------------------------------------------------------
// MARK: This was working but throwing a warning:
//
//        data.withUnsafeMutableBytes {(bytes: UnsafeMutablePointer<Int8>)->Void in
//            b58tobin(bytes, &size, c, c.count)
//        }
// ---------------------------------------------------------------------------------
// MARK: This is expiramental to silence the warning:
        
        data.withUnsafeMutableBytes { (rawMutableBufferPointer) in
            let bufferPointer = rawMutableBufferPointer.bindMemory(to: Int8.self)
            if let address = bufferPointer.baseAddress {
                b58tobin(address, &size, c, c.count)
            }
        }
// ---------------------------------------------------------------------------------

        let beginIndex = (csize - size)

        if beginIndex < 0 || csize > data.count {
            return []
        }

        let r = data.subdata(in: beginIndex..<csize)
        return Array(r)
    }

    public class func decodeToStr(_ str: String) -> String {
        return String(data: Data(decode(str)), encoding: .utf8) ?? ""
    }

    static let Alphabet = CharacterSet(charactersIn: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    static let WrongAlphabet = Alphabet.inverted

    public class func validate(_ str: String) -> Bool {
        return str.rangeOfCharacter(from: WrongAlphabet) == nil
    }
}
