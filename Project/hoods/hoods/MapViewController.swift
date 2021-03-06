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
    
    var areaHintHidden: CGRect
    var areaHintShowingSmall: CGRect
    var areaHintShowingBig: CGRect
    var areaHintShadowHidden: CGRect
    var areaHintShadowShowingSmall: CGRect
    var areaHintShadowShowingBig: CGRect
    
    var searchHintHidden: CGRect
    var searchHintShowingSmall: CGRect
    var searchHintShowingBig: CGRect
    var searchHintShadowHidden: CGRect
    var searchHintShadowShowingSmall: CGRect
    var searchHintShadowShowingBig: CGRect
    
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

class MapViewController: UIViewController {
    
    let padding: CGFloat = 20
    fileprivate var hoodScanning = false
    fileprivate var frames: Frames?

    // gestures
    fileprivate var tap = UITapGestureRecognizer()
    fileprivate var profilePan = UIPanGestureRecognizer()

    // map
    @IBOutlet var mapboxView: MGLMapView!
    fileprivate var addressAnnotation: Annotation?
    fileprivate let manhattan = CLLocationCoordinate2DMake(40.722716755829168, -73.986322678333224)

    // search results
    fileprivate var searchResultsView = UIView()
    fileprivate var filteredHoods = [[String:String]]()
    
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
    
    // area hint
    fileprivate var areaHintView = HintView()
    fileprivate var areaHintViewShadow = UIView()
    
    // search hint
    fileprivate var searchHintView = HintView()
    fileprivate var searchHintViewShadow = UIView()
    
    // tap hint
    fileprivate var tapHintView = HintView()
    fileprivate var tapHintViewShadow = UIView()
    
    // enable location hint
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
        addProfile()
        addSearchResultsView()
        addCameraView()
        
        cameraView.hoodView.searchBar.delegate = self
        DataSource.si.populateHoodNamesForSearching()
        
