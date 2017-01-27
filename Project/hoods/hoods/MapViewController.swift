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
import AudioToolbox

struct Frames {
    var cameraView: CGRect
    var searchResultsViewHidden: CGRect
    var searchResultsViewDropped: CGRect
    var profileViewHidden: CGRect
    var profileViewClosed: CGRect
    var profileViewOpen: CGRect
    var profileViewShadowHidden: CGRect
    var profileViewShadowClosed: CGRect
    var profileViewShadowOpen: CGRect
    var federationButtonHidden: CGRect
    var federationButtonNormal: CGRect
    var federationButtonTapped: CGRect
    var federationButtonShadowHidden: CGRect
    var federationButtonShadowNormal: CGRect
    var federationButtonShadowTapped: CGRect
    var shakeHintHidden: CGRect
    var shakeHintShowingSmall: CGRect
    var shakeHintShowingBig: CGRect
    var shakeHintShadowHidden: CGRect
    var shakeHintShadowShowingSmall: CGRect
    var shakeHintShadowShowingBig: CGRect
    var hoodHintHidden: CGRect
    var hoodHintShowingSmall: CGRect
    var hoodHintShowingBig: CGRect
    var hoodHintShadowHidden: CGRect
    var hoodHintShadowShowingSmall: CGRect
    var hoodHintShadowShowingBig: CGRect
    var tapHintHidden: CGRect
    var tapHintShowingSmall: CGRect
    var tapHintShowingBig: CGRect
    var tapHintShadowHidden: CGRect
    var tapHintShadowShowingSmall: CGRect
    var tapHintShadowShowingBig: CGRect
    var enableLocationHintHidden: CGRect
    var enableLocationHintShowingSmall: CGRect
    var enableLocationHintShowingBig: CGRect
    var enableLocationHintShadowHidden: CGRect
    var enableLocationHintShadowShowingSmall: CGRect
    var enableLocationHintShadowShowingBig: CGRect
}

@available(iOS 10.0, *)
class MapViewController: UIViewController {
    
    let padding: CGFloat = 20
    fileprivate var hoodScanning = false
    fileprivate var frames: Frames?
    
    // gestures
    fileprivate var tap = UITapGestureRecognizer()
    fileprivate var profilePan = UIPanGestureRecognizer()

    // map
    fileprivate let manhattan = CLLocationCoordinate2DMake(40.722716755829168, -73.986322678333224)
    @IBOutlet var mapboxView: MGLMapView!
    
    // search results
    fileprivate var searchResultsView = UIView()
    
    // camera
    fileprivate var cameraView: CameraView!
    
    // profile
    fileprivate var profileView = ProfileView()
    fileprivate var profileViewShadow = UIView()
    fileprivate var profileButton = UIButton()
    
    // federation
    fileprivate var federationButton = FederationButton()
    fileprivate var federationButtonShadow = UIView()
    
    // shake hint
    fileprivate var shakeHintView = HintView()
    fileprivate var shakeHintViewShadow = UIView()
    
    // hood hint
    fileprivate var hoodHintView = HintView()
    fileprivate var hoodHintViewShadow = UIView()
    
    // tap hint
    fileprivate var tapHintView = HintView()
    fileprivate var tapHintViewShadow = UIView()
    
    // allow location hint
    fileprivate var enableLocationHintView = HintView()
    fileprivate var enableLocationHintViewShadow = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNotificationCenter()

        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.purple
        mapboxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        DataSource.si.locationManager.delegate = self
        DataSource.si.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.si.locationManager.distanceFilter = kCLDistanceFilterNone

        DataSource.si.viewSize = view.frame.size
        populateFrameDict()
        
        addTapGesture()
        addFederationButton()
        addSearchResultsView()
        addProfile()
        addCameraView()
        cameraView.hoodView.searchBar.delegate = self
        
