//
//  GeoAnnotationView.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation
import MapKit

class GeoAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D

    var date: Date?

    // Title and subtitle for use by selection UI.
    var title: String?

    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

class GeoAnnotationView: MKPinAnnotationView {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        canShowCallout = true
        isDraggable = false
        animatesDrop = true
        canShowCallout = true

        if let geoAnnotation = annotation as? GeoAnnotation, let timeStamp = geoAnnotation.date {
            switch timeStamp.timeIntervalSince(Date()) {
                case ..<600: // 0 to 10 minutes
                    pinTintColor = .green
                case 600..<1200: //10 to 20 minutes
                    pinTintColor = .yellow

                default:
                    //old
                    pinTintColor = .black
            }
        } else {
            // no data
            pinTintColor = .red
        }
        let rightButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = rightButton
    }

    deinit {
        print("\(#function)")
    }
}
