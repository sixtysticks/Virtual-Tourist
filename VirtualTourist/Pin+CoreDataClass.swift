//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by David Gibbs on 18/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation
import CoreData

public class Pin: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.creationDate = Date() as NSDate?
            self.page = 1
            self.per_page = Constants.FlickrParameterValues.ResultsReturned
        } else {
            fatalError("Unable to find entity name")
        }
    }
    
}
