//
//  JTCalendarViewController.swift
//  eventTracker
//
//  Created by Diqing Chang on 05.08.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit
import JTAppleCalendar
import os.log
import CoreData

class JTCalendarViewController: UIViewController,UITableViewDataSource, UITableViewDelegate,EventAddedDelegate{

    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var eventTableView: UITableView!
    @IBOutlet weak var Month: UILabel!
    @IBOutlet weak var eventTableWidth: NSLayoutConstraint!
    @IBOutlet weak var buttonSwitchDiaryMode: UIButton!
    @IBOutlet weak var diaryTextField: UITextView!
    @IBOutlet weak var calendarToBottom: NSLayoutConstraint!
    @IBOutlet weak var calendarFrameHeight: NSLayoutConstraint!
    @IBOutlet weak var testview: UIStackView!
    @IBOutlet weak var calendarFrame: UIView!
    
    // define colors
    let outsideMonthColor = UIColor(colorWithHexValue: 0x333333)
    let insideMonthColor = UIColor(colorWithHexValue: 0xB4B4B4)
    let selectedMonthColor = UIColor.white
    let currentDateSelectedViewColor = UIColor(colorWithHexValue: 0x4e3f5d)
    let selectedViewColorDiary = UIColor(colorWithHexValue: 0x315C69)
    let selectedViewColorEvent = UIColor(colorWithHexValue: 0xB4B4B4)
    
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let sectionTitleDateFormater = DateFormatter()
    let eventStore = EKEventStore()
    let screenSize: CGRect = UIScreen.main.bounds
    
    // instantiated Animations
    let animationBounceEffect = AnimationClass.BounceEffect()
    let animationFadeIn = AnimationClass.fadeInEffect()
    let animationFadeOut = AnimationClass.fadeOutEffect()
    
    var diary : Diaries?
    var eventList = [Date: [EKEvent]]()
    var dateListThisMonth = [Date]()
    var selectedCell: JTAppleCell?
    
    var weekMode : Bool = false
    var diaryMode : Bool = false
    var defaultCalendar: EKCalendar?
    var weekNumber: Float?
    var selectedDate : Date? {
        didSet{
            if selectedDate != nil {
                weekNumber = self.getWeekNumber(selectedDate!)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventTableView.delegate = self
        eventTableView.dataSource = self
        
        sectionTitleDateFormater.dateFormat = "MMMM-dd"
        requestAccessToCalendar()
        self.loadCalendar()
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))

        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.calendarView.addGestureRecognizer(swipeUp)
        self.calendarView.addGestureRecognizer(swipeDown)
        
        scaleViews()
        setupCalendarView()
    }
    