        initialZoomToUserLocation()
    }
    
    func appDidBecomeActive() {
        if let coord = DataSource.si.locationManager.location?.coordinate {
            flyToUserLocation()
            updateHoodLabels(with: coord, fromTap: false)
            updateWeatherLabelFromVisiting()
        }
        
        // only show hint view on first launch
        if !UserDefaults.standard.bool(forKey: "firstLaunch1.0") {
            UserDefaults.standard.set(true, forKey: "firstLaunch1.0")
            UserDefaults.standard.synchronize()
            
            if DataSource.si.locationManager.location != nil {
                showShakeHintView()
                showHoodHintView()
                showTapHintView()
            } else {
                showEnableLocationHintView()
            }
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
    
    @objc fileprivate func initialZoomToUserLocation() {
        // if location available, start far out and then zoom into location at an angle over 3s
        if let coord = DataSource.si.locationManager.location?.coordinate {
            
            // start far out at a 50° angle
            zoom(into: CLLocationCoordinate2DMake(coord.latitude - 0.05, coord.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // move into your location at a 30° angle over 3 seconds
            zoom(into: coord, distance: 5000, zoom: 10, pitch: 30, duration: 4, animatedCenterChange: false)
            
            // else move camera into manhattan from 50° to 30° over 3 seconds
        } else {
            moveCameraToManhattanAnimated(true)
        }
    }
    
    fileprivate func flyToUserLocation() {
        
        // if location available...
        if let coord = DataSource.si.locationManager.location?.coordinate {
            
            let mapCam = MGLMapCamera(lookingAtCenter: coord, fromDistance: 5000, pitch: 30, heading: 0)
            mapboxView.fly(to: mapCam, withDuration: 3, peakAltitude: 13000, completionHandler: nil)
        }
    }
    
    fileprivate func fly(to coord: CLLocationCoordinate2D) {
        let mapCam = MGLMapCamera(lookingAtCenter: coord, fromDistance: 5500, pitch: 30, heading: 0)
        mapboxView.fly(to: mapCam, withDuration: 1, peakAltitude: 7000, completionHandler: nil)
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
        cameraView = CameraView(frame: (frames?.cameraView)!)
        view.addSubview(cameraView!)
    }
    
    fileprivate func updateHoodLabels(with coordinate: CLLocationCoordinate2D, fromTap: Bool) {
        switch fromTap {
        case true:
            do {
                if let hood = try DataSource.si.tappedHoodName(for: coordinate) {
                    cameraView.hoodView.hoodLabel.text = hood
                }
            } catch {}
            if let area = DataSource.si.tappedArea {
                cameraView.hoodView.areaLabel.text = area
            }
            updateWeatherLabelFromVisiting()
        case false:
            if let hood = DataSource.si.visitingHoodName(for: coordinate) {
                cameraView.hoodView.hoodLabel.text = hood
            }
            if let area = DataSource.si.visitingArea {
                cameraView.hoodView.areaLabel.text = area
            }
            updateWeatherLabelFromTap()
        }
    }
    
    @objc fileprivate func updateWeatherLabelFromVisiting() {
        if DataSource.si.weather.visitingWeatherID != nil {
            let weather = DataSource.si.weather.weatherEmojis(id: DataSource.si.weather.visitingWeatherID!)
            DataSource.si.visitingWeather = weather
            
            DispatchQueue.main.async {
                if let visitingWeatherTemp = DataSource.si.weather.visitingWeatherTemp {
                    let temperature = String(format: "%.0f", arguments: [visitingWeatherTemp])
                    self.cameraView.hoodView.weatherLabel.text = "\(temperature)ºF \(weather)"
                } else {
                    self.cameraView.hoodView.weatherLabel.text = weather
                }
            }
        }
    }
    
    @objc fileprivate func updateWeatherLabelFromTap() {
        if DataSource.si.weather.tappedWeatherID != nil {
            let weather = DataSource.si.weather.weatherEmojis(id: DataSource.si.weather.tappedWeatherID!)
            DataSource.si.tappedWeather = weather
            
            DispatchQueue.main.async {
                if let tappedWeatherTemp = DataSource.si.weather.tappedWeatherTemp {
                    let temperature = String(format: "%.0f", arguments: [tappedWeatherTemp])
                    self.cameraView.hoodView.weatherLabel.text = "\(temperature)ºF \(weather)"
                } else {
                    self.cameraView.hoodView.weatherLabel.text = weather
                }
            }
        }
    }
    
// MARK: Search
    
    fileprivate func addSearchResultsView() {
        searchResultsView = SearchResultsView(frame: (frames?.searchResultsViewHidden)!)
        mapboxView.addSubview(searchResultsView)
    }
    
    fileprivate func dropSearchResultsView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: { 
            self.searchResultsView.frame = (self.frames?.searchResultsViewDropped)!
        }) { finished in
        }
    }
    
    fileprivate func hideSearchResultsView() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseIn, animations: {
            self.searchResultsView.frame = (self.frames?.searchResultsViewHidden)!
        }) { finished in
        }
    }
    
