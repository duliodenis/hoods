//
//  HoodModule.swift
//  hoods
//
//  Created by Andrew Carvajal on 9/12/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class HoodModule: ModuleView {
    
    let currentHoodLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        currentHoodLabel.adjustsFontSizeToFitWidth = true
        currentHoodLabel.font = UIFont.boldSystemFontOfSize(42)
        currentHoodLabel.setContentHuggingPriority(251, forAxis: .Vertical)
        currentHoodLabel.textAlignment = .Center
                
        let views = [currentHoodLabel]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            currentHoodLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor),
            currentHoodLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor),
            currentHoodLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor),
            currentHoodLabel.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor, constant: 50),
        ]
        NSLayoutConstraint.activateConstraints(constraints)
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
