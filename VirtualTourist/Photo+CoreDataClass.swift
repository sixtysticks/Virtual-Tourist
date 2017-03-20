//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by David Gibbs on 18/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class Photo: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext, pin: Pin, dict: [String:AnyObject]) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = dict["url_m"] as! String?
            self.id = dict["id"] as! String?
            self.pin = pin
            
            do {
                try CoreDataStack.sharedInstance().saveContext()
            } catch {
                fatalError("Error in 'Photo' NSManagedObject")
            }
        } else {
            fatalError("Unable to find entity name")
        }
    }

}
