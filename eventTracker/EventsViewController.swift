//
//  EventsViewController.swift
//  eventTracker
//
//  Created by ChangDiqing on 27.07.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit

class EventsViewController: UIViewController, UITableViewDataSource{

    @IBOutlet weak var eventsTableView: UITableView!
    
    var calendar: EKCalendar!
    var events: [EKEvent]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        eventsTableView.dataSource = self
        loadEvents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: TableView
    
    func numberOfSections(in tableView: UITableView) -> Int { 
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let events = events {  // this filters out events as nil
            return events.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath) as? EventsTableViewCell else {
            fatalError("The dequeue cell is not an instance of EventsTableViewCell!")
        }
        cell.titleLabel.text = events?[(indexPath as NSIndexPath).row].title
        cell.detailLabel.text = formatDate(events?[(indexPath as NSIndexPath).row].startDate)
        return cell
    }
    
    func formatDate(_ date: Date?) -> String {
        // reformat date and conevert it from date to string
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            return dateFormatter.string(from: date)
        }
        
        return ""
    }
    
    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! UINavigationController
        
        let addEventVC = destinationVC.childViewControllers[0] as! AddEventViewController
        addEventVC.calendar = calendar
        //addEventVC.delegate = self
    }
    
    // MARK: Private Methodes
    func loadEvents() {
        let dateFormatter = DateFormatter()  // isntantiate a date formatter
        dateFormatter.dateFormat = "yyyy-MM-dd"  // set the date format of dateFormatter for displaying date
        
        let startDate = dateFormatter.date(from: "2016-01-01")
        let endDate = dateFormatter.date(from: "2016-12-31")
        
        if let startDate = startDate, let endDate = endDate {
            let eventStore = EKEventStore()  // instantiate a EKEventStore, which manage the data storage of calendar events
            
            let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            
            self.events = eventStore.events(matching: eventsPredicate).sorted {
                (e1: EKEvent, e2: EKEvent) -> Bool in
                
                return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
            }
        }
    }
    
    // MARK: Event Added Delegate, will be called by the assigned delegate
    func eventDidAdd() {
        self.loadEvents()
        self.eventsTableView.reloadData()
    }
    
    
    

}
