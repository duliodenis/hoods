//
//  FederationButton.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/23/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class FederationButton: UIButton {
    
    let federationIconImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitle("✈️g", for: UIControlState())
        titleLabel!.font = UIFont.systemFont(ofSize: 23)
        titleLabel!.adjustsFontSizeToFitWidth = true
        tintColor = UIColor.white
        backgroundColor = UIColor.black
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true
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
