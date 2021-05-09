//
//  SponsorViewController.swift
//  QR Vault
//
//  Created by Peter on 09/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class SponsorViewController: UIViewController {

    @IBOutlet weak var monthlyOutlet: UIButton!
    @IBOutlet weak var donateOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monthlyOutlet.layer.cornerRadius = 8
        donateOutlet.layer.cornerRadius = 8
    }
    
    @IBAction func sponsorAction(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://github.com/BlockchainCommons")!) { (Bool) in }
    }
    
    @IBAction func donateAction(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://www.blockchaincommons.com")!) { (Bool) in }
    }
    
    @IBAction func close(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.dismiss(animated: true, completion: nil)
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
