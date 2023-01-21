//
//  Route.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit
import CoreLocation

class MapRoute {
	private(set) var source: CLLocationCoordinate2D
	private(set) var destination: CLLocationCoordinate2D
	private(set) var route: MKRoute
	var formattedSteps: [Step]{
		var steps = [Step]()
		route.steps.forEach{ step in
			if step.distance == 0 {
				steps.append(Step(distance: 0, type: .start, name: sourceInfo.name, address: sourceInfo.getAddress()))
			} else {
				steps.append(Step(instructions: step.instructions, distance: step.distance, type: .direction))
			}
		}
		steps.append(Step(distance: 0, type: .end, name: destinationInfo.name, address: destinationInfo.getAddress()))
		return steps
	}
	var title: String{
		if let last = formattedSteps.last{
			return last.name ?? route.name
		}
		return route.name
	}
	private(set) var sourceInfo: CLPlacemark
	private(set) var destinationInfo: CLPlacemark
	
	init(source: CLLocationCoordinate2D,
		 destination: CLLocationCoordinate2D,
		 route: MKRoute,
		 sourceInfo: CLPlacemark,
		 destinationInfo: CLPlacemark) {
		self.source = source
		self.destination = destination
		self.route = route
		self.sourceInfo = sourceInfo
		self.destinationInfo = destinationInfo
	}
}

extension CLPlacemark {
	
	func getAddress() -> String {
		return [[subThoroughfare, thoroughfare], [locality, administrativeArea, postalCode], [country]]
			.map { (subComponents) -> String in
				subComponents.compactMap({ $0 }).joined(separator: " ")
			}
			.filter({ return !$0.isEmpty && $0 != name })
			.joined(separator: ", ")
	}
}
