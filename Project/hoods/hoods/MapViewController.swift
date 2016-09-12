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
    
    private let manhattan = CLLocationCoordinate2DMake(40.722716755829168, -73.986322678333224)
    @IBOutlet var mapboxView: MGLMapView!
    private var hoodScanning = false
    private var tap = UITapGestureRecognizer()
    private var feedPan = UIPanGestureRecognizer()
    private var buttonHideTimer: Double = 0
    private var feedView = FeedView()
    private var profileView = ProfileView()
    private var profileViewShadow = UIView()
    private var profileButton = UIButton()
    private var federationButton = FederationButton()
    private var federationButtonShadow = UIView()
    private var frameDict = [String:CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpNotificationCenter()

        // Mapbox view
        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.clearColor()
        mapboxView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // location manager
        DataSource.sharedInstance.locationManager.delegate = self
        DataSource.sharedInstance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.sharedInstance.locationManager.distanceFilter = kCLDistanceFilterNone

        populateFrameDict()
        
        addTapGesture()
        addFederationButton()
        addProfile()
        addFeedView()
        addPanGesture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: Camera
    
    private func moveCameraTo(coord: CLLocationCoordinate2D, distance: CLLocationDistance, zoom: Double, pitch: CGFloat, duration: NSTimeInterval, animatedCenterChange: Bool) {
        
        // if the camera is not already on the coords passed in, move camera
        if mapboxView.centerCoordinate.latitude != coord.latitude && mapboxView.centerCoordinate.longitude != coord.longitude {
            mapboxView.setCenterCoordinate(coord, zoomLevel: zoom, direction: 0, animated: animatedCenterChange, completionHandler: {
            })
            let camera = MGLMapCamera(lookingAtCenterCoordinate: coord, fromDistance: distance, pitch: pitch, heading: 0)
            mapboxView.setCamera(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
    }
    
    @objc private func attemptToMoveCameraToUserLocation() {
                
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
    
    private func moveCameraToManhattanAnimated(animated: Bool) {
        
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
    
// MARK: Feed
    
    private func addFeedView() {
        
        feedView = FeedView(frame: CGRect(x: 0, y: view.frame.maxY - 120, width: view.frame.width, height: view.frame.height))
        feedView.currentHoodLabel.text = "Hoods"
        view.addSubview(feedView)
    }
    
    private func feedAnimationTo(topOrBottom: String, sender: UIPanGestureRecognizer) {
        switch topOrBottom {
        case "top":
            
            self.feedView.animateCornerRadiusOf(self.feedView, fromValue: self.feedView.roundedCornerRadius, toValue: 0.0, duration: 0.5)
            
            // animate the feed to the top
            UIView.animateWithDuration(0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.feedView.frame = self.frameDict["feedViewTop"]!
                }, completion: { (Bool) -> Void in
                    
            })
        case "bottom":
            
            if sender.locationInView(mapboxView).y < frameDict["feedViewBottom"]!.minY {
                self.feedView.animateCornerRadiusOf(feedView, fromValue: 0.0, toValue: self.feedView.roundedCornerRadius, duration: 0.5)
            }
            
            // animate the feed's minY to the bottom -100
            UIView.animateWithDuration(0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.feedView.frame = self.frameDict["feedViewBottom"]!
                }, completion: { (Bool) -> Void in
            })
        default: break
        }
    }
    
// MARK: Profile
    
    private func addProfile() {
        
        // add the profile view with profile frame CLOSED
        profileView = ProfileView(frame: frameDict["profileViewHidden"]!)
        profileView.layer.cornerRadius = profileView.frame.width / 2

        // add the profile view shadow
        profileViewShadow = UIView(frame: frameDict["profileViewShadowHidden"]!)
        profileViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        profileViewShadow.layer.cornerRadius = profileViewShadow.frame.width / 2
        profileViewShadow.layer.masksToBounds = true
        
        // set the profile button frame to CLOSED
        profileButton.frame = frameDict["profileViewHidden"]!
        profileButton.addTarget(self, action: #selector(MapViewController.profileButtonTapped(_:)), forControlEvents: .TouchUpInside)
        
        mapboxView.addSubview(profileViewShadow)
        mapboxView.addSubview(profileView)
        mapboxView.addSubview(profileButton)
        
        // activate constraints for closed profile
        if DataSource.sharedInstance.profileState == nil {
            profileView.activateConstraintsForState(.Closed)
        }
    }
    
    @objc private func profileButtonTapped(sender: UIButton) {
        toggleProfileSizeForState(.Open)
    }
    
    private func toggleProfileSizeForState(desiredState: ProfileState) {
        
        if desiredState == .Open {
            
            // lock the map
            mapboxView.allowsScrolling = false
            mapboxView.allowsZooming = false
            
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .CurveEaseOut, animations: {
                
                // set the profile frame and its shadow to OPEN
                self.profileView.frame = self.frameDict["profileViewOpen"]!
                self.profileViewShadow.frame = self.frameDict["profileViewShadowOpen"]!
                
                // activate the profile subview constraints for OPENED state
                self.profileView.activateConstraintsForState(.Open)
                
                // set the profile button frame to 0
                self.profileButton.frame = CGRectZero
                }, completion: { (Bool) in
            })
            
        } else { // desiredState == .ProfileStateClosed
            UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .CurveEaseInOut, animations: {
                
                // set the profile frame to CLOSED
                self.profileView.frame = self.frameDict["profileViewClosed"]!
                self.profileViewShadow.frame = self.frameDict["profileViewShadowClosed"]!
                
                // activate the profile subview constraints for CLOSED state
                self.profileView.activateConstraintsForState(.Closed)
                
                // set the profile button frame to profile frame CLOSED
                self.profileButton.frame = self.frameDict["profileViewClosed"]!
                }, completion: { (Bool) in
                    
                    // unlock the map
                    self.mapboxView.allowsScrolling = true
                    self.mapboxView.allowsZooming = true
            })
        }
    }
    
// MARK: Federation Button
    
    func addFederationButton() {
        
        // button
        let federationButtonSize = CGSize(width: 50, height: 50)
        federationButton = FederationButton(frame: frameDict["federationButtonHidden"]!)
        federationButton.addTarget(self, action: #selector(MapViewController.federationButtonTapped), forControlEvents: .TouchUpInside)
        
        // shadow
        federationButtonShadow = UIView(frame: frameDict["federationButtonShadowHidden"]!)
        federationButtonShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        federationButtonShadow.layer.cornerRadius = federationButtonSize.width / 2
        federationButtonShadow.layer.masksToBounds = true
        
        view.addSubview(federationButtonShadow)
        view.addSubview(federationButton)
    }
    
    @objc private func federationButtonTapped(sender: UIButton) {
        
        // close profile
        if DataSource.sharedInstance.profileState == .Open {
            toggleProfileSizeForState(.Closed)
        }
        
        // animate the color green for half a sec
        federationButton.backgroundColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)
        UIView.animateWithDuration(0.1, animations: {
            self.federationButton.backgroundColor = UIColor.blackColor()
            self.federationButton.frame = self.frameDict["federationButtonTapped"]!
            self.federationButtonShadow.frame = self.frameDict["federationButtonShadowTapped"]!
        }) { (Bool) in
            UIView.animateWithDuration(0.2, animations: {
                self.federationButton.frame = self.frameDict["federationButtonNormal"]!
                self.federationButtonShadow.frame = self.frameDict["federationButtonShadowNormal"]!
            })
        }
        
        // if location is available
        if DataSource.sharedInstance.locationManager.location != nil {
            
            // zoom to location
            attemptToMoveCameraToUserLocation()
        }
    }
    
// MARK: Touches
    
    private func addTapGesture() {
        
        tap.delegate = self
        tap.addTarget(self, action: #selector(tapFired))
        tap.delaysTouchesBegan = true
        tap.cancelsTouchesInView = true
        mapboxView.addGestureRecognizer(tap)
    }
    
    private func addPanGesture() {
        
        feedPan = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.panFired(_:)))
        feedPan.delegate = self
        mapboxView.addGestureRecognizer(feedPan)
    }
    
    @objc private func tapFired(sender: UITapGestureRecognizer) {
        
        // if profile is open
        if DataSource.sharedInstance.profileState == .Open {
            
            // if tap is outside profile
            if !profileView.frame.contains(sender.locationInView(mapboxView)) {
                
                // hide map icons and close profile
                hideMapIcons()
                toggleProfileSizeForState(.Closed)
            }
        }
    }
    
    @objc private func panFired(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(mapboxView)
        let touchLocation = sender.locationInView(mapboxView)
        
        // pan gesture is inside feed view
        if feedView.frame.contains(touchLocation) {
            
            // pan gesture just ended
            if feedPan.state == .Changed {
                
                // pan gesture is going up at least 12
                if translation.y <= -12 {
                    feedAnimationTo("top", sender: sender)
                    
                    // close profile
                    if DataSource.sharedInstance.profileState == .Open {
                        toggleProfileSizeForState(.Closed)
                    }
                    
                // pan gesture is going down at least 12
                } else if translation.y >= 12 {
                    feedAnimationTo("bottom", sender: sender)
                }
            }
        }
    }
    
// MARK: Offline Maps
    
    private func startOfflinePackDownload() {
        
        let latitude = DataSource.sharedInstance.locationManager.location?.coordinate.latitude
        let longitude = DataSource.sharedInstance.locationManager.location?.coordinate.longitude
        
        // create a region that includes the current viewport and any tiles needed to view it when zoomed further in
        let region = MGLTilePyramidOfflineRegion(styleURL: mapboxView.styleURL, bounds: MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(latitude! - 0.3, longitude! - 0.3), CLLocationCoordinate2DMake(latitude! + 0.3, longitude! + 0.3)), fromZoomLevel: mapboxView.zoomLevel, toZoomLevel: 10)
        
        // store some data for identification purposes alongside the downloaded resources
        let userInfo = ["name": "My Offline Pack"]
        let context = NSKeyedArchiver.archivedDataWithRootObject(userInfo)
        
        // create and register an offline pack with the shared offline storage object
        MGLOfflineStorage.sharedOfflineStorage().addPackForRegion(region, withContext: context) { (pack, error) in
            guard error == nil else {
                
                // the pack couldn't be created for some reason
                print("error: \(error?.localizedFailureReason)")
                return
            }
            
            // start downloading
            pack!.resume()
        }
    }
    
    @objc private func offlinePackProgressDidChange(notification: NSNotification) {
        
        // get the offline pack this notifiction is regarding,
        // and the associated user info for the pack; in this case, 'name = My Offline Pack'
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String:String] {
            
            let progress = pack.progress
            
            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // calculate current progress percentage
            let progressPercentage = Float(completedResources) / Float(expectedResources)
        
            // if this pack has finished, print its size and its resource count
            if completedResources == expectedResources {
                let byteCount = NSByteCountFormatter.stringFromByteCount(Int64(pack.progress.countOfBytesCompleted), countStyle: NSByteCountFormatterCountStyle.Memory)
                print("Offline pack '\(userInfo["name"])' completed: \(byteCount), \(completedResources) resources")
            } else {
                
                // otherwise, print download/verification progress
                print("Offline pack '\(userInfo["name"])' has \(completedResources) of \(expectedResources) resources - \(progressPercentage * 100)%")
            }
        }
    }
    
    @objc private func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String:String],
            error = notification.userInfo?[MGLOfflinePackErrorUserInfoKey] as? NSError {
            
            print("Offline pack '\(userInfo["name"])' received error: \(error.localizedFailureReason)")
        }
    }
    
    @objc private func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String:String],
            maximumCount = notification.userInfo?[MGLOfflinePackMaximumCountUserInfoKey]?.unsignedLongLongValue {
            
            print("Offline pack '\(userInfo["name"])' reached limit of \(maximumCount) tiles")
        }
    }
    
