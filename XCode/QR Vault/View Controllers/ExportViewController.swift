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

class ExportViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let tap = UITapGestureRecognizer()
    var id:UUID!
    
    @IBOutlet weak var labelField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareQrOutlet: UIButton!
    @IBOutlet weak var shareTextOutlet: UIButton!
    @IBOutlet weak var convertToUrOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        labelField.delegate = self
        setTitleView()
        textView.text = ""
        shareQrOutlet.alpha = 0
        shareTextOutlet.alpha = 0
        textView.alpha = 0
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
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
    
    @IBAction func updateAction(_ sender: Any) {
        labelField.resignFirstResponder()
        
        guard labelField.text != "" else { return }
        
        promptToUpdateLabel()
    }
    
    private func promptToUpdateLabel() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Update label?", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [unowned vc = self] action in
                vc.updateLabel()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateLabel() {
        guard textView.text != "" else {
            showAlert(title: "Uh-oh", message: "There is no text to save")
            return
        }
        
        CoreDataManager.sharedInstance.updateEntity(id: id, keyToUpdate: "label", newValue: labelField.text!) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "There was a problem...", message: "We had an issue saving the updated label: \(errorDescription ?? "unknown error")")
                return
            }
            
            self.showAlert(title: "Label updated ✅", message: "")
        }
    }
    
    
    @IBAction func convertToUrAction(_ sender: Any) {
        guard let text = textView.text else { return }
        
        let type = Parser.parse(text)
        
        switch type {
        case "Mnemonic":
            guard let mnemonic = BIP39Mnemonic(text.processed()), let ur = URHelper.entropyToUr(data: mnemonic.entropy.data) else { fallthrough }
            
            DispatchQueue.main.async {
                self.imageView.image = QRGenerator.getQRCode(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        case "SSKR Shard":
            guard let hexData = Data(text.processed()), let ur = URHelper.shardToUr(data: hexData) else { fallthrough }
            
            DispatchQueue.main.async {
                self.imageView.image = QRGenerator.getQRCode(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        default:
            showAlert(title: "Type not yet supported", message: "Currently we only support converting bip39 mnemonics and SSKR shards to UR's.")
            break
        }
    }
    
    private func promptToUpdate() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Update?", message: "Updating to a UR will overwrite the existing QR code as UR format.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [unowned vc = self] action in
                vc.updateData()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateData() {
        guard textView.text != "" else {
            showAlert(title: "Uh-oh", message: "There is no text to save")
            return
        }
        
        let data = textView.text.utf8
        
        guard let encryptedData = Encryption.encrypt(data) else {
            showAlert(title: "Uh-oh", message: "We had an error encrypting that data...")
            return
        }
        
        CoreDataManager.sharedInstance.updateEntity(id: id, keyToUpdate: "qrData", newValue: encryptedData) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "There was a problem...", message: "We had an issue saving the encrypted data: \(errorDescription ?? "unknown error")")
                return
            }
            
            self.showAlert(title: "Success ✅", message: "QR has been updated to a UR, the data has been encrypted and stored securely to your device.")
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
            vc.labelField.text = vc.reducedName(text: qr.label)
            
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
    
    @objc func handleTap() {
        #if targetEnvironment(macCatalyst)
        #else
        DispatchQueue.main.async { [unowned vc = self] in
            vc.labelField.resignFirstResponder()
        }
        #endif
        
    }

}
