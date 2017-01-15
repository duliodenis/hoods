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
    case visiting
    case tapping
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

enum GeoError: Error {
    case areaError
    case hoodError
}

class DataSource {
    static let sharedInstance = DataSource()
    fileprivate init() {}
    
    var hoodState: HoodState?
    var mapButtonState: MapButtonState?
    var profileState: ProfileState?

    var locationManager = CLLocationManager()
    
    var visitingHoodName: String?
    var visitingArea: String?
    var visitingPlacemark: CLPlacemark?
    var visitingPolygonRenderer: MKPolygonRenderer?
    var visitingHoodCoords = [CLLocationCoordinate2D]()

    var tappedHoodName: String?
    var tappedArea: String?
    var tappedPlacemark: CLPlacemark?

    var calloutRepresentedObject: MGLAnnotation?
    var fbProfileDict = [String:String]()
    var viewSize: CGSize?
    
    func updateVisitingArea(with placemark: CLPlacemark) {
        
        // if locality is SF, set the area singleton to locality...
        if let locality = placemark.locality {
            if locality == "San Francisco" {
                visitingArea = locality
                
                // else it's not SF, set the area to subLocality
            } else {
                if let subLocality = placemark.subLocality {
                    visitingArea = subLocality
                }
            }
        }
    }
    
    func updateTappedArea(with placemark: CLPlacemark) {
        
        // if locality is SF, set the area singleton to locality...
        if let locality = tappedPlacemark!.locality {
            if locality == "San Francisco" {
                tappedArea = locality
                
                // else it's not SF, set the area to subLocality
            } else {
                if let subLocality = tappedPlacemark!.subLocality {
                    tappedArea = subLocality
                }
            }
        }
    }
    
    func visitingHoodName(for location: CLLocationCoordinate2D) -> String? {
        if visitingArea != nil {
            
            // if coord not found in last hood polygon...
            if !stillInTheHood(location) {
                
                // if found in hood...
                if let hood = hoodName(for: location, in: visitingArea!, fromTap: false) {
                    
                    // update singleton
                    visitingHoodName = hood
                    return hood
                    
                    // else stop scanning
                } else {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "StopScanning"), object: nil)
                }
            }
        }
        return nil
    }
    
    func tappedHoodName(for coord: CLLocationCoordinate2D) throws -> String? {
        
        // if this is the first map tap...
        if tappedArea == nil && visitingArea != nil {
            
            // if hood check from visiting area succeeded...
            if let hoodFromVisitingArea = hoodName(for: coord, in: visitingArea!, fromTap: true) {
                
                // update singletons
                tappedArea = visitingArea!
                tappedHoodName = hoodFromVisitingArea
                return hoodFromVisitingArea
                
                // else not found in hood, scan tapped area
            } else {
                throw GeoError.areaError
            }
            
            // else scan tapped area
        } else {
            if let hoodFromTappedArea = hoodName(for: coord, in: tappedArea!, fromTap: true) {
                return hoodFromTappedArea
            }
        }
        return nil
    }
    
    fileprivate func hoodName(for location: CLLocationCoordinate2D, in area: String, fromTap: Bool) -> String? {
        var filePath = ""
        
        // set file path to geoJSON for area
        filePath = Bundle.main.path(forResource: geoJSONFile(for: area), ofType: "geojson")!
        print("filepath: \(filePath)")
        
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
                        if let neighborhood = properties["name"] as? String {
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
                                
                                // CLLCoordinate2D -> MKMapPoint -> CGPoint
                                let mapPoint = MKMapPointForCoordinate(location)
                                let cgPoint = polygonRenderer.point(for: mapPoint)
                                
                                // check if inside polygon renderer's path
                                if polygonRenderer.path.contains(cgPoint) {
                                    
                                    if !fromTap {
                                        visitingPolygonRenderer = polygonRenderer
                                        visitingHoodCoords = coords
                                        print("You are in \(currentNeighborhood).")
                                    } else {
                                        print("You just tapped \(currentNeighborhood).")
                                    }
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
        return nil
    }
    
    func stillInTheHood(_ currentLocation: CLLocationCoordinate2D) -> Bool {
        
        // if location available...
        if locationManager.location != nil {
            
            // and you have been to a hood...
            if visitingPolygonRenderer != nil {
                
                let mapPoint = MKMapPointForCoordinate(currentLocation)
                let cgPoint = visitingPolygonRenderer!.point(for: mapPoint)
                
                // check if your coords are in the last polygon renderer path
                if visitingPolygonRenderer!.path.contains(cgPoint) {
                    print("You're still in the hood.")
                    return true
                }
            }
        }
        return false
    }
    
    fileprivate func geoJSONFile(for area: String) -> String {
        
        // if the user location was found in an area, return appropriate GeoJSON file name
        switch area {
        case "Manhattan":
            return "manhattan"
        case "Brooklyn":
            return "nyc"
        case "Queens":
            return "queens"
        case "Bronx":
            return "nyc"
        case "Staten Island":
            return "statenIsland"
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
                    print("fb error: \(error as Any)")
                } else {
                    
                    guard let resultNew = result as? [String:Any] else { return }
                    
                    self.fbProfileDict["firstName"] = resultNew["first_name"] as? String
                    self.fbProfileDict["lastName"] = resultNew["last_name"] as? String
                    self.fbProfileDict["email"] = resultNew["email"] as? String
                    
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
    
    func centroid(from coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        
        // get the lowest and highest longitude and latitude
        var x1Long = coords.first?.longitude
        var x2Long = coords.first?.longitude
        var y1Lat = coords.first?.latitude
        var y2Lat = coords.first?.latitude
        for coord in coords {
            if coord.longitude < 0 {
                if coord.longitude > x1Long! {
                    x1Long = coord.longitude
                } else {
                    x2Long = coord.longitude
                }
            } else {
                if coord.longitude < x1Long! {
                    x1Long = coord.longitude
                } else {
                    x2Long = coord.longitude
                }
            }
            if coord.latitude < 0 {
                if coord.latitude > y1Lat! {
                    y1Lat = coord.latitude
                } else {
                    y2Lat = coord.latitude
                }
            } else {
                if coord.latitude < y1Lat! {
                    y1Lat = coord.latitude
                } else {
                    y2Lat = coord.latitude
                }
            }
        }
        return CLLocationCoordinate2D(latitude: y1Lat! + ((y2Lat! - y1Lat!) / 2), longitude: x1Long! + ((x2Long! - x1Long!) / 2))
    }
}
