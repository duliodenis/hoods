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
    
    var calloutRepresentedObjectTitle = ""
    var currentHoodName: String?
    var currentPolygonRenderer: MKPolygonRenderer?
    
    private func currentHoodFromAllHoods(currentLocation: CLLocationCoordinate2D) -> String {
        
        // point to manualNYC.geojson and use SwiftyJSON
        let filePath = NSBundle.mainBundle().pathForResource("manualNYC", ofType: "geojson")!
        let data = NSData(contentsOfFile: filePath)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            
            if let hoods = json["features"] as? [[String: AnyObject]] {
                for hood in hoods {
                    
                    // set up an empty array that will be each polygon
                    var coords = [CLLocationCoordinate2D]()
                    
                    var currentNeighborhood = ""
                    
                    if let properties = hood["properties"] as? [String: AnyObject] {
                        if let neighborhood = properties["neighborhood"] as? String {
                            currentNeighborhood = neighborhood
                        }
                    }
                    
                    if let geometry = hood["geometry"] as? [String: AnyObject] {
                        if let coordinates = geometry["coordinates"] as? [[[Float]]] {
                            for array in coordinates {
                                for coord in array {
                                    let latitude = CLLocationDegrees(coord[1])
                                    let longitude = CLLocationDegrees(coord[0])
                                    coords.append(CLLocationCoordinate2DMake(latitude, longitude))
                                }
                                
                                let polygon = MKPolygon(coordinates: &coords, count: coords.count)
                                let polygonRenderer = MKPolygonRenderer(polygon: polygon)
                                
                                let mapPoint = MKMapPointForCoordinate(currentLocation)
                                let cgPoint = polygonRenderer.pointForMapPoint(mapPoint)
                                
                                if CGPathContainsPoint(polygonRenderer.path, nil, cgPoint, true) {
                                    
                                    currentPolygonRenderer = polygonRenderer
                                    currentHoodName = currentNeighborhood
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
}