// MARK: Profile
    
    fileprivate func addProfile() {
        
        // add the profile view with profile frame CLOSED
        profileView = ProfileView(frame: (frames?.profileViewHidden)!)

        // add the profile view shadow
        profileViewShadow = UIView(frame: (frames?.profileViewShadowHidden)!)
        profileViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        profileViewShadow.layer.cornerRadius = profileViewShadow.frame.width / 2
        profileViewShadow.layer.masksToBounds = true
        
        // set the profile button frame to CLOSED
        profileButton.frame = (frames?.profileViewHidden)!
        profileButton.addTarget(self, action: #selector(MapViewController.profileButtonTapped(_:)), for: .touchUpInside)
        
        mapboxView.addSubview(profileViewShadow)
        mapboxView.addSubview(profileView)
        mapboxView.addSubview(profileButton)
        
        addProfilePanGesture()
        
        // activate constraints for closed profile
        if DataSource.si.profileState == nil {
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
        if DataSource.si.profileState != .closed {
            
            toggleProfileSizeForState(.closed)
            
            self.profileView.layer.cornerRadius = self.profileView.closedRoundedCornerRadius
        }
    }
    
    @objc fileprivate func profileButtonTapped(_ sender: UIButton) {
        
        // if map button not already hiding...
        if DataSource.si.mapButtonState != .hiding {
            
            // open profile
            toggleProfileSizeForState(.open)
            
            // animate corner radius to 0
            profileView.animateCornerRadiusOf(self.profileView, fromValue: profileView.closedRoundedCornerRadius, toValue: profileView.openRoundedCornerRadius, duration: 0)
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
                self.profileView.frame = (self.frames?.profileViewOpen)!
                self.profileViewShadow.frame = (self.frames?.profileViewShadowOpen)!
                
                // activate the profile subview constraints for OPENED state
                self.profileView.activateConstraintsForState(.open)
                
                // set the profile button frame to 0
                self.profileButton.frame = CGRect.zero
                }, completion: { (Bool) in
                    
                    // sharpen edges of hood/camera view
                    self.cameraView.animateCornerRadiusOf(self.cameraView, fromValue: self.cameraView.roundedCornerRadius, toValue: 0.0, duration: 0.3)
            })
         
        // else close it
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: UIViewAnimationOptions(), animations: {
                
                // set the profile frame to CLOSED
                self.profileView.frame = (self.frames?.profileViewClosed)!
                self.profileViewShadow.frame = (self.frames?.profileViewShadowClosed)!
                
                // activate the profile subview constraints for CLOSED state
                self.profileView.activateConstraintsForState(.closed)
                
                // set the profile button frame to profile frame CLOSED
                self.profileButton.frame = (self.frames?.profileViewClosed)!
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
        federationButton = FederationButton(frame: (frames?.federationButtonHidden)!)
        federationButton.addTarget(self, action: #selector(MapViewController.federationButtonTapped), for: .touchDown)
        
        // shadow
        federationButtonShadow = UIView(frame: (frames?.federationButtonShadowHidden)!)
        federationButtonShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        federationButtonShadow.layer.cornerRadius = (frames?.federationButtonNormal.width)! / 2
        federationButtonShadow.layer.masksToBounds = true
        
        view.addSubview(federationButtonShadow)
        view.addSubview(federationButton)
    }
    
    @objc fileprivate func federationButtonTapped(_ sender: UIButton) {
        
        // animate the color green for half a sec
        federationButton.backgroundColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)
        UIView.animate(withDuration: 0.1, animations: {
            self.federationButton.backgroundColor = UIColor.black
            self.federationButton.frame = (self.frames?.federationButtonTapped)!
            self.federationButtonShadow.frame = (self.frames?.federationButtonShadowTapped)!
            }, completion: { (Bool) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.federationButton.frame = (self.frames?.federationButtonNormal)!
                    self.federationButtonShadow.frame = (self.frames?.federationButtonShadowNormal)!
                })
        })
        
        // close profile
        if DataSource.si.profileState == .open {
            toggleProfileSizeForState(.closed)
        }
        
        // if location is available
        if let coord = DataSource.si.locationManager.location?.coordinate {
            
            DataSource.si.mapState = .visiting
            
            flyToUserLocation()
            updateHoodLabels(with: coord, fromTap: false)
            updateWeatherLabelFromTap()
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
            
            DataSource.si.mapState = .tapping
            
            // haptic feedback for iPhone 7 and iPhone 7 Plus
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // CGPoint -> CLLocationCoordinate2D -> CLLocation
            let tappedLocationCoord = mapboxView.convert(sender.location(in: mapboxView), toCoordinateFrom: mapboxView)
            let tappedLocation = CLLocation(latitude: tappedLocationCoord.latitude, longitude: tappedLocationCoord.longitude)
            
            func reverseGeocode() {
                DataSource.si.geocoder.reverseGeocodeLocation(tappedLocation, completionHandler: { (placemarks, error) in
                    
                    if let placemark = placemarks?[0] {
                        
                        // update tapped area and placemark singletons
                        DataSource.si.tappedPlacemark = placemark
                        DataSource.si.updateTappedArea(with: placemark)
                        
                        do {
                            if let hood = try DataSource.si.tappedHoodName(for: tappedLocationCoord) {
                                self.cameraView.hoodView.hoodLabel.text = hood
                                self.fly(to: tappedLocationCoord)
                            }
                        } catch {}
                        if let area = DataSource.si.tappedArea {
                            self.cameraView.hoodView.areaLabel.text = area
                        }
                        DataSource.si.weather.updateWeatherIDAndTemp(coordinate: tappedLocationCoord, fromTap: true)
                    }
                })
            }
            
            // update the label and hood check state
            do {
                if let hood = try DataSource.si.tappedHoodName(for: tappedLocationCoord) {
                    cameraView.hoodView.hoodLabel.text = hood
                    fly(to: tappedLocationCoord)
                } else {
                    reverseGeocode()
                }
                if let area = DataSource.si.tappedArea {
                    cameraView.hoodView.areaLabel.text = area
                }
                DataSource.si.weather.updateWeatherIDAndTemp(coordinate: tappedLocationCoord, fromTap: true)
            } catch {
                reverseGeocode()
            }
            
            if cameraView.hoodView.searchBar.isFirstResponder {
                
                // dismiss search keyboard
                cameraView.hoodView.searchBar.resignFirstResponder()
            }
        }
        
    // profile behavior
        
        // if profile is open and tap was outside profile...
        if DataSource.si.profileState == .open {
            if !profileView.frame.contains(sender.location(in: mapboxView)) {
                
                // hide map icons and close profile
                hideMapIcons()
                toggleProfileSizeForState(.closed)
            }
        }
    }
    