        initialZoomIntoUserLocation()
    }
    
    func appDidBecomeActive() {
        if let coord = DataSource.si.locationManager.location?.coordinate {
            flyToUserLocation()
            updateHoodLabels(with: coord, from: "visit", hoodName: nil, areaName: nil)
            updateWeatherLabelFromVisit()
        }
        
        // only show hint view on first launch
        if !UserDefaults.standard.bool(forKey: "firstLaunch1.0") {
            UserDefaults.standard.set(true, forKey: "firstLaunch1.0")
            UserDefaults.standard.synchronize()
            
            if DataSource.si.locationManager.location != nil {
                showShakeHintView()
                showHoodHintView()
                showAreaHintView()
                showSearchHintView()
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
        
        // if the camera is not already on the coords passed in, zoom camera
        if mapboxView.centerCoordinate.latitude != coord.latitude && mapboxView.centerCoordinate.longitude != coord.longitude {
            mapboxView.setCenter(coord, zoomLevel: zoom, direction: 0, animated: animatedCenterChange, completionHandler: {
            })
            let camera = MGLMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: 0)
            mapboxView.setCamera(camera, withDuration: duration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
    }
    
    @objc fileprivate func initialZoomIntoUserLocation() {
        if let coord = DataSource.si.locationManager.location?.coordinate {
            
            // start far out at a 50° angle
            zoom(into: CLLocationCoordinate2DMake(coord.latitude - 0.05, coord.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // zoom into user location at a 30° angle over 3 seconds
            zoom(into: coord, distance: 5500, zoom: 10, pitch: 30, duration: 4, animatedCenterChange: false)
        } else {
            zoomIntoManhattan(animated: true)
        }
    }
    
    fileprivate func flyToUserLocation() {
        
        // if location available...
        if let coord = DataSource.si.locationManager.location?.coordinate {

            let distance = DataSource.si.cameraDistanceForHoodDiameter(from: DataSource.si.visitingHoodCoords)
            fly(to: coord, duration: 3.5, cameraDistance: distance, peakAltitude: 13000)
            DataSource.si.playSound(named: "swoosh", fileExtension: "wav")
        }
    }
    
    fileprivate func fly(to coord: CLLocationCoordinate2D, duration: TimeInterval, cameraDistance: CLLocationDistance, peakAltitude: CLLocationDistance) {

        let mapCam = MGLMapCamera(lookingAtCenter: coord, fromDistance: cameraDistance, pitch: 30, heading: 0)
        mapboxView.fly(to: mapCam, withDuration: duration, peakAltitude: peakAltitude, completionHandler: nil)
    }
    
    fileprivate func zoomIntoManhattan(animated: Bool) {
        if animated {
            
            // start far out at a 50° angle
            zoom(into: CLLocationCoordinate2DMake(manhattan.latitude - 0.05, manhattan.longitude - 0.05), distance: 17000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            
            // zoom into manhattan at a 30° angle over 3 seconds
            zoom(into: manhattan, distance: 5000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
        }
    }
    
// MARK: Hood View
    
    fileprivate func addCameraView() {
        cameraView = CameraView(frame: (frames?.cameraView)!)
        view.addSubview(cameraView!)
    }
    
    fileprivate func updateHoodLabels(with coordinate: CLLocationCoordinate2D, from: String, hoodName: String?, areaName: String?) {
        switch from {
        case "tap":
            do {
                if let hood = try DataSource.si.tappedHoodName(for: coordinate) {
                    cameraView.hoodView.hoodLabel.text = hood
                }
            } catch {}
            if let area = DataSource.si.tappedArea {
                cameraView.hoodView.areaLabel.text = area
            }
        case "addressSearch":
            do {
                if let hood = try DataSource.si.searchedAddressHoodName(for: coordinate) {
                    cameraView.hoodView.hoodLabel.text = hood
                }
            } catch {}
            if let area = DataSource.si.searchedAddressArea {
                cameraView.hoodView.areaLabel.text = area
            }
        case "visit":
            if let hood = DataSource.si.visitingHoodName(for: coordinate) {
                cameraView.hoodView.hoodLabel.text = hood
            }
            if let area = DataSource.si.visitingArea {
                cameraView.hoodView.areaLabel.text = area
            }
        default:
            for hood in DataSource.si.hoodAndAreaNames {
                if hoodName != nil && areaName != nil {
                    if hood["neighborhood"] == hoodName && hood["area"] == areaName {
                        cameraView.hoodView.hoodLabel.text = hood["neighborhood"]!
                        cameraView.hoodView.areaLabel.text = hood["area"]!
                    }
                }
            }
        }
    }
    
    @objc fileprivate func updateWeatherLabelFromVisit() {
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
    
    @objc fileprivate func updateWeatherLabelFromSearch() {
        if DataSource.si.weather.searchedAddressWeatherID != nil {
            let weather = DataSource.si.weather.weatherEmojis(id: DataSource.si.weather.searchedAddressWeatherID!)
            DataSource.si.searchedAddressWeather = weather
            
            DispatchQueue.main.async {
                if let searchedAddressWeatherTemp = DataSource.si.weather.searchedAddressWeatherTemp {
                    let temperature = String(format: "%.0f", arguments: [searchedAddressWeatherTemp])
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
        
        (searchResultsView as! SearchResultsView).tableView.delegate = self
        (searchResultsView as! SearchResultsView).tableView.dataSource = self
        (searchResultsView as! SearchResultsView).tableView.rowHeight = 50
    }
    
    fileprivate func dropSearchResultsView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.searchResultsView.frame = (self.frames?.searchResultsViewDropped)!
        }) { finished in
        }
    }
    
    fileprivate func hideSearchResultsView() {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseIn, animations: {
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
            
            toggleProfileSize(to: .closed)
            
            self.profileView.layer.cornerRadius = self.profileView.closedRoundedCornerRadius
        }
    }
    
    @objc fileprivate func profileButtonTapped(_ sender: UIButton) {
        
        // if map button not already hiding...
        if DataSource.si.mapButtonState != .hiding {
            
            // open profile
            toggleProfileSize(to: .open)
            
            // animate corner radius to 0
            profileView.animateCornerRadius(of: self.profileView, fromValue: profileView.closedRoundedCornerRadius, toValue: profileView.openRoundedCornerRadius, duration: 0)
        }
    }
    
    fileprivate func toggleProfileSize(to desiredState: ProfileState) {
        
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
                    self.cameraView.animateCornerRadius(of: self.cameraView, fromValue: self.cameraView.roundedCornerRadius, toValue: 0.0, duration: 0.3)
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
            toggleProfileSize(to: .closed)
        }
        
        // if location is available
        if let coord = DataSource.si.locationManager.location?.coordinate {
            
            DataSource.si.mapState = .visiting
            
            flyToUserLocation()
            updateHoodLabels(with: coord, from: "visit", hoodName: nil, areaName: nil)
            updateWeatherLabelFromVisit()
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
        if !cameraView.frame.contains(sender.location(in: mapboxView)) && !profileView.frame.contains(sender.location(in: mapboxView)) && !federationButton.frame.contains(sender.location(in: mapboxView)) && !searchResultsView.frame.contains(sender.location(in: mapboxView)) {
            
            // play map tap sound
            DataSource.si.playSound(named: "tap-mellow", fileExtension: "aif")
            
            // update map state
            DataSource.si.mapState = .tapping
            
            // enable haptic feedback for iPhone 7 and iPhone 7 Plus
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            
            // CGPoint -> CLLocationCoordinate2D -> CLLocation
            let tappedLocationCoord = mapboxView.convert(sender.location(in: mapboxView), toCoordinateFrom: mapboxView)
            let tappedLocation = CLLocation(latitude: tappedLocationCoord.latitude, longitude: tappedLocationCoord.longitude)
            
            // reverse geocode func that is used if hood not found for current or tapped area
            func reverseGeocode() {
                DataSource.si.geocoder.reverseGeocodeLocation(tappedLocation, completionHandler: { (placemarks, error) in
                    
                    if let placemark = placemarks?[0] {
                        
                        // update tapped placemark and area singletons
                        DataSource.si.tappedPlacemark = placemark
                        DataSource.si.updateTappedArea(with: placemark)
                        
                        // update hood label and fly to hood
                        do {
                            if let hood = try DataSource.si.tappedHoodName(for: tappedLocationCoord) {
                                self.cameraView.hoodView.hoodLabel.text = hood
                                
//                                self.updateHoodNameImage(fromText: hood)
//                                self.addAnnotation(at: DataSource.si.polygonCenter(from: DataSource.si.tappedHoodCoords), title: hood, imageName: "hoodNameImage", reuseIdentifier: "hoodNameImage")

                                let distance = DataSource.si.cameraDistanceForHoodDiameter(from: DataSource.si.tappedHoodCoords)
                                let center = DataSource.si.polygonCenter(from: DataSource.si.tappedHoodCoords)
                                self.fly(to: center, duration: 1, cameraDistance: distance, peakAltitude: 7000)
                            }
                        } catch {}
                        
                        // update area label
                        if let area = DataSource.si.tappedArea {
                            self.cameraView.hoodView.areaLabel.text = area
                        }
                        
                        // update weather data for tapped location and update weather label
                        DataSource.si.weather.updateWeatherIDAndTemp(coordinate: tappedLocationCoord, from: "tap")
                        self.updateWeatherLabelFromTap()
                    }
                })
            }
            
            do {
                // try to update hood label from tapped location and fly there...
                if let hood = try DataSource.si.tappedHoodName(for: tappedLocationCoord) {
                    cameraView.hoodView.hoodLabel.text = hood
                    
//                    updateHoodNameImage(fromText: hood)
//                    addAnnotation(at: DataSource.si.polygonCenter(from: DataSource.si.tappedHoodCoords), title: hood, imageName: "hoodNameImage", reuseIdentifier: "hoodNameImage")
                    
                    let distance = DataSource.si.cameraDistanceForHoodDiameter(from: DataSource.si.tappedHoodCoords)
                    let center = DataSource.si.polygonCenter(from: DataSource.si.tappedHoodCoords)
                    fly(to: center, duration: 1, cameraDistance: distance, peakAltitude: 7000)
                    
                // else use reverse geocode func to update area and then update hood/area/weather labels
                } else {
                    reverseGeocode()
                }
                
                // update area label
                if let area = DataSource.si.tappedArea {
                    cameraView.hoodView.areaLabel.text = area
                }
                
                // update weather data from tapped location and update weather label
                DataSource.si.weather.updateWeatherIDAndTemp(coordinate: tappedLocationCoord, from: "tap")
                updateWeatherLabelFromTap()
            } catch {
                reverseGeocode()
            }
            
            // if keyboard showing from search bar, hide it
            if cameraView.hoodView.searchBar.isFirstResponder {
                cameraView.hoodView.searchBar.resignFirstResponder()
            }
        }
        
    // profile behavior
        
        // if profile is open and tap was outside profile...
        if DataSource.si.profileState == .open {
            if !profileView.frame.contains(sender.location(in: mapboxView)) {
                
                // hide map icons and close profile
                hideMapIcons()
                toggleProfileSize(to: .closed)
            }
        }
    }
    
// MARK: Annotations
    
    fileprivate func addAnnotation(at coordinate: CLLocationCoordinate2D, title: String, imageName: String, reuseIdentifier: String) {
        
        // if there's already an address annotation on the map, remove it first
        if addressAnnotation != nil {
            mapboxView.removeAnnotation(addressAnnotation!)
        }
        
        addressAnnotation?.image = UIImage(named: "address")
        
        addressAnnotation = Annotation(coordinate: coordinate, title: title, imageName: imageName, reuseIdentifier: reuseIdentifier)
        mapboxView.addAnnotation(addressAnnotation!)
    }
    
    fileprivate func updateHoodNameImage(fromText hoodName: String) {
        if hoodName != "" {
            let hoodNameImage = DataSource.si.image(from: hoodName as NSString, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 7)], size: CGSize(width: 100, height: 50))
            print("hoodNameImage: \(hoodNameImage)")
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("hoodNameImage")
            
            if let pngImageData = UIImagePNGRepresentation(hoodNameImage) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    print("file exists")
                    do {
                        try FileManager.default.removeItem(atPath: fileURL.path)
                    } catch {
                        print(error.localizedDescription)
                    }
                    FileManager.default.createFile(atPath: fileURL.path, contents: pngImageData, attributes: nil)
                } else {
                    print("file didn't exist, creating")
                    FileManager.default.createFile(atPath: fileURL.path, contents: pngImageData, attributes: nil)
                }
            }
        } else {
            print("hood name was nil")
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
                
                // delay hiding 7 sec
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
                
                // delay hiding 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                    
                    // hide hood hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.hoodHintViewShadow.frame = (self.frames?.hoodHintShadowHidden)!
                        self.hoodHintView.frame = (self.frames?.hoodHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
        }
    }
    
    fileprivate func showAreaHintView() {
        areaHintView = HintView(frame: (frames?.areaHintHidden)!)
        areaHintView.layer.cornerRadius = (frames?.areaHintHidden.width)! / 2
        areaHintView.layer.masksToBounds = true
        areaHintView.button.isEnabled = false
        areaHintView.label.text = "tap the area name to go back to hoods"
        
        areaHintViewShadow = UIView(frame: (frames?.areaHintShadowHidden)!)
        areaHintViewShadow.layer.cornerRadius = (frames?.areaHintHidden.width)! / 2
        areaHintViewShadow.layer.masksToBounds = true
        areaHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(areaHintViewShadow)
        mapboxView.addSubview(areaHintView)
        
        // show area hint view
        UIView.animate(withDuration: 0.7, delay: 22, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.areaHintViewShadow.frame = (self.frames?.areaHintShadowShowingSmall)!
            self.areaHintView.frame = (self.frames?.areaHintShowingSmall)!
            
            // animate area hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.areaHintViewShadow.frame = (self.frames?.areaHintShadowShowingBig)!
                self.areaHintView.frame = (self.frames?.areaHintShowingBig)!
                
            }, completion: { finished in
                
                // delay hiding 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                    
                    // hide area hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.areaHintViewShadow.frame = (self.frames?.areaHintShadowHidden)!
                        self.areaHintView.frame = (self.frames?.areaHintHidden)!
                        
                    }, completion: { finished in
                    })
                })
            })
        }
    }
    
    fileprivate func showSearchHintView() {
        searchHintView = HintView(frame: (frames?.searchHintHidden)!)
        searchHintView.layer.cornerRadius = (frames?.searchHintHidden.width)! / 2
        searchHintView.layer.masksToBounds = true
        searchHintView.button.isEnabled = false
        searchHintView.label.text = "try searching for a hood or an address"
        
        searchHintViewShadow = UIView(frame: (frames?.searchHintShadowHidden)!)
        searchHintViewShadow.layer.cornerRadius = (frames?.searchHintHidden.width)! / 2
        searchHintViewShadow.layer.masksToBounds = true
        searchHintViewShadow.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        
        mapboxView.addSubview(searchHintViewShadow)
        mapboxView.addSubview(searchHintView)
        
        // show search hint view
        UIView.animate(withDuration: 0.7, delay: 35, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.searchHintViewShadow.frame = (self.frames?.searchHintShadowShowingSmall)!
            self.searchHintView.frame = (self.frames?.searchHintShowingSmall)!
            
            // animate search hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.searchHintViewShadow.frame = (self.frames?.searchHintShadowShowingBig)!
                self.searchHintView.frame = (self.frames?.searchHintShowingBig)!
                
            }, completion: { finished in
                
                // delay hiding 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                    
                    // hide search hint view
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                        self.searchHintViewShadow.frame = (self.frames?.searchHintShadowHidden)!
                        self.searchHintView.frame = (self.frames?.searchHintHidden)!
                        
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
        UIView.animate(withDuration: 0.7, delay: 28, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.tapHintViewShadow.frame = (self.frames?.tapHintShadowShowingSmall)!
            self.tapHintView.frame = (self.frames?.tapHintShowingSmall)!
            
            // animate tap hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.tapHintViewShadow.frame = (self.frames?.tapHintShadowShowingBig)!
                self.tapHintView.frame = (self.frames?.tapHintShowingBig)!
                
            }, completion: { finished in
                
                // delay hiding 3 sec
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
        
        // show enable location hint view
        UIView.animate(withDuration: 0.7, delay: 3, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
            self.enableLocationHintViewShadow.frame = (self.frames?.enableLocationHintShadowShowingSmall)!
            self.enableLocationHintView.frame = (self.frames?.enableLocationHintShowingSmall)!
            
            // animate enable location hint view to big
        }) { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
                self.enableLocationHintViewShadow.frame = (self.frames?.enableLocationHintShadowShowingBig)!
                self.enableLocationHintView.frame = (self.frames?.enableLocationHintShowingBig)!
                
            }, completion: { finished in
                
                // delay 5 sec
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
                    
                    // hide enable location hint view
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
            
            DataSource.si.playSound(named: "woosh", fileExtension: "wav")
            
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
                        self.toggleProfileSize(to: .closed)
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
        
        // listen for weather notifications from weather getter
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherLabelFromVisit), name: NSNotification.Name(rawValue: "GotWeatherFromVisit"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherLabelFromTap), name: NSNotification.Name(rawValue: "GotWeatherFromTap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherLabelFromSearch), name: NSNotification.Name(rawValue: "GotWeatherFromSearch"), object: nil)
        
        // setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)
    }
    
// MARK: Frame Dict
    
    fileprivate func populateFrameDict() {
        
        // i have included parentheses for those who does not know pemdas http://lmgtfy.com/?q=pemdas
        
        let buttonSize = CGSize(width: 50, height: 50)
        DataSource.si.hoodViewHeight = view.frame.height * 0.14
        let searchResultsViewHeight = view.frame.height * 0.5
        let hintViewSize = CGSize(width: view.frame.width / 2, height: buttonSize.height)
        
        // camera view view
        let cameraView = CGRect(x: 0, y: view.frame.minY - view.frame.height, width: view.frame.width, height: view.frame.height + DataSource.si.hoodViewHeight!)
        
        // search results view
        let searchResultsViewHidden = CGRect(x: 0, y: view.frame.minY - view.frame.height - searchResultsViewHeight, width: view.frame.width, height: searchResultsViewHeight)
        let searchResultsViewDropped = CGRect(x: 0, y: view.frame.minY - view.frame.height, width: view.frame.width, height: view.frame.height + searchResultsViewHeight)
        
        // profile view
        let profileViewHidden = CGRect(x: -padding - buttonSize.width, y: cameraView.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let profileViewClosed = CGRect(x: padding, y: cameraView.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let profileViewOpen = CGRect(x: 0, y: cameraView.maxY, width: view.frame.width, height: view.frame.height - DataSource.si.hoodViewHeight!)
        
        // profile view shadow
        let profileViewShadowHidden = CGRect(x: profileViewHidden.minX + 6, y: profileViewHidden.minY + 7, width: buttonSize.width, height: 50)
        let profileViewShadowClosed = CGRect(x: profileViewClosed.minX + 6, y: profileViewClosed.minY + 7, width: buttonSize.width, height: 50)
        let profileViewShadowOpen = CGRect(x: profileViewOpen.minX + 6, y: profileViewOpen.minY + 9, width: view.frame.width, height: view.frame.height - DataSource.si.hoodViewHeight!)
        
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
        let hoodHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: DataSource.si.hoodViewHeight! + padding, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: DataSource.si.hoodViewHeight! + padding, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: DataSource.si.hoodViewHeight! + padding, width: hintViewSize.width, height: hintViewSize.height)
        
        // hood hint shadow
        let hoodHintShadowHidden = CGRect(x: hoodHintHidden.minX + 4, y: hoodHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShadowShowingSmall = CGRect(x: hoodHintShowingSmall.minX + 4, y: hoodHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let hoodHintShadowShowingBig = CGRect(x: hoodHintShowingBig.minX + 4, y: hoodHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // area hint
        let areaHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: hoodHintHidden.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let areaHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: hoodHintShowingSmall.maxY + padding, width: buttonSize.width, height: buttonSize.height)
        let areaHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: hoodHintShowingBig.maxY + padding, width: hintViewSize.width, height: hintViewSize.height)
        
        // area hint shadow
        let areaHintShadowHidden = CGRect(x: areaHintHidden.minX + 4, y: areaHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let areaHintShadowShowingSmall = CGRect(x: areaHintShowingSmall.minX + 4, y: areaHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let areaHintShadowShowingBig = CGRect(x: areaHintShowingBig.minX + 4, y: areaHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // search hint
        let searchHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: DataSource.si.hoodViewHeight! + padding, width: buttonSize.width, height: buttonSize.height)
        let searchHintShowingSmall = CGRect(x: padding, y: DataSource.si.hoodViewHeight! + padding, width: buttonSize.width, height: buttonSize.height)
        let searchHintShowingBig = CGRect(x: padding, y: DataSource.si.hoodViewHeight! + padding, width: hintViewSize.width, height: hintViewSize.height)
        
        // search hint shadow
        let searchHintShadowHidden = CGRect(x: searchHintHidden.minX + 4, y: searchHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let searchHintShadowShowingSmall = CGRect(x: searchHintShowingSmall.minX + 4, y: searchHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let searchHintShadowShowingBig = CGRect(x: searchHintShowingBig.minX + 4, y: searchHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // tap hint
        let tapHintHidden = CGRect(x: view.frame.minX - buttonSize.width - padding, y: view.frame.midY - (buttonSize.height / 2), width: buttonSize.width, height: buttonSize.height)
        let tapHintShowingSmall = CGRect(x: view.frame.midX - (buttonSize.width / 2), y: view.frame.midY - (buttonSize.height / 2), width: buttonSize.width, height: buttonSize.height)
        let tapHintShowingBig = CGRect(x: view.frame.midX - (hintViewSize.width / 2), y: view.frame.midY - (hintViewSize.height / 2), width: hintViewSize.width, height: hintViewSize.height)
        
        // tap hint shadow
        let tapHintShadowHidden = CGRect(x: tapHintHidden.minX + 4, y: tapHintHidden.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let tapHintShadowShowingSmall = CGRect(x: tapHintShowingSmall.minX + 4, y: tapHintShowingSmall.minY + 5, width: buttonSize.width, height: buttonSize.height)
        let tapHintShadowShowingBig = CGRect(x: tapHintShowingBig.minX + 4, y: tapHintShowingBig.minY + 5, width: hintViewSize.width, height: hintViewSize.height)
        
        // enable location hint
        let enableLocationHintHidden = tapHintHidden
        let enableLocationHintShowingSmall = tapHintShowingSmall
        let enableLocationHintShowingBig = tapHintShowingBig
        
        // enable location hint shadow
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
                        
                        areaHintHidden: areaHintHidden,
                        areaHintShowingSmall: areaHintShowingSmall,
                        areaHintShowingBig: areaHintShowingBig,
                        areaHintShadowHidden: areaHintShadowHidden,
                        areaHintShadowShowingSmall: areaHintShadowShowingSmall,
                        areaHintShadowShowingBig: areaHintShadowShowingBig,
                        
                        searchHintHidden: searchHintHidden,
                        searchHintShowingSmall: searchHintShowingSmall,
                        searchHintShowingBig: searchHintShowingBig,
                        searchHintShadowHidden: searchHintShadowHidden,
                        searchHintShadowShowingSmall: searchHintShadowShowingSmall,
                        searchHintShadowShowingBig: searchHintShadowShowingBig,
                        
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

extension MapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        // if touch is not in camera, profile, search results, enable location hint, or federation button, let gesture pass through to map
        if !cameraView!.frame.contains(touch.location(in: mapboxView)) &&
            !profileView.frame.contains(touch.location(in: mapboxView)) &&
            !searchResultsView.frame.contains(touch.location(in: mapboxView)) &&
            !enableLocationHintView.frame.contains(touch.location(in: mapboxView)) &&
            !federationButton.frame.contains(touch.location(in: mapboxView))
                {
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
            
            DataSource.si.locationManager.startUpdatingLocation()
            DataSource.si.locationManager.startUpdatingHeading()
            
            // turns on hood checking until it fails and this gets set to false
            hoodScanning = true
            
            // only show user location if status is authorized when in use
            mapboxView.showsUserLocation = true
            
        } else if status == .denied {
            
            zoomIntoManhattan(animated: true)
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
                    if !DataSource.si.stillInTheHood(at: locations[0].coordinate) {
                        
                        // reverse geocode coord to get the area
                        DataSource.si.geocoder.reverseGeocodeLocation(locations[0], completionHandler: { (placemarks, error) in
                            if error == nil {
                                
                                // update the visiting placemark singleton and get the visiting area
                                let placemark = placemarks![0]
                                DataSource.si.visitingPlacemark = placemark
                                DataSource.si.updateVisitingArea(with: placemark)
                                
                                self.updateHoodLabels(with: locations[0].coordinate, from: "visit", hoodName: nil, areaName: nil)
                                
                                // update weather id and if successful, update label from notification that it posts
                                DataSource.si.weather.updateWeatherIDAndTemp(coordinate: (placemark.location?.coordinate)!, from: "visit")
                                self.updateWeatherLabelFromVisit()
                            }
                        })
                    } else {
                        updateHoodLabels(with: locations[0].coordinate, from: "visit", hoodName: nil, areaName: nil)
                    }
                    DataSource.si.weather.updateWeatherIDAndTemp(coordinate: locations[0].coordinate, from: "visit")
                    updateWeatherLabelFromVisit()
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

extension MapViewController: UISearchResultsUpdating {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredContent(with: cameraView.hoodView.searchBar.text!)
        (searchResultsView as! SearchResultsView).tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            for hood in DataSource.si.hoodAndAreaNames {
                let searchText = searchBar.text?.lowercased()
                if hood["neighborhood"]?.lowercased() == searchText {
                    print("got a hood from search button")
                    DataSource.si.updateSearchedHoodCoords(from: hood["neighborhood"]!, in: hood["area"]!)
                    let center = DataSource.si.polygonCenter(from: DataSource.si.searchedHoodCoords)
                    let distance = DataSource.si.cameraDistanceForHoodDiameter(from: DataSource.si.searchedHoodCoords)
                    self.fly(to: center, duration: 1, cameraDistance: distance, peakAltitude: 7000)
                    self.cameraView.hoodView.searchBar.resignFirstResponder()
                    self.updateHoodLabels(with: center, from: "hoodSearch", hoodName: hood["neighborhood"]!, areaName: hood["area"]!)
                    
//                    updateHoodNameImage(fromText: hood["neighborhood"]!)
//                    addAnnotation(at: DataSource.si.polygonCenter(from: DataSource.si.searchedHoodCoords), title: hood["neighborhood"]!, imageName: "hoodNameImage", reuseIdentifier: "hoodNameImage")

                    DataSource.si.weather.updateWeatherIDAndTemp(coordinate: center, from: "search")
                    self.updateWeatherLabelFromSearch()
                    self.setHoodScanningToFalse()
                    return
                }
            }
            DataSource.si.geocoder.geocodeAddressString(searchBar.text!, completionHandler: { (placemarks, error) in
                if error == nil {
                    if let placemark = placemarks?.first {
                        DataSource.si.searchedAddressPlacemark = placemark
                        DataSource.si.updateSearchedAddressArea(with: placemark)
                        
                        if let coord = placemark.location?.coordinate {
                            self.fly(to: coord, duration: 1, cameraDistance: 5500, peakAltitude: 7000)
                            DataSource.si.playSound(named: "swoosh", fileExtension: "wav")
                            self.cameraView.hoodView.searchBar.resignFirstResponder()
                            self.updateHoodLabels(with: coord, from: "addressSearch", hoodName: nil, areaName: nil)
                            DataSource.si.weather.updateWeatherIDAndTemp(coordinate: coord, from: "search")
                            self.updateWeatherLabelFromSearch()
                            
                            self.addAnnotation(at: coord, title: "address", imageName: "address", reuseIdentifier: "address")

                            self.setHoodScanningToFalse()
                        }
                    }
                } else {
                    DataSource.si.playSound(named: "rigidFart", fileExtension: "wav")
                    print(error?.localizedDescription as Any)
                }
            })
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func updateFilteredContent(with searchText: String) {
        filteredHoods.removeAll()
        for hood in DataSource.si.hoodAndAreaNames {
            if hood["neighborhood"]?.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil {
                let neighborhood = hood["neighborhood"]
                let area = hood["area"]
                filteredHoods.append(["neighborhood": neighborhood!, "area": area!])
            }
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHoods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell")
        let filteredHood = filteredHoods[indexPath.row]
        let neighborhood = filteredHood["neighborhood"]!
        let area = filteredHood["area"]!
        cell?.textLabel?.text = "\(neighborhood), \(area)"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filteredHood = filteredHoods[indexPath.row]
        DataSource.si.updateSearchedHoodCoords(from: filteredHood["neighborhood"]!, in: filteredHood["area"]!)
        
        let searchedCenter = DataSource.si.polygonCenter(from: DataSource.si.searchedHoodCoords)
        let distance = DataSource.si.cameraDistanceForHoodDiameter(from: DataSource.si.searchedHoodCoords)
        fly(to: searchedCenter, duration: 1, cameraDistance: distance, peakAltitude: 7000)
        
        DataSource.si.playSound(named: "swoosh", fileExtension: "wav")
        
        // hide keyboard
        cameraView.hoodView.searchBar.resignFirstResponder()
        
        // update labels
        cameraView.hoodView.hoodLabel.text = filteredHood["neighborhood"]!
        cameraView.hoodView.areaLabel.text = filteredHood["area"]!
        
        // add hood name annotation
//        updateHoodNameImage(fromText: filteredHood["neighborhood"]!)
//        addAnnotation(at: DataSource.si.polygonCenter(from: DataSource.si.searchedHoodCoords), title: filteredHood["neighborhood"]!, imageName: "hoodNameImage", reuseIdentifier: "hoodNameImage")
        
        DataSource.si.weather.updateWeatherIDAndTemp(coordinate: searchedCenter, from: "search")
        updateWeatherLabelFromSearch()
        
        setHoodScanningToFalse()
    }
}

extension UIView {
    
    func animateCornerRadius(of viewToAnimate: UIView, fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        viewToAnimate.layer.add(animation, forKey: "cornerRadius")
        viewToAnimate.layer.cornerRadius = toValue
    }
}
