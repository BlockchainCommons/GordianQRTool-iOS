//
//  UniformResource.swift
//  QR Vault
//
//  Created by Peter on 10/20/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import URKit
import LibWally

enum URHelper {
    
    static func shardToUr(data: Data) -> String? {
        let wrapper:CBOR = .tagged(.init(rawValue: 309), .byteString(data.bytes))
        let cbor = Data(wrapper.cborEncode())
        do {
            let rawUr = try UR(type: "crypto-sskr", cbor: cbor)
            return UREncoder.encode(rawUr)
        } catch {
            return nil
        }
    }
    
    static func psbtUr(_ data: Data) -> UR? {
        let cbor = CBOR.byteString(data.bytes).cborEncode().data
        
        return try? UR(type: "crypto-psbt", cbor: cbor)
    }
    
    static func psbtUrString(_ data: Data) -> String? {
        let cbor = CBOR.byteString(data.bytes).cborEncode().data
        
        guard let rawUr = try? UR(type: "crypto-psbt", cbor: cbor) else { return nil }
        
        return UREncoder.encode(rawUr)
    }
    
    static func textToUr(_ data: Data) -> UR? {
        let cbor = CBOR.byteString(data.bytes).cborEncode().data
        
        return try? UR(type: "bytes", cbor: cbor)
    }
    
    static func psbtUrToBase64Text(_ ur: UR) -> String? {
        guard ur.type == "crypto-psbt", let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(bytes) = decodedCbor else {
                return nil
        }
        
        return Data(bytes).base64EncodedString()
    }
    
    static func bytesUrToText(_ ur: UR) -> String? {
        guard ur.type == "bytes", let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(bytes) = decodedCbor else {
                return nil
        }
        
        return Data(bytes).utf8
    }
    
    static func mnemonicToCryptoSeed(_ words: String) -> String? {
        guard let entropy = try? BIP39Mnemonic(words: words).entropy else { return nil }
        
        return URHelper.entropyToUr(data: entropy.data)
    }
    
    static func cryptoSeedToMnemonic(cryptoSeed: String) -> String? {
        guard let data = URHelper.urToEntropy(urString: cryptoSeed).data, let mnemonic = try? BIP39Mnemonic(entropy: BIP39Mnemonic.Entropy(data)) else { return nil }
        
        return mnemonic.words.joined(separator: " ")
    }
    
    static func urToEntropy(urString: String) -> (data: Data?, birthdate: UInt64?) {
        do {
            let ur = try URDecoder.decode(urString)
            let decodedCbor = try CBOR.decode(ur.cbor.bytes)
            guard case let CBOR.map(dict) = decodedCbor! else { return (nil, nil) }
            var data:Data?
            var birthdate:UInt64?
            for (key, value) in dict {
                switch key {
                case 1:
                    guard case let CBOR.byteString(byteString) = value else { fallthrough }
                    data = Data(byteString)
                case 2:
                    guard case let CBOR.unsignedInt(n) = value else { fallthrough }
                    birthdate = n
                default:
                    break
                }
            }
            return (data, birthdate)
        } catch {
            return (nil, nil)
        }
    }
    
    static func entropyToUr(data: Data) -> String? {
        let wrapper:CBOR = .map([
            .unsignedInt(1) : .byteString(data.bytes),
        ])
        let cbor = Data(wrapper.cborEncode())
        do {
            let rawUr = try UR(type: "crypto-seed", cbor: cbor)
            return UREncoder.encode(rawUr)
        } catch {
            return nil
        }
    }
    
    static func useInfo(_ map: [CBOR : CBOR]) -> (type: String?, network: String?) {
        var network = "main"
        var type = "btc"
        for (k, v) in map {
            switch k {
            case 1:
                // type
                switch v {
                case CBOR.unsignedInt(0):
                    type = "btc"
                case CBOR.unsignedInt(145):
                    type = "bcash"
                default:
                    type = "?"
                }
            case 2:
                // network
                switch v {
                case CBOR.unsignedInt(0):
                    network = "main"
                case CBOR.unsignedInt(1):
                    network = "test"
                default:
                    break
                }
            default:
                break
            }
        }
        
        return (type, network)
    }
    
    static func urToShard(sskrUr: String) -> String? {
        guard let ur = try? URDecoder.decode(sskrUr),
              let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(byteString) = decodedCbor else { return nil }
        return Data(byteString).hexString
    }
    
    static func urShardToShardData(sskrUr: String) -> Data? {
        guard let ur = try? URDecoder.decode(sskrUr),
              let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(byteString) = decodedCbor else { return nil }
        return byteString.data
    }
    
