//
//  MapHelper.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import MapKit


class MapHelper{
	static let instance = MapHelper()
	
	private init(){}
	
	static func getInstance()->MapHelper{
		return instance;
	}
	
	func getRoute(from source: CLLocationCoordinate2D,
				  to destination: CLLocationCoordinate2D,
				  transportType: MKDirectionsTransportType = [.automobile, .walking],
				  completion: @escaping(MKRoute)->()){
		let request = MKDirections.Request()
		// Source
		let sourcePlaceMark = MKPlacemark(coordinate: source)
		request.source = MKMapItem(placemark: sourcePlaceMark)
		// Destination
		let destPlaceMark = MKPlacemark(coordinate: destination)
		request.destination = MKMapItem(placemark: destPlaceMark)
		// Transport Types
		request.transportType = transportType
		
		let directions = MKDirections(request: request)
		directions.calculate { response, error in
			guard let response = response else {
				print("Error: \(error?.localizedDescription ?? "No error specified").")
				return
			}
			
			let route = response.routes[0]
			
			completion(route)
		}
	}
	
	func getBatchRoutes(from coordinates:[CLLocationCoordinate2D],
						transportType: MKDirectionsTransportType = [.automobile, .walking],
						completion: @escaping([MapRoute])->()){
		var routes = [MapRoute]()
		var routeCoordinate = [[CLLocationCoordinate2D]]()
		for (index, coordinate) in coordinates.enumerated(){
			if let lastCoordinate = routeCoordinate.last, lastCoordinate.count < 2{
				routeCoordinate[routeCoordinate.endIndex-1].append(coordinate)
			}
			if index < coordinates.count - 1{
				routeCoordinate.append([coordinate])
			}
		}
		
		if routeCoordinate[routeCoordinate.endIndex-1].count < 2{
			routeCoordinate.remove(at: routeCoordinate.endIndex-1)
		}
		
		routeCoordinate.forEach{
			coordinates in
			getRoute(from: coordinates[0], to: coordinates[1], transportType: transportType){route in
				let mapRoute = MapRoute(from: coordinates[0],
										to: coordinates[1],
										route: route)
				routes.append(mapRoute)
				
				if routes.count == routeCoordinate.count{
					completion(routes)
				}
			}
		}
	}
}

