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

enum MapButtonState {
    case hidden
    case hiding
    case shown
}

enum ProfileState {
    case closed
    case open
}

class DataSource {
    static let sharedInstance = DataSource()
    fileprivate init() {}
    
    var locationManager = CLLocationManager()
    var lastHoodName: String?
    var lastPolygonRenderer: MKPolygonRenderer?
    var lastPlacemark: CLPlacemark?
    var calloutRepresentedObjectTitle = ""
    var area: String?
    var mapButtonState: MapButtonState?
    var profileState: ProfileState?
    
    func currentHoodName(_ currentLocation: CLLocationCoordinate2D) -> String? {
        
        // if your coords are not in the last hood polygon
        if stillInTheHood(currentLocation) == false {
            
            // if last area is a supported area
            if geoJSONForArea() != "" {
                
                // check through all hood polygons for your coords and update last hood name (last polygon gets updated too)
                lastHoodName = hoodCheck(currentLocation)
                
                // if in a supported area, but hood check failed, stop scanning
                if lastHoodName == "" {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "NotInAHood"), object: nil)
                }
                
            // else last area is not a supported area
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "NotInAHood"), object: nil)
            }
        }
        return lastHoodName
    }
    
    fileprivate func hoodCheck(_ currentLocation: CLLocationCoordinate2D) -> String {
        
        print("full hood check")
        
        // set file path to geoJSON for current area
        let filePath = Bundle.main.path(forResource: geoJSONForArea(), ofType: "geojson")!
        
        // convert GeoJSON to NSData
        let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:AnyObject]
            
            if let hoods = json?["features"] as? [[String: AnyObject]] {
                
                // iterate through all hoods in the GeoJSON file
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
                                let cgPoint = polygonRenderer.point(for: mapPoint)
                                
                                if polygonRenderer.path.contains(cgPoint) {
                                    // update the name and polygon renderer
                                    lastPolygonRenderer = polygonRenderer
                                    lastHoodName = currentNeighborhood
                                    
                                    print("You are in \(currentNeighborhood).")
                                    return currentNeighborhood
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
    
    fileprivate func stillInTheHood(_ currentLocation: CLLocationCoordinate2D) -> Bool {
        
        // if gps is working
        if locationManager.location != nil {
            
            // and you have been to a hood
            if lastPolygonRenderer != nil {
                
                let mapPoint = MKMapPointForCoordinate(currentLocation)
                let cgPoint = lastPolygonRenderer!.point(for: mapPoint)
                
                // check if your coords are in the last polygon renderer path
                if lastPolygonRenderer!.path.contains(cgPoint) {
                    print("You're still in the hood.")
                    return true
                }
            }
        }
        return false
    }
    
    func updateArea() {
        
        // if the locality is SF, set the area singleton to it
        if let locality = lastPlacemark!.locality {
            if locality == "San Francisco" {
                DataSource.sharedInstance.area = locality
                
            // else if it's not SF, set the area to the subLocality
            } else {
                if let subLocality = lastPlacemark!.subLocality {
                    DataSource.sharedInstance.area = subLocality
                }
            }
        }
    }
    
    fileprivate func geoJSONForArea() -> String {
        
        // if the user location was found in an area, return appropriate GeoJSON file name
        if area != nil {
            switch area! {
            case "Manhattan":
                return "manhattan"
            case "Brooklyn":
                return "nyc"
            case "Queens":
                return "nyc"
            case "Bronx":
                return "nyc"
            case "Staten Island":
                return "nyc"
            case "San Francisco":
                return "sanFrancisco"
            default:
                return ""
            }
        }
        
        // if the user location is not found in any area, return ""
        return ""
    }
}
