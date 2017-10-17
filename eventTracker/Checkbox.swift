//
//  Checkbox.swift
//  eventTracker
//
//  Created by Diqing Chang on 03.10.17.
//  Copyright © 2017 ChangDiqing. All rights reserved.
//

import UIKit

class CheckBox: UIButton {
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
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControlEvents.touchUpInside)
        self.isChecked = false
    }
    
    func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
/*
extension UIColor {
    convenience init(colorWithHexValue value: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}*/
