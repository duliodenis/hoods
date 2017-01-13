//
//  HoodView.swift
//  hoods
//
//  Created by Andrew Carvajal on 10/21/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class HoodView: UIView {
    
    let hoodLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        hoodLabel.adjustsFontSizeToFitWidth = true
        hoodLabel.font = UIFont.boldSystemFont(ofSize: 42)
        hoodLabel.setContentHuggingPriority(251, for: .vertical)
        hoodLabel.textAlignment = .center
        
        let views = [hoodLabel]
        
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        
        let constraints: [NSLayoutConstraint] = [
            hoodLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            hoodLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            hoodLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            hoodLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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
