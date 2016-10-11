//
//  MapViewController.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit
import Mapbox
import MapKit

class MapViewController: UIViewController {
    
    // gestures
    fileprivate var tap = UITapGestureRecognizer()
    fileprivate var dashboardPan = UIPanGestureRecognizer()
    fileprivate var profilePan = UIPanGestureRecognizer()
    
    // map
    fileprivate let manhattan = CLLocationCoordinate2DMake(40.722716755829168, -73.986322678333224)
    @IBOutlet var mapboxView: MGLMapView!
    
    // dashboard
    fileprivate var dashboardView = DashboardView()
    let dashboardMinimizedHeight: CGFloat = 120
    let padding: CGFloat = 20
    
    // search
    fileprivate var searchResultsView = SearchResultsView()
    
    // profile
    fileprivate var profileView = ProfileView()
    fileprivate var profileViewShadow = UIView()
    fileprivate var profileButton = UIButton()
    
    // federation button
    fileprivate var federationButton = FederationButton()
    fileprivate var federationButtonShadow = UIView()
    
    // misc
    fileprivate var frameDict = [String:CGRect]()
    fileprivate var hoodScanning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpNotificationCenter()

        // Mapbox view
        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.clear
        mapboxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // location manager
        DataSource.sharedInstance.locationManager.delegate = self
        DataSource.sharedInstance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.sharedInstance.locationManager.distanceFilter = kCLDistanceFilterNone

        populateFrameDict()
        
        addTapGesture()
        addFederationButton()
        addProfile()
        addSearchResultsView()
        addDashboardView()
        dashboardView.searchModule.searchBar.delegate = self
        addDashboardPanGestureToMap()
        
