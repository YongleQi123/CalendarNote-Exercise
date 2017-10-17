//
//  LongtermPlanTableViewTableViewController.swift
//  eventTracker
//
//  Created by Diqing Chang on 26.09.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit
import JTAppleCalendar
import os.log
import CoreData

class LTTableViewTableViewController: UITableViewController {

    let eventStore = EKEventStore()
    var defaultCalendar: EKCalendar?
    let LTPDateFormater = DateFormatter()
    var LTPs = [EKEvent]()
    var eventIdentifierList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LTPDateFormater.dateFormat = "MMM dd,yyyy"
        CalendarHandler.requestAccessToCalendar()
        if let _defaultCalendar = CalendarHandler.loadCalendar(calendarKey: "CalendarNoteLongtermCalendar") {
            defaultCalendar = _defaultCalendar
        } else {
            defaultCalendar = CalendarHandler.addCalendar(calendarKey: "CalendarNoteLongtermCalendar")
        }
        // Load the saved event identifiers if they exist
        if let eventIdentifierList = UserDefaults.standard.array(forKey: "CalendarNoteLTPList") as? [String] {
            self.eventIdentifierList = eventIdentifierList
        }
        
        // Load any saved meals, otherwise load sample data.
        if let savedLTPs = loadEvents(dateFrom: "2017-01-01",dateTo: "2100-12-31", inCalendars: [defaultCalendar!]) {
            LTPs += savedLTPs
        }
        
