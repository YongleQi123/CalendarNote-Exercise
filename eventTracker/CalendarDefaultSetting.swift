//
//  appDefaultSetting.swift
//  eventTracker
//
//  Created by Diqing Chang on 20.08.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import Foundation
import os.log

// New Class for storing all the default settings

class CalendarDefaultSetting: NSObject, NSCoding {
    
    //MARK: Properties
    var defaultCalendarTitle: String?
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("defaultCalendarSetting")
    
    //MARK: Types
    struct PropertyKey {
        static let defaultCalendarTitle = "defaultCalendarTitle"
    }
    
    //MARK: Initialization
    init?(defaultCalendarTitle: String) {
        // name can not be empty!
        guard !defaultCalendarTitle.isEmpty else {
            return nil
        }
        self.defaultCalendarTitle = defaultCalendarTitle
    }
    
    //Mark: NSCoding
    func encode(with aCoder: NSCoder) {  // so what is this 'with aCoder: NSCoder' for?? maybe it is the tool that is already enbedded in swift and does not need to be input again?? this is just a guess
        
        aCoder.encode(defaultCalendarTitle, forKey: PropertyKey.defaultCalendarTitle)  // Here I encode my values in order to save them
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer shoud fail.
        guard let defaultCalendarTitle = aDecoder.decodeObject(forKey: PropertyKey.defaultCalendarTitle) as? String
            else {
                os_log("Unable to decode the default Calendar Settings.", log: OSLog.default, type: .debug)
                return nil
        }
        
        // Must call designated initializer.
        self.init(defaultCalendarTitle: defaultCalendarTitle)
    }
    
}
