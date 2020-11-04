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
    
    static func image(_ input: Data) -> UIImage {
        return LifeHashGenerator.generateSync(input)
    }
    
}
