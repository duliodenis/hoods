//
//  ProfileView.swift
//  hoods
//
//  Created by Andrew Carvajal on 9/2/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class ProfileView: UIView {
    
    var profileConstraints = [NSLayoutConstraint]()
    let profileImageView = UIImageView()
    let profileFirstNameLabel = UILabel()
    let profileLastNameLabel = UILabel()
    var fbLoginButton = FBSDKLoginButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // profile properties
        layer.masksToBounds = true
        backgroundColor = UIColor.white
        
        // subview specific properties
        profileImageView.image = cropToBounds(UIImage(named: "yuge")!, width: Double(frame.width), height: Double(frame.height))
        profileImageView.layer.cornerRadius = (frame.width - 4) / 2
        profileImageView.layer.masksToBounds = true
        
        profileFirstNameLabel.text = "Andrew"
        profileLastNameLabel.text = "Carvajal"
        
        let labels = [profileFirstNameLabel, profileLastNameLabel]
        for label in labels {
            label.numberOfLines = 2
            label.textAlignment = .left
            label.font = UIFont.boldSystemFont(ofSize: 100)
            label.adjustsFontSizeToFitWidth = true
        }
        
        // subview common properties
        let subviews = [profileImageView, profileLastNameLabel, profileFirstNameLabel, fbLoginButton] as [Any]
        for sub in subviews {
            (sub as! UIView).translatesAutoresizingMaskIntoConstraints = false
            addSubview(sub as! UIView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func activateConstraintsForState(_ state: ProfileState) {
        
        // deactivate constraints
        NSLayoutConstraint.deactivate(profileConstraints)
        
        // activate constraints for state passed in
        if state == .closed {
            
            // closed profile constraints
            profileConstraints = [
                
                profileImageView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
                profileImageView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
                profileImageView.widthAnchor.constraint(equalToConstant: frame.width - 4),
                profileImageView.heightAnchor.constraint(equalToConstant: frame.height - 4),
                
                profileFirstNameLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 10),
                profileFirstNameLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: 10),
                profileFirstNameLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: 100),
                profileFirstNameLabel.bottomAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                
                profileLastNameLabel.topAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                profileLastNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 10),
                profileLastNameLabel.rightAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 100),
                profileLastNameLabel.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
                
                fbLoginButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
                fbLoginButton.leftAnchor.constraint(equalTo: profileImageView.leftAnchor),
                fbLoginButton.rightAnchor.constraint(equalTo: profileLastNameLabel.rightAnchor),
                fbLoginButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            ]
            
            DataSource.sharedInstance.profileState = .closed
        } else {
            
            // open profile constraints
            profileConstraints = [
                profileImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 10),
                profileImageView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 10),
                profileImageView.widthAnchor.constraint(equalToConstant: frame.width / 3),
                profileImageView.heightAnchor.constraint(equalToConstant: frame.width / 3),
                
                profileFirstNameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 10),
                profileFirstNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 10),
                profileFirstNameLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -5),
                profileFirstNameLabel.bottomAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                
                profileLastNameLabel.topAnchor.constraint(equalTo: profileImageView.centerYAnchor),
                profileLastNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 10),
                profileLastNameLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -5),
                profileLastNameLabel.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -10),
                
                fbLoginButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
                fbLoginButton.leftAnchor.constraint(equalTo: profileImageView.leftAnchor),
                fbLoginButton.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -10),
                fbLoginButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 35)
            ]
            
            DataSource.sharedInstance.profileState = .open
        }
        
        // activate constraints
        NSLayoutConstraint.activate(profileConstraints)
    }
    
    fileprivate func cropToBounds(_ image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage = UIImage(cgImage: image.cgImage!)
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
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgWidth, height: cgHeight)
        
        // create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // create a new image based on the imageRef and rotate back to the original orientation
        let image = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
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
