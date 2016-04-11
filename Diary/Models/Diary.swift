//
//  Diary.swift
//  
//
//  Created by kevinzhow on 15/7/7.
//
//

import Foundation
import CoreData

@objc(Diary)

class Diary: NSManagedObject {

    @NSManaged var content: String
    @NSManaged var created_at: NSDate
    @NSManaged var location: String?
    @NSManaged var month: NSNumber
    @NSManaged var title: String?
    @NSManaged var year: NSNumber
    @NSManaged var id: String?

}
