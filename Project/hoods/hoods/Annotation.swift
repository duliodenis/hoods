//
//  Annotation.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit
import Mapbox

class Annotation: NSObject, MGLAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var imageName: String?
    var reuseIdentifier: String?
    
    var image: UIImage?
    
    init(coordinate: CLLocationCoordinate2D, title: String, imageName: String, reuseIdentifier: String) {
        self.coordinate = coordinate
        self.title = title
        self.imageName = imageName
        self.reuseIdentifier = reuseIdentifier
    }
}