// MARK: Miscellaneous
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        
        // if motion was a shake and location available
        if motion == .MotionShake {
            showMapIcons()
        }
    }
    
    private func showMapIcons() {
        
        // add 5 seconds to timer
        buttonHideTimer = buttonHideTimer + 5
        
        // if buttons are not already showing
        if DataSource.sharedInstance.mapButtonState != .Shown {
            
            // animate showing of icons
            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .CurveEaseIn, animations: {
                
                // set map button state to Shown
                DataSource.sharedInstance.mapButtonState = .Shown
                
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
    
    private func hideMapIcons() {
        
        // delay using timer
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(buttonHideTimer * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            
            // if profile is not open, proceed with hiding of icons
            if DataSource.sharedInstance.profileState != .Open {
                
                // animate hiding of icons
                UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .CurveEaseIn, animations: {
                    
                    if DataSource.sharedInstance.profileState == .Open {
                        self.toggleProfileSizeForState(.Closed)
                    }
                    self.profileViewShadow.frame = self.frameDict["profileViewShadowHidden"]!
                    self.profileView.frame = self.frameDict["profileViewHidden"]!
                    self.profileButton.frame = self.frameDict["profileViewHidden"]!
                    self.federationButtonShadow.frame = self.frameDict["federationButtonShadowHidden"]!
                    self.federationButton.frame = self.frameDict["federationButtonHidden"]!
                    
                    }, completion: { finished in
                        
                        self.buttonHideTimer = self.buttonHideTimer - 5
                        
                        // set map icon state to Hidden
                        DataSource.sharedInstance.mapButtonState = .Hidden
                })
            }
        }
    }
    
    private func setUpNotificationCenter() {
        
        // listen for "ApplicationDidBecomeActive" notification from app delegate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(attemptToMoveCameraToUserLocation), name: "ApplicationDidBecomeActive", object: nil)
        
        // listen for "NotInAHood" notification from data source
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setHoodScanningToFalse), name: "NotInAHood", object: nil)
        
        // Setup offline pack notification handlers.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackProgressDidChange), name: MGLOfflinePackProgressChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackDidReceiveError), name: MGLOfflinePackErrorNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: MGLOfflinePackMaximumMapboxTilesReachedNotification, object: nil)
    }
    
    private func populateFrameDict() {
        
        // feed view
        frameDict["feedViewTop"] = CGRect(x: 0, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height)
        frameDict["feedViewBottom"] = CGRect(x: 0, y: self.view.frame.height - 120, width: self.view.frame.width, height: self.view.frame.height)
        
        // profile view
        frameDict["profileViewHidden"] = CGRect(x: -50, y: -50, width: 50, height: 50)
        frameDict["profileViewClosed"] = CGRect(x: 15, y: 15, width: 50, height: 50)
        frameDict["profileViewOpen"] = CGRect(x: view.frame.midX - (view.frame.width * 0.85) / 2, y: 50, width: view.frame.width * 0.85, height: view.frame.width * 0.85)
        
        // profile view shadow
        frameDict["profileViewShadowHidden"] = CGRect(x: frameDict["profileViewHidden"]!.minX + 6, y: frameDict["profileViewHidden"]!.minY + 7, width: 50, height: 50)
        frameDict["profileViewShadowClosed"] = CGRect(x: frameDict["profileViewClosed"]!.minX + 6, y: frameDict["profileViewClosed"]!.minY + 7, width: 50, height: 50)
        frameDict["profileViewShadowOpen"] = CGRect(x: frameDict["profileViewOpen"]!.minX + 6, y: frameDict["profileViewOpen"]!.minY + 9, width: view.frame.width * 0.85, height: view.frame.width * 0.85)
        
        // federation button
        frameDict["federationButtonHidden"] = CGRect(x: view.frame.maxX + 50, y: view.frame.height - 120 - 50 - 20, width: 50, height: 50)
        frameDict["federationButtonNormal"] = CGRect(x: view.frame.maxX - 50 - 20, y: view.frame.height - 120 - 50 - 20, width: 50, height: 50)
        frameDict["federationButtonTapped"] = CGRect(x: view.frame.maxX - 50 - 20, y: view.frame.height - 120 - 50 - 20 + 3, width: 50, height: 50)
        
        // federation button shadow
        frameDict["federationButtonShadowHidden"] = CGRect(x: frameDict["federationButtonHidden"]!.minX + 4, y: frameDict["federationButtonHidden"]!.minY + 5, width: 50, height: 50)
        frameDict["federationButtonShadowNormal"] = CGRect(x: frameDict["federationButtonNormal"]!.minX + 4, y: frameDict["federationButtonNormal"]!.minY + 5, width: 50, height: 50)
        frameDict["federationButtonShadowTapped"] = CGRect(x: frameDict["federationButtonTapped"]!.minX + 3, y: frameDict["federationButtonTapped"]!.minY + 4, width: 50, height: 50)
    }
    
    @objc private func setHoodScanningToFalse() {
        hoodScanning = false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

// MARK: UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        // intercept feed gesture
        if gestureRecognizer == feedPan {
            
            // if touch is not in feed, let gesture pass through to map
            if !feedView.frame.contains(touch.locationInView(view)) {
                return false
            }
        }
        return true
    }
}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    // when authorization status changes...
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .AuthorizedWhenInUse {
            
            DataSource.sharedInstance.locationManager.startUpdatingLocation()
            DataSource.sharedInstance.locationManager.startUpdatingHeading()
            
            // turns on hood checking until it fails and this gets set to false
            hoodScanning = true
            
            // only show user location if status is authorized when in use
            mapboxView.showsUserLocation = true
            
            // move camera into your location
            attemptToMoveCameraToUserLocation()
            
        } else if status == .Denied {
            
            moveCameraToManhattanAnimated(false)
        }
        
        // notify the app delegate to release the hole
        NSNotificationCenter.defaultCenter().postNotificationName("LocationManagerAuthChanged", object: nil)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
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
                        
                        // use hood check to try and set current hood label
                        let newLocation = DataSource.sharedInstance.currentHoodName(locations[0].coordinate)!
                        
                        // if hood check failed, set label to Hoods
                        if newLocation != "" {
                            self.feedView.currentHoodLabel.text = newLocation
                        } else {
                            self.feedView.currentHoodLabel.text = "Hoods"
                        }
                    }
                })
            }
        }
    }
}

// MARK: MGLMapViewDelegate

extension MapViewController: MGLMapViewDelegate {
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // annotation icon
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? Annotation,
            image = point.image,
            reuseIdentifier = point.reuseIdentifier {
            
            if let annotationImage = mapboxView.dequeueReusableAnnotationImageWithIdentifier(reuseIdentifier) {
                return annotationImage
            } else {
                return MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
            }
        }
        return nil
    }
    
    // pass in the annotation's represented object (MGLAnnotation built-in coordinate, title and subtitle)
    func mapView(mapView: MGLMapView, calloutViewForAnnotation annotation: MGLAnnotation) -> UIView? {
        if annotation.respondsToSelector(Selector("title")) {
            return CalloutViewController(representedObject: annotation)
        }
        return nil
    }
}

extension UIView {
    
    func animateCornerRadiusOf(viewToAnimate: UIView, fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        viewToAnimate.layer.addAnimation(animation, forKey: "cornerRadius")
        viewToAnimate.layer.cornerRadius = toValue
    }
}