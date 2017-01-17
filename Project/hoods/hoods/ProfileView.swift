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
    
    var openRoundedCornerRadius = CGFloat()
    var closedRoundedCornerRadius = CGFloat()
    var profileConstraints = [NSLayoutConstraint]()
    let profileImageView = UIImageView()
    let profileFirstNameLabel = UILabel()
    let profileLastNameLabel = UILabel()
    var fbLoginButton = FBSDKLoginButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfile), name: NSNotification.Name(rawValue: "FetchedProfile"), object: nil)
        
        // profile properties
        openRoundedCornerRadius = 0
        closedRoundedCornerRadius = frame.size.width / 2
        layer.cornerRadius = closedRoundedCornerRadius
        layer.masksToBounds = true
        backgroundColor = UIColor.white
        
        // subview specific properties
        profileImageView.image = DataSource.sharedInstance.cropToBounds(UIImage(named: "profile_placeholder")!, width: Double(frame.width), height: Double(frame.height))
        profileImageView.layer.cornerRadius = (frame.width - 4) / 2
        profileImageView.layer.masksToBounds = true
                
        fbLoginButton.readPermissions = ["public_profile", "user_friends"]
        
        DataSource.sharedInstance.fetchProfile()
        
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
        
        updateProfile()
        
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
    
    @objc fileprivate func updateProfile() {
        
        profileFirstNameLabel.text = DataSource.sharedInstance.fbProfileDict["firstName"]
        profileLastNameLabel.text = DataSource.sharedInstance.fbProfileDict["lastName"]
        if FBSDKAccessToken.current() != nil {
            downloadImage(url: URL(string:"http://graph.facebook.com/\(FBSDKAccessToken.current().userID!)/picture?type=large")!)
        } else {
            profileImageView.image = UIImage(named: "profile_placeholder")
        }
    }
    
    func downloadImage(url: URL) {
        
        // use passed in url to asynchronously get image and set it to profile image view
        DataSource.sharedInstance.getDataFromURL(url: url) { (data, response, error) in
            DispatchQueue.main.sync() { () -> Void in
                guard let data = data, error == nil else { return }
//                print(response?.suggestedFilename ?? url.lastPathComponent)
                self.profileImageView.image = UIImage(data: data)
            }
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
