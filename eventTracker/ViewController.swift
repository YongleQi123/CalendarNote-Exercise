//
//  ViewController.swift
//  eventTracker
//
//  Created by ChangDiqing on 20.07.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CalendarAddedDelegate {
    // basiclly this CalendarAddedDelegate allows it to call the add calendar function
    
    @IBOutlet weak var needPermissionView: UIView!
    @IBOutlet weak var calendarsTableView: UITableView!
    
    var calendars: [EKCalendar]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarsTableView.delegate = self
        calendarsTableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkCalendarAuthorizationStatus()
    }
    
    //MARK: Private Methods
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            requestAccessToCalendar()
        case EKAuthorizationStatus.authorized:
            // Tihngs are in line with being able to show the calendars in the table view
            loadCalendars()
            refreshTableView()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            needPermissionView.fadeIn()
        
        }
    }
    
    func requestAccessToCalendar() {
        EKEventStore().requestAccess(
            to: EKEntityType.event, completion: {
                (accessGranted: Bool, error: Error?) in
                
                if accessGranted == true {
                    DispatchQueue.main.async(execute: {
                        self.loadCalendars()
                        self.refreshTableView()
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        self.needPermissionView.fadeIn()
                    })
                }
            }
        )
    }
    
    func loadCalendars() {
        self.calendars = EKEventStore().calendars(for: EKEntityType.event).sorted() {
            (cal1, cal2) -> Bool in return cal1.title < cal2.title
        }
    }
    
    func refreshTableView() {
        calendarsTableView.isHidden = false
        calendarsTableView.reloadData()
    }
    
    @IBAction func goToSettingsButtonTapped(_ sender: UIButton) {
        let openSettingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(openSettingsUrl!)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let calendars = self.calendars {
            return calendars.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath) as? calendarTableViewCell else {
            fatalError("The dequeue cell is not an instance of calendarTableCell.")
        }
        
        if let calendars = self.calendars {
            let calendarName = calendars[(indexPath as NSIndexPath).row].title
            cell.titelTextField.text = calendarName
        } else {
            cell.titelTextField.text = "Unknown Calendar Name"
        }
        
        return cell
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "showAddCalendar":
                let destinationVC = segue.destination as! UINavigationController
                let addCalendarVC = destinationVC.viewControllers[0] as! AddCalendarViewController
                addCalendarVC.delegate = self
            case "showEvents":
                let eventsVC = segue.destination as! EventsViewController
                let selectedIndexPath = calendarsTableView.indexPathForSelectedRow!
                eventsVC.calendar = calendars?[(selectedIndexPath as NSIndexPath).row]
                
            default: break
            }
        }
    }
    
    
    // MARK: Calendar Added, called by Delegate
    func calendarDidAdd() {
        self.loadCalendars()
        self.refreshTableView()
    }


}

