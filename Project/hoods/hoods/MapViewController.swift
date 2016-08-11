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
    private let locationManager = CLLocationManager()
    private var scanningHood = false
    private var feedView = FeedView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up Mapbox view
        mapboxView.delegate = self
        mapboxView.tintColor = UIColor.clearColor()
        mapboxView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // set up location manager
        DataSource.sharedInstance.locationManager.delegate = self
        DataSource.sharedInstance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        DataSource.sharedInstance.locationManager.distanceFilter = kCLDistanceFilterNone

        addFeedView()
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
            moveCameraTo(centerCoordinate, distance: 4000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
            
        // else move camera into manhattan from 50° to 30° over 3 seconds
        } else {
            moveCameraTo(CLLocationCoordinate2DMake(manhattan.latitude - 0.05, manhattan.longitude - 0.05), distance: 13000, zoom: 10, pitch: 50, duration: 0, animatedCenterChange: false)
            moveCameraTo(manhattan, distance: 4000, zoom: 10, pitch: 30, duration: 3, animatedCenterChange: false)
        }
    }
    
    private func setCameraToManhattan() {
        
        // set camera to manhattan instantly
        moveCameraTo(manhattan, distance: 4000, zoom: 10, pitch: 30, duration: 0, animatedCenterChange: false)
    }
    
// MARK: Feed
    
    private func addFeedView() {
        feedView = FeedView(frame: CGRect(x: 0, y: view.frame.maxY - 90, width: view.frame.width, height: 130))
        mapboxView.addSubview(feedView)
    }
}

// MARK: CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    // when authorization status changes...
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .AuthorizedWhenInUse {
            
            // only show user location if status is authorized when in use
            mapboxView.showsUserLocation = true
            
            // turns on hood checking until it fails and this gets set to false
            scanningHood = true
            
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
            // update the current hood label
            feedView.currentHoodLabel.text = DataSource.sharedInstance.currentHoodName(locationManager.location!.coordinate)
            
        }
        
        // notify the app delegate to release the hole
        NSNotificationCenter.defaultCenter().postNotificationName("LocationManagerAuthChanged", object: nil)
        
        // move camera into your location
        attemptToMoveCameraToUserLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if scanningHood == true {
            feedView.currentHoodLabel.text = DataSource.sharedInstance.currentHoodName(locations[0].coordinate)
        }
        
        // if hood label is blank after hood check, set label to "Hoods"
        if feedView.currentHoodLabel.text == "" {
            feedView.youAreInLabel.text = "You're not in any"
            feedView.currentHoodLabel.text = "Hoods"
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
