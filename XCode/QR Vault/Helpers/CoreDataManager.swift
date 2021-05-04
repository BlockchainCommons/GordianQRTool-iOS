//
//  CoreDataManager.swift
//  QR Vault
//
//  Created by Peter on 06/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import CoreData

//class NSCustomPersistentContainer: NSPersistentContainer {
//    
//    override open class func defaultDirectoryURL() -> URL {
//        var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.QRVault.core.data")
//        storeURL = storeURL?.appendingPathComponent("QR_Vault.sqlite")
//        return storeURL!
//    }
//
//}

class CoreDataManager {
    
    static let sharedInstance = CoreDataManager()
    private init() {}
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "QR_Vault")
        //let container = NSCustomPersistentContainer(name: "QR_Vault")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Could not retrieve a persistent store description.")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.blockchaincommons.gordian.qrvault")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
        
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveEntity(dict: [String:Any], completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        print("saveEntityToCoreData")
        
        let context = persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "QR", in: context) else {
            completion((false, "unable to access QR"))
            return
        }
                
        let credential = NSManagedObject(entity: entity, insertInto: context)
        var succ = Bool()
        
        for (key, value) in dict {
            
            credential.setValue(value, forKey: key)
            
            do {
                
                try context.save()
                succ = true
                
            } catch {
                
                succ = false
                
            }
            
        }
        
        if succ {
            
            completion((true, nil))
            
        } else {
            
            completion((false, "error saving entity"))
            
        }
        
    }
    
    func retrieveEntity(completion: @escaping ((entity: [[String:Any]]?, errorDescription: String?)) -> Void) {
        print("retrieveEntity")
        
        let context = persistentContainer.viewContext
        var fetchRequest:NSFetchRequest<NSFetchRequestResult>? = NSFetchRequest<NSFetchRequestResult>(entityName: "QR")
        fetchRequest?.returnsObjectsAsFaults = false
        fetchRequest?.resultType = .dictionaryResultType
        
        do {
            
            if fetchRequest != nil {
                             
                if let results = try context.fetch(fetchRequest!) as? [[String:Any]] {
                    
                    fetchRequest = nil
                    completion((results, nil))

                } else {
                    
                    fetchRequest = nil
                    completion((nil, "error fetching entity"))
                    
                }
                
            }

        } catch {

            fetchRequest = nil
            completion((nil, "Error fetching QR"))

        }
        
    }
    
    func deleteEntity(id: UUID, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        
        let context = persistentContainer.viewContext
        var fetchRequest:NSFetchRequest<NSManagedObject>? = NSFetchRequest<NSManagedObject>(entityName: "QR")
        fetchRequest?.returnsObjectsAsFaults = false
        
        do {
            
            if fetchRequest != nil {
                
                var results:[NSManagedObject]? = try context.fetch(fetchRequest!)
                var succ = Bool()
                
                if results != nil {
                    
                    if results!.count > 0 {
                        
                        for (index, data) in results!.enumerated() {
                            
                            if id == data.value(forKey: "id") as? UUID {
                                
                                context.delete(results![index] as NSManagedObject)
                                
                                do {
                                    
                                    try context.save()
                                    succ = true
                                    
                                } catch {
                                    
                                    succ = false
                                    
                                }
                                
                            }
                            
                        }
                        
                        results = nil
                        fetchRequest = nil
                        
                        if succ {
                            
                            completion((true, nil))
                            
                        } else {
                            
                            completion((false, "error deleting"))
                            
                        }
                        
                    } else {
                        
                        completion((false, "no results for that entity to delete"))
                        
                    }
                    
                } else {
                    
                    completion((false, "no results for that entity to delete"))
                    
                }
                
            } else {
                
                completion((false, "failed trying to delete that entity"))
                
            }
            
        } catch {
            
            completion((false, "failed trying to delete that entity"))
            
        }
        
    }
    
    func updateEntity(id: UUID, keyToUpdate: String, newValue: Any, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        DispatchQueue.main.async {
            let context = self.persistentContainer.viewContext
            var fetchRequest:NSFetchRequest<NSManagedObject>? = NSFetchRequest<NSManagedObject>(entityName: "QR")
            fetchRequest?.returnsObjectsAsFaults = false
            do {
                if fetchRequest != nil {
                    var results:[NSManagedObject]? = try context.fetch(fetchRequest!)
                    if results != nil {
                        if results!.count > 0 {
                            var success = false
                            for (i, data) in results!.enumerated() {
                                if id == data.value(forKey: "id") as? UUID {
                                    data.setValue(newValue, forKey: keyToUpdate)
                                    do {
                                        try context.save()
                                        success = true
                                        
                                    } catch {
                                        success = false
                                        
                                    }
                                }
                                if i + 1 == results!.count {
                                    fetchRequest = nil
                                    results = nil
                                    if success {
                                        #if DEBUG
                                        print("updated successfully")
                                        #endif
                                        completion((true, nil))
                                        
                                    } else {
                                        completion((false, "error editing"))
                                        
                                    }
                                }
                            }
                        } else {
                            completion((false, "no results"))
                            
                        }
                    }
                }
            } catch {
                completion((false, "failed"))
                
            }
        }
    }
    
}