        attemptToMoveCameraToUserLocation()
    }
    
    func appDidBecomeActive() {
        attemptToMoveCameraToUserLocation()
        attemptToUpdateHoodLabel(with: (DataSource.sharedInstance.locationManager.location?.coordinate)!, fromTap: false)
        moveDashboardTo(.minimized, sender: UIPanGestureRecognizer())
        moveSearchResultsViewTo(.minimized)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: Camera
    
    fileprivate func moveCameraTo(_ coord: CLLocationCoordinate2D, distance: CLLocationDistance, zoom: Double, pitch: CGFloat, duration: TimeInterval, animatedCenterChange: Bool) {
        
        // if the camera is not already on the coords passed in, move camera
        if mapboxView.centerCoordinate.latitude != coord.latitude && mapboxView.centerCoordinate.longitude != coord.longitude {
            mapboxView.setCenter(coord, zoomLevel: zoom, direction: 0, animated: animatedCenterChange, completionHandler: {
            })
            let camera = MGLMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: 0)
            mapboxView.setCamera(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
    }
    
    @objc fileprivate func attemptToMoveCameraToUserLocation() {
                
        // if location available, start far out and then zoom into location at an angle over 3s
        if let centerCoordinate = DataSource.sharedInstance.locationManager.location?.coordinate {
            
            // start far out at a 50° angle
            moveCameraTo(CLLocationCoordinate2DMake(centerCoordinate.latitude - 0.05, centerCoordinate.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into your location at a 30° angle over 3 seconds
            moveCameraTo(centerCoordinate, distance: 5000, zoom: 10, pitch: 30, duration: 4, animatedCenterChange: false)
            
        // else move camera into manhattan from 50° to 30° over 3 seconds
        } else {
            moveCameraToManhattanAnimated(true)
        }
    }
    
    fileprivate func moveCameraToManhattanAnimated(_ animated: Bool) {
        
        if animated {
            
            // start far out at a 50° angle
            moveCameraTo(CLLocationCoordinate2DMake(manhattan.latitude - 0.05, manhattan.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into manhattan at a 30° angle over 3 seconds
            moveCameraTo(manhattan, distance: 5000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
            
        } else {
            
            // set camera to manhattan instantly
            moveCameraTo(manhattan, distance: 13000, zoom: 10, pitch: 30, duration: 0, animatedCenterChange: false)
        }
    }
    
// MARK: Dashboard
    
    fileprivate func addDashboardView() {
        
        dashboardView = DashboardView(frame: CGRect(x: 0, y: view.frame.maxY - dashboardMinimizedHeight, width: view.frame.width, height: view.frame.height))
        dashboardView.hoodModule.currentHoodLabel.text = "Hoods"
        view.addSubview(dashboardView)
    }
    
    fileprivate func moveDashboardTo(_ state: DashboardState, sender: UIPanGestureRecognizer) {
        switch state {
        case .full:
            
            // animate the dashboard to the top
            UIView.animate(withDuration: 0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: { () -> Void in
                
                self.dashboardView.frame = self.frameDict["dashboardViewFull"]!
                }, completion: { (Bool) -> Void in
                    
                    // sharpen dashboard corners
                    if DataSource.sharedInstance.dashboardState != .full {
                        self.dashboardView.animateCornerRadiusOf(self.dashboardView, fromValue: self.dashboardView.roundedCornerRadius, toValue: 0.0, duration: 1)
                    }
                    
                    // update state last
                    DataSource.sharedInstance.dashboardState = .full
            })
        case .minimized:
            
            // round dashboard corners
            if DataSource.sharedInstance.dashboardState != .minimized {
                self.dashboardView.animateCornerRadiusOf(dashboardView, fromValue: 0.0, toValue: self.dashboardView.roundedCornerRadius, duration: 0.5)
            }
            
            // hide keyboard
            dashboardView.searchModule.searchBar.resignFirstResponder()
            
            // move the dashboard's minY to minimized -100
            UIView.animate(withDuration: 0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: { () -> Void in
                
                self.dashboardView.frame = self.frameDict["dashboardViewMinimized"]!
                }, completion: { (Bool) -> Void in
                    
                    // update state last
                    DataSource.sharedInstance.dashboardState = .minimized
            })
        case .searching:
            
            UIView.animate(withDuration: 0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: { 
                
                self.dashboardView.frame = self.frameDict["dashboardViewSearching"]!
                }, completion: { (Bool) in
                    
                    // update state
                    DataSource.sharedInstance.dashboardState = .searching
            })
        }
    }
    
// MARK: Search Results
    
    fileprivate func addSearchResultsView() {
        searchResultsView = SearchResultsView(frame: frameDict["searchResultsViewMinimized"]!)
        view.addSubview(searchResultsView)
    }
    
    fileprivate func moveSearchResultsViewTo(_ state: DashboardState) {
        switch state {
        case .minimized:
            
            // round search results corners
            if DataSource.sharedInstance.dashboardState != .minimized {
                self.searchResultsView.animateCornerRadiusOf(searchResultsView, fromValue: 0.0, toValue: self.searchResultsView.roundedCornerRadius, duration: 0.5)
            }

            
            UIView.animate(withDuration: 0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: { () -> Void in
                
                self.searchResultsView.frame = self.frameDict["searchResultsViewMinimized"]!
                }, completion: { (Bool) -> Void in
            })
            
        case .searching:
            
            UIView.animate(withDuration: 0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: { () -> Void in
                
                self.searchResultsView.frame = self.frameDict["searchResultsViewSearching"]!
                }, completion: { (Bool) -> Void in
                    
                    // sharpen search results corners
                    if DataSource.sharedInstance.dashboardState != .searching {
                        self.searchResultsView.animateCornerRadiusOf(self.searchResultsView, fromValue: self.searchResultsView.roundedCornerRadius, toValue: 0.0, duration: 0.5)
                    }
            })
        default: break
        }
    }
    
// MARK: Profile
    
    fileprivate func addProfile() {
        
        // add the profile view with profile frame CLOSED
        profileView = ProfileView(frame: frameDict["profileViewHidden"]!)

        // add the profile view shadow
        profileViewShadow = UIView(frame: frameDict["profileViewShadowHidden"]!)
        profileViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        profileViewShadow.layer.cornerRadius = profileViewShadow.frame.width / 2
        profileViewShadow.layer.masksToBounds = true
        
        // set the profile button frame to CLOSED
        profileButton.frame = frameDict["profileViewHidden"]!
        profileButton.addTarget(self, action: #selector(MapViewController.profileButtonTapped(_:)), for: .touchUpInside)
        
        mapboxView.addSubview(profileViewShadow)
        mapboxView.addSubview(profileView)
        mapboxView.addSubview(profileButton)
        
        addProfilePanGesture()
        
        // activate constraints for closed profile
        if DataSource.sharedInstance.profileState == nil {
            profileView.activateConstraintsForState(.closed)
        }
    }
    
    fileprivate func addProfilePanGesture() {
        profilePan = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.profilePanFired(_:)))
        profilePan.delegate = self
        profileView.addGestureRecognizer(profilePan)
    }
    
    @objc fileprivate func profilePanFired(_ sender: UIPanGestureRecognizer) {
        
        // if the pan was not in the profile pic and the profile was not closed already
        if !profileView.profileImageView.frame.contains(sender.location(in: profileView)) || DataSource.sharedInstance.profileState != .closed {
            toggleProfileSizeForState(.closed)
            
            self.profileView.layer.cornerRadius = self.profileView.closedRoundedCornerRadius
        }
    }
    
    @objc fileprivate func profileButtonTapped(_ sender: UIButton) {
        
        if DataSource.sharedInstance.mapButtonState != .hiding {
            toggleProfileSizeForState(.open)
            self.profileView.animateCornerRadiusOf(self.profileView, fromValue: self.profileView.openRoundedCornerRadius, toValue: 0.0, duration: 0)
        }
    }
    
    fileprivate func toggleProfileSizeForState(_ desiredState: ProfileState) {
        
        // open the profile
        if desiredState == .open {
            
            // lock the map
            mapboxView.allowsScrolling = false
            mapboxView.allowsZooming = false
            
            // bring profile over dashboard
            mapboxView.bringSubview(toFront: profileViewShadow)
            mapboxView.bringSubview(toFront: profileView)
            mapboxView.bringSubview(toFront: profileButton)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                
                // set the profile frame and its shadow to OPEN
                self.profileView.frame = self.frameDict["profileViewOpen"]!
                self.profileViewShadow.frame = self.frameDict["profileViewShadowOpen"]!
                
                // activate the profile subview constraints for OPENED state
                self.profileView.activateConstraintsForState(.open)
                
                // set the profile button frame to 0
                self.profileButton.frame = CGRect.zero
                }, completion: { (Bool) in
            })
         
        // else close it
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: {
                
                // set the profile frame to CLOSED
                self.profileView.frame = self.frameDict["profileViewClosed"]!
                self.profileViewShadow.frame = self.frameDict["profileViewShadowClosed"]!
                
                // activate the profile subview constraints for CLOSED state
                self.profileView.activateConstraintsForState(.closed)
                
                // set the profile button frame to profile frame CLOSED
                self.profileButton.frame = self.frameDict["profileViewClosed"]!
                }, completion: { (Bool) in
                    
                    // unlock the map
                    self.mapboxView.allowsScrolling = true
                    self.mapboxView.allowsZooming = true
                    
                    // bring dashboard over profile
                    self.mapboxView.bringSubview(toFront: self.dashboardView)
                    
                    self.hideMapIcons()
            })
        }
    }
    
// MARK: Federation Button
    
    func addFederationButton() {
        
        // button
        let federationButtonSize = CGSize(width: 50, height: 50)
        federationButton = FederationButton(frame: frameDict["federationButtonHidden"]!)
        federationButton.addTarget(self, action: #selector(MapViewController.federationButtonTapped), for: .touchUpInside)
        
        // shadow
        federationButtonShadow = UIView(frame: frameDict["federationButtonShadowHidden"]!)
        federationButtonShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        federationButtonShadow.layer.cornerRadius = federationButtonSize.width / 2
        federationButtonShadow.layer.masksToBounds = true
        
        view.addSubview(federationButtonShadow)
        view.addSubview(federationButton)
    }
    
    @objc fileprivate func federationButtonTapped(_ sender: UIButton) {
        
        // close profile
        if DataSource.sharedInstance.profileState == .open {
            toggleProfileSizeForState(.closed)
        }
        
        // animate the color green for half a sec
        federationButton.backgroundColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)
        UIView.animate(withDuration: 0.1, animations: {
            self.federationButton.backgroundColor = UIColor.black
            self.federationButton.frame = self.frameDict["federationButtonTapped"]!
            self.federationButtonShadow.frame = self.frameDict["federationButtonShadowTapped"]!
        }, completion: { (Bool) in
            UIView.animate(withDuration: 0.2, animations: {
                self.federationButton.frame = self.frameDict["federationButtonNormal"]!
                self.federationButtonShadow.frame = self.frameDict["federationButtonShadowNormal"]!
            })
        }) 
        
        // if location is available
        if DataSource.sharedInstance.locationManager.location != nil {
            
            DataSource.sharedInstance.hoodState = .currentHood
            
            // zoom to location
            attemptToMoveCameraToUserLocation()
        }
    }
    
// MARK: Touches
    
    fileprivate func addTapGesture() {
        
        tap.delegate = self
        tap.addTarget(self, action: #selector(tapFired))
        tap.delaysTouchesBegan = true
        tap.cancelsTouchesInView = true
        mapboxView.addGestureRecognizer(tap)
    }
    
    fileprivate func addDashboardPanGestureToMap() {

        dashboardPan = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.dashboardPanFired(_:)))
        dashboardPan.delegate = self
        mapboxView.addGestureRecognizer(dashboardPan)
    }
    
    @objc fileprivate func tapFired(_ sender: UITapGestureRecognizer) {
        
    // map behavior
        
        // get address of touch location
        let tappedLocation = mapboxView.convert(sender.location(in: mapboxView), toCoordinateFrom: mapboxView)
        
        // update hood state
        DataSource.sharedInstance.hoodState = .otherHood
        
        // update hood module
        attemptToUpdateHoodLabel(with: tappedLocation, fromTap: false)
        
    // profile behavior
        
        // if profile is open
        if DataSource.sharedInstance.profileState == .open {
            
            // and tap is outside profile
            if !profileView.frame.contains(sender.location(in: mapboxView)) {
                
                // hide map icons and close profile
                hideMapIcons()
                toggleProfileSizeForState(.closed)
            }
        }
        
    // dashboard behavior
        
        dashboardView.searchModule.searchBar.resignFirstResponder()
        moveDashboardTo(.minimized, sender: UIPanGestureRecognizer())
    }
    
    @objc fileprivate func dashboardPanFired(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: mapboxView)
        let touchLocation = sender.location(in: mapboxView)
        
        // pan gesture is inside dashboard view
        if dashboardView.frame.contains(touchLocation) {
            
            // pan gesture just ended
            if dashboardPan.state == .changed {
                
                // pan gesture is going up at least 12
                if translation.y <= -12 {
                    moveDashboardTo(.full, sender: sender)
                    
                    // close profile
                    if DataSource.sharedInstance.profileState == .open {
                        toggleProfileSizeForState(.closed)
                    }
                    
                // pan gesture is going down at least 12
                } else if translation.y >= 12 {
                    moveDashboardTo(.minimized, sender: sender)
                    moveSearchResultsViewTo(.minimized)
                }
            }
        }
    }
    
// MARK: Offline Maps
    
    fileprivate func startOfflinePackDownload() {
        
        let latitude = DataSource.sharedInstance.locationManager.location?.coordinate.latitude
        let longitude = DataSource.sharedInstance.locationManager.location?.coordinate.longitude
        
        // create a region that includes the current viewport and any tiles needed to view it when zoomed further in
        let region = MGLTilePyramidOfflineRegion(styleURL: mapboxView.styleURL, bounds: MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(latitude! - 0.3, longitude! - 0.3), CLLocationCoordinate2DMake(latitude! + 0.3, longitude! + 0.3)), fromZoomLevel: mapboxView.zoomLevel, toZoomLevel: 10)
        
        // store some data for identification purposes alongside the downloaded resources
        let userInfo = ["name": "My Offline Pack"]
        let context = NSKeyedArchiver.archivedData(withRootObject: userInfo)
        
        // create and register an offline pack with the shared offline storage object
        MGLOfflineStorage.shared().addPack(for: region, withContext: context) { (pack, error) in
            guard error == nil else {
                
                // the pack couldn't be created for some reason
                print("error: \(error?.localizedDescription)")
                return
            }
            
            // start downloading
            pack!.resume()
        }
    }
    
    @objc fileprivate func offlinePackProgressDidChange(_ notification: Notification) {
        
        // get the offline pack this notifiction is regarding,
        // and the associated user info for the pack; in this case, 'name = My Offline Pack'
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String:String] {
            
            let progress = pack.progress
            
            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // calculate current progress percentage
            let progressPercentage = Float(completedResources) / Float(expectedResources)
        
            // if this pack has finished, print its size and its resource count
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack '\(userInfo["name"])' completed: \(byteCount), \(completedResources) resources")
            } else {
                
                // otherwise, print download/verification progress
                print("Offline pack '\(userInfo["name"])' has \(completedResources) of \(expectedResources) resources - \(progressPercentage * 100)%")
            }
        }
    }
    
    @objc fileprivate func offlinePackDidReceiveError(_ notification: Notification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String:String],
            let error = (notification as NSNotification).userInfo?[MGLOfflinePackErrorUserInfoKey] as? NSError {
            
            print("Offline pack '\(userInfo["name"])' received error: \(error.localizedFailureReason)")
        }
    }
    
    @objc fileprivate func offlinePackDidReceiveMaximumAllowedMapboxTiles(_ notification: Notification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String:String],
            let maximumCount = ((notification as NSNotification).userInfo?[MGLOfflinePackMaximumCountUserInfoKey] as AnyObject).uint64Value {
            
            print("Offline pack '\(userInfo["name"])' reached limit of \(maximumCount) tiles")
        }
    }
    
