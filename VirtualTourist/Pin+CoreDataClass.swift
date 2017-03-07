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
            print("ENTERED PIN CLASS")
            self.init(entity: ent, insertInto: context)
            self.creationDate = Date() as NSDate?
        } else {
            fatalError("Unable to find entity name")
        }
        print("EXIT PIN CLASS")
    }
    
    var formattedDate: String {
        get {
            let formatter =  DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .short
            formatter.doesRelativeDateFormatting =  true
            formatter.locale = Locale.current
            
            return formatter.string(from: creationDate as! Date)
        }
    }
    
}
