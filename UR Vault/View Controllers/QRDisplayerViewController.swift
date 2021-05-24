//
//  QRDisplayerViewController.swift
//  QR Vault
//
//  Created by Peter Denton on 5/10/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import URKit

class QRDisplayerViewController: UIViewController {
    
    var qrStruct:QRStruct?
    var text = ""
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    var headerText = ""
    var descriptionText = ""
    var headerIcon: UIImage!
    //var spinner = ConnectingView()
    //let qrGenerator = QRGenerator()
    private let spinner = UIActivityIndicatorView(style: .medium)

    
    private var encoder:UREncoder!
    private var timer: Timer?
    private var parts = [String]()
    private var ur: UR!
    private var partIndex = 0
    
    @IBOutlet weak private var animateOutlet: UIButton!
    @IBOutlet weak private var headerLabel: UILabel!
    @IBOutlet weak private var lifehashImageView: UIImageView!
    @IBOutlet weak private var qrImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        headerLabel.text = headerText
        qrImageView.isUserInteractionEnabled = true
        tapQRGesture = UITapGestureRecognizer(target: self, action: #selector(shareQRCode(_:)))
        qrImageView.addGestureRecognizer(tapQRGesture)
        lifehashImageView.layer.magnificationFilter = .nearest
    }
    
    override func viewDidAppear(_ animated: Bool) {
        spinner.center = qrImageView.center
        view.addSubview(spinner)
        spinner.startAnimating()
        
        guard let qr = qrStruct else { return }
        
        loadData(qr: qr)
    }
    
    @IBAction func animateAction(_ sender: Any) {
        qrImageView.image = nil
        spinner.center = qrImageView.center
        view.addSubview(spinner)
        spinner.startAnimating()
        convertToUrParts()
        animateOutlet.alpha = 0
    }
    
    
    @IBAction func closeAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.qrStruct = nil
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    private func loadData(qr: QRStruct) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.headerLabel.text = qr.label
            
            guard let decryptedQr = Encryption.decrypt(qr.qrData),
                  let decryptedText = String(data: decryptedQr, encoding: .utf8),
                  let lifehash = DeriveLifehash.lifehash(qr.qrData) else {
                
                return
            }
            
            self.text = decryptedText
            
            if self.text.hasPrefix("ur:") {
                self.text = self.text.uppercased()
            }
            
            self.lifehashImageView.image = lifehash
            
            if let image = QRGenerator.generate(textInput: decryptedText) {
                self.qrImageView.image = image
                self.spinner.stopAnimating()
                self.spinner.removeFromSuperview()
            } else {
                self.animateOutlet.alpha = 0
                self.convertToUrParts()
            }
        }
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        let objectsToShare = [qrImageView.image]
        let activityController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        }
        self.present(activityController, animated: true) {}
    }
    
    
    
    private func qR() -> UIImage? {
        
        return QRGenerator.generate(textInput: text)
    }
    
    private func convertToUrParts() {
        var uR:UR?
        
        if let b64 = Data(base64Encoded: text), let urCheck = URHelper.psbtUr(b64) {
            uR = urCheck
        } else if let bytesUr = URHelper.textToUr(text.utf8) {
            uR = bytesUr
        }
            
        guard let ur = uR else { return }
        
        let encoder = UREncoder(ur, maxFragmentLen: 250)
        weak var timer: Timer?
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let part = encoder.nextPart()
            let index = encoder.seqNum
            
            if index <= encoder.seqLen {
                self.parts.append(part.uppercased())
            } else {
                self.spinner.stopAnimating()
                self.spinner.removeFromSuperview()
                timer?.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.animate), userInfo: nil, repeats: true)
            }
        }
    }
    
    private func showQR(_ string: String) {
        if let image = QRGenerator.generate(textInput: string) {
            qrImageView.image = image
        }
    }
    
    @objc func animate() {
        showQR(parts[partIndex])
        
        if partIndex < parts.count - 1 {
            partIndex += 1
        } else {
            partIndex = 0
        }
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
