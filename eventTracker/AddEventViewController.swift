//
//  AddEventViewController.swift
//  eventTracker
//
//  Created by ChangDiqing on 28.07.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit

class AddEventViewController: UIViewController {
    
    var calendar: EKCalendar!  // Here declare a variable
    var selectedDate: Date?
    
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var eventStartDatePicker: UIDatePicker!
    @IBOutlet weak var eventEndDatePicker: UIDatePicker!
    
    var delegate: EventAddedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.eventStartDatePicker.setDate(initialDatePickerValue(), animated: false)
        self.eventEndDatePicker.setDate(initialDatePickerValue(), animated: false)

        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addEventButtonTapped(_ sender: UIBarButtonItem) {
        // Create an Event Store instance
        let eventStore = EKEventStore();
        
        var calendarForEvent: EKCalendar!
        let calendars: [EKCalendar] = eventStore.calendars(for: EKEntityType.event) as [EKCalendar]
        
        for aCal in calendars {
            if(aCal.calendarIdentifier == self.calendar.calendarIdentifier) {
                calendarForEvent = aCal
                break
            }
        }
        
        // Use Event Store to create a new calendar instance
        //if let calendarForEvent = eventStore.calendar(withIdentifier: self.calendar.calendarIdentifier) {
        if calendarForEvent != nil{
            
            eventStore.requestAccess(to: .event) { (granted, error) in
                
                if (granted) && (error == nil) {
                    print("granted \(granted)")
                    print("error \(String(describing: error))")
                
                    let newEvent: EKEvent = EKEvent(eventStore: eventStore)  // instantiate an EKEvent Object
                
                    newEvent.calendar = calendarForEvent
                    newEvent.title = self.eventNameTextField.text ?? "Some Event Name"
                    newEvent.startDate = self.eventStartDatePicker.date
                    newEvent.endDate = self.eventEndDatePicker.date
                
                    // Save the event using the Event Store instance
                    do {
                        try eventStore.save(newEvent, span: .thisEvent)
                        //eventStore.save(newEvent, span: .thisEvent)
                        //eventStore.save(newEvent, span: .thisEvent, commit: true)
                        self.delegate?.eventDidAdd(dates: [newEvent.startDate])
                    
                        self.dismiss(animated: true, completion: nil)
                    } catch let error as NSError {
                        print("failed to save event with error: \(error)")
                    }
                    print("Saved Event")
                } else {
                    print("failed")
                }
            }
            
        }
    
    }
    // MARK: Private Methodes
    
    func initialDatePickerValue() -> Date {
        let calendarUnitFlags: NSCalendar.Unit = [.year, .month, .day, .hour, .minute, .second]
        var dateComponents: DateComponents
        if let selectedDate = selectedDate {
            dateComponents = (Calendar.current as NSCalendar).components(calendarUnitFlags, from: selectedDate)
        } else {
            dateComponents = (Calendar.current as NSCalendar).components(calendarUnitFlags, from: Date())
        }
        
        
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        return Calendar.current.date(from: dateComponents)!
    }

}