    override func viewWillTransition( to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator ) {
        DispatchQueue.main.async() {
            self.scaleViews()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source

    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        title = sectionTitleDateFormater.string(from: self.dateListThisMonth[section])
        
        return title
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return self.dateListThisMonth.count
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let date = self.dateListThisMonth[section]
        
        if let events = self.eventList[date] {
            return events.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JTEvent", for: indexPath) as? JTCalendarEventTableViewCell else {
            fatalError("The dequeue cell is not an instance of JTCalendarEventTableViewCell.")
        }
        
        let date = self.dateListThisMonth[indexPath.section]
        if let JTEvents = self.eventList[date] {
            let eventTitle = JTEvents[(indexPath as NSIndexPath).row].title
            cell.JTEventLabel.text = eventTitle
        } else {
            cell.JTEventLabel.text = "Unknown Event"
        }
        
        return cell
    }
    
    //MARK: methods
    func loadCalendar() {
        // check if there is a calendar with the saved default calendar identifier
        var exist: Bool = false
        let existingCalendars = eventStore.calendars(for: EKEntityType.event)
        if let calendarIdentifier = UserDefaults.standard.string(forKey: "CalendarNotePrimaryCalendar") {
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
        let newCalendarName: String = "CalendarNote#1.1"
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
            UserDefaults.standard.set(newCalendar.calendarIdentifier as String, forKey: "CalendarNotePrimaryCalendar")
            
            // use this new calendar and save its title as calednar default setting
        } catch {
            let alert = UIAlertController(title: "Calendar could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
        }
        return newCalendar
    }

    //MARK: Calendar display
    
    func handleCellTextColor(validCell: CustomCell, cellState: CellState) {
        
        if cellState.isSelected {
            validCell.dateLabel.textColor = selectedMonthColor
            validCell.eventLabel.textColor = selectedMonthColor
            if self.diaryMode {
                validCell.selectedView.backgroundColor = self.selectedViewColorDiary
            } else {
                validCell.selectedView.backgroundColor = self.selectedViewColorEvent
            }
        } else {
            if cellState.dateBelongsTo == .thisMonth {
                validCell.dateLabel.textColor = insideMonthColor
                validCell.eventLabel.textColor = insideMonthColor
            } else {
                validCell.dateLabel.textColor = outsideMonthColor
                validCell.eventLabel.textColor = outsideMonthColor
            }
        }
    }
    
    
    func handleCellSelected(validCell: CustomCell, cellState: CellState) {
        if cellState.isSelected {
            validCell.selectedView.isHidden = false
        } else {
            validCell.selectedView.isHidden = true
        }
    }
    
    func scaleViews() {
        updateCalendarHeight{(success) -> Void in
            return
        }
        self.updateEventTableWidth()
    }
    
    func switchDiaryMode() {
        self.diaryMode = !self.diaryMode
        self.updateEventTableWidth()
    }
    
    @IBAction func buttonSwitchDiaryMode(_ sender: UIButton) {
        guard let validCell = self.selectedCell as? CustomCell else {return}
        self.switchDiaryMode()
        if self.diaryMode {
            validCell.selectedView.backgroundColor = self.selectedViewColorDiary
            print("color 1")
        } else {
            validCell.selectedView.backgroundColor = self.selectedViewColorEvent
            print("color 2")
        }
        
        print("######### \(String(describing: validCell.selectedView.backgroundColor))")

    }
    
    func updateEventTableWidth() {
        if diaryMode {
            self.buttonSwitchDiaryMode.setTitle("Diary",for: .normal)
            eventTableWidth.constant = 0
        } else {
            self.buttonSwitchDiaryMode.setTitle("Events",for: .normal)
            eventTableWidth.constant = self.view.bounds.size.width
        }
    }
    
    func updateCalendarHeight(completion: (_ success: Bool) -> ()) {

            // Do something
            
            // Call completion, when finished, success or faliure
        var success: Bool = false
        if weekMode {
            self.calendarFrameHeight.constant = 107
            //toBottomConstraint.constant = UIScreen.main.bounds.height * 0.8
            //calendarView.scrollDirection = .horizontal
            //calendarView.itemSize = nil
        } else {
            self.calendarFrameHeight.constant = 642//self.view.bounds.size.height - 70
            //toBottomConstraint.constant = 0
            //calendarView.scrollDirection = .vertical
            //calendarView.itemSize = floor(UIScreen.main.bounds.height / 12.5)
        }
        success = true
        completion(success)
    }
    
    
    func setupCalendarView() {
        // Setup calendar spacing
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        // calendarView.scrollingMode = .nonStopToCell(withResistance: 0.75)
        // Setup labels
        calendarView.visibleDates { (visibleDates) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        self.formatter.dateFormat = "MMMM YYYY"
        self.Month.text = self.formatter.string(from: date)
    }
    

    func getWeekNumberInMonth(selectedDate: Date, indateCount: Int) -> Float{
        let dayCount = Calendar.current.component(.day, from: selectedDate)
        return ceilf(Float(dayCount+indateCount)/7.00)
        
    }
    
    func changeMode(_ isWeekMode: Bool) {
        guard let selectedDate = self.selectedDate else { return }
        // Set up view depending on whether schedule or monthly view has been selected
        if weekMode {
            
            UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
                self.calendarToBottom.constant = CGFloat(-107*(6-self.weekNumber!))
                self.calendarFrameHeight.constant = 107
                self.testview.layoutIfNeeded()
            }, completion: {(finished:Bool) in
                self.calendarToBottom.constant = -535
                self.calendarView.reloadData(withanchor: selectedDate, completionHandler: nil)
            })
            
            
        }else {
            self.calendarToBottom.constant = CGFloat(-107*(6-self.weekNumber!))
            self.calendarView.reloadData(withanchor: selectedDate){
                self.testview.layoutIfNeeded()
                UIView.animate(withDuration: 0.3) {
                    self.calendarToBottom.constant = 0
                    self.calendarFrameHeight.constant = 642
                    self.testview.layoutIfNeeded()
                    //print("############ \(self.calendarFrame.frame.height)")
                }
            }
        }
    }
    
    
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.down:
                weekMode = false
            case UISwipeGestureRecognizerDirection.up:
                weekMode = true
            default:
                break
            }
            changeMode(weekMode)
        }
    }
    
    // To be modified
    /*
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
    */
    
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
    
    //MARK: Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? UINavigationController else {return}
        
        guard let addEventVC = destinationVC.childViewControllers[0] as? AddEventViewController else {return}
        addEventVC.calendar = self.defaultCalendar
        addEventVC.delegate = self
        addEventVC.selectedDate = self.selectedDate
    }
    
    // MARK: Event Added Delegate, will be called by the assigned delegate
    func eventDidAdd(dates: [Date]) {
        //self.calendarView.reloadData()
        DispatchQueue.main.async {
           self.calendarView.reloadDates(dates)
        }
    }
    
    //MARK: Button Methods
    
    
    
    
    //MARK: private Methods
    func loadDefaultSettings() -> CalendarDefaultSetting? {  // This method has a return type of an optional array of Expense objects, meaning that it might return array of Expense objects or might return nothing (nil).
        
        let path = CalendarDefaultSetting.ArchiveURL.path
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: path) as? CalendarDefaultSetting
        // This method attempts to unarchive the object stored at the path Expense,ArchiveURL.path and downcast that object to an array of Expense objects.
    }
    
    func fetchDiaryByDate(_ selectedDate: Date) -> Diaries? {
        
        //获取数据上下文对象
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext
        
        //声明数据的请求
        let fetchRequest: NSFetchRequest<Diaries> = Diaries.fetchRequest()
        fetchRequest.fetchLimit = 10  //限制查询结果的数量
        fetchRequest.fetchOffset = 0  //查询的偏移量
        
        //声明一个实体结构
        let EntityName = "Diaries"
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: EntityName, in: context)
        fetchRequest.entity = entity
        
        //设置查询条件
        let predicate = NSPredicate(format: "timeStamp == %@",selectedDate as CVarArg)
        fetchRequest.predicate = predicate
        
        //查询操作
        do{
            let fetchedObjects = try context.fetch(fetchRequest)
            return fetchedObjects.first
        }catch {
            let nserror = error as NSError
            fatalError("查询错误： \(nserror), \(nserror.userInfo)")
        }
    }
    
    func createNewDiary(_ selectedDate: Date) -> Diaries{
        //init, add time stemp and empty content
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext
        let newDiary = Diaries(context: context)
        newDiary.timeStamp = selectedDate as NSDate
        newDiary.content = ""
        //app.saveContext()
        return newDiary
    }
    
    func saveDiary() {
        let app = UIApplication.shared.delegate as! AppDelegate
        //let context = app.persistentContainer.viewContext
        app.saveContext()
    }
    
    func configureCell(view: JTAppleCell?, cellState: CellState) {
        guard let myCustomCell = view as? CustomCell  else { return }
        handleCellSelected(validCell: myCustomCell, cellState: cellState)
        handleCellTextColor(validCell: myCustomCell, cellState: cellState)
    }
    
    func deleteDiary(_ myDiary: Diaries?) {
        if myDiary != nil {
            let app = UIApplication.shared.delegate as! AppDelegate
            let context = app.persistentContainer.viewContext
            //let context = myDiary.managedObjectContext // questionable, will this work?
            context.delete(myDiary!)
            app.saveContext()
        }
        
    }
    
    func getWeekNumber(_ date: Date) -> Float {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        let indateCount = 7 - calendar.component(.weekday, from: monthStart!)
        let dateCount = calendar.component(.day, from: date)
        return ceilf(Float(indateCount+dateCount)/7.00)
    }

    /*
    func loadCalendars() {
        
        let calendars = EKEventStore().calendars(for: EKEntityType.event)

    }
    */
    
    //func loadEvents(cellDate: Date) {
        //let predicate = self.eventStore.predicateForEvents(withStart: cellDate.startOfDay, end: cellDate.endOfDay!, calendars: nil)
        //let existingEvents = self.eventStore.events(matching: predicate)
        //for ele in existingEvents {
        //    print(ele.title)
        //}
    //}
}

