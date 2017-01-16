//
//  HoodView.swift
//  hoods
//
//  Created by Andrew Carvajal on 10/21/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class HoodView: UIView {
    
    let button = UIButton()
    let areaLabel = UILabel()
    let hoodLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        hoodLabel.text = "HOODS"
        areaLabel.alpha = 0
        areaLabel.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        let labels = [areaLabel, hoodLabel]
        for label in labels {
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.font = UIFont.boldSystemFont(ofSize: 42)
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        addSubview(button)
        
        let constraints: [NSLayoutConstraint] = [
            hoodLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            hoodLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            hoodLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            hoodLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            
            areaLabel.topAnchor.constraint(equalTo: hoodLabel.topAnchor),
            areaLabel.leftAnchor.constraint(equalTo: hoodLabel.leftAnchor),
            areaLabel.rightAnchor.constraint(equalTo: hoodLabel.rightAnchor),
            areaLabel.bottomAnchor.constraint(equalTo: hoodLabel.bottomAnchor),
            
            button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            button.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            button.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func buttonTapped(sender: UIButton) {
        
        if areaLabel.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.hoodLabel.alpha = 0
            }, completion: { finished in
                
                self.hoodLabel.isHidden = true
                self.areaLabel.isHidden = false
                UIView.animate(withDuration: 1, animations: {
                    self.areaLabel.alpha = 1
                    
                }, completion: { finished in
                    UIView.animate(withDuration: 5, delay: 3, options: .curveEaseIn, animations: {
                        self.areaLabel.alpha = 0
                        
                    }, completion: { finished in
                        
                        self.areaLabel.isHidden = true
                        self.hoodLabel.isHidden = false
                        UIView.animate(withDuration: 1, animations: { 
                            self.hoodLabel.alpha = 1
                        })
                    })
                })
            })
        }
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