// MARK: Miscellaneous
    
    func attemptToUpdateHoodLabel(with location: CLLocationCoordinate2D, fromTap: Bool) {
        
        // use hood check to try and set current hood label
        if DataSource.sharedInstance.locationManager.location != nil {
            
            if fromTap == true {
                if let newLocation = DataSource.sharedInstance.tappedHoodName(location) {
                    
                    // hood check succeeded but returned blank name
                    if newLocation != "" {
                        self.dashboardView.hoodModule.currentHoodLabel.text = newLocation
                    } else {
                        self.dashboardView.hoodModule.currentHoodLabel.text = "Hoods"
                    }
                } else {
                    self.dashboardView.hoodModule.currentHoodLabel.text = "Hoods"
                }
            }
            if let newLocation = DataSource.sharedInstance.lastVisitedHoodName(location) {
                
                // hood check succeeded but returned blank name
                if newLocation != "" {
                    self.dashboardView.hoodModule.currentHoodLabel.text = newLocation
                } else {
                    self.dashboardView.hoodModule.currentHoodLabel.text = "Hoods"
                }
            } else {
                self.dashboardView.hoodModule.currentHoodLabel.text = "Hoods"
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        
        // if motion was a shake and location available
        if motion == .motionShake {
            showMapIcons()
        }
    }
    
    fileprivate func showMapIcons() {
                
        // if buttons are not already showing
        if DataSource.sharedInstance.mapButtonState != .shown {
            
            // animate showing of icons
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .curveEaseIn, animations: {
                
                // set map button state to Shown
                DataSource.sharedInstance.mapButtonState = .shown
                
                self.profileViewShadow.frame = self.frameDict["profileViewShadowClosed"]!
                self.profileView.frame = self.frameDict["profileViewClosed"]!
                self.profileButton.frame = self.frameDict["profileViewClosed"]!
                self.federationButtonShadow.frame = self.frameDict["federationButtonShadowNormal"]!
                self.federationButton.frame = self.frameDict["federationButtonNormal"]!
                
                // then hide them
                }, completion: { finished in
                    
                    self.hideMapIcons()
            })
        }
    }
    
    fileprivate func hideMapIcons() {
        
        // delay using timer
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(7 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            
            // if profile is not open, proceed with hiding of icons
            if DataSource.sharedInstance.profileState != .open {
                
                // animate hiding of icons
                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .curveEaseIn, animations: {
                    
                    DataSource.sharedInstance.mapButtonState = .hiding
                    
                    if DataSource.sharedInstance.profileState == .open {
                        self.toggleProfileSizeForState(.closed)
                    }
                    self.profileViewShadow.frame = self.frameDict["profileViewShadowHidden"]!
                    self.profileView.frame = self.frameDict["profileViewHidden"]!
                    self.profileButton.frame = self.frameDict["profileViewHidden"]!
                    self.federationButtonShadow.frame = self.frameDict["federationButtonShadowHidden"]!
                    self.federationButton.frame = self.frameDict["federationButtonHidden"]!
                    
                    }, completion: { finished in
                        
                        // set map icon state to Hidden
                        DataSource.sharedInstance.mapButtonState = .hidden
                })
            }
        }
    }
    
    fileprivate func setUpNotificationCenter() {
        
        // listen for "ApplicationDidBecomeActive" notification from app delegate
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name(rawValue: "ApplicationDidBecomeActive"), object: nil)
        
        // listen for "NotInAHood" notification from data source
        NotificationCenter.default.addObserver(self, selector: #selector(setHoodScanningToFalse), name: NSNotification.Name(rawValue: "NotInAHood"), object: nil)
        
        // setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
        
        // get keyboard height
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    fileprivate func populateFrameDict() {
        
        // dashboard view
        frameDict["dashboardViewFull"] = CGRect(x: 0, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height)
        frameDict["dashboardViewMinimized"] = CGRect(x: 0, y: self.view.frame.height - dashboardMinimizedHeight, width: self.view.frame.width, height: self.view.frame.height)
        frameDict["dashboardViewSearching"] = CGRect(x: 0, y: self.view.frame.height - dashboardMinimizedHeight - DataSource.sharedInstance.keyboardHeight, width: self.view.frame.width, height: self.view.frame.height)
        
        // search view
        frameDict["searchResultsViewMinimized"] = CGRect(x: 0, y: self.view.frame.height - dashboardMinimizedHeight, width: self.view.frame.width, height: self.view.frame.height)
        frameDict["searchResultsViewSearching"] = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        // profile view
        frameDict["profileViewHidden"] = CGRect(x: -50, y: -50, width: 50, height: 50)
        frameDict["profileViewClosed"] = CGRect(x: 15, y: 15, width: 50, height: 50)
        frameDict["profileViewOpen"] = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        // profile view shadow
        frameDict["profileViewShadowHidden"] = CGRect(x: frameDict["profileViewHidden"]!.minX + 6, y: frameDict["profileViewHidden"]!.minY + 7, width: 50, height: 50)
        frameDict["profileViewShadowClosed"] = CGRect(x: frameDict["profileViewClosed"]!.minX + 6, y: frameDict["profileViewClosed"]!.minY + 7, width: 50, height: 50)
        frameDict["profileViewShadowOpen"] = CGRect(x: frameDict["profileViewOpen"]!.minX + 6, y: frameDict["profileViewOpen"]!.minY + 9, width: view.frame.width * 0.85, height: view.frame.width * 0.85)
        
        // federation button
        frameDict["federationButtonHidden"] = CGRect(x: view.frame.maxX + 50, y: view.frame.height - dashboardMinimizedHeight - 50 - padding, width: 50, height: 50)
        frameDict["federationButtonNormal"] = CGRect(x: view.frame.maxX - 50 - padding, y: view.frame.height - dashboardMinimizedHeight - 50 - padding, width: 50, height: 50)
        frameDict["federationButtonTapped"] = CGRect(x: view.frame.maxX - 50 - padding, y: view.frame.height - dashboardMinimizedHeight - 50 - padding + 3, width: 50, height: 50)
        
        // federation button shadow
        frameDict["federationButtonShadowHidden"] = CGRect(x: frameDict["federationButtonHidden"]!.minX + 4, y: frameDict["federationButtonHidden"]!.minY + 5, width: 50, height: 50)
        frameDict["federationButtonShadowNormal"] = CGRect(x: frameDict["federationButtonNormal"]!.minX + 4, y: frameDict["federationButtonNormal"]!.minY + 5, width: 50, height: 50)
        frameDict["federationButtonShadowTapped"] = CGRect(x: frameDict["federationButtonTapped"]!.minX + 3, y: frameDict["federationButtonTapped"]!.minY + 4, width: 50, height: 50)
    }
    
    @objc fileprivate func setHoodScanningToFalse() {
        hoodScanning = false
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func keyboardWillChangeFrame(_ notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardFrame.size.height
            DataSource.sharedInstance.keyboardHeight = keyboardHeight
            populateFrameDict()
            moveDashboardTo(.searching, sender: UIPanGestureRecognizer())
        }
    }
}

