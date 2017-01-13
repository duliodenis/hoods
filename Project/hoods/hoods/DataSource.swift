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
import FBSDKLoginKit

enum HoodState {
    case currentHood
    case otherHood
}

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
    var lastVisitedHoodName: String?
    var lastTappedHoodName: String?
    var lastVisitedPolygonRenderer: MKPolygonRenderer?
    var lastPlacemark: CLPlacemark?
    var calloutRepresentedObject: MGLAnnotation?
    var lastVisitedArea: String?
    var lastTappedArea: String?
    var hoodState: HoodState?
    var mapButtonState: MapButtonState?
    var profileState: ProfileState?
    var profileDict = [String:String]()
    var viewSize: CGSize?
    
    func lastVisitedHoodName(_ location: CLLocationCoordinate2D) -> String? {
        
        // if your coords are not in the last hood polygon
        if stillInTheHood(location) == false {
            
            // if last area is a supported area
            if lastVisitedArea != nil {
                
                // if geoJSON file found for last visited area
                if geoJSONFile(for: lastVisitedArea!) != "" {
                    
                    // check through all hood polygons for your coords and update last hood name (last polygon renderer gets updated too)
                    lastVisitedHoodName = fullHoodCheck(location, in: lastVisitedArea!)
                    
                    // if in a supported area, but hood check failed, stop scanning
                    if lastVisitedHoodName == "" {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "NotInAHood"), object: nil)
                    }
                    
                    // else last area is not a supported area
                } else {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "NotInAHood"), object: nil)
                }
            }
        }
        return lastVisitedHoodName
    }
    
    func tappedHoodName(_ location: CLLocationCoordinate2D) -> String? {
        
        if geoJSONFile(for: lastTappedArea!) != "" {
            
            // get file name from location area
            lastTappedHoodName = fullHoodCheck(location, in: lastTappedArea!)
        } else {
            print("You just tapped an unsupported hood.")
        }
        return lastTappedHoodName
    }
    
    fileprivate func fullHoodCheck(_ location: CLLocationCoordinate2D, in area: String) -> String {
        
        var filePath = ""
        
        // set file path to geoJSON for area
        filePath = Bundle.main.path(forResource: geoJSONFile(for: area), ofType: "geojson")!
        
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
                                let mapPoint = MKMapPointForCoordinate(location)
                                let cgPoint = polygonRenderer.point(for: mapPoint)
                                
                                if polygonRenderer.path.contains(cgPoint) {
                                    // update the name and polygon renderer
                                    lastVisitedPolygonRenderer = polygonRenderer
                                    lastVisitedHoodName = currentNeighborhood
                                    
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
            if lastVisitedPolygonRenderer != nil {
                
                let mapPoint = MKMapPointForCoordinate(currentLocation)
                let cgPoint = lastVisitedPolygonRenderer!.point(for: mapPoint)
                
                // check if your coords are in the last polygon renderer path
                if lastVisitedPolygonRenderer!.path.contains(cgPoint) {
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
                DataSource.sharedInstance.lastVisitedArea = locality
                
            // else if it's not SF, set the area to the subLocality
            } else {
                if let subLocality = lastPlacemark!.subLocality {
                    DataSource.sharedInstance.lastVisitedArea = subLocality
                }
            }
        }
    }
    
    fileprivate func geoJSONFile(for area: String) -> String {
        
        // if the user location was found in an area, return appropriate GeoJSON file name
        switch area {
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
    
    func fetchProfile() {
        
        // if logged in
        if FBSDKAccessToken.current() != nil {
                        
            // request these
            let parameters = ["fields": "email, first_name, last_name,  picture.type(large)"]

            FBSDKGraphRequest(graphPath: "me", parameters: parameters).start(completionHandler: { connection, result, error in
                if error != nil {
                    print(error as Any)
                } else {
                    
                    guard let resultNew = result as? [String:Any] else { return }
                    
                    self.profileDict["firstName"] = resultNew["first_name"] as? String
                    self.profileDict["lastName"] = resultNew["last_name"] as? String
                    self.profileDict["email"] = resultNew["email"] as? String
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FetchedProfile"), object: nil)
                }
            })
            
        } else {
            print("The current access token is nil.")
        }
    }
    
    func getDataFromURL(url: URL, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    
    func cropToBounds(_ image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage = UIImage(cgImage: image.cgImage!)
        let contextSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgWidth = CGFloat(width)
        var cgHeight = CGFloat(height)
        
        // see what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = (contextSize.width - contextSize.height) / 2
            posY = 0
            cgWidth = contextSize.height
            cgHeight = contextSize.height
        } else {
            posX = 0
            posY = (contextSize.height - contextSize.width) / 2
            cgWidth = contextSize.width
            cgHeight = contextSize.width
        }
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgWidth, height: cgHeight)
        
        // create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // create a new image based on the imageRef and rotate back to the original orientation
        let image = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
}
