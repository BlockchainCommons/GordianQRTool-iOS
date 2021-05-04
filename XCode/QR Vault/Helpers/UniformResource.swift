//
//  UniformResource.swift
//  QR Vault
//
//  Created by Peter on 10/20/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import URKit

enum URHelper {
    
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
    
    static func psbtUrToBase64Text(_ ur: UR) -> String? {
        guard let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(bytes) = decodedCbor else {
                return nil
        }
        
        return Data(bytes).base64EncodedString()
    }
}


