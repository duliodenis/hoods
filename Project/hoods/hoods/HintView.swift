//
//  HintView.swift
//  hoods
//
//  Created by Andrew Carvajal on 1/18/17.
//  Copyright © 2017 YugeTech. All rights reserved.
//

import UIKit

class HintView: UIView {
    
    let button = UIButton()
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 100)
        addSubview(label)
        
        let constraints: [NSLayoutConstraint] = [
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 10),
            label.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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