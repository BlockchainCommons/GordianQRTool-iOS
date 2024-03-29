//
//  LabelViewController.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class LabelViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    var text = ""
    let tap = UITapGestureRecognizer()
    @IBOutlet weak var saveOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var confirmLabelOutlet: UILabel!
    @IBOutlet weak var labelView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        textView.delegate = self
        labelView.delegate = self
        textView.isEditable = false
        textView.isSelectable = true
        setTitleView()
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        saveOutlet.layer.cornerRadius = 8
        labelView.returnKeyType = .default
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 4
        
        labelView.layer.borderWidth = 1.0
        labelView.layer.borderColor = UIColor.darkGray.cgColor
        labelView.clipsToBounds = true
        labelView.layer.cornerRadius = 4
        
        
        labelView.text = ""
        
        if text != "" {
            textView.text = text
        } else {
            confirmLabelOutlet.text = "Add text to convert into a QR:"
            textView.text = ""
            textView.isEditable = true
            textView.autocorrectionType = .no
            textView.autocapitalizationType = .none
            textView.returnKeyType = .default
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
            
            self.performSegue(withIdentifier: "seeBlurbFromTextEntry", sender: self)
        }
    }
    
    @objc func handleTap() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.labelView.resignFirstResponder()
            vc.textView.resignFirstResponder()
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if labelView.text != "" && textView.text != "" {
            saveNow()
        } else {
            if labelView.text == "" {
                shakeAlert(viewToShake: labelView)
            }
            if textView.text == "" {
                shakeAlert(viewToShake: textView)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            shakeAlert(viewToShake: textField)
        }
        if textView.text == "" {
            shakeAlert(viewToShake: textView)
        }
        textField.resignFirstResponder()
        return true
    }
    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if(text == "\n") {
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
    
//    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
//        return false
//    }
    
    private func shakeAlert(viewToShake: UIView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - 10, y: viewToShake.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + 10, y: viewToShake.center.y))
        DispatchQueue.main.async {
            viewToShake.layer.add(animation, forKey: "position")
        }
    }
    
    private func saveNow() {
        guard let label = labelView.text, let qrData = (textView.text).data(using: .utf8) else {
            showAlert(title: "Error!", message: "We had an error getting your label or converting your text to a QR. Please try again.")
            return
        }
        
        guard let encryptedQr = Encryption.encrypt(qrData) else {
            showAlert(title: "Error!", message: "We had an error encrypting your QR code")
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
        CoreDataService.saveEntity(dict: dict) { [unowned vc = self] (success, errorDescription) in
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.text = ""
                    vc.textView.text = ""
                    vc.labelView.text = ""
                    vc.navigationController?.popToRootViewController(animated: true)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
