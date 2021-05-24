//
//  HomeViewController.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices
import LibWally
import AVFoundation

class HomeViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @IBOutlet weak private var homeTable: UITableView!
    private var qrToExport:QRStruct!
    private var idToDelete:UUID!
    private var qrArray = [[String:Any]]()
    private var qrStruct:QRStruct?
    private var editButton = UIBarButtonItem()
    private let dateFormatter = DateFormatter()
    private var isDeleting = Bool()
    private var indPath:IndexPath!
    private var authorized = false
    private var refreshControl = UIRefreshControl()
    var textToAdd = ""
    var initialLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if KeyChain.load(key: "hasUpdated") == nil {
            let _ = KeyChain.remove(key: "privateKey")
            KeyChain.removeAll()
            CoreDataService.deleteAllData(completion: { success in })
            let _ = KeyChain.save(key: "hasUpdated", data: "true".utf8)
        }
        
        navigationController?.delegate = self
        homeTable.delegate = self
        homeTable.dataSource = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        homeTable.addSubview(refreshControl)
        
        setTitleView()
        homeTable.tableFooterView = UIView(frame: CGRect.zero)
        editButton = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(editNodes))
        
        NotificationCenter.default.addObserver(self, selector: #selector(lockApp), name: .appBackgrounded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unlock), name: .appActivated, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if initialLoad {
            initialLoad = false
            firstTime()
        } else {
            loadData()
        }
    }
    
    @IBAction func sortAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Sort Items", message: "", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "By type", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.sortByType()
            }))
            
            alert.addAction(UIAlertAction(title: "By label", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.sortByName()
            }))
            
            alert.addAction(UIAlertAction(title: "By date added", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.sortByDate()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func sortByDate() {
        UserDefaults.standard.setValue(false, forKey: "sortByType")
        UserDefaults.standard.setValue(false, forKey: "sortByName")
        loadData()
    }
    
    private func sortByType() {
        UserDefaults.standard.setValue(true, forKey: "sortByType")
        UserDefaults.standard.setValue(false, forKey: "sortByName")
        loadData()
    }
    
    private func sortByName() {
        UserDefaults.standard.setValue(false, forKey: "sortByType")
        UserDefaults.standard.setValue(true, forKey: "sortByName")
        loadData()
    }
    
    
    @objc func lockApp() {
        authorized = false
        qrArray.removeAll()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.homeTable.reloadData()
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        if let _ = KeyChain.load(key: "userIdentifier"), authorized {
            loadData()
        } else {
            addAuth()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func unlock() {
        if !initialLoad {
            addAuth()
        }
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        if let _ = KeyChain.load(key: "userIdentifier"), authorized {
            loadData()
        } else {
            addAuth()
        }
    }
    
    @IBAction func scanQrAction(_ sender: Any) {
        if let _ = KeyChain.load(key: "userIdentifier"), authorized {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                showScanner()
            } else {
                prommptForCameraPermissions()
            }
        } else {
            addAuth()
        }
    }
    
    private func prommptForCameraPermissions() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToPromptForCameraPermissions", sender: self)
        }
    }
    
    private func showScanner() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToScanQr", sender: self)
        }
    }
    
    
    @IBAction func pasteAction(_ sender: Any) {
        if let _ = KeyChain.load(key: "userIdentifier"), authorized {
            if let data = UIPasteboard.general.data(forPasteboardType: "com.apple.traditional-mac-plain-text") {
                guard let string = String(bytes: data, encoding: .utf8) else { return }
                
                self.textToAdd = string
                self.segueToAddLabel()
            } else if let string = UIPasteboard.general.string {
                
                self.textToAdd = string
                self.segueToAddLabel()
                
            } else if UIPasteboard.general.hasImages {
                if let image = UIPasteboard.general.image {
                    let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                    let ciImage:CIImage = CIImage(image: image)!
                    var qrCodeLink = ""
                    let features = detector.features(in: ciImage)
                    for feature in features as! [CIQRCodeFeature] {
                        qrCodeLink += feature.messageString!
                    }
                    self.textToAdd = qrCodeLink
                    self.segueToAddLabel()
                }
            } else {
                UR_Vault.showAlert(self, "", "Whatever you have pasted does not seem to be valid text.")
            }
        } else {
            addAuth()
        }
    }
    
    private func segueToAddLabel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "addLabelSegue", sender: self)
        }
    }
    
    
    private func loadData() {
        if authorized {
            CoreDataService.retrieveEntity { [weak self] (qrs, errorDescription) in
                guard let self = self else { return }
                
                guard var qrsArray = qrs, qrsArray.count > 0 else { return }
                
                self.qrArray.removeAll()
                
                if let sortByType = UserDefaults.standard.object(forKey: "sortByType") as? Bool, sortByType {
                    
                    for (i, qr) in qrsArray.enumerated() {
                        if (qr["type"] as? String) == nil {
                            qrsArray[i]["type"] = self.parse(qr["qrData"] as! Data)
                        }
                    }
                    
                    qrsArray = qrsArray.sorted{ ($0["type"] as? String ?? "unknown").lowercased().condenseWhitespace() < ($1["type"] as? String ?? "unknown").lowercased().condenseWhitespace() }
                    
                } else if let sortByName = UserDefaults.standard.object(forKey: "sortByName") as? Bool, sortByName {
                    qrsArray = qrsArray.sorted{ ($0["label"] as? String ?? "").lowercased().condenseWhitespace() < ($1["label"] as? String ?? "").lowercased().condenseWhitespace() }
                    
                } else {
                    qrsArray = qrsArray.sorted{ ($0["dateAdded"] as? Date ?? Date()) > ($1["dateAdded"] as? Date ?? Date()) }
                    
                }
                
                for (i, qr) in qrsArray.enumerated() {
                    self.qrArray.append(qr)
                    if i + 1 == qrsArray.count {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            self.homeTable.reloadData()
                        }
                    }
                }
            }
        } else {
            addAuth()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if qrArray.count > 0 {
            return qrArray.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if qrArray.count == 0 {
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath)
            emptyCell.selectionStyle = .none
            emptyCell.textLabel?.numberOfLines = 0
            
            CoreDataService.retrieveEntity { (encryptedData, errorDescription) in
                if encryptedData != nil {
                    emptyCell.textLabel?.text = "Authenticate to access your data"
                } else {
                    emptyCell.textLabel?.text = "Tap the paste or scan button to add a QR code"
                }
            }
            
            return emptyCell
            
        } else {
            let qrCell = tableView.dequeueReusableCell(withIdentifier: "qrCell", for: indexPath)
            qrCell.selectionStyle = .none
            
            let dict = qrArray[indexPath.section]
            let str = QRStruct(dictionary: dict)
            
            let label = qrCell.viewWithTag(1) as! UILabel
            let date = qrCell.viewWithTag(2) as! UILabel
            let typeLabel = qrCell.viewWithTag(3) as! UILabel
            let typeBackground = qrCell.viewWithTag(4)!
            
            let imageView = qrCell.viewWithTag(5) as! UIImageView
            imageView.layer.magnificationFilter = .nearest
            
            let qrExportButton = qrCell.viewWithTag(6) as! UIButton
            let detailButton = qrCell.viewWithTag(7) as! UIButton
            
            typeLabel.textAlignment = .center
            typeBackground.layer.cornerRadius = 8
            
            label.text = str.label
            date.text = formatDate(date: str.dateAdded)
            imageView.image = DeriveLifehash.lifehash(str.qrData)
            
            if str.type != nil {
                typeLabel.alpha = 1
                typeLabel.text = str.type
            } else {
                let type = parse(str.qrData)

                if type != "" {
                    typeLabel.alpha = 1
                    typeLabel.text = type
                } else {
                    typeLabel.alpha = 1
                    typeLabel.text = "unknown"
                }
            }
            
            qrExportButton.restorationIdentifier = "\(indexPath.section)"
            qrExportButton.addTarget(self, action: #selector(self.exportQrAction), for: .touchUpInside)
            
            detailButton.restorationIdentifier = "\(indexPath.section)"
            detailButton.addTarget(self, action: #selector(self.seeDetailAction), for: .touchUpInside)
            
            return qrCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }


    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        let footerChildView = UIView(frame: CGRect(x: 60, y: 0, width: tableView.frame.width - 60, height: 0.5))
        footerChildView.backgroundColor = .clear
        footerView.addSubview(footerChildView)
        return footerView
    }
    
    @objc func exportQrAction(_ sender: UIButton) {
        guard qrArray.count > 0, let indexString = sender.restorationIdentifier, let index = Int(indexString) else { return }
            
        let qr = qrArray[index]
        let str = QRStruct(dictionary: qr)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.qrToExport = str
            self.performSegue(withIdentifier: "segueToQrDisplayer", sender: self)//exportSegue
        }
        
    }
    
    @objc func seeDetailAction(_ sender: UIButton) {
        guard qrArray.count > 0, let indexString = sender.restorationIdentifier, let index = Int(indexString) else { return }
            
        let qr = qrArray[index]
        let str = QRStruct(dictionary: qr)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.qrToExport = str
            self.performSegue(withIdentifier: "exportSegue", sender: self)
        }
    }
    
    private func parse(_ data: Data) -> String {
        guard let decryptedQr = Encryption.decrypt(data), let item = String(data: decryptedQr, encoding: .utf8) else {
            return ""
        }
        
        return Parser.parse(item)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            isDeleting = true
            let id = qrArray[indexPath.section]["id"] as! UUID
            indPath = indexPath
            idToDelete = id
            deleteQr()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            return .delete
        }
        return .none
    }
    
    private func deleteQr() {
        CoreDataService.deleteEntity(id: idToDelete) { [weak self] (success, errorDescription) in
            guard let self = self else { return }
            
            guard success else {
                self.showAlert(title: "Error", message: errorDescription ?? "error deleteing that QR")
                
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.qrArray.remove(at: self.indPath.section)
                
                if self.qrArray.count == 0 {
                    self.homeTable.reloadData()
                } else {
                    self.homeTable.deleteSections(IndexSet.init(arrayLiteral: self.indPath.section), with: .fade)
                }
                self.editNodes()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if qrArray.count > 0 {
            return 170
        } else {
            return 100
        }
    }
    
    @objc func editNodes() {
        homeTable.setEditing(!homeTable.isEditing, animated: true)
        if homeTable.isEditing {
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editNodes))
        } else {
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNodes))
        }
        self.navigationItem.setLeftBarButton(editButton, animated: true)
    }
    
    @IBAction func editAction(_ sender: Any) {
        if let _ = KeyChain.load(key: "userIdentifier"), authorized {
            editNodes()
        } else {
            addAuth()
        }
    }
    
    private func firstTime() {
        if KeyChain.load(key: "privateKey") == nil {
            let pk = Encryption.privateKey()
            let status = KeyChain.save(key: "privateKey", data: pk)
            if status == 0 {
                //showAlert(title: "Success", message: "We securely created a private key and stored it to your devices secure enclave.\n\nThis private key will be encrypted and stored securely on your device. QR Vault will use this private key to encrypt and decrypt all the QR codes you save. This way you have two levels of encryption protecting your data.")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.performSegue(withIdentifier: "segueToIntroText", sender: self)
                }
                
            } else {
                let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? "Undefined error"])
                showAlert(title: "Error!", message: "There was an error creating a private key and storing it on your keychain. Error: \(error)")
            }
        } else {
            addAuth()
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
    
    private func formatDate(date: Date) -> String {
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm"
        return dateFormatter.string(from: date)
    }
    
    private func addAuth() {
        if let _ = KeyChain.load(key: "userIdentifier") {
            guard let _ = self.view.window else { return }
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.performSegue(withIdentifier: "segueToGetAuth", sender: self)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let authorizationProvider = ASAuthorizationAppleIDProvider()
            if let usernameData = KeyChain.load(key: "userIdentifier") {
                if let username = String(data: usernameData, encoding: .utf8) {
                    if username == appleIDCredential.user {
                        authorizationProvider.getCredentialState(forUserID: username) { [weak self] (state, error) in
                            guard let self = self else { return }
                            
                            switch state {
                            case .authorized:
                                self.authorized = true
                                self.loadData()
                            case .revoked:
                                self.showAlert(title: "No account found.", message: "")
                                fallthrough
                            case .notFound:
                                self.showAlert(title: "No account found.", message: "")
                            default:
                                print("triggered")
                                break
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @objc func logoTapped() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "supportSegue", sender: self)
        }
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
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "segueToQrDisplayer"://exportSegue
            guard let vc = segue.destination as? QRDisplayerViewController else { fallthrough }
            
            vc.qrStruct = qrToExport
            
        case "exportSegue":
            guard let vc = segue.destination as? ExportViewController else { fallthrough }
            
            vc.qrStruct = qrToExport
            
        case "segueToScanQr":
            guard let vc = segue.destination as? QRScannerViewController else { fallthrough }
            
            vc.doneBlock = { [weak self] result in
                guard let self = self, let result = result else { return }
                
                
                self.textToAdd = result
                self.performSegue(withIdentifier: "addLabelSegue", sender: self)
            }
            
        case "addLabelSegue":
            guard let vc = segue.destination as? LabelViewController else { return }
            
            vc.text = textToAdd
            
        case "segueToPromptForCameraPermissions":
            guard let vc = segue.destination as? CameraPermissionsViewController else { fallthrough }
            
            vc.doneBlock = { [weak self] granted in
                guard let self = self else { return }
                
                if granted {
                    self.showScanner()
                }
            }
            
        case "segueToGetAuth":
            guard let vc = segue.destination as? PromptForAuthViewController else { fallthrough }
            
            vc.doneBlock = { [weak self] success in
                guard let self = self else { return }
                
                self.loadData()
            }
            
        case "segueToIntroText":
            guard let vc = segue.destination as? IntroViewController else { fallthrough }
            
            vc.doneBlock = { _ in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.performSegue(withIdentifier: "segueToLicense", sender: self)
                }
            }
            
        case "segueToLicense":
            guard let vc = segue.destination as? LicenseDisclaimerViewController else { fallthrough }
            
            vc.doneBlock = { [weak self] _ in
                guard let self = self else { return }
                
                self.loadData()
            }
            
        default:
            break
        }
    }

}
