//
//  PromptForAuthViewController.swift
//  QR Vault
//
//  Created by Peter Denton on 5/11/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices

class PromptForAuthViewController: UIViewController, UINavigationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    var doneBlock : ((Bool) -> Void)?

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = """
            UR Vault always encrypts your data before saving it and uses Apple's native 2FA (two factor authentication) to ensure that only you can decrypt and access that information.

            Upon your first use of UR Vault, you will need to "Sign in with Apple", then every time you launch the app you will again be prompted to "Sign in with Apple", to ensure that only you can access and decrypt your data. Your Apple ID information is only used by the app, not shared with Blockchain Commons!

            """
    }
    
    @IBAction func closeAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addAuthAction(_ sender: Any) {
        addAuth()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    private func addAuth() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case _ as ASAuthorizationAppleIDCredential:
            switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                DispatchQueue.main.async {
                    if let userIdentifier = appleIDCredential.user.data(using: .utf8) {
                        let status = KeyChain.save(key: "userIdentifier", data: userIdentifier)
                        if status == 0 {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                self.dismiss(animated: true) {
                                    self.doneBlock!(true)
                                }
                                
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
                                self.dismiss(animated: true) {
                                    self.doneBlock!(false)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            self.dismiss(animated: true) {
                                self.doneBlock!(false)
                            }
                        }
                    }
                }
            default:
                break
            }
        default:
            break
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