// MARK: Offline Maps
    
    fileprivate func startOfflinePackDownload() {
        
        let latitude = DataSource.si.locationManager.location?.coordinate.latitude
        let longitude = DataSource.si.locationManager.location?.coordinate.longitude
        
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
    
    fileprivate func showShakeHintView() {
        shakeHintView = HintView(frame: (frames?.shakeHintHidden)!)
        shakeHintView.layer.cornerRadius = (frames?.shakeHintHidden.width)! / 2
        shakeHintView.layer.masksToBounds = true
        shakeHintView.button.isEnabled = false
        shakeHintView.label.text = "shake to see the buttons"
        
        shakeHintViewShadow = UIView(frame: (frames?.shakeHintShadowHidden)!)
        shakeHintViewShadow.layer.cornerRadius = (frames?.shakeHintHidden.width)! / 2
        shakeHintViewShadow.layer.masksToBounds = true
        shakeHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(shakeHintViewShadow)
        mapboxView.addSubview(shakeHintView)
        
        // show shake hint view
        UIView.animate(withDuration: 0.7, delay: 5, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.shakeHintViewShadow.frame = (self.frames?.shakeHintShadowShowingSmall)!
            self.shakeHintView.frame = (self.frames?.shakeHintShowingSmall)!
            
        // animate shake hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.shakeHintViewShadow.frame = (self.frames?.shakeHintShadowShowingBig)!
                self.shakeHintView.frame = (self.frames?.shakeHintShowingBig)!
                
            }, completion: { finished in
                
                // delay 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 7, execute: {
                    
                    // hide shake hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.shakeHintViewShadow.frame = (self.frames?.shakeHintShadowHidden)!
                        self.shakeHintView.frame = (self.frames?.shakeHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
        }
    }
    
    fileprivate func showHoodHintView() {
        hoodHintView = HintView(frame: (frames?.hoodHintHidden)!)
        hoodHintView.layer.cornerRadius = (frames?.hoodHintHidden.width)! / 2
        hoodHintView.layer.masksToBounds = true
        hoodHintView.button.isEnabled = false
        hoodHintView.label.text = "tap the hood's name to see its area"
        
        hoodHintViewShadow = UIView(frame: (frames?.hoodHintShadowHidden)!)
        hoodHintViewShadow.layer.cornerRadius = (frames?.hoodHintHidden.width)! / 2
        hoodHintViewShadow.layer.masksToBounds = true
        hoodHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(hoodHintViewShadow)
        mapboxView.addSubview(hoodHintView)
        
        // show hood hint view
        UIView.animate(withDuration: 0.7, delay: 16, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.hoodHintViewShadow.frame = (self.frames?.hoodHintShadowShowingSmall)!
            self.hoodHintView.frame = (self.frames?.hoodHintShowingSmall)!
            
            // animate hood hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.hoodHintViewShadow.frame = (self.frames?.hoodHintShadowShowingBig)!
                self.hoodHintView.frame = (self.frames?.hoodHintShowingBig)!
                
            }, completion: { finished in
                
                // delay 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 7, execute: {
                    
                    // hide shake hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.hoodHintViewShadow.frame = (self.frames?.hoodHintShadowHidden)!
                        self.hoodHintView.frame = (self.frames?.hoodHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
        }
    }
    
    fileprivate func showTapHintView() {
        tapHintView = HintView(frame: (frames?.tapHintHidden)!)
        tapHintView.layer.cornerRadius = (frames?.tapHintHidden.width)! / 2
        tapHintView.layer.masksToBounds = true
        tapHintView.button.isEnabled = false
        tapHintView.label.text = "tap the map to see which hood that is"
        
        tapHintViewShadow = UIView(frame: (frames?.tapHintShadowHidden)!)
        tapHintViewShadow.layer.cornerRadius = (frames?.tapHintHidden.width)! / 2
        tapHintViewShadow.layer.masksToBounds = true
        tapHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(tapHintViewShadow)
        mapboxView.addSubview(tapHintView)
        
        // show tap hint view
        UIView.animate(withDuration: 0.7, delay: 23, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.tapHintViewShadow.frame = (self.frames?.tapHintShadowShowingSmall)!
            self.tapHintView.frame = (self.frames?.tapHintShowingSmall)!
            
            // animate tap hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.tapHintViewShadow.frame = (self.frames?.tapHintShadowShowingBig)!
                self.tapHintView.frame = (self.frames?.tapHintShowingBig)!
                
            }, completion: { finished in
                
                // delay 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                    
                    // hide tap hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.tapHintViewShadow.frame = (self.frames?.tapHintShadowHidden)!
                        self.tapHintView.frame = (self.frames?.tapHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
        }
    }
    
    fileprivate func showEnableLocationHintView() {
        enableLocationHintView = HintView(frame: (frames?.enableLocationHintHidden)!)
        enableLocationHintView.layer.cornerRadius = (frames?.enableLocationHintHidden.width)! / 2
        enableLocationHintView.layer.masksToBounds = true
        enableLocationHintView.button.isEnabled = true
        enableLocationHintView.label.text = "tap here to enable location updates and see which hood you're in"
        
        enableLocationHintViewShadow = UIView(frame: (frames?.enableLocationHintShadowHidden)!)
        enableLocationHintViewShadow.layer.cornerRadius = (frames?.enableLocationHintHidden.width)! / 2
        enableLocationHintViewShadow.layer.masksToBounds = true
        enableLocationHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(enableLocationHintViewShadow)
        mapboxView.addSubview(enableLocationHintView)
        
        // show allow location hint view
        UIView.animate(withDuration: 0.7, delay: 3, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.enableLocationHintViewShadow.frame = (self.frames?.enableLocationHintShadowShowingSmall)!
            self.enableLocationHintView.frame = (self.frames?.enableLocationHintShowingSmall)!
            
            // animate allow location hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.enableLocationHintViewShadow.frame = (self.frames?.enableLocationHintShadowShowingBig)!
                self.enableLocationHintView.frame = (self.frames?.enableLocationHintShowingBig)!
                
            }, completion: { finished in
                
                // delay 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
                    
                    // hide allow location hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.enableLocationHintViewShadow.frame = (self.frames?.tapHintShadowHidden)!
                        self.enableLocationHintView.frame = (self.frames?.tapHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
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
        if DataSource.si.mapButtonState != .shown {
            
            // animate showing of icons
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .curveEaseIn, animations: {
                
                // set map button state to Shown
                DataSource.si.mapButtonState = .shown
                
//                self.profileViewShadow.frame = self.frameDict["profileViewShadowClosed"]!
//                self.profileView.frame = self.frameDict["profileViewClosed"]!
//                self.profileButton.frame = self.frameDict["profileViewClosed"]!
                self.federationButtonShadow.frame = (self.frames?.federationButtonShadowNormal)!
                self.federationButton.frame = (self.frames?.federationButtonNormal)!
                
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
            if DataSource.si.profileState != .open {
                
                // animate hiding of icons
                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 4, options: .curveEaseIn, animations: {
                    
                    DataSource.si.mapButtonState = .hiding
                    
                    if DataSource.si.profileState == .open {
                        self.toggleProfileSizeForState(.closed)
                    }
                    
//                    self.profileViewShadow.frame = self.frameDict["profileViewShadowHidden"]!
//                    self.profileView.frame = self.frameDict["profileViewHidden"]!
//                    self.profileButton.frame = self.frameDict["profileViewHidden"]!
                    self.federationButtonShadow.frame = (self.frames?.federationButtonShadowHidden)!
                    self.federationButton.frame = (self.frames?.federationButtonHidden)!
                    
                    }, completion: { finished in
                        
                        // set map icon state to Hidden
                        DataSource.si.mapButtonState = .hidden
                })
            }
        }
    }
    
    fileprivate func configureNotificationCenter() {
        
        // listen for "ApplicationDidBecomeActive" notification from app delegate
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name(rawValue: "ApplicationDidBecomeActive"), object: nil)
        
        // listen for "StopScanning" notification from data source
        NotificationCenter.default.addObserver(self, selector: #selector(setHoodScanningToFalse), name: NSNotification.Name(rawValue: "StopScanning"), object: nil)
        
        // listen for "GotWeatherFromVisiting" notification from weather getter
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherLabelFromVisiting), name: NSNotification.Name(rawValue: "GotWeatherFromVisiting"), object: nil)
        
        // listen for "GotWeatherFromTap" notification from weather getter
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherLabelFromTap), name: NSNotification.Name(rawValue: "GotWeatherFromTap"), object: nil)
        
        // setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
    }
    
// MARK: Frame Dict
    
    fileprivate func populateFrameDict() {
        
        // i have included parentheses for those who does not know pemdas http://lmgtfy.com/?q=pemdas
        
        let buttonSize = CGSize(width: 50, height: 50)
        let hoodViewHeight = view.frame.height * 0.14
        let searchResultsViewHeight = view.frame.height * 0.4
        let hintViewSize = CGSize(width: view.frame.width / 2, height: buttonSize.height)
        
        // hood view
        let cameraView = CGRect(x: 0, y: view.frame.minY - view.frame.height, width: view.frame.width, height: view.frame.height + hoodViewHeight)
        
        // search results view
        let searchResultsViewHidden = CGRect(x: 0, y: view.frame.minY - view.frame.height - searchResultsViewHeight, width: view.frame.width, height: searchResultsViewHeight)
        let searchResultsViewDropped = CGRect(x: 0, y: view.frame.minY - view.frame.height, width: view.frame.width, height: view.frame.height + searchResultsViewHeight)
        
        // profile view
        let profileViewHidden = CGRect(x: -padding - buttonSize.width, y: cameraView.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let profileViewClosed = CGRect(x: padding, y: cameraView.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let profileViewOpen = CGRect(x: 0, y: cameraView.maxY, width: view.frame.width, height: view.frame.height - hoodViewHeight)
        
        // profile view shadow
        let profileViewShadowHidden = CGRect(x: profileViewHidden.minX + 6, y: profileViewHidden.minY + 7, width: buttonSize.width, height: 50)
        let profileViewShadowClosed = CGRect(x: profileViewClosed.minX + 6, y: profileViewClosed.minY + 7, width: buttonSize.width, height: 50)
        let profileViewShadowOpen = CGRect(x: profileViewOpen.minX + 6, y: profileViewOpen.minY + 9, width: view.frame.width, height: view.frame.height - hoodViewHeight)
        
        // federation button
        let federationButtonHidden = CGRect(x: view.frame.maxX + padding, y: view.frame.height - buttonSize.height - (padding * 2), width: buttonSize.width, height: buttonSize.height)
        let federationButtonNormal = CGRect(x: view.frame.maxX - buttonSize.width - (padding * 2), y: view.frame.height - buttonSize.height - (padding * 2), width: buttonSize.width, height: buttonSize.height)
        let federationButtonTapped = CGRect(x: view.frame.maxX - buttonSize.width - (padding * 2), y: view.frame.height - buttonSize.height - (padding * 2) + 3, width: buttonSize.width, height: buttonSize.height)
        
        // federation button shadow
        let federationButtonShadowHidden = CGRect(x: federationButtonHidden.minX + 4, y: federationButtonHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let federationButtonShadowNormal = CGRect(x: federationButtonNormal.minX + 4, y: federationButtonNormal.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let federationButtonShadowTapped = CGRect(x: federationButtonTapped.minX + 3, y: federationButtonTapped.minY + 4, width: buttonSize.width, height: buttonSize.height)
        
        // shake hint
        let shakeHintHidden = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: view.frame.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let shakeHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: view.frame.maxY - hintViewSize.height - (padding * 2), width: buttonSize.width, height: buttonSize.height)
        let shakeHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: view.frame.maxY - hintViewSize.height - (padding * 2), width: hintViewSize.width, height: hintViewSize.height)
        
        // shake hint shadow
        let shakeHintShadowHidden = CGRect(x: shakeHintHidden.minX + 4, y: shakeHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let shakeHintShadowShowingSmall = CGRect(x: shakeHintShowingSmall.minX + 4, y: shakeHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let shakeHintShadowShowingBig = CGRect(x: shakeHintShowingBig.minX + 4, y: shakeHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // hood hint
        let hoodHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: hoodViewHeight + padding, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: hoodViewHeight + padding, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: hoodViewHeight + padding, width: hintViewSize.width, height: hintViewSize.height)
        
        // hood hint shadow
        let hoodHintShadowHidden = CGRect(x: hoodHintHidden.minX + 4, y: hoodHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShadowShowingSmall = CGRect(x: hoodHintShowingSmall.minX + 4, y: hoodHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShadowShowingBig = CGRect(x: hoodHintShowingBig.minX + 4, y: hoodHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // tap hint
        let tapHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: view.frame.midY - (buttonSize.height / 2), width: buttonSize.width, height: buttonSize.height)
        let tapHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: view.frame.midY - (buttonSize.height / 2), width: buttonSize.width, height: buttonSize.height)
        let tapHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: view.frame.midY - (hintViewSize.height / 2), width: hintViewSize.width, height: hintViewSize.height)
        
        // tap hint shadow
        let tapHintShadowHidden = CGRect(x: tapHintHidden.minX + 4, y: tapHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let tapHintShadowShowingSmall = CGRect(x: tapHintShowingSmall.minX + 4, y: tapHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let tapHintShadowShowingBig = CGRect(x: tapHintShowingBig.minX + 4, y: tapHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // allow location hint
        let enableLocationHintHidden = tapHintHidden
        let enableLocationHintShowingSmall = tapHintShowingSmall
        let enableLocationHintShowingBig = tapHintShowingBig
        
        // allow location hint shadow
        let enableLocationHintShadowHidden = tapHintShadowHidden
        let enableLocationHintShadowShowingSmall = tapHintShadowShowingSmall
        let enableLocationHintShadowShowingBig = tapHintShadowShowingBig
        
        frames = Frames(cameraView: cameraView,
                        searchResultsViewHidden: searchResultsViewHidden,
                        searchResultsViewDropped: searchResultsViewDropped,
                        profileViewHidden: profileViewHidden,
                        profileViewClosed: profileViewClosed,
                        profileViewOpen: profileViewOpen,
                        profileViewShadowHidden: profileViewShadowHidden,
                        profileViewShadowClosed: profileViewShadowClosed,
                        profileViewShadowOpen: profileViewShadowOpen,
                        federationButtonHidden: federationButtonHidden,
                        federationButtonNormal: federationButtonNormal,
                        federationButtonTapped: federationButtonTapped,
                        federationButtonShadowHidden: federationButtonShadowHidden,
                        federationButtonShadowNormal: federationButtonShadowNormal,
                        federationButtonShadowTapped: federationButtonShadowTapped,
                        shakeHintHidden: shakeHintHidden,
                        shakeHintShowingSmall: shakeHintShowingSmall,
                        shakeHintShowingBig: shakeHintShowingBig,
                        shakeHintShadowHidden: shakeHintShadowHidden,
                        shakeHintShadowShowingSmall: shakeHintShadowShowingSmall,
                        shakeHintShadowShowingBig: shakeHintShadowShowingBig,
                        hoodHintHidden: hoodHintHidden,
                        hoodHintShowingSmall: hoodHintShowingSmall,
                        hoodHintShowingBig: hoodHintShowingBig,
                        hoodHintShadowHidden: hoodHintShadowHidden,
                        hoodHintShadowShowingSmall: hoodHintShadowShowingSmall,
                        hoodHintShadowShowingBig: hoodHintShadowShowingBig,
                        tapHintHidden: tapHintHidden,
                        tapHintShowingSmall: tapHintShowingSmall,
                        tapHintShowingBig: tapHintShowingBig,
                        tapHintShadowHidden: tapHintShadowHidden,
                        tapHintShadowShowingSmall: tapHintShadowShowingSmall,
                        tapHintShadowShowingBig: tapHintShadowShowingBig,
                        enableLocationHintHidden: enableLocationHintHidden,
                        enableLocationHintShowingSmall: enableLocationHintShowingSmall,
                        enableLocationHintShowingBig: enableLocationHintShowingBig,
                        enableLocationHintShadowHidden: enableLocationHintShadowHidden,
                        enableLocationHintShadowShowingSmall: enableLocationHintShadowShowingSmall,
                        enableLocationHintShadowShowingBig: enableLocationHintShadowShowingBig)
    }
    
    @objc fileprivate func setHoodScanningToFalse() {
        hoodScanning = false
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

// MARK: UIGestureRecognizerDelegate

@available(iOS 10.0, *)
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

@available(iOS 10.0, *)
extension MapViewController: CLLocationManagerDelegate {
    
    // when authorization status changes...
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            DataSource.si.locationManager.startUpdatingLocation()
            DataSource.si.locationManager.startUpdatingHeading()
            
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
            if DataSource.si.mapState != .tapping {
                DataSource.si.mapState = .visiting
                
                // if not still in the hood...
                if DataSource.si.locationManager.location != nil {
                    if !DataSource.si.stillInTheHood(locations[0].coordinate) {
                        
                        // reverse geocode coord to get the area
                        DataSource.si.geocoder.reverseGeocodeLocation(locations[0], completionHandler: { (placemarks, error) in
                            if error == nil {
                                
                                // update the visiting placemark singleton and get the visiting area
                                let placemark = placemarks![0]
                                DataSource.si.visitingPlacemark = placemark
                                DataSource.si.updateVisitingArea(with: placemark)
                                
                                self.updateHoodLabels(with: locations[0].coordinate, fromTap: false)
                                
                                // update weather id and if successful, update label from notification that it posts
                                DataSource.si.weather.updateWeatherIDAndTemp(coordinate: (placemark.location?.coordinate)!, fromTap: false)
                                self.updateWeatherLabelFromVisiting()
                            }
                        })
                    } else {
                        updateHoodLabels(with: locations[0].coordinate, fromTap: false)
                        updateWeatherLabelFromVisiting()
                    }
                }
            }
        }
    }
}

// MARK: MGLMapViewDelegate

@available(iOS 10.0, *)
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

@available(iOS 10.0, *)
extension MapViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DataSource.si.mapState = .searching
        cameraView.hoodView.enlargeSearch()
        dropSearchResultsView()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        hideSearchResultsView()
        cameraView.hoodView.hideSearch()
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