    static func extendedKeyToUr(key: HDKey) -> String? {
        var extendedKeyBase58String = ""
        var isPrivate = false
        var isMaster = false
        var cointype:UInt64 = 1
        
        if key.network == .mainnet {
            cointype = 0
        }
                
        let b58Data = Data(Base58.decode(extendedKeyBase58String))
        let depth = b58Data.subdata(in: Range(4...4))
        let parentFingerprint = b58Data.subdata(in: Range(5...8))
        let chaincode = b58Data.subdata(in: Range(13...44))
        let keydata = b58Data.subdata(in: Range(45...77))
        
        if let xprv = key.xpriv {
            extendedKeyBase58String = xprv
            isPrivate = true
            if depth.hexStrng == "00" { isMaster = true }
        } else {
            extendedKeyBase58String = key.xpub
        }
        
        var originsArray:[OrderedMapEntry] = []
        originsArray.append(.init(key: 1, value: .array([])))
        originsArray.append(.init(key: 3, value: .unsignedInt(UInt64(depth.hexString) ?? 0)))
        let originsWrapper = CBOR.orderedMap(originsArray)
        
        let useInfoWrapper:CBOR = .map([
            .unsignedInt(2) : .unsignedInt(cointype)
        ])
        
        guard let hexValue = UInt64(parentFingerprint.hexString, radix: 16) else { return nil }
        
        var hdkeyArray:[OrderedMapEntry] = []
        hdkeyArray.append(.init(key: 1, value: .boolean(isMaster)))
        hdkeyArray.append(.init(key: 2, value: .boolean(isPrivate)))
        hdkeyArray.append(.init(key: 3, value: .byteString([UInt8](keydata))))
        hdkeyArray.append(.init(key: 4, value: .byteString([UInt8](chaincode))))
        hdkeyArray.append(.init(key: 5, value: .tagged(CBOR.Tag(rawValue: 305), useInfoWrapper)))
        hdkeyArray.append(.init(key: 6, value: .tagged(CBOR.Tag(rawValue: 304), originsWrapper)))
        hdkeyArray.append(.init(key: 8, value: .unsignedInt(hexValue)))
        let hdKeyWrapper = CBOR.orderedMap(hdkeyArray)
        
        guard let rawUr = try? UR(type: "crypto-hdkey", cbor: hdKeyWrapper) else { return nil }
        
        return UREncoder.encode(rawUr)
    }
    
    static func cosignerToUr(_ cosigner: String) -> String? {
        let descriptorParser = DescriptorParser()
        let descriptor = "wsh(\(cosigner))"
        let descriptorStruct = descriptorParser.descriptor(descriptor)
        var key = descriptorStruct.accountXpub
        var cointype:UInt64 = 1
        var isPrivate = false
        var isMaster = false
        
        if descriptorStruct.accountXprv != "" {
            key = descriptorStruct.accountXprv
        }
        
        guard let hdkey = try? HDKey(base58: key) else { return nil }
        
        if hdkey.network == .mainnet {
            cointype = 0
        }
        
        /// Decodes our original extended key to base58 data.
        let b58 = Base58.decode(key)
        let b58Data = Data(b58)
        let depth = b58Data.subdata(in: Range(4...4))
        let parentFingerprint = b58Data.subdata(in: Range(5...8))
        let chaincode = b58Data.subdata(in: Range(13...44))
        let keydata = b58Data.subdata(in: Range(45...77))
        
        if let _ = hdkey.xpriv {
            isPrivate = true
            if depth.hexStrng == "00" { isMaster = true }
        }
                
        let arr = cosigner.split(separator: "]")
        
        guard arr.count > 0 else { return nil }
        
        var processedPath = "\(arr[0])".replacingOccurrences(of: "[", with: "")
        
        let arr2 = processedPath.split(separator: "/")
        
        guard arr.count > 0 else { return nil }
        
        processedPath = processedPath.replacingOccurrences(of: "\(arr2[0])", with: "m/")
        
        var originsArray:[OrderedMapEntry] = []
        originsArray.append(.init(key: 1, value: .array(origins(processedPath))))
        originsArray.append(.init(key: 2, value: .unsignedInt(UInt64(descriptorStruct.fingerprint, radix: 16) ?? 0)))
        originsArray.append(.init(key: 3, value: .unsignedInt(UInt64(depth.hexString) ?? 0)))
        let originsWrapper = CBOR.orderedMap(originsArray)
        
        let useInfoWrapper:CBOR = .map([
            .unsignedInt(2) : .unsignedInt(cointype)
        ])
        
        guard let hexValue = UInt64(parentFingerprint.hexString, radix: 16) else { return nil }
        
        var hdkeyArray:[OrderedMapEntry] = []
        hdkeyArray.append(.init(key: 1, value: .boolean(isMaster)))
        hdkeyArray.append(.init(key: 2, value: .boolean(isPrivate)))
        hdkeyArray.append(.init(key: 3, value: .byteString([UInt8](keydata))))
        hdkeyArray.append(.init(key: 4, value: .byteString([UInt8](chaincode))))
        hdkeyArray.append(.init(key: 5, value: .tagged(CBOR.Tag(rawValue: 305), useInfoWrapper)))
        hdkeyArray.append(.init(key: 6, value: .tagged(CBOR.Tag(rawValue: 304), originsWrapper)))
        hdkeyArray.append(.init(key: 8, value: .unsignedInt(hexValue)))
        let hdKeyWrapper = CBOR.orderedMap(hdkeyArray)
        
        guard let rawUr = try? UR(type: "crypto-hdkey", cbor: hdKeyWrapper) else { return nil }
        
        return UREncoder.encode(rawUr)
    }
    
    static func origins(_ path: String) -> [CBOR] {
        var cborArray:[CBOR] = []
        for (i, item) in path.split(separator: "/").enumerated() {
            if i != 0 && item != "m" {
                if item.contains("h") {
                    let processed = item.split(separator: "h")
                    
                    if let int = Int("\(processed[0])") {
                        let unsignedInt = CBOR.unsignedInt(UInt64(int))
                        cborArray.append(unsignedInt)
                        cborArray.append(CBOR.boolean(true))
                    }
                    
                } else if item.contains("'") {
                    let processed = item.split(separator: "'")
                    
                    if let int = Int("\(processed[0])") {
                        let unsignedInt = CBOR.unsignedInt(UInt64(int))
                        cborArray.append(unsignedInt)
                        cborArray.append(CBOR.boolean(true))
                    }
                } else {
                    if let int = Int("\(item)") {
                        let unsignedInt = CBOR.unsignedInt(UInt64(int))
                        cborArray.append(unsignedInt)
                        cborArray.append(CBOR.boolean(false))
                    }
                }
            }
        }
        
        return cborArray
    }
}


