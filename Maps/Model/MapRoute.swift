//
//  Route.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit

class MapRoute {
	private(set) var from: CLLocationCoordinate2D
	private(set) var to: CLLocationCoordinate2D
	private(set) var route: MKRoute
	
	init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, route: MKRoute) {
		self.from = from
		self.to = to
		self.route = route
	}
}
