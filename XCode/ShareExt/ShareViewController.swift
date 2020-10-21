//
//  ShareViewController.swift
//  ShareExt
//
//  Created by Peter on 08/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
        var imageFound = false
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    // This is an image. We'll load it, then place it in our image view.
                    //weak var weakImageView = self.imageView
                    provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (imageURL, error) in
                        OperationQueue.main.addOperation { [unowned vc = self] in
                            if let imageURL = imageURL as? URL {
                                if let image = UIImage(data: try! Data(contentsOf: imageURL)) {
                                    vc.selectedImage = image
                                }
                            } else if let image = imageURL as? UIImage {
                                vc.selectedImage = image
                            }
                        }
                    })
                    
                    imageFound = true
                    break
                }
            }
            
            if (imageFound) {
                // We only handle one image, so stop looking for more.
                break
            }
        }
    }
    
    private func save(image: UIImage) {
        
        let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let ciImage:CIImage = CIImage(image: image)!
        var qrCodeLink = ""
        let features = detector.features(in: ciImage)
        for feature in features as! [CIQRCodeFeature] {
            qrCodeLink += feature.messageString!
        }
        saveNow(label: contentText ?? "No label", qrString: qrCodeLink)
    }
    
    private func saveNow(label: String, qrString: String) {
        guard let data = qrString.data(using: .utf8), let encryptedQr = Encryption.encrypt(data) else {
            showAlert(title: "Error!", message: "We had an error getting your label or converting your text to a QR. Please try again.")
            
            return
        }
        
        var dict = [String:Any]()
        dict["qrData"] = encryptedQr
        dict["id"] = UUID()
        dict["label"] = label
        dict["dateAdded"] = Date()
        saveToCoreData(dict: dict)
    }
    
    private func saveToCoreData(dict: [String:Any]) {
        let cd = CoreDataManager.sharedInstance
        cd.saveEntity(dict: dict) { [unowned vc = self] (success, errorDescription) in
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    print("saved success")
                    vc.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
            } else {
                vc.showAlert(title: "Error", message: "We had an error saving your QR: \(errorDescription ?? "unknown error")")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in }))
            vc.present(alert, animated: true, completion: nil)
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        if let _ = selectedImage {
            if !contentText.isEmpty {
                return true
            }
        }
            
        return false
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        
        save(image: self.selectedImage!)
        
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
