//
//  IntroViewController.swift
//  QR Vault
//
//  Created by Peter Denton on 5/11/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    var doneBlock : ((Bool) -> Void)?
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = """
            UR Vault creates a secure and redundant place to store all of your sensitive QR codes. Any QR code can be stored, but UR Vault is built especially to support Uniform Resources that are encoded as QRs, including seeds, HD keys, and account maps.

            UR Vault utilizes multiple layers of encryption, 2FA (two factor authentication), and your device's keychain to ensure that only you may ever access your data.

            UR Vault also creates secure resilience by automatically backing up your data to iCloud using backups that ​will sync to any other device where you are logged in with the same Apple ID. All data stored on the iCloud is fully encrypted with a private key that is itself encrypted and stored on your device's secure enclave. To ensure the app can sync across devices or easily be recovered on another device you must enable "keychain sync" under the iCloud settings on your devices.

            """
    }
    
    
    @IBAction func continueAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.dismiss(animated: true) {
                self.doneBlock!(true)
            }
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
