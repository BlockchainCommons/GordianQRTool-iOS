//
//  DescriptorParser.swift
//  QR Vault
//
//  Created by Peter Denton on 5/6/21.
//  Copyright © 2021 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class DescriptorParser {
    
    func descriptor(_ descriptor: String) -> Descriptor {
        var dict = [String:Any]()
        
        dict["complete"] = true
                
        if descriptor.contains("&") {
            dict["isSpecter"] = true
            
        } else {
            dict["isSpecter"] = false
            
        }
        
        if descriptor.contains("multi") {
            dict["isMulti"] = true
            
            if descriptor.contains("sortedmulti") {
                dict["isBIP67"] = true
                
            }
            
            let arr = descriptor.split(separator: "(")
            for (i, item) in arr.enumerated() {
                if i == 0 {
                    
                    switch item {
                        
                    case "multi":
                        dict["format"] = "Bare-multi"
                        
                    case "wsh":
                        dict["format"] = "P2WSH"
                        
                    case "sh":
                        if arr[1] == "wsh" {
                            dict["format"] = "P2SH-P2WSH"
                            
                        } else {
                            dict["format"] = "P2SH"
                            
                        }
                        
                    default:
                        break
                        
                    }
                    
                }
                
                switch item {
                    
                case "multi", "sortedmulti":
                    let mofnarray = (arr[i + 1]).split(separator: ",")
                    let numberOfKeys = mofnarray.count - 1
                    dict["mOfNType"] = "\(mofnarray[0]) of \(numberOfKeys)"
                    dict["sigsRequired"] = UInt(mofnarray[0])
                    var keysWithPath = [String]()
                    for (i, item) in mofnarray.enumerated() {
                        let processed = item.replacingOccurrences(of: ")", with: "")
                        if i != 0 {
                            keysWithPath.append("\(processed)")
                        }
                        if i + 1 == mofnarray.count {
                            dict["keysWithPath"] = keysWithPath
                        }
                        if item == "" {
                            dict["complete"] = false
                        }
                    }
                     
                    var fingerprints = [String]()
                    var keyArray = [String]()
                    var paths = [String]()
                    var derivationArray = [String]()
                    
                    /// extracting the xpubs and their paths so we can derive the individual multisig addresses locally
                    for key in keysWithPath {
                        var path = String()
                        if key.contains("/") {
                            if key.contains("[") && key.contains("]") {
                                // remove the bracket with deriv/fingerprint
                                let arr = key.split(separator: "]")
                                let rootPath = arr[0].replacingOccurrences(of: "[", with: "")
                                
                                let rootPathArr = rootPath.split(separator: "/")
                                fingerprints.append("[\(rootPathArr[0])]")
                                var deriv = "m"
                                for (i, rootPathItem) in rootPathArr.enumerated() {
                                    
                                    if i > 0 {
                                        
                                        deriv += "/" + "\(rootPathItem)"
                                        
                                    }
                                    
                                }
                                derivationArray.append(deriv)
                                
                                let processedKey = arr[1]
                                // it has a path
                                let pathArray = processedKey.split(separator: "/")
                                for pathItem in pathArray {
                                    if pathItem.contains("xpub") || pathItem.contains("tpub") || pathItem.contains("xprv") || pathItem.contains("tprv") {
                                        keyArray.append("\(pathItem.replacingOccurrences(of: "))", with: ""))")
                                    } else {
                                        if !pathItem.contains("*") {
                                            if path == "" {
                                                path = "\(pathItem)"
                                            } else {
                                                path += "/" + pathItem
                                            }
                                        } else {
                                            paths.append(path)
                                        }
                                    }
                                }
                            }
                        } else {
                            /// The keys are child keys so we do not need to extract the path from them we can just use the prefix
                        }
                    }
                    
                    dict["derivationArray"] = derivationArray
                    dict["multiSigKeys"] = keyArray
                    dict["multiSigPaths"] = paths
                    
                    var processed = fingerprints.description.replacingOccurrences(of: "[\"", with: "")
                    processed = processed.replacingOccurrences(of: "\"]", with: "")
                    processed = processed.replacingOccurrences(of: "\"", with: "")
                    dict["fingerprint"] = processed
                    
                    for deriv in derivationArray {

                        switch deriv {
                            
                        case "m/48'/0'/0'/1'", "m/48'/1'/0'/1'":
                            dict["isBIP44"] = false
                            dict["isP2PKH"] = true
                            dict["isBIP84"] = false
                            dict["isP2WPKH"] = false
                            dict["isBIP49"] = false
                            dict["isP2SHP2WPKH"] = false
                            dict["isWIP48"] = true
                            dict["isAccount"] = true
                            
                        case "m/48'/0'/0'/2'", "m/48'/1'/0'/2'":
                            dict["isBIP44"] = false
                            dict["isP2PKH"] = false
                            dict["isBIP84"] = false
                            dict["isP2WPKH"] = true
                            dict["isBIP49"] = false
                            dict["isP2SHP2WPKH"] = false
                            dict["isWIP48"] = true
                            dict["isAccount"] = true
                            
                        case "m/48'/0'/0'/3'", "m/48'/1'/0'/3'":
                            dict["isBIP44"] = false
                            dict["isP2PKH"] = false
                            dict["isBIP84"] = false
                            dict["isP2WPKH"] = false
                            dict["isBIP49"] = false
                            dict["isP2SHP2WPKH"] = true
                            dict["isWIP48"] = true
                            dict["isAccount"] = true

                        case "m/44'/0'/0'", "m/44'/1'/0'":
                            dict["isBIP44"] = true
                            dict["isP2PKH"] = true
                            dict["isBIP84"] = false
                            dict["isP2WPKH"] = false
                            dict["isBIP49"] = false
                            dict["isP2SHP2WPKH"] = false
                            dict["isAccount"] = true

                        case "m/84'/0'/0'", "m/84'/1'/0'":
                            dict["isBIP84"] = true
                            dict["isP2WPKH"] = true
                            dict["isBIP44"] = false
                            dict["isP2PKH"] = false
                            dict["isBIP49"] = false
                            dict["isP2SHP2WPKH"] = false
                            dict["isAccount"] = true

                        case "m/49'/0'/0'", "m/49'/1'/0'":
                            dict["isBIP49"] = true
                            dict["isP2SHP2WPKH"] = true
                            dict["isBIP44"] = false
                            dict["isP2PKH"] = false
                            dict["isBIP84"] = false
                            dict["isP2WPKH"] = false
                            dict["isAccount"] = true

                        default:

                            break

                        }

                    }
                    
                default:
                    break
                }
            }
                        
        } else {
            
            dict["isMulti"] = false
            
            if descriptor.contains("[") && descriptor.contains("]") {
                
                let arr1 = descriptor.split(separator: "[")
                if arr1.count > 0 {
                    dict["keysWithPath"] = ["[" + "\(arr1[1])"]
                    let arr2 = arr1[1].split(separator: "]")
                    let derivation = arr2[0]
                    dict["prefix"] = "[\(derivation)]"
                    dict["fingerprint"] = "\((derivation.split(separator: "/"))[0])"
                    let extendedKeyWithPath = arr2[1]
                    let arr4 = extendedKeyWithPath.split(separator: "/")
                    let extendedKey = arr4[0]
                    if extendedKey.contains("tpub") || extendedKey.contains("xpub") {
                        dict["accountXpub"] = "\(extendedKey.replacingOccurrences(of: ")", with: ""))"
                    } else if extendedKey.contains("tprv") || extendedKey.contains("xprv") {
                        dict["accountXprv"] = "\(extendedKey.replacingOccurrences(of: ")", with: ""))"
                    }
                    
                    let arr3 = derivation.split(separator: "/")
                    var path = "m"
                    
                    for (i, item) in arr3.enumerated() {
                        switch i {
                            
                        case 1:
                            path += "/" + item
                            
                        default:
                            if i != 0 {
                                path += "/" + item
                                
                                if i + 1 == arr3.count {
                                    
                                    dict["derivation"] = path
                                    
                                    switch path {
                                                            
                                    case "m/44'/0'/0'", "m/44'/1'/0'":
                                        dict["isBIP44"] = true
                                        dict["isP2PKH"] = true
                                        dict["isAccount"] = true
                                        
                                    case "m/84'/0'/0'", "m/84'/1'/0'":
                                        dict["isBIP84"] = true
                                        dict["isP2WPKH"] = true
                                        dict["isAccount"] = true
                                        
                                    case "m/49'/0'/0'", "m/49'/1'/0'":
                                        dict["isBIP49"] = true
                                        dict["isP2SHP2WPKH"] = true
                                        dict["isAccount"] = true
                                        
                                    default:
                                        
                                        break
                                        
                                    }
                                    
                                }
                                
                            } else {
                                break
                                
                            }
                            
                        }
                        
                    }
                }
            }
            
            if descriptor.contains("combo") {
                
                dict["format"] = "Combo"
                
            } else {
                
                let arr = descriptor.split(separator: "(")
                
                for (i, item) in arr.enumerated() {
                    
                    if i == 0 {
                        
                        switch item {
                            
                        case "wpkh":
                            dict["format"] = "P2WPKH"
                            dict["isP2WPKH"] = true
                            
                        case "sh":
                            if arr[1] == "wpkh" {
                                
                                dict["format"] = "P2SH-P2WPKH"
                                dict["isP2SHP2WPKH"] = true
                                
                            } else {
                                
                                dict["format"] = "P2SH"
                                
                            }
                            
                        case "pk":
                            dict["format"] = "P2PK"
                            
                        case "pkh":
                            dict["format"] = "P2PKH"
                            dict["isP2PKH"] = true
                            
                        default:
                            
                            break
                            
                        }
                    }
                }
                
            }
            
        }
        
        if descriptor.contains("xpub") || descriptor.contains("xprv") {
            dict["chain"] = "Mainnet"
            dict["isHD"] = true
            
        } else if descriptor.contains("tpub") || descriptor.contains("tprv") {
            dict["chain"] = "Testnet"
            dict["isHD"] = true
            
        } else {
            dict["isHD"] = false
            
        }
        
        if descriptor.contains("xprv") || descriptor.contains("tprv") {
            dict["isHot"] = true
            
        } else {
            dict["isHot"] = false
            
        }
        
        return Descriptor(dictionary: dict)
        
    }
    
}
