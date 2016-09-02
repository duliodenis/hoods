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
    private var feedView = FeedView()
    private var tap = UITapGestureRecognizer()
    private var feedPan = UIPanGestureRecognizer()
    private var profileView = ProfileView()
    private var profileViewShadow = UIView()
    private var profileButton = UIButton()
    private var federationButton = FederationButton()
    private var federationButtonShadow = UIView()
    private var buttonFrameDict = [String:CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listen for "ApplicationDidBecomeActive" notification from app delegate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(attemptToMoveCameraToUserLocation), name: "ApplicationDidBecomeActive", object: nil)
        
        // listen for "NotInAHood" notification from data source
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setHoodScanningToFalse), name: "NotInAHood", object: nil)

        // Mapbox view
        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.clearColor()
        mapboxView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // location manager
        DataSource.sharedInstance.locationManager.delegate = self
        DataSource.sharedInstance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.sharedInstance.locationManager.distanceFilter = kCLDistanceFilterNone

        populateButtonFrameDict()
        
        setCameraToManhattan()
        
        addTapGesture()
        addProfile()
        addFederationButton()
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
            
            print("using location manager location coordinate")
            
            // start far out at a 50° angle
            moveCameraTo(CLLocationCoordinate2DMake(centerCoordinate.latitude - 0.05, centerCoordinate.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into your location at a 30° angle over 3 seconds
            moveCameraTo(centerCoordinate, distance: 4000, zoom: 10, pitch: 30, duration: 4, animatedCenterChange: false)
            
        // else move camera into manhattan from 50° to 30° over 3 seconds
        } else {
            moveCameraTo(CLLocationCoordinate2DMake(manhattan.latitude - 0.05, manhattan.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            moveCameraTo(manhattan, distance: 4000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
        }
    }
    
    private func setCameraToManhattan() {
        
        // set camera to manhattan instantly
        moveCameraTo(manhattan, distance: 13000, zoom: 10, pitch: 30, duration: 0, animatedCenterChange: false)
    }
    
// MARK: Feed
    
    private func addFeedView() {
        
        feedView = FeedView(frame: CGRect(x: 0, y: view.frame.maxY - 120, width: view.frame.width, height: view.frame.height))
        feedView.currentHoodLabel.text = "Hoods"
        view.addSubview(feedView)
    }
    
    private func feedAnimationTo(topOrBottom: String) {
        switch topOrBottom {
        case "top":
            
            self.feedView.animateCornerRadiusOf(self.feedView, fromValue: self.feedView.frame.width * 0.07, toValue: 0.0, duration: 0.5)
            
            // animate the feed's minY to the view's minY
            UIView.animateWithDuration(0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.feedView.frame = CGRectMake(0, self.view.frame.origin.y, self.feedView.frame.width, self.feedView.frame.height)
                }, completion: { (Bool) -> Void in
                    
            })
        case "bottom":
            
            self.feedView.animateCornerRadiusOf(feedView, fromValue: 0.0, toValue: feedView.frame.width * 0.07, duration: 0.5)
            
            // animate the feed's minY to the view's height - 100
            UIView.animateWithDuration(0.426, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.feedView.frame = CGRectMake(0, self.view.frame.height - 100, self.feedView.frame.width, self.feedView.frame.height)
                }, completion: { (Bool) -> Void in
            })
        default: break
        }
    }
    
// MARK: Profile
    
    private func addProfile() {
        
        // add the profile view with profile frame CLOSED
        profileView = ProfileView(frame: buttonFrameDict["profileViewClosed"]!)
        profileView.layer.cornerRadius = profileView.frame.width / 2

        // add the profile view shadow
        profileViewShadow = UIView(frame: buttonFrameDict["profileViewShadowClosed"]!)
        profileViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        profileViewShadow.layer.cornerRadius = profileViewShadow.frame.width / 2
        profileViewShadow.layer.masksToBounds = true
        
        // set the profile button frame to CLOSED
        profileButton.frame = buttonFrameDict["profileViewClosed"]!
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
                self.profileView.frame = self.buttonFrameDict["profileViewOpen"]!
                self.profileViewShadow.frame = self.buttonFrameDict["profileViewShadowOpen"]!
                
                // activate the profile subview constraints for OPENED state
                self.profileView.activateConstraintsForState(.Open)
                
                // set the profile button frame to 0
                self.profileButton.frame = CGRectZero
                }, completion: { (Bool) in
            })
            
        } else { // desiredState == .ProfileStateClosed
            UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .CurveEaseInOut, animations: {
                
                // set the profile frame to CLOSED
                self.profileView.frame = self.buttonFrameDict["profileViewClosed"]!
                self.profileViewShadow.frame = self.buttonFrameDict["profileViewShadowClosed"]!
                
                // activate the profile subview constraints for CLOSED state
                self.profileView.activateConstraintsForState(.Closed)
                
                // set the profile button frame to profile frame CLOSED
                self.profileButton.frame = self.buttonFrameDict["profileViewClosed"]!
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
        federationButton = FederationButton(frame: buttonFrameDict["federationButtonNormal"]!)
        federationButton.addTarget(self, action: #selector(MapViewController.federationButtonTapped), forControlEvents: .TouchUpInside)
        
        // shadow
        federationButtonShadow = UIView(frame: buttonFrameDict["federationButtonShadowNormal"]!)
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
        UIView.animateWithDuration(0.2, animations: {
            self.federationButton.backgroundColor = UIColor.blackColor()
            self.federationButton.frame = self.buttonFrameDict["federationButtonTapped"]!
            self.federationButtonShadow.frame = self.buttonFrameDict["federationButtonShadowTapped"]!
        }) { (Bool) in
            UIView.animateWithDuration(0.3, animations: {
                self.federationButton.frame = self.buttonFrameDict["federationButtonNormal"]!
                self.federationButtonShadow.frame = self.buttonFrameDict["federationButtonShadowNormal"]!
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
        
        // if profile is open and tap is outside profile, toggle profile size
        if DataSource.sharedInstance.profileState == .Open {
            if !profileView.frame.contains(sender.locationInView(mapboxView)) {
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
                    feedAnimationTo("top")
                    
                    // close profile
                    if DataSource.sharedInstance.profileState == .Open {
                        toggleProfileSizeForState(.Closed)
                    }
                    
                // pan gesture is going down at least 12
                } else if translation.y >= 12 {
                    feedAnimationTo("bottom")
                }
            }
        }
    }
    
// MARK: Miscellaneous
    
    private func populateButtonFrameDict() {
        
        // profile view
        buttonFrameDict["profileViewClosed"] = CGRect(x: 15, y: 15, width: 50, height: 50)
        buttonFrameDict["profileViewOpen"] = CGRect(x: view.frame.midX - (view.frame.width * 0.85) / 2, y: 50, width: view.frame.width * 0.85, height: view.frame.width * 0.85)
        
        // profile view shadow
        buttonFrameDict["profileViewShadowClosed"] = CGRect(x: buttonFrameDict["profileViewClosed"]!.minX + 6, y: buttonFrameDict["profileViewClosed"]!.minY + 7, width: 50, height: 50)
        buttonFrameDict["profileViewShadowOpen"] = CGRect(x: buttonFrameDict["profileViewOpen"]!.minX + 6, y: buttonFrameDict["profileViewOpen"]!.minY + 9, width: view.frame.width * 0.85, height: view.frame.width * 0.85)
        
        // federation button
        buttonFrameDict["federationButtonNormal"] = CGRect(x: view.frame.maxX - 50 - 20, y: view.frame.height - 120 - 50 - 20, width: 50, height: 50)
        buttonFrameDict["federationButtonTapped"] = CGRect(x: view.frame.maxX - 50 - 20, y: view.frame.height - 120 - 50 - 20 + 3, width: 50, height: 50)
        
        // federation button shadow
        buttonFrameDict["federationButtonShadowNormal"] = CGRect(x: buttonFrameDict["federationButtonNormal"]!.minX + 4, y: buttonFrameDict["federationButtonNormal"]!.minY + 5, width: 50, height: 50)
        buttonFrameDict["federationButtonShadowTapped"] = CGRect(x: buttonFrameDict["federationButtonTapped"]!.minX + 3, y: buttonFrameDict["federationButtonTapped"]!.minY + 4, width: 50, height: 50)
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
            
            // notify the app delegate to release the hole
            NSNotificationCenter.defaultCenter().postNotificationName("LocationManagerAuthChanged", object: nil)
            
        } else if status == .Denied {
            
            // notify the app delegate to release the hole
            NSNotificationCenter.defaultCenter().postNotificationName("LocationManagerAuthChanged", object: nil)
            setCameraToManhattan()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if hoodScanning == true {
            
            // if location is available
            if DataSource.sharedInstance.locationManager.location != nil {
                
                DataSource.sharedInstance.locationManager.startUpdatingLocation()
                DataSource.sharedInstance.locationManager.startUpdatingHeading()
                
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