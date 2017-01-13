//
//  CameraView.swift
//  hoods
//
//  Created by Andrew Carvajal on 1/13/17.
//  Copyright © 2017 YugeTech. All rights reserved.
//

import UIKit
import UIKit

class CameraView: UIView {
    
    var roundedCornerRadius = CGFloat()
    let hoodView = HoodView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        roundedCornerRadius = frame.size.width / 20
        
        layer.cornerRadius = roundedCornerRadius
        layer.masksToBounds = true
        backgroundColor = UIColor.white
        
        hoodView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hoodView)
        
        let constraints: [NSLayoutConstraint] = [
            hoodView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: DataSource.sharedInstance.viewSize!.height),
            hoodView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            hoodView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            hoodView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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

