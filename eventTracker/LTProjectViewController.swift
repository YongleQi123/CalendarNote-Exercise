//
//  ProjectViewController.swift
//  eventTracker
//
//  Created by Diqing Chang on 30.09.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit
import os.log

class LTProjectViewController: UIViewController, UITextFieldDelegate,UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailTextField: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var dateFrom: UIDatePicker!
    @IBOutlet weak var dateTo: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var checkboxMon: CheckBox!
    @IBOutlet weak var checkboxTue: CheckBox!
    @IBOutlet weak var checkboxWed: CheckBox!
    @IBOutlet weak var checkboxThu: CheckBox!
    @IBOutlet weak var checkboxFri: CheckBox!
    @IBOutlet weak var checkboxSat: CheckBox!
    @IBOutlet weak var checkboxSun: CheckBox!
    
    /*
     This value is either passed by `MealTableViewController` in `prepare(for:sender:)`
     @IBOutlet weak var saveButton: UIBarButtonItem!
     @IBOutlet weak var saveButton: UIBarButtonItem!
     or constructed as part of adding a new meal.
     */
    var event: EKEvent?
    var eventStore: EKEventStore?
    var defaultCalendar: EKCalendar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Handle the text field’s user input through delegate callbacks.
        titleTextField.delegate = self
        detailTextField.delegate = self
        
        // Set up views IF editing an existing Meal.
        if let event = event {  // if there is already an event passed to this controller then just read info
            navigationItem.title = event.title
            titleTextField.text = event.title
            dateFrom.date = event.startDate
            dateTo.date = event.recurrenceRules?.first?.recurrenceEnd?.endDate ?? event.startDate
            detailTextField.text = event.notes
            initWeekDayCheckbox()
        } else if eventStore != nil && defaultCalendar != nil {  // if no event passed to this controller and an eventStore is given, then create a new event
            event = EKEvent(eventStore: eventStore!)
            event?.calendar = defaultCalendar!
        }
        
        // Enable the Save button only if the text field has a valid Meal name.
        updateSaveButtonState()
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set photoImageView to display the selected image.
        photoImageView.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        //let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        if presentingViewController is UITabBarController {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The LTProjectViewController is not inside a navigation controller.")
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        // Set the project to be passed to LTTableViewController after the unwind segue.
        
        let tempDays = selectedDays()
        let recurringEnd = EKRecurrenceEnd(end:dateTo.date)
        let rule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, daysOfTheWeek: tempDays as? [EKRecurrenceDayOfWeek], daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end:recurringEnd)
        
        self.event?.title = titleTextField.text ?? "Error naming event"
        self.event?.notes = detailTextField.text!
        self.event?.isAllDay = true
        self.event?.startDate = dateFrom.date
        self.event?.endDate = dateFrom.date
        saveEvent(event: self.event!)
        self.event?.recurrenceRules = [rule]
    }
    
    //MARK: Actions
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        // Hide the keyboard.
        titleTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    //MARK: Private Methods
    
    private func saveEvent(event: EKEvent) {
        do {
            try eventStore?.save(event, span: .futureEvents, commit: true)
        } catch let error as NSError {
            print("failed to save event with error: \(error)")
        }
    }
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = titleTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    private func selectedDays() -> NSMutableArray{
        let tempDays = NSMutableArray()
        
        if checkboxMon.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.monday))
        }
        if checkboxTue.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.tuesday))
        }
        if checkboxWed.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.wednesday))
        }
        if checkboxThu.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.thursday))
        }
        if checkboxFri.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.friday))
        }
        if checkboxSat.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.saturday))
        }
        if checkboxSun.isChecked{
            tempDays.add(EKRecurrenceDayOfWeek(.sunday))
        }
        
        return tempDays
    }
    
    private func initWeekDayCheckbox() {
        if let daysOfTheWeek = event?.recurrenceRules?.first?.daysOfTheWeek {
            print("Loading recurrenceRules succeeded")
            for ele in daysOfTheWeek {
                self.checkWeekDayByHash(hashValue: ele.dayOfTheWeek.hashValue)
            }
        } else {
            print("Loading recurrenceRules failed")
            print(event?.recurrenceRules)
        }
    }
    
    private func checkWeekDayByHash(hashValue: Int) {
        if hashValue == 1 {
            checkboxMon.isChecked = true
        } else if hashValue == 2 {
            checkboxTue.isChecked = true
        } else if hashValue == 3 {
            checkboxWed.isChecked = true
        } else if hashValue == 4 {
            checkboxThu.isChecked = true
        } else if hashValue == 5 {
            checkboxFri.isChecked = true
        } else if hashValue == 6 {
            checkboxSat.isChecked = true
        } else {
            checkboxSun.isChecked = true
        }
    }
}
