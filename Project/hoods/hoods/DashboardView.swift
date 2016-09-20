//
//  DashboardView.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class DashboardView: UIView {
    
    var roundedCornerRadius = CGFloat()
    var hoodModule = HoodModule()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // rounded corners for feed view
        roundedCornerRadius = frame.size.width / 20
        layer.cornerRadius = roundedCornerRadius
        layer.masksToBounds = true
        
        backgroundColor = UIColor.white
                
        let views = [hoodModule]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            hoodModule.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            hoodModule.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            hoodModule.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            hoodModule.bottomAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 50),
        ]
        NSLayoutConstraint.activate(constraints)
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
