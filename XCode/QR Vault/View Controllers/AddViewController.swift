//
//  AddViewController.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class AddViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var initialLoad = Bool()
    var text = ""
    let qrScanner = QRScanner()
    let spinner = Spinner()
    var isTorchOn = Bool()
    @IBOutlet weak var imageView: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        spinner.add(vc: self, description: "")
        setTitleView()
        initialLoad = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        imageView.image = nil
        configureScanner()
        scanNow()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        qrScanner.stopScanner()
        text = ""
    }
    
    @IBAction func addAsText(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.qrScanner.stopScanner()
            vc.imageView.image = nil
            vc.qrScanner.imageView.image = nil
            vc.text = ""
            vc.performSegue(withIdentifier: "labelSegue", sender: vc)
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
            
            self.performSegue(withIdentifier: "seeBlurbFromScanner", sender: self)
        }
    }
        
    func configureScanner() {
        imageView.frame = view.frame
        imageView.isUserInteractionEnabled = true
        qrScanner.keepRunning = false
        qrScanner.vc = self
        qrScanner.imageView = imageView
        qrScanner.completion = { self.getQRCode() }
        qrScanner.didChooseImage = { self.didPickImage() }
        qrScanner.torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        qrScanner.uploadButton.addTarget(self, action: #selector(chooseQRCodeFromLibrary), for: .touchUpInside)
        isTorchOn = false
    }
    
    func addScannerButtons() {
        self.addBlurView(frame: CGRect(x: self.navigationController!.view.frame.maxX - 80,
                                       y: self.navigationController!.view.frame.maxY - 200,
                                       width: 70,
                                       height: 70), button: self.qrScanner.uploadButton)
        self.addBlurView(frame: CGRect(x: 10,
                                       y: self.navigationController!.view.frame.maxY - 200,
                                       width: 70,
                                       height: 70), button: self.qrScanner.torchButton)
    }
    
    func didPickImage() {
        addQr(text: qrScanner.qrString)
    }
    
    @objc func chooseQRCodeFromLibrary() {
        qrScanner.chooseQRCodeFromLibrary()
    }
    
    func addBlurView(frame: CGRect, button: UIButton) {
        button.removeFromSuperview()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.frame = frame
        blur.clipsToBounds = true
        blur.layer.cornerRadius = frame.width / 2
        blur.contentView.addSubview(button)
        self.imageView.addSubview(blur)
    }
    
    func scanNow() {
        qrScanner.scanQRCode()
        addScannerButtons()
        spinner.remove()
    }
    
    func getQRCode() {
        addQr(text: qrScanner.stringToReturn)
    }
    
    @objc func toggleTorch() {
        if isTorchOn {
            qrScanner.toggleTorch(on: false)
            isTorchOn = false
        } else {
            qrScanner.toggleTorch(on: true)
            isTorchOn = true
        }
    }
    
    private func addQr(text: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.qrScanner.stopScanner()
            vc.imageView.image = nil
            vc.qrScanner.imageView.image = nil
            vc.text = text
            vc.performSegue(withIdentifier: "labelSegue", sender: vc)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "labelSegue":
            if let vc = segue.destination as? LabelViewController {
                vc.text = text
            }
        default:
            break
        }
    }
    

}
