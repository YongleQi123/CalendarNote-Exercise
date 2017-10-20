//
//  LTPTableViewCell.swift
//  eventTracker
//
//  Created by Diqing Chang on 01.10.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit
import EventKit

class LTPTableViewCell: UITableViewCell {

    @IBOutlet weak var LTPTitle: UILabel!
    @IBOutlet weak var LTPStartDate: UILabel!
    @IBOutlet weak var LTPEndDate: UILabel!
    
    @IBOutlet weak var labelMon: CheckboxLabel!
    @IBOutlet weak var labelTue: CheckboxLabel!
    @IBOutlet weak var labelWed: CheckboxLabel!
    @IBOutlet weak var labelThu: CheckboxLabel!
    @IBOutlet weak var labelFri: CheckboxLabel!
    @IBOutlet weak var labelSat: CheckboxLabel!
    @IBOutlet weak var labelSun: CheckboxLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let colorMon = labelMon.backgroundColor
        let colorTue = labelTue.backgroundColor
        let colorWed = labelWed.backgroundColor
        let colorThu = labelThu.backgroundColor
        let colorFri = labelFri.backgroundColor
        let colorSat = labelSat.backgroundColor
        let colorSun = labelSun.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if(highlighted) {
            labelMon.backgroundColor = colorMon
            labelTue.backgroundColor = colorTue
            labelWed.backgroundColor = colorWed
            labelThu.backgroundColor = colorThu
            labelFri.backgroundColor = colorFri
            labelSat.backgroundColor = colorSat
            labelSun.backgroundColor = colorSun
        }
    }
    
    func initWeekDayCheckbox(event: EKEvent) {
        if let daysOfTheWeek = event.recurrenceRules?.first?.daysOfTheWeek {
            print("Loading recurrenceRules succeeded")
            for ele in daysOfTheWeek {
                self.checkWeekDayByHash(hashValue: ele.dayOfTheWeek.hashValue)
            }
        } else {
            print("Loading recurrenceRules failed")
        }
    }
    
    //MARK: Private Methods
    private func checkWeekDayByHash(hashValue: Int) {
        if hashValue == 1 {
            labelMon.isChecked = true
        } else if hashValue == 2 {
            labelTue.isChecked = true
        } else if hashValue == 3 {
            labelWed.isChecked = true
        } else if hashValue == 4 {
            labelThu.isChecked = true
        } else if hashValue == 5 {
            labelFri.isChecked = true
        } else if hashValue == 6 {
            labelSat.isChecked = true
        } else {
            labelSun.isChecked = true
        }
    }

}