        /*
        for i in LTPs {
         deleteEvent(event: i)
        }*/
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LTPs.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "LTPCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LTPTableViewCell  else {
            fatalError("The dequeued cell is not an instance of LTPTableViewCell.")
        }
        // Fetches the appropriate meal for the data source layout.
        let LTP = LTPs[indexPath.row]
        //deleteEvent(event: LTP)
        
        cell.LTPTitle.text = LTP.title
        cell.LTPStartDate.text = LTPDateFormater.string(from: LTP.startDate)
        let endDate = LTP.recurrenceRules?.first?.recurrenceEnd?.endDate ?? LTP.startDate
        cell.LTPEndDate.text = LTPDateFormater.string(from: endDate)
        cell.initWeekDayCheckbox(event: LTP)
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            deleteEvent(event: LTPs[indexPath.row])
            LTPs.remove(at: indexPath.row)
            self.eventIdentifierList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // here code for deleting event
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        UserDefaults.standard.set(self.eventIdentifierList as Array, forKey: "CalendarNoteLTPList")
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    //MARK: methods


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {

        case "addItem":
            guard let DestinationNavi = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let LTPDetailViewController = DestinationNavi.childViewControllers.first! as? LTProjectViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            LTPDetailViewController.eventStore = eventStore
            LTPDetailViewController.defaultCalendar = defaultCalendar
            os_log("Adding a new LTP(Longterm Project).", log: OSLog.default, type: .debug)
            
        case "showDetail":
            guard let LTPDetailViewController = segue.destination as? LTProjectViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedLTPCell = sender as? LTPTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedLTPCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            LTPDetailViewController.eventStore = eventStore
            LTPDetailViewController.event = LTPs[indexPath.row]
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    @IBAction func unwindToLTPList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? LTProjectViewController, let newLTP = sourceViewController.event {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                LTPs[selectedIndexPath.row] = newLTP
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else {
                // Add a new meal.
                guard let calendar = defaultCalendar else {
                    fatalError("Unexpected calendar: \(String(describing: defaultCalendar))")
                }
                newLTP.calendar = calendar
                let newIndexPath = IndexPath(row: LTPs.count, section: 0)
                LTPs.append(newLTP)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            DispatchQueue.main.async() {
                self.saveEvent(event: newLTP) 
                if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                    self.eventIdentifierList[selectedIndexPath.row] = newLTP.eventIdentifier
                } else {
                    self.eventIdentifierList.append(newLTP.eventIdentifier)
                }
                UserDefaults.standard.set(self.eventIdentifierList as Array, forKey: "CalendarNoteLTPList")
            }
            
            
            //save new event
            // here code for saving the LTP.
            // 首先我得知道如何编辑event，需要删除旧的event添加新的event还是可以直接编辑已有的event呢？
        }
    }
    
    //MARK: Private Methods
    
    private func  createEvent() {
        
        let event = EKEvent(eventStore: eventStore)
        /* Create an event that happens today and happens
         every month for a year from now */
        let startDate = Date()
        
        /* The event's end date is one hour from the moment it is created */
        let oneHour:TimeInterval = 1 * 60 * 60
        let endDate = startDate.addingTimeInterval(oneHour)
        
        /* Assign the required properties, especially
         the target calendar */
        event.calendar = defaultCalendar!
        event.title = "My Event"
        event.isAllDay = true
        event.startDate = startDate
        event.endDate = startDate
        
        /* The end date of the recurring rule
         is one year from now */
        let oneYear:TimeInterval = 365 * 24 * 60 * 60;
        let oneYearFromNow = startDate.addingTimeInterval(oneYear)
        
        /* Create an Event Kit date from this date*/
        let recurringEnd = EKRecurrenceEnd(end:oneYearFromNow)
        
        /*And the recurring rule. This event happens every
         month (EKRecurrenceFrequencyMonthly), once a month (interval:1)
         and the recurring rule ends a year from now (end:RecurringEnd)*/
        let tempDays = NSMutableArray()
        tempDays.add(EKRecurrenceDayOfWeek(.monday))
        tempDays.add(EKRecurrenceDayOfWeek(.tuesday))
        
        let recurringRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, daysOfTheWeek: tempDays as? [EKRecurrenceDayOfWeek], daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end: nil)
        saveEvent(event: event)
        /*Set the recurring rule for the event */
        event.addRecurrenceRule(recurringRule)
        
        
        saveEvent(event: event)
    }
    
    private func loadSampleLTPs() {
        
        let eventStore = EKEventStore()
        
        let LTP1 = EKEvent(eventStore: eventStore)
        LTP1.title = "Sample project 1"
        LTP1.notes = "Sample project details"
        LTP1.startDate = Date()
        LTP1.endDate = Date()
        
        let LTP2 = EKEvent(eventStore: eventStore)
        LTP2.title = "Sample project 2"
        LTP2.notes = "Sample project details"
        LTP2.startDate = Date()
        LTP2.endDate = Date()
        
        let LTP3 = EKEvent(eventStore: eventStore)
        LTP3.title = "Sample project 3"
        LTP3.notes = "Sample project details"
        LTP3.startDate = Date()
        LTP3.endDate = Date()
        
        LTPs += [LTP1, LTP2, LTP3]
    }
    
    private func deleteEvent(event: EKEvent) {
        do {
            print(event)
            try eventStore.remove(event, span: .futureEvents, commit: true)
        } catch let error as NSError {
            print("failed to delete event with error: \(error)")
        }
    }
    
    private func saveEvent(event: EKEvent) {
        do {
            print(event)
            try eventStore.save(event, span: .futureEvents, commit: true)
        } catch let error as NSError {
            print("failed to save event with error: \(error)")
        }
    }
    
    private func loadEvents(dateFrom: String, dateTo: String, inCalendars: [EKCalendar]) -> [EKEvent]?  {
        print(self.eventIdentifierList)
        let dateFormatter = DateFormatter()  // isntantiate a date formatter
        dateFormatter.dateFormat = "yyyy-MM-dd"  // set the date format of dateFormatter for displaying date
        var eventContainer = [EKEvent]()
        for identifier in self.eventIdentifierList {
            if let loadedEvent = eventStore.event(withIdentifier: identifier) {
                eventContainer.append(loadedEvent)
            } else {
                if let index = self.eventIdentifierList.index(of: identifier) {
                    self.eventIdentifierList.remove(at: index)
                }
            }
        }
        UserDefaults.standard.set(self.eventIdentifierList as Array, forKey: "CalendarNoteLTPList")
        return eventContainer
    }
}
