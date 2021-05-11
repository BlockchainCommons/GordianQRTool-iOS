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
    
    static func textToUr(_ data: Data) -> UR? {
        let cbor = CBOR.byteString(data.bytes).cborEncode().data
        
        return try? UR(type: "bytes", cbor: cbor)
    }
    
    static func psbtUrToBase64Text(_ ur: UR) -> String? {
        guard let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(bytes) = decodedCbor else {
                return nil
        }
        
        return Data(bytes).base64EncodedString()
    }
    
    static func bytesUrToText(_ ur: UR) -> String? {
        guard let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
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
    
    // crypto-seed > mnemonic
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
    
    // mnemonic > crypto-seed
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
}


