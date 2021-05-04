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
    
    @IBOutlet weak private var lifehashImageView: UIImageView!
    @IBOutlet weak private var labelField: UITextField!
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textView: UITextView!
    @IBOutlet weak private var shareQrOutlet: UIButton!
    @IBOutlet weak private var shareTextOutlet: UIButton!
    @IBOutlet weak private var backgroundLabelView: UIVisualEffectView!
    @IBOutlet weak private var backgroundQrView: UIVisualEffectView!
    @IBOutlet weak private var convertToUrOutlet: UIButton!
    @IBOutlet weak private var backgroundTextView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        labelField.delegate = self
        setTitleView()
        textView.text = ""
        shareQrOutlet.alpha = 0
        shareTextOutlet.alpha = 0
        textView.alpha = 0
        backgroundQrView.clipsToBounds = true
        backgroundQrView.layer.cornerRadius = 8
        backgroundLabelView.clipsToBounds = true
        backgroundLabelView.layer.cornerRadius = 8
        backgroundTextView.clipsToBounds = true
        backgroundTextView.layer.cornerRadius = 8
        convertToUrOutlet.showsTouchWhenHighlighted = true
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
        load()
    }
    
    private func load() {
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Update label?", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.updateLabel()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateLabel() {
        guard textView.text != "" else {
            showAlert(title: "Uh-oh", message: "There is no text to save")
            return
        }
        
        CoreDataService.updateEntity(id: id, keyToUpdate: "label", newValue: labelField.text!) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "There was a problem...", message: "We had an issue saving the updated label: \(errorDescription ?? "unknown error")")
                return
            }
            
            self.showAlert(title: "Label updated ✅", message: "")
        }
    }
    
    @IBAction func convertAction(_ sender: Any) {
        guard let text = textView.text else { return }
        
        let type = Parser.parse(text)
        
        switch type {
        case "Mnemonic":
            guard let mnemonic = try? BIP39Mnemonic(words: text.processed()), let ur = URHelper.entropyToUr(data: mnemonic.entropy.data) else { fallthrough }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.imageView.image = QRGenerator.getQRCode(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        case "SSKR Shard":
            guard let hexData = Data(base64Encoded: text.processed()), let ur = URHelper.shardToUr(data: hexData) else { fallthrough }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Update?", message: "Updating to a UR will overwrite the existing QR code as UR format.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.updateData()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.getQr()
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
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
        
        CoreDataService.updateEntity(id: id, keyToUpdate: "qrData", newValue: encryptedData) { [weak self] (success, errorDescription) in
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Warning!", message: "Once you delete a QR it will be gone forever", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.deleteQr()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteQr() {
        CoreDataService.deleteEntity(id: id) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            if success {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                self.showAlert(title: "Error", message: errorDescription ?? "error deleteing that QR")
            }
        }
    }
    
    private func getQr() {
        CoreDataService.retrieveEntity { [weak self] (entity, errorDescription) in
            guard let self = self else { return }
            
            guard let entity = entity else { return }
            
            for e in entity {
                let str = QRStruct(dictionary: e)
                if str.id == self.id {
                    self.loadData(qr: str)
                }
            }
        }
    }
    
    private func loadData(qr: QRStruct) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.labelField.text = self.reducedName(text: qr.label)
            
            guard let decryptedQr = Encryption.decrypt(qr.qrData), let text = String(data: decryptedQr, encoding: .utf8) else {
                return
            }
            
            self.textView.text = text
            let image = QRGenerator.getQRCode(textInput: text)
            self.imageView.image = image
            self.shareTextOutlet.alpha = 1
            self.shareQrOutlet.alpha = 1
            self.textView.alpha = 1
            
            if !text.hasPrefix("ur:") {
                self.convertToUrOutlet.alpha = 1
            } else {
                self.convertToUrOutlet.alpha = 0
            }
            
            let type = self.parse(qr.qrData)
            
            if type == "Account Map" {
                if let descData = self.descriptor(qr.qrData) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.lifehashImageView.image = LifeHash.image(descData)
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.imageView.image = LifeHash.image(qr.qrData)
                    }
                }
            } else {
                self.lifehashImageView.image = LifeHash.image(qr.qrData)
            }
        }
    }
    
    private func parse(_ data: Data) -> String {
        guard let decryptedQr = Encryption.decrypt(data), let item = String(data: decryptedQr, encoding: .utf8) else {
            return ""
        }
        
        return Parser.parse(item)
    }
    
    private func descriptor(_ data: Data) -> Data? {
        guard let decryptedQr = Encryption.decrypt(data), let item = String(data: decryptedQr, encoding: .utf8) else {
            return nil
        }
        
        guard let data = item.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
            let descriptor = dict["descriptor"] as? String,
            let _ = dict["blockheight"] as? Int else {
                return nil
        }
        
        return descriptor.utf8
    }
    
    private func shareString() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let textToShare = [self.textView.text!]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            self.present(activityViewController, animated: true) {}
        }
    }
    
    private func shareImage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let imageToShare = [self.imageView.image!]
            let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            self.present(activityViewController, animated: true) {}
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
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
                    authorizationProvider.getCredentialState(forUserID: username) { [weak self] (state, error) in
                        guard let self = self else { return }
                        
                        switch (state) {
                        case .authorized:
                            print("Account Found - Signed In")
                            self.getQr()
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.labelField.resignFirstResponder()
        }
        #endif
        
    }

}