// MARK: UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        // intercept dashboard gesture
        if gestureRecognizer == dashboardPan {
            
            // if touch is not in dashboard, let gesture pass through to map
            if !dashboardView.frame.contains(touch.location(in: view)) {
                return false
            }
        }
        return true
    }
}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    // when authorization status changes...
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            DataSource.sharedInstance.locationManager.startUpdatingLocation()
            DataSource.sharedInstance.locationManager.startUpdatingHeading()
            
            // turns on hood checking until it fails and this gets set to false
            hoodScanning = true
            
            // only show user location if status is authorized when in use
            mapboxView.showsUserLocation = true
            
        } else if status == .denied {
            
            moveCameraToManhattanAnimated(false)
        }
        
        if status != .notDetermined {
            
            // notify the app delegate to release the hole
            NotificationCenter.default.post(name: Notification.Name(rawValue: "LocationManagerAuthChanged"), object: nil)

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if hoodScanning == true {
            
            // if location is available
            if DataSource.sharedInstance.locationManager.location != nil {
                
                // update the area singleton
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(locations[0], completionHandler: { (placemarks, error) in
                    if error == nil {
                        
                        // update the user location placemark singleton
                        DataSource.sharedInstance.lastPlacemark = placemarks![0]
                        
                        // update the area singleton
                        DataSource.sharedInstance.updateArea()
                        
                        if DataSource.sharedInstance.hoodState != .otherHood {
                            
                            DataSource.sharedInstance.hoodState = .currentHood
                            
                            // update the hood label
                            self.attemptToUpdateHoodLabel(with: (DataSource.sharedInstance.locationManager.location?.coordinate)!, fromTap: false)
                        }
                    }
                })
            }
        }
    }
}

// MARK: MGLMapViewDelegate

extension MapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // annotation icon
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? Annotation,
            let image = point.image,
            let reuseIdentifier = point.reuseIdentifier {
            
            if let annotationImage = mapboxView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
                return annotationImage
            } else {
                return MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
            }
        }
        return nil
    }
    
    // pass in the annotation's represented object (MGLAnnotation built-in coordinate, title and subtitle)
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> UIView? {
        if annotation.responds(to: #selector(getter: MGLAnnotation.title)) {
            return CalloutViewController(representedObject: annotation)
        }
        return nil
    }
}

extension MapViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        moveSearchResultsViewTo(.searching)
    }
}

extension UIView {
    
    func animateCornerRadiusOf(_ viewToAnimate: UIView, fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        viewToAnimate.layer.add(animation, forKey: "cornerRadius")
        viewToAnimate.layer.cornerRadius = toValue
    }
}
