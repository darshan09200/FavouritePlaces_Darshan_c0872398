//
//  Annotation.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit

enum AnnotationType{
	case pin
	case label
}

class Annotation: MKPointAnnotation {
	var type: AnnotationType = .pin
	override var coordinate: CLLocationCoordinate2D{
		willSet{
			title = ""
		}
	}
}
