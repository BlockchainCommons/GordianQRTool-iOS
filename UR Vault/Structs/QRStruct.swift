//
//  QRStruct.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct QRStruct: CustomStringConvertible {
    
    let label:String
    let dateAdded:Date
    let qrText:String
    let id:UUID
    let qrData:Data
    let type:String?
    
    init(dictionary: [String: Any]) {
        
        self.label = dictionary["label"] as? String ?? "No label"
        self.dateAdded = dictionary["dateAdded"] as! Date
        self.qrText = dictionary["qrText"] as? String ?? ""
        self.id = dictionary["id"] as! UUID
        self.qrData = dictionary["qrData"] as! Data
        self.type = dictionary["type"] as? String
    }
    
    public var description: String {
        return ""
    }
    
}
