//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by David Gibbs on 06/03/2017.
//  Copyright © 2017 SixtySticks. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var hasDownloaded: Bool
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
