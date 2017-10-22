//
//  CalendarHandler.swift
//  eventTracker
//
//  Created by Diqing Chang on 27.09.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import Foundation
import UIKit
import EventKit
import os.log

class CalendarHandler {
    
    static func requestAccessToCalendar() {
        func requestAccessToCalendar() {
            EKEventStore().requestAccess(
                to: EKEntityType.event, completion: {
                    (accessGranted: Bool, error: Error?) in
    
                        if accessGranted == true {
                            DispatchQueue.main.async(execute: {
                            //self.loadCalendars()
                            })
                        }
                }
            )
        }
    }
    
    static func loadCalendar(calendarKey: String) -> EKCalendar? {
        // check if there is a calendar with the saved default calendar identifier
        // CalendarNotePrimaryCalendar_index & CalendarNoteLongtermCalendar_index
        let existingCalendars = EKEventStore().calendars(for: EKEntityType.event)
        if let calendarIdentifier = UserDefaults.standard.string(forKey: calendarKey) {
            for ele in existingCalendars {
                if ele.calendarIdentifier == calendarIdentifier {
                    os_log("found default calendar.", log: OSLog.default, type: .debug)
                    print(ele.calendarIdentifier)
                    return ele
                }
            }
        }
        
        // if no calendar found a new one shall be created
        os_log("no calendar found.", log: OSLog.default, type: .debug)
        return nil
    }
    
    static func addCalendar(calendarKey: String) -> EKCalendar? {
        // CalendarNotePrimaryCalendar_index & CalendarNoteLongtermCalendar_index
        let eventStore = EKEventStore()
        let existingCalendars = EKEventStore().calendars(for: EKEntityType.event)
        // Calendar Instance: Use Event Store to create a new calendar instance
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        let newCalendarName: String = calendarKey
        var tail: Int = 0
        var exist: Bool = true
        
        while exist == true {
            exist = false
            for ele in existingCalendars {
                if ele.title == newCalendarName + "_" + String(tail) {
                    exist = true
                    tail += 1
                }
            }
        }
        
        newCalendar.title = newCalendarName + "_" + String(tail) // ?? funktioniert wie ODER
        
        // Access list of available sources from the Event Store
        let sourceInEventStore = eventStore.sources
        
        // Filter the available sources and select the "Local" source to assign to the new calendar's source property
        newCalendar.source = sourceInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType.rawValue == EKSourceType.local.rawValue
            }.first!
        
        // Save the calendar using the Event Store instance
        do{
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("########and the identifier is \(newCalendar.calendarIdentifier)")
            UserDefaults.standard.set(newCalendar.calendarIdentifier as String, forKey: calendarKey)
            
            // use this new calendar and save its title as calednar default setting
        } catch {
            let alert = UIAlertController(title: "Calendar could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
        }
        return newCalendar
    }
    
    static func deleteEvent(event: EKEvent) {
        let eventStore = EKEventStore()
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch let error as NSError {
            print("failed to delete event with error: \(error)")
        }
    }
    
    static func saveEvent(eventStore: EKEventStore, event: EKEvent) {
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch let error as NSError {
            print("failed to save event with error: \(error)")
        }
    }
    
    static func loadEvents(dateFrom: String, dateTo: String, inCalendars: [EKCalendar]) -> [EKEvent]?  {
        let dateFormatter = DateFormatter()  // isntantiate a date formatter
        dateFormatter.dateFormat = "yyyy-MM-dd"  // set the date format of dateFormatter for displaying date
        let startDate = dateFormatter.date(from: dateFrom)
        let endDate = dateFormatter.date(from: dateTo)
        
        if let startDate = startDate, let endDate = endDate {
            let eventStore = EKEventStore()  // instantiate a EKEventStore, which manage the data storage of calendar events
            
            let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: inCalendars)
            
            return eventStore.events(matching: eventsPredicate).sorted {
                (e1: EKEvent, e2: EKEvent) -> Bool in
                
                return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
            }
        }
        
        return nil
    }
    
}
