//
//  ExportViewController.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices
import LibWally

class ExportViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UINavigationControllerDelegate {
    
    var id:UUID!
    
    @IBOutlet weak var labelOutlet: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareQrOutlet: UIButton!
    @IBOutlet weak var shareTextOutlet: UIButton!
    @IBOutlet weak var convertToUrOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        setTitleView()
        labelOutlet.text = ""
        textView.text = ""
        shareQrOutlet.alpha = 0
        shareTextOutlet.alpha = 0
        textView.alpha = 0
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
        #if DEBUG
            getQr()
        #else
            addAuth()
        #endif
    }
    
    @IBAction func convertToUrAction(_ sender: Any) {
        guard let text = textView.text else { return }
        
        let type = Parser.parse(text)
        
        if type == "Mnemonic" {
            guard let mnemonic = BIP39Mnemonic(text.processed()), let ur = URHelper.entropyToUr(data: mnemonic.entropy.data) else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = QRGenerator.getQRCode(textInput: ur)
                self.textView.text = ur
            }
        }
    }
    
    @IBAction func shareQr(_ sender: Any) {
        shareImage()
    }
    
    @IBAction func shareText(_ sender: Any) {
        shareString()
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Warning!", message: "Once you delete a QR it will be gone forever", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned vc = self] action in
                vc.deleteQr()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteQr() {
        let cd = CoreDataManager.sharedInstance
        cd.deleteEntity(id: id) { [unowned vc = self] (success, errorDescription) in
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                vc.showAlert(title: "Error", message: errorDescription ?? "error deleteing that QR")
            }
        }
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
            vc.labelOutlet.text = vc.reducedName(text: qr.label)
            
            guard let decryptedQr = Encryption.decrypt(qr.qrData), let text = String(data: decryptedQr, encoding: .utf8) else {
                return
            }
            
            DispatchQueue.main.async { [unowned vc = self] in
                vc.textView.text = text
                let image = QRGenerator.getQRCode(textInput: text)
                vc.imageView.image = image
                vc.shareTextOutlet.alpha = 1
                vc.shareQrOutlet.alpha = 1
                vc.textView.alpha = 1
                
                if !text.hasPrefix("ur:") {
                    self.convertToUrOutlet.alpha = 1
                } else {
                    self.convertToUrOutlet.alpha = 0
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
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in }))
            vc.present(alert, animated: true, completion: nil)
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
    
    private func reducedName(text: String) -> String {
        if text.count > 50 {
            let first = String(text.prefix(15))
            let last = String(text.suffix(15))
            return "\(first)...\(last)"
        } else {
            return text
        }
    }

}
