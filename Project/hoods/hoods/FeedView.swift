//
//  FeedView.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class FeedView: UIView {
    
    let youAreInLabel = UILabel()
    let currentHoodLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // rounded corners for feed view
        layer.cornerRadius = frame.size.width * 0.05
        layer.masksToBounds = true
        
        backgroundColor = UIColor.whiteColor()
        
        youAreInLabel.font = UIFont.systemFontOfSize(23)
        youAreInLabel.text = "You are in"
        youAreInLabel.setContentHuggingPriority(251, forAxis: .Vertical)
        
        currentHoodLabel.font = UIFont.systemFontOfSize(50)
        
        let labels = [youAreInLabel, currentHoodLabel]
        
        for label in labels {
            label.textAlignment = .Center
            label.adjustsFontSizeToFitWidth = true
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        
        let constraints: [NSLayoutConstraint] = [
            youAreInLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor),
            youAreInLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor),
            youAreInLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerXAnchor),
            youAreInLabel.bottomAnchor.constraintEqualToAnchor(currentHoodLabel.topAnchor, constant: frame.size.height * 0.25),
            
            currentHoodLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor),
            currentHoodLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor),
            currentHoodLabel.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.bottomAnchor, constant: -10)
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
