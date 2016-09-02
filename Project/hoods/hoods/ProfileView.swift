//
//  ProfileView.swift
//  hoods
//
//  Created by Andrew Carvajal on 9/2/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

class ProfileView: UIView {
    
    var profileConstraints = [NSLayoutConstraint]()
    let profileImageView = UIImageView()
    let profileFirstNameLabel = UILabel()
    let profileLastNameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // profile properties
        layer.masksToBounds = true
        backgroundColor = UIColor.whiteColor()
        
        // subview specific properties
        profileImageView.image = cropToBounds(UIImage(named: "yuge")!, width: Double(frame.width), height: Double(frame.height))
        profileImageView.layer.cornerRadius = (frame.width - 4) / 2
        profileImageView.layer.masksToBounds = true
        
        profileFirstNameLabel.text = "Andrew"
        profileLastNameLabel.text = "Carvajal"
        
        let labels = [profileFirstNameLabel, profileLastNameLabel]
        for label in labels {
            label.numberOfLines = 2
            label.textAlignment = .Left
            label.font = UIFont.systemFontOfSize(100)
            label.adjustsFontSizeToFitWidth = true
        }
        
        // subview common properties
        let subviews = [profileImageView, profileFirstNameLabel, profileLastNameLabel]
        for sub in subviews {
            sub.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sub)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func activateConstraintsForState(state: ProfileState) {
        
        // deactivate constraints
        NSLayoutConstraint.deactivateConstraints(profileConstraints)
        
        // activate constraints for state passed in
        if state == .Closed {
            print("ProfileView:deactivating constraints and activating CLOSED constraints")
            
            // closed profile constraints
            profileConstraints = [
                profileImageView.centerXAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerXAnchor),
                profileImageView.centerYAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerYAnchor),
                profileImageView.widthAnchor.constraintEqualToConstant(frame.width - 4),
                profileImageView.heightAnchor.constraintEqualToConstant(frame.width - 4),
                
                profileFirstNameLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor, constant: 10),
                profileFirstNameLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: 10),
                profileFirstNameLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: 100),
                profileFirstNameLabel.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerYAnchor, constant: 0),
                
                profileLastNameLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerYAnchor, constant: 0),
                profileLastNameLabel.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: 10),
                profileLastNameLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: 100),
                profileLastNameLabel.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.bottomAnchor, constant: -10)
            ]
            
            DataSource.sharedInstance.profileState = .Closed
        } else {
            print("ProfileView:deactivating constraints and activating OPEN constraints")
            
            // open profile constraints
            profileConstraints = [
                profileImageView.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor, constant: 10),
                profileImageView.leftAnchor.constraintEqualToAnchor(layoutMarginsGuide.leftAnchor, constant: 10),
                profileImageView.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerXAnchor, constant: -10),
                profileImageView.bottomAnchor.constraintEqualToAnchor(layoutMarginsGuide.centerYAnchor, constant: -10),
                
                profileFirstNameLabel.topAnchor.constraintEqualToAnchor(layoutMarginsGuide.topAnchor, constant: 20),
                profileFirstNameLabel.leftAnchor.constraintEqualToAnchor(profileImageView.rightAnchor, constant: 10),
                profileFirstNameLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: -10),
                profileFirstNameLabel.bottomAnchor.constraintEqualToAnchor(profileImageView.centerYAnchor, constant: 0),
                
                profileLastNameLabel.topAnchor.constraintEqualToAnchor(profileImageView.centerYAnchor, constant: 0),
                profileLastNameLabel.leftAnchor.constraintEqualToAnchor(profileImageView.rightAnchor, constant: 10),
                profileLastNameLabel.rightAnchor.constraintEqualToAnchor(layoutMarginsGuide.rightAnchor, constant: -10),
                profileLastNameLabel.bottomAnchor.constraintEqualToAnchor(profileImageView.bottomAnchor, constant: -20)
            ]
            
            DataSource.sharedInstance.profileState = .Open
        }
        
        // activate constraints
        NSLayoutConstraint.activateConstraints(profileConstraints)
    }
    
    private func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage = UIImage(CGImage: image.CGImage!)
        let contextSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgWidth = CGFloat(width)
        var cgHeight = CGFloat(height)
        
        // see what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = (contextSize.width - contextSize.height) / 2
            posY = 0
            cgWidth = contextSize.height
            cgHeight = contextSize.height
        } else {
            posX = 0
            posY = (contextSize.height - contextSize.width) / 2
            cgWidth = contextSize.width
            cgHeight = contextSize.width
        }
        let rect: CGRect = CGRectMake(posX, posY, cgWidth, cgHeight)
        
        // create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // create a new image based on the imageRef and rotate back to the original orientation
        let image = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
