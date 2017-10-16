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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CalendarHandler.requestAccessToCalendar()
        if let _defaultCalendar = CalendarHandler.loadCalendar(calendarKey: "CalendarNoteLongtermCalendar") {
            defaultCalendar = _defaultCalendar
        } else {
            defaultCalendar = CalendarHandler.addCalendar(calendarKey: "CalendarNoteLongtermCalendar")
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
    func loadCalendar() {
        // check if there is a calendar with the saved default calendar identifier
        var exist: Bool = false
        let existingCalendars = eventStore.calendars(for: EKEntityType.event)
        if let calendarIdentifier = UserDefaults.standard.string(forKey: "CalendarNoteLongtermCalendar") {
            for ele in existingCalendars {
                if ele.calendarIdentifier == calendarIdentifier {
                    os_log("found default calendar.", log: OSLog.default, type: .debug)
                    self.defaultCalendar = ele
                    exist = true
                    break
                }
            }
        }
        
        // if no calendar found a new one shall be created
        if !exist {
            os_log("no calendar found.", log: OSLog.default, type: .debug)
            self.defaultCalendar = self.addCalendar(existingCalendars)
        }
    }
    
    func addCalendar(_ existingCalendars: [EKCalendar]) -> EKCalendar? {
        let eventStore = EKEventStore()
        // Calendar Instance: Use Event Store to create a new calendar instance
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        let newCalendarName: String = "CalendarNote#1.1_LTPlan"
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
            UserDefaults.standard.set(newCalendar.calendarIdentifier as String, forKey: "CalendarNoteLongtermCalendar")
            
            // use this new calendar and save its title as calednar default setting
        } catch {
            let alert = UIAlertController(title: "Calendar could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
        }
        return newCalendar
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? UINavigationController else {return}
        
        guard let addEventVC = destinationVC.childViewControllers[0] as? AddEventViewController else {return}
        addEventVC.calendar = self.defaultCalendar
        addEventVC.delegate = self
        addEventVC.selectedDate = self.selectedDate
    }


}
