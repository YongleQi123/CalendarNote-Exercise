//
//  CheckboxLabel.swift
//  eventTracker
//
//  Created by Diqing Chang on 13.10.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit

class CheckboxLabel: UILabel {

    // Colors
    let uncheckedColor = UIColor.white
    let checkedColor = UIColor(colorWithHexValue: 0xB4B4B4)
    // Bool property
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.backgroundColor = checkedColor
            } else {
                self.backgroundColor = uncheckedColor
            }
        }
    }
    
    override func awakeFromNib() {
        self.isChecked = false
    }

}
