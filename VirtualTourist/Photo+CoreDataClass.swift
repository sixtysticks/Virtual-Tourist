//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by David Gibbs on 18/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation
import CoreData

public class Photo: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext, pin: Pin) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.pin = pin
        } else {
            fatalError("Unable to find entity name")
        }
    }

}
