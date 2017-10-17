//
//  AddCalendarViewController.swift
//  eventTracker
//
//  Created by ChangDiqing on 23.07.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit  // of course i need this fucking kit

class AddCalendarViewController: UIViewController {

    

    @IBOutlet weak var calendarNameTextField: UITextField!
    var delegate: CalendarAddedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addCalendarButtonTapped(_ sender: UIBarButtonItem) {
        // EventStore: If addButton tapped, create an Event Store instance
        let eventStore = EKEventStore()
        
        // Calendar Instance: Use Event Store to create a new calendar instance
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Configure the title of calendar instance
        // Probably want to prevent someone from saving a calendar if they
        // forget to type in a name
        newCalendar.title = calendarNameTextField.text ?? "Some Calendar name" // ?? funktioniert wie ODER
       
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
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
            delegate?.calendarDidAdd() // Call a function of ViewController via delegate
            self.dismiss(animated: true, completion: nil)  // do not know what completion means
        } catch {
            let alert = UIAlertController(title: "Calendar could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }

}