extension JTCalendarViewController: JTAppleCalendarViewDataSource {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let startDate = formatter.date(from: "2017 01 01")!
        let endDate = formatter.date(from: "2017 12 31")!
        
        let parameters = ConfigurationParameters(
            startDate: startDate,
            endDate: endDate,
            numberOfRows: weekMode ? 1: 6,
            generateInDates: .forAllMonths,
            generateOutDates: weekMode ? .tillEndOfRow : .tillEndOfGrid,
            firstDayOfWeek: .monday,
            hasStrictBoundaries: false
        )
        return parameters
    }
}

extension JTCalendarViewController: JTAppleCalendarViewDelegate{
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.dateLabel.text = cellState.text
        self.configureCell(view: cell, cellState: cellState)
        
        let predicate = self.eventStore.predicateForEvents(withStart: date.startOfDay, end: date.endOfDay!, calendars: [self.defaultCalendar!] )
        let existingEvents = self.eventStore.events(matching: predicate)
        var eventsOfDay = [EKEvent]()
        var labelText: String = ""
        for ele in existingEvents {
            labelText = labelText + "\n" + ele.title
            eventsOfDay.append(ele)
        }
        eventList[date] = eventsOfDay
        
        cell.eventLabel.text = labelText
         
        if self.fetchDiaryByDate(date) != nil {
            cell.iconDiary.isHidden = false
        } else {
            cell.iconDiary.isHidden = true
        }
    
