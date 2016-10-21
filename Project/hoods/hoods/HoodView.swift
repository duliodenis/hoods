//
//  HoodView.swift
//  hoods
//
//  Created by Andrew Carvajal on 10/21/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class HoodView: UIView {
    
    var roundedCornerRadius = CGFloat()
    let currentHoodLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        roundedCornerRadius = frame.size.width / 20

        layer.cornerRadius = frame.size.width / 20
        layer.masksToBounds = true
        backgroundColor = UIColor.white
        
        currentHoodLabel.adjustsFontSizeToFitWidth = true
        currentHoodLabel.font = UIFont.boldSystemFont(ofSize: 42)
        currentHoodLabel.setContentHuggingPriority(251, for: .vertical)
        currentHoodLabel.textAlignment = .center
        
        let views = [currentHoodLabel]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            currentHoodLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 20),
            currentHoodLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            currentHoodLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            currentHoodLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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
