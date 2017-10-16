//
//  Diaries+CoreDataProperties.swift
//  
//
//  Created by Diqing Chang on 01.09.17.
//
//

import Foundation
import CoreData


extension Diaries {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Diaries> {
        return NSFetchRequest<Diaries>(entityName: "Diaries")
    }

    @NSManaged public var content: String?
    @NSManaged public var timeStamp: NSDate?

}
