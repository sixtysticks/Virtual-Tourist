//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by David Gibbs on 24/02/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var hasDownloaded: Bool
    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin //NSSet?

}

// MARK: Generated accessors for pin
extension Photo {

    @objc(addPinObject:)
    @NSManaged public func addToPin(_ value: Pin)

    @objc(removePinObject:)
    @NSManaged public func removeFromPin(_ value: Pin)

    @objc(addPin:)
    @NSManaged public func addToPin(_ values: NSSet)

    @objc(removePin:)
    @NSManaged public func removeFromPin(_ values: NSSet)

}
