//
//  ModuleView.swift
//  hoods
//
//  Created by Andrew Carvajal on 9/12/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class ModuleView: UIView {
    
    var roundedCornerRadius = CGFloat()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // rounded corners for module view
        roundedCornerRadius = frame.size.width / 20
        layer.cornerRadius = roundedCornerRadius
        layer.masksToBounds = true
        
        backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
