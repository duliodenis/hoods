//
//  DataSource.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit
import Mapbox

class DataSource {
    static let sharedInstance = DataSource()
    private init() {}
    
    var calloutRepresentedObjectTitle = ""
}
