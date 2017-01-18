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
    let weatherLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        
        hoodLabel.text = "HOODS"
        areaLabel.alpha = 0
        areaLabel.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        weatherLabel.text = "⛈⛈"
        
        let labels = [areaLabel, hoodLabel, weatherLabel]
        for label in labels {
            label.textAlignment = .center
            label.numberOfLines = 0
            label.adjustsFontSizeToFitWidth = true
            label.font = UIFont.boldSystemFont(ofSize: 100)
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        addSubview(button)
        
        let frameHeight = (DataSource.si.viewSize?.height)! * 0.15
        
        let constraints: [NSLayoutConstraint] = [
            hoodLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            hoodLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            hoodLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            hoodLabel.heightAnchor.constraint(equalToConstant: frameHeight * 0.6),
            
            areaLabel.topAnchor.constraint(equalTo: hoodLabel.topAnchor),
            areaLabel.leftAnchor.constraint(equalTo: hoodLabel.leftAnchor),
            areaLabel.rightAnchor.constraint(equalTo: hoodLabel.rightAnchor),
            areaLabel.bottomAnchor.constraint(equalTo: hoodLabel.bottomAnchor),
            
            button.topAnchor.constraint(equalTo: hoodLabel.topAnchor),
            button.leftAnchor.constraint(equalTo: hoodLabel.leftAnchor),
            button.rightAnchor.constraint(equalTo: hoodLabel.rightAnchor),
            button.bottomAnchor.constraint(equalTo: hoodLabel.bottomAnchor),
            
            weatherLabel.topAnchor.constraint(equalTo: hoodLabel.bottomAnchor),
            weatherLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            weatherLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            weatherLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func buttonTapped(sender: UIButton) {
        
        // if hood label showing, hide hood label and show area label for 5 seconds
        if areaLabel.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                self.hoodLabel.alpha = 0
            }, completion: { finished in
                
                self.hoodLabel.isHidden = true
                self.areaLabel.isHidden = false
                UIView.animate(withDuration: 1, animations: {
                    self.areaLabel.alpha = 1
                })
            })
            
        // else if area label is showing, hide area label and show hood label
        } else {
            UIView.animate(withDuration: 0.3, animations: { 
                self.areaLabel.alpha = 0
            }, completion: { finished in
                
                self.areaLabel.isHidden = true
                self.hoodLabel.isHidden = false
                UIView.animate(withDuration: 1, animations: { 
                    self.hoodLabel.alpha = 1
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
