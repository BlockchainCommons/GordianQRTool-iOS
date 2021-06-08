//
//  QRGenerator.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit

class QRGenerator {
    
    class func generate(textInput: String) -> UIImage? {
        let data = textInput.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .ascii)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        let transform = CGAffineTransform(scaleX: 10.0, y: 10.0)
        
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        let grey = #colorLiteral(red: 0.07804081589, green: 0.09001789242, blue: 0.1025182381, alpha: 1)
        
        let colorParameters = [
            "inputColor0": CIColor(color: grey), // Foreground
            "inputColor1": CIColor(color: .white) // Background
        ]
        
        let colored = (output.applyingFilter("CIFalseColor", parameters: colorParameters))
        
        return renderedImage(uiImage: UIImage(ciImage: colored))
    }
    
    class func renderedImage(uiImage: UIImage) -> UIImage? {
        let image = uiImage
        let rect = CGRect(origin: .zero, size: image.size)
        
        return UIGraphicsImageRenderer(size: image.size, format: image.imageRendererFormat).image { _ in image.draw(in: rect) }
    }
    
}

