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
    
    let padding: CGFloat = 20
    fileprivate var hoodScanning = false
    fileprivate var frameDict = [String:CGRect]()
    
    // gestures
    fileprivate var tap = UITapGestureRecognizer()
    fileprivate var profilePan = UIPanGestureRecognizer()
    
    // map
    fileprivate let manhattan = CLLocationCoordinate2DMake(40.722716755829168, -73.986322678333224)
    @IBOutlet var mapboxView: MGLMapView!
    
    // camera
    fileprivate var cameraView: CameraView!
    
    // profile
    fileprivate var profileView = ProfileView()
    fileprivate var profileViewShadow = UIView()
    fileprivate var profileButton = UIButton()
    
    // federation
    fileprivate var federationButton = FederationButton()
    fileprivate var federationButtonShadow = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNotificationCenter()

        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.purple
        mapboxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        DataSource.sharedInstance.locationManager.delegate = self
        DataSource.sharedInstance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.sharedInstance.locationManager.distanceFilter = kCLDistanceFilterNone

        DataSource.sharedInstance.viewSize = view.frame.size
        populateFrameDict()
        
        addTapGesture()
        addFederationButton()
        addProfile()
        addCameraView()
                
        attemptToMoveCameraToUserLocation()
    }
    
    func appDidBecomeActive() {
        attemptToMoveCameraToUserLocation()
        
        if DataSource.sharedInstance.locationManager.location != nil {
            updateHoodAndAreaLabels(with: (DataSource.sharedInstance.locationManager.location?.coordinate)!, fromTap: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: Camera
    
    fileprivate func zoom(into coord: CLLocationCoordinate2D, distance: CLLocationDistance, zoom: Double, pitch: CGFloat, duration: TimeInterval, animatedCenterChange: Bool) {
        
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
            zoom(into: CLLocationCoordinate2DMake(centerCoordinate.latitude - 0.05, centerCoordinate.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into your location at a 30° angle over 3 seconds
            zoom(into: centerCoordinate, distance: 5000, zoom: 10, pitch: 30, duration: 4, animatedCenterChange: false)
            
        // else move camera into manhattan from 50° to 30° over 3 seconds
        } else {
            moveCameraToManhattanAnimated(true)
        }
    }
    
    fileprivate func moveCameraToManhattanAnimated(_ animated: Bool) {
        
        if animated {
            
            // start far out at a 50° angle
            zoom(into: CLLocationCoordinate2DMake(manhattan.latitude - 0.05, manhattan.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into manhattan at a 30° angle over 3 seconds
            zoom(into: manhattan, distance: 5000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
            
        } else {
            
            // set camera to manhattan instantly
            zoom(into: manhattan, distance: 13000, zoom: 10, pitch: 30, duration: 0, animatedCenterChange: false)
        }
    }
    
// MARK: Hood View
    
    fileprivate func addCameraView() {
        cameraView = CameraView(frame: frameDict["cameraView"]!)
        view.addSubview(cameraView!)
    }
    
    fileprivate func updateHoodAndAreaLabels(with coordinate: CLLocationCoordinate2D, fromTap: Bool) {
        switch fromTap {
        case true:
            do {
                if let hood = try DataSource.sharedInstance.tappedHoodName(for: coordinate) {
                    cameraView.hoodView.hoodLabel.text = hood
                }
            } catch {}
            if let area = DataSource.sharedInstance.tappedArea {
                cameraView.hoodView.areaLabel.text = area
            }
        case false:
            print("it was not from a tap")
            if let hood = DataSource.sharedInstance.visitingHoodName(for: coordinate) {
                cameraView.hoodView.hoodLabel.text = hood
            }
            if let area = DataSource.sharedInstance.visitingArea {
                cameraView.hoodView.areaLabel.text = area
            }
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
                    
                    self.hideMapIcons()
            })
        }
    }
    
// MARK: Federation Button
    
    func addFederationButton() {
        
        // button
        federationButton = FederationButton(frame: frameDict["federationButtonHidden"]!)
        federationButton.addTarget(self, action: #selector(MapViewController.federationButtonTapped), for: .touchDown)
        
        // shadow
        federationButtonShadow = UIView(frame: frameDict["federationButtonShadowHidden"]!)
        federationButtonShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        federationButtonShadow.layer.cornerRadius = frameDict["federationButtonNormal"]!.width / 2
        federationButtonShadow.layer.masksToBounds = true
        
        view.addSubview(federationButtonShadow)
        view.addSubview(federationButton)
    }
    
    @objc fileprivate func federationButtonTapped(_ sender: UIButton) {
        
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
        
        // close profile
        if DataSource.sharedInstance.profileState == .open {
            toggleProfileSizeForState(.closed)
        }
        
        // if location is available
        if DataSource.sharedInstance.locationManager.location != nil {
            
            DataSource.sharedInstance.hoodState = .visiting
            
            attemptToMoveCameraToUserLocation()
        
            updateHoodAndAreaLabels(with: (DataSource.sharedInstance.locationManager.location?.coordinate)!, fromTap: false)
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
    
    @objc fileprivate func tapFired(_ sender: UITapGestureRecognizer) {
        
    // map behavior
        
        // if tap was not in any other view...
        if !cameraView.frame.contains(sender.location(in: mapboxView)) && !profileView.frame.contains(sender.location(in: mapboxView)) && !federationButton.frame.contains(sender.location(in: mapboxView)) {
            
            // CGPoint -> CLLocationCoordinate2D -> CLLocation
            let tappedLocationCoord = mapboxView.convert(sender.location(in: mapboxView), toCoordinateFrom: mapboxView)
            let tappedLocation = CLLocation(latitude: tappedLocationCoord.latitude, longitude: tappedLocationCoord.longitude)
            
            func flyToHood() {
                let mapCam = MGLMapCamera(lookingAtCenter: tappedLocationCoord, fromDistance: 5000, pitch: 30, heading: 0)
                self.mapboxView.fly(to: mapCam, withDuration: 1, peakAltitude: 6000, completionHandler: nil)
            }
            
            func reverseGeocode() {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(tappedLocation, completionHandler: { (placemarks, error) in
                    
                    // update tapped area and placemark singletons
                    DataSource.sharedInstance.tappedPlacemark = placemarks![0]
                    DataSource.sharedInstance.updateTappedArea(with: placemarks![0])
                    
                    do {
                        if let hood = try DataSource.sharedInstance.tappedHoodName(for: tappedLocationCoord) {
                            self.cameraView.hoodView.hoodLabel.text = hood
                            flyToHood()
                        }
                    } catch {
                    }
                })
            }
            // update the label and hood check state
            do {
                if let hood = try DataSource.sharedInstance.tappedHoodName(for: tappedLocationCoord) {
                    cameraView.hoodView.hoodLabel.text = hood
                    flyToHood()
                } else {
                    reverseGeocode()
                }
            } catch {
                reverseGeocode()
            }
        }
        
    // profile behavior
        
        // if profile is open and tap was outside profile...
        if DataSource.sharedInstance.profileState == .open {
            if !profileView.frame.contains(sender.location(in: mapboxView)) {
                
                // hide map icons and close profile
                hideMapIcons()
                toggleProfileSizeForState(.closed)
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
    
    fileprivate func configureNotificationCenter() {
        
        // listen for "ApplicationDidBecomeActive" notification from app delegate
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name(rawValue: "ApplicationDidBecomeActive"), object: nil)
        
        // listen for "StopScanning" notification from data source
        NotificationCenter.default.addObserver(self, selector: #selector(setHoodScanningToFalse), name: NSNotification.Name(rawValue: "StopScanning"), object: nil)
        
        // setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
    }
    
// MARK: Frame Dict
    
    fileprivate func populateFrameDict() {
        let buttonSize = CGSize(width: 50, height: 50)
        let hoodViewHeight = view.frame.height * 0.1
        
        // hood view
        frameDict["cameraView"] = CGRect(x: 0, y: view.frame.minY - view.frame.height, width: view.frame.width, height: view.frame.height + hoodViewHeight)
        
        // profile view
        frameDict["profileViewHidden"] = CGRect(x: -padding - buttonSize.width, y: frameDict["cameraView"]!.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        frameDict["profileViewClosed"] = CGRect(x: padding, y: frameDict["cameraView"]!.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        frameDict["profileViewOpen"] = CGRect(x: 0, y: frameDict["cameraView"]!.maxY, width: view.frame.width, height: view.frame.height - hoodViewHeight)
        
        // profile view shadow
        frameDict["profileViewShadowHidden"] = CGRect(x: frameDict["profileViewHidden"]!.minX + 6, y: frameDict["profileViewHidden"]!.minY + 7, width: buttonSize.width, height: 50)
        frameDict["profileViewShadowClosed"] = CGRect(x: frameDict["profileViewClosed"]!.minX + 6, y: frameDict["profileViewClosed"]!.minY + 7, width: buttonSize.width, height: 50)
        frameDict["profileViewShadowOpen"] = CGRect(x: frameDict["profileViewOpen"]!.minX + 6, y: frameDict["profileViewOpen"]!.minY + 9, width: view.frame.width, height: view.frame.height - hoodViewHeight)
        
        // federation button
        frameDict["federationButtonHidden"] = CGRect(x: view.frame.maxX + padding, y: view.frame.height - buttonSize.height - padding, width: buttonSize.width, height: buttonSize.height)
        frameDict["federationButtonNormal"] = CGRect(x: view.frame.maxX - buttonSize.width - padding, y: view.frame.height - buttonSize.height - padding, width: buttonSize.width, height: buttonSize.height)
        frameDict["federationButtonTapped"] = CGRect(x: view.frame.maxX - buttonSize.width - padding, y: view.frame.height - buttonSize.height - padding + 3, width: buttonSize.width, height: buttonSize.height)
        
        // federation button shadow
        frameDict["federationButtonShadowHidden"] = CGRect(x: frameDict["federationButtonHidden"]!.minX + 4, y: frameDict["federationButtonHidden"]!.minY + 5, width: buttonSize.width, height: buttonSize.height)
        frameDict["federationButtonShadowNormal"] = CGRect(x: frameDict["federationButtonNormal"]!.minX + 4, y: frameDict["federationButtonNormal"]!.minY + 5, width: buttonSize.width, height: buttonSize.height)
        frameDict["federationButtonShadowTapped"] = CGRect(x: frameDict["federationButtonTapped"]!.minX + 3, y: frameDict["federationButtonTapped"]!.minY + 4, width: buttonSize.width, height: buttonSize.height)
    }
    
    @objc fileprivate func setHoodScanningToFalse() {
        hoodScanning = false
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

// MARK: UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        // if touch is not in camera or profile views, let gesture pass through to map
        if !cameraView!.frame.contains(touch.location(in: mapboxView)) && !profileView.frame.contains(touch.location(in: mapboxView)) {
            return true
        }
        return false
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
        
        // update hood state
        if hoodScanning == true {
            if DataSource.sharedInstance.hoodState != .tapping {
                DataSource.sharedInstance.hoodState = .visiting
            }
            
            // if not still in the hood...
            if DataSource.sharedInstance.locationManager.location != nil {
                if !DataSource.sharedInstance.stillInTheHood(locations[0].coordinate) {

                    // reverse geocode coord to get the area
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(locations[0], completionHandler: { (placemarks, error) in
                        if error == nil {
                            
                            // update the visiting placemark singleton and get the visiting area
                            let placemark = placemarks![0]
                            DataSource.sharedInstance.visitingPlacemark = placemark
                            DataSource.sharedInstance.updateVisitingArea(with: placemark)
                            
                            self.updateHoodAndAreaLabels(with: locations[0].coordinate, fromTap: false)
                        }
                    })
                } else {
                    updateHoodAndAreaLabels(with: locations[0].coordinate, fromTap: false)
                }
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