        return cell
    }
    
    // This method could be deleted
    func calendar(_ calendar: JTAppleCalendarView, willDisplayCell cell: JTAppleCell, date: Date, cellState: CellState) {
        
        cell.prepareForReuse()
        //cell.setupCellBeforeDisplay(cellState, date: date)
    }
    
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CustomCell else {return}
        if !validCell.selectedView.isHidden {self.switchDiaryMode()}
        self.selectedDate = date
        self.selectedCell = cell!
        self.configureCell(view: cell, cellState: cellState)
        
        if let fetchedDiary = self.fetchDiaryByDate(date) {
            self.diary = fetchedDiary
        } else {
            self.diary = nil
        }
        self.diaryTextField.text = self.diary?.content ?? ""
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        self.configureCell(view: cell, cellState: cellState)
        self.selectedDate = nil
        let cell = cell as? CustomCell
        
        if self.diaryTextField.text.isEmpty {
            self.deleteDiary(self.diary)
            cell?.iconDiary.isHidden = true
        } else {
            if self.diary != nil {
                self.diary!.content = self.diaryTextField.text
            } else {
                let newDiary = self.createNewDiary(date)
                newDiary.content = self.diaryTextField.text
            }
            cell?.iconDiary.isHidden = false
            self.saveDiary()
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        self.setupViewsOfCalendar(from: visibleDates)
        if selectedDate == nil {self.selectedDate = visibleDates.monthDates.first!.date}
        dateListThisMonth.removeAll()
        
        for ele in visibleDates.monthDates {
            dateListThisMonth.append(ele.date)
        }
        
        if self.weekMode {
            self.eventTableView.reloadData()
        }
    }
}

extension UIColor {
    convenience init(colorWithHexValue value: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
}
