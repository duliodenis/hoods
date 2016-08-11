//
//  DataSource.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit
import Mapbox
import MapKit

class DataSource {
    static let sharedInstance = DataSource()
    private init() {}
    
    var locationManager = CLLocationManager()
    var lastHoodName: String?
    var lastPolygonRenderer: MKPolygonRenderer?
    var calloutRepresentedObjectTitle = ""
    
    func currentHoodName(currentLocation: CLLocationCoordinate2D) -> String {
        
        // if your coords are not in the last polygon...
        if stillInTheHood(currentLocation) == false {
            
            // check through all hood polygons for your coords and update last hood name
            lastHoodName = fullHoodCheck(currentLocation)
            
            // if full hood check failed, send notification to set scanningHoods to false and return blank string
            if lastHoodName == "" {
                NSNotificationCenter.defaultCenter().postNotificationName("NotInAHood", object: nil)
                return ""
                
            // if full hood check succeeded, return last hood name
            } else {
                return lastHoodName!
            }
            
        // else you have been to a hood and your coords are in the last polygon, return last hood name
        } else if lastHoodName != nil {
            print("You are still in \(lastHoodName!).")
            return lastHoodName!
            
        // else your coords are in the last polygon, return blank string
        } else {
            return ""
        }
    }
    
    private func fullHoodCheck(currentLocation: CLLocationCoordinate2D) -> String {
        
        // convert GeoJSON to NSData
        let filePath = NSBundle.mainBundle().pathForResource("manualNYC", ofType: "geojson")!
        let data = NSData(contentsOfFile: filePath)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            
            if let hoods = json["features"] as? [[String: AnyObject]] {
                
                // iterate through all hoods
                for hood in hoods {
                    
                    var coords = [CLLocationCoordinate2D]()
                    var currentNeighborhood = ""
                    
                    if let properties = hood["properties"] as? [String: AnyObject] {
                        if let neighborhood = properties["neighborhood"] as? String {
                            currentNeighborhood = neighborhood
                        }
                    }
                    
                    // add the coord pairs to the coords array
                    if let geometry = hood["geometry"] as? [String: AnyObject] {
                        if let coordinates = geometry["coordinates"] as? [[[Float]]] {
                            for array in coordinates {
                                for coord in array {
                                    let latitude = CLLocationDegrees(coord[1])
                                    let longitude = CLLocationDegrees(coord[0])
                                    coords.append(CLLocationCoordinate2DMake(latitude, longitude))
                                }
                                
                                // create the polygon renderer from the polygon from the coords array
                                let polygon = MKPolygon(coordinates: &coords, count: coords.count)
                                let polygonRenderer = MKPolygonRenderer(polygon: polygon)
                                
                                // CLLCoordinate2D -> MKMapPoint -> check if CGPoint is inside polygon renderer's CGPath
                                let mapPoint = MKMapPointForCoordinate(currentLocation)
                                let cgPoint = polygonRenderer.pointForMapPoint(mapPoint)
                                
                                if CGPathContainsPoint(polygonRenderer.path, nil, cgPoint, true) {
                                    
                                    // update the name and polygon renderer
                                    lastPolygonRenderer = polygonRenderer
                                    lastHoodName = currentNeighborhood
                                    
                                    print("You are in \(currentNeighborhood).")
                                    return currentNeighborhood
                                } else {
                                    print("You are not in \(currentNeighborhood).")
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("error serializing JSON: \(error)")
        }
        return ""
    }
    
    private func stillInTheHood(currentLocation: CLLocationCoordinate2D) -> Bool {
        
        // if gps is working
        if locationManager.location != nil {
            
            // and you have been to a hood
            if lastPolygonRenderer != nil {
                
                let mapPoint = MKMapPointForCoordinate(currentLocation)
                let cgPoint = lastPolygonRenderer!.pointForMapPoint(mapPoint)
                
                // check if your coords are in the last polygon renderer path
                if CGPathContainsPoint(lastPolygonRenderer!.path, nil, cgPoint, true) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    }
}
