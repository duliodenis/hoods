//
//  FederationButton.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/23/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class FederationButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitle("Λ", forState: .Normal)
        titleLabel!.font = UIFont.systemFontOfSize(23)
        titleLabel!.adjustsFontSizeToFitWidth = true
        tintColor = UIColor.whiteColor()
        backgroundColor = UIColor.blackColor()
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
