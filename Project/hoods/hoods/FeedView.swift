//
//  FeedView.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class FeedView: UIView {
    
    let currentHoodLabel = UILabel()
    let vPlaceholder = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // rounded corners for feed view
        layer.cornerRadius = frame.size.width * 0.05
        layer.masksToBounds = true
        
        backgroundColor = UIColor.whiteColor()
        
        currentHoodLabel.adjustsFontSizeToFitWidth = true
        currentHoodLabel.font = UIFont.boldSystemFontOfSize(42)
        currentHoodLabel.setContentHuggingPriority(251, forAxis: .Vertical)
        currentHoodLabel.textAlignment = .Center
        
        vPlaceholder.backgroundColor = UIColor.whiteColor()
        
        let views = [currentHoodLabel, vPlaceholder]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            currentHoodLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor),
            currentHoodLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor),
            currentHoodLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor),            currentHoodLabel.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor, constant: 40),
            
            vPlaceholder.topAnchor.constraintEqualToAnchor(currentHoodLabel.bottomAnchor),
            vPlaceholder.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor),
            vPlaceholder.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor),
            vPlaceholder.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.bottomAnchor, constant: -10)
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
