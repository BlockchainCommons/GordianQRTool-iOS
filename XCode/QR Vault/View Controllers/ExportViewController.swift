//
//  ExportViewController.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices

class ExportViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UINavigationControllerDelegate {
    
    var id:UUID!
    @IBOutlet weak var labelOutlet: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareQrOutlet: UIButton!
    @IBOutlet weak var shareTextOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        setTitleView()
        labelOutlet.text = ""
        textView.text = ""
        shareQrOutlet.alpha = 0
        shareTextOutlet.alpha = 0
        textView.alpha = 0
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 4
    }
    
    private func setTitleView() {
        let imageView = UIImageView(image: UIImage(named: "logo.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        addAuth()
    }
    
    @IBAction func shareQr(_ sender: Any) {
        shareImage()
    }
    
    @IBAction func shareText(_ sender: Any) {
        shareString()
    }
    
    private func getQr() {
        let cd = CoreDataManager.sharedInstance
        cd.retrieveEntity { [unowned vc = self] (entity, errorDescription) in
            if entity != nil {
                for e in entity! {
                    let str = QRStruct(dictionary: e)
                    if str.id == vc.id {
                        vc.loadData(qr: str)
                    }
                }
            }
        }
    }
    
    private func loadData(qr: QRStruct) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.labelOutlet.text = qr.label
            Encryption.decryptData(dataToDecrypt: qr.qrData) { (decryptedQr) in
                if decryptedQr != nil {
                    if let text = String(data: decryptedQr!, encoding: .utf8) {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.textView.text = text
                            let image = QRGenerator.getQRCode(textInput: text)
                            vc.imageView.image = image
                            vc.shareTextOutlet.alpha = 1
                            vc.shareQrOutlet.alpha = 1
                            vc.textView.alpha = 1
                        }
                    }
                }
            }
        }
    }
    
    private func shareString() {
        DispatchQueue.main.async { [unowned vc = self] in
            let textToShare = [vc.textView.text!]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityViewController, animated: true) {}
        }
    }
    
    private func shareImage() {
        DispatchQueue.main.async { [unowned vc = self] in
            let imageToShare = [vc.imageView.image!]
            let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityViewController, animated: true) {}
        }
    }
    
    private func addAuth() {
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return self.view.window!
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
            
        case _ as ASAuthorizationAppleIDCredential:
            
            let authorizationProvider = ASAuthorizationAppleIDProvider()
            
            if let usernameData = KeyChain.load(key: "userIdentifier") {
                
                if let username = String(data: usernameData, encoding: .utf8) {
                    
                    authorizationProvider.getCredentialState(forUserID: username) { [unowned vc = self] (state, error) in
                        
                        switch (state) {
                            
                        case .authorized:
                            print("Account Found - Signed In")
                            vc.getQr()
                            
                        case .revoked:
                            print("No Account Found")
                            fallthrough
                            
                        case .notFound:
                            print("No Account Found")
                            
                        default:
                            break
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            break
            
        }
        
    }

}
