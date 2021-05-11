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
            UR Vault is a specialist app designed to create a secure and redundant place for all your sensitive QR codes to be stored.

            UR Vault utilizes multiple layers of encryption, 2FA (two factor authentication) along with your devices keychain to ensure only you may ever access your data.

            UR Vault automatically creates fully encrypted iCloud backups and will sync to any other device where you are logged in with the same Apple ID.

            All data stored on the iCloud is encrypted with a private key which is itself encrypted and stored on your device secure enclave. To ensure the app can sync across devices or easily be recovered on another device you must enable "keychain sync" under your iCloud settings on your devices.
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
