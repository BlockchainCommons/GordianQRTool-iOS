//
//  CameraPermissionsViewController.swift
//  QR Vault
//
//  Created by Peter Denton on 5/11/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPermissionsViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    var doneBlock : ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textView.text = """
            Gordian QR Tool works best when you give it permission to scan QR codes that you would like to save securely.

            You may scan static or animated QR codes. QR Tool is designed to work especially well with Uniform Resource encoding, but will work with any QR code.

            Please tap "Continue" to allow QR Tool to access your camera so that it can scan QR codes.
            """
    }
    
    @IBAction func getAccess(_ sender: Any) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
            guard let self = self else { return }
            
            guard granted else {
                self.dismissWithPermission(false)
                return
            }
            
            self.dismissWithPermission(true)
        })
    }
    
    private func dismissWithPermission(_ granted: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.dismiss(animated: true) {
                self.doneBlock!(granted)
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
