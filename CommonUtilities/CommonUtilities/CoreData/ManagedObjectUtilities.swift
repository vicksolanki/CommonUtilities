//
//  ManagedObjectHelper.swift
//  Megabooth
//
//  Created by Swipe Studio on 09/03/2018.
//  Copyright © 2018 Swipe Studio. All rights reserved.
//

import Foundation
import CoreData


protocol Managed: class, NSFetchRequestResult  {
    
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    var isSaved: Bool { get }
}

extension NSManagedObject: Managed { }

extension Managed {
    
    static var defaultSortDescriptors: [NSSortDescriptor] {
        
        return []
    }
    
    static var sortedFetchRequest: NSFetchRequest<Self> {
        
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
    
    public static func sortedFetchRequest(with predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = sortedFetchRequest
        request.predicate = predicate
        return request
    }
}

extension Managed where Self: NSManagedObject {
   
    static var entityName: String { return entity().name! }
    
    var isSaved: Bool {
        get {
            return !objectID.isTemporaryID
        }
    }
}


extension Managed where Self: NSManagedObject {
    
    static func findOrCreate(in context: NSManagedObjectContext,
                             matching predicate: NSPredicate,
                             configure: (Self) -> ()) -> Self {
        
        guard let object = findOrFetch(in: context, matching: predicate) else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        
        return object
    }
}

extension Managed where Self: NSManagedObject {
   
    static func findOrFetch(in context: NSManagedObjectContext,
                            matching predicate: NSPredicate) -> Self? {
      
        guard let object = materializedObject(in: context, matching: predicate)
            else {
                return fetch(in: context) { request in
                    request.predicate = predicate
                    request.returnsObjectsAsFaults = false
                    request.fetchLimit = 1
                    }.first
                
        }
        return object
    }
}

extension Managed where Self: NSManagedObject {
    
    static func materializedObject(in context: NSManagedObjectContext,
                                   matching predicate: NSPredicate) -> Self? {
        
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self,
                predicate.evaluate(with: result) else {
                    continue
            }
            return result
        }
        return nil
    }
}

extension Managed where Self: NSManagedObject {
    
    static func fetch(in context: NSManagedObjectContext,
                      configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> [Self] {
        
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }
}


