//
//  Annotation.swift
//  WojtekProject
//
//  Created by Wojciech Kudrynski on 10/11/2021.
//

import MapKit

class Annotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    var title: String?
    var url: URL?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}
