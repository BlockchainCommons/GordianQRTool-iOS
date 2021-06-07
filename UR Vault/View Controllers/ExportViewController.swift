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

class ExportViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    let tap = UITapGestureRecognizer()
    var qrStruct:QRStruct?
    
    @IBOutlet weak var labelTextView: UITextView!
    @IBOutlet weak private var launchSafariOutlet: UIButton!
    @IBOutlet weak private var lifehashImageView: UIImageView!
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textView: UITextView!
    @IBOutlet weak private var shareQrOutlet: UIButton!
    @IBOutlet weak private var shareTextOutlet: UIButton!
    @IBOutlet weak private var backgroundLabelView: UIVisualEffectView!
    @IBOutlet weak private var backgroundQrView: UIVisualEffectView!
    @IBOutlet weak private var convertToUrOutlet: UIButton!
    @IBOutlet weak private var backgroundTextView: UIVisualEffectView!
    @IBOutlet weak private var backgroundTypeView: UIVisualEffectView!
    @IBOutlet weak private var typeTextField: UITextField!
    @IBOutlet weak private var dateAddedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        labelTextView.delegate = self
        typeTextField.delegate = self
        setTitleView()
        textView.text = ""
        launchSafariOutlet.alpha = 0
        shareQrOutlet.alpha = 0
        shareTextOutlet.alpha = 0
        textView.alpha = 0
        roundCorners(backgroundTypeView)
        roundCorners(backgroundQrView)
        roundCorners(backgroundLabelView)
        roundCorners(backgroundTextView)
        
        labelTextView.layer.borderWidth = 1.0
        labelTextView.layer.borderColor = UIColor.darkGray.cgColor
        labelTextView.clipsToBounds = true
        labelTextView.layer.cornerRadius = 4
        
        convertToUrOutlet.showsTouchWhenHighlighted = true
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        lifehashImageView.layer.magnificationFilter = .nearest
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIScene.willDeactivateNotification, object: nil)
        
        load()
    }
    
    @IBAction func launchSafariAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let text = self.textView.text else { return }
            
            guard let url = URL(string: text) else { return }
            UIApplication.shared.open(url)
        }
        
    }
    
    
    @objc func appMovedToBackground() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.textView.text = ""
            self.imageView.image = nil
            self.qrStruct = nil
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    private func roundCorners(_ view: UIView) {
        DispatchQueue.main.async {
            view.clipsToBounds = true
            view.layer.cornerRadius = 8
        }
    }
    
    private func setTitleView() {
        let imageView = UIImageView(image: UIImage(named: "logo.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(logoTapped))
        imageView.addGestureRecognizer(tapRecognizer)
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
    }
    
    @objc func logoTapped() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "seeBlurbFromExportView", sender: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    private func load() {
        loadData(qr: qrStruct)
    }
    
    @IBAction func updateAction(_ sender: Any) {
        labelTextView.resignFirstResponder()
        
        guard labelTextView.text != "" else { return }
        
        self.updateLabel()
    }
    
    @IBAction func updateTypeAction(_ sender: Any) {
        typeTextField.resignFirstResponder()
        
        guard typeTextField.text != "" else { return }
        
        self.updateType()
    }
    
    private func updateType() {
        guard typeTextField.text != "", let id = qrStruct?.id else {
            showAlert(title: "Uh-oh", message: "There is no text to save")
            return
        }
        
        CoreDataService.updateEntity(id: id, keyToUpdate: "type", newValue: typeTextField.text!) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "There was a problem...", message: "We had an issue saving the updated type: \(errorDescription ?? "unknown error")")
                return
            }
            
            self.showAlert(title: "", message: "Type updated ✓")
        }
    }
    
    private func updateLabel() {
        guard textView.text != "", let id = qrStruct?.id else {
            showAlert(title: "Uh-oh", message: "There is no text to save")
            return
        }
        
        CoreDataService.updateEntity(id: id, keyToUpdate: "label", newValue: labelTextView.text!) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "There was a problem...", message: "We had an issue saving the updated label: \(errorDescription ?? "unknown error")")
                return
            }
            
            self.showAlert(title: "Label updated ✅", message: "")
        }
    }
    
    private func setType(_ qr: QRStruct) {
        guard let type = qr.type else {
            guard let text = textView.text else { return }
            
            let result = Parser.parse(text)
            
            self.setTypeText(result)
            
            return
        }
        
        self.setTypeText(type)
    }
    
    private func setTypeText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.typeTextField.text = text
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
                
                self.imageView.image = QRGenerator.generate(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        case "SSKR Shard":
            guard let hexData = Data(base64Encoded: text.processed()), let ur = URHelper.shardToUr(data: hexData) else { fallthrough }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.imageView.image = QRGenerator.generate(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        case "hdkey":
            guard let hdkey = try? HDKey(base58: text.condenseWhitespace()) else { fallthrough }
        
            guard let ur = URHelper.extendedKeyToUr(key: hdkey) else { fallthrough }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.imageView.image = QRGenerator.generate(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        case "cosigner":
            guard let ur = URHelper.cosignerToUr(text.condenseWhitespace()) else { fallthrough }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.imageView.image = QRGenerator.generate(textInput: ur)
                self.textView.text = ur
            }
            
            promptToUpdate()
            
        default:
            showAlert(title: "Type not yet supported.", message: "Currently we only support converting bip39 mnemonics, SSKR shards, cosigners, and extended keys to UR's.")
            break
        }
    }
    
    private func promptToUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Update?", message: "Updating to a UR will overwrite the existing data as UR format.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.updateData()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.loadData(qr: self.qrStruct)
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateData() {
        guard textView.text != "", let id = qrStruct?.id else {
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
        guard let id = qrStruct?.id else { return }
        
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
    
    private func loadData(qr: QRStruct?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let qr = qr else { return }
            
            self.labelTextView.text = qr.label
            
            guard let decryptedQr = Encryption.decrypt(qr.qrData), var text = String(data: decryptedQr, encoding: .utf8) else {
                return
            }
            
            self.textView.text = text
            
            if text.hasPrefix("ur:") {
                text = text.uppercased()
            }
            
            if text.hasPrefix("http://") || text.hasPrefix("https://") {
                self.launchSafariOutlet.alpha = 1
            }
            
            let image = QRGenerator.generate(textInput: text)
            self.imageView.image = image
            self.shareTextOutlet.alpha = 1
            self.shareQrOutlet.alpha = 1
            self.textView.alpha = 1
            
            if !text.hasPrefix("UR:") {
                self.convertToUrOutlet.alpha = 1
            } else {
                self.convertToUrOutlet.alpha = 0
            }
            
            self.dateAddedLabel.text = "Added: \(self.format(date: qr.dateAdded))"
            self.lifehashImageView.image = DeriveLifehash.lifehash(qr.qrData)
            
            self.setType(qr)
        }
    }
    
    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
                            self.loadData(qr: self.qrStruct)
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
    
//    private func reducedName(text: String) -> String {
//        if text.count > 50 {
//            let first = String(text.prefix(15))
//            let last = String(text.suffix(15))
//            return "\(first)...\(last)"
//        } else {
//            return text
//        }
//    }
    
    @objc func handleTap() {
        #if targetEnvironment(macCatalyst)
        #else
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.labelTextView.resignFirstResponder()
            self.typeTextField.resignFirstResponder()
        }
        #endif
        
    }

}
