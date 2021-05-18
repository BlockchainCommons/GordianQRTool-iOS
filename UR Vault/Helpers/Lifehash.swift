//
//  File.swift
//  QR Vault
//
//  Created by Peter on 10/20/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LifeHash
import UIKit

enum LifeHash {
    
    static func image(_ input: String) -> UIImage {
        let arr = input.split(separator: "#")
        var bare = ""
        
        if arr.count > 0 {
            bare = "\(arr[0])".replacingOccurrences(of: "'", with: "h")
        } else {
            bare = input.replacingOccurrences(of: "'", with: "h")
        }
                        
        return LifeHashGenerator.generateSync(bare, version: .version2)
    }
    
    static func hash(_ input: Data) -> Data? {
        return LifeHashGenerator.generateSync(input, version: .version2).pngData()
    }
    
    static func hash(_ input: String) -> Data? {
        return LifeHashGenerator.generateSync(input, version: .version2).pngData()
    }
    
    static func image(_ input: Data) -> UIImage? {
        return LifeHashGenerator.generateSync(input, version: .version2)
    }
    
}
