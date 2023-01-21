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
	
	func getAddress(of location: CLLocationCoordinate2D,
					completion: @escaping(CLPlacemark?)->()){
		let geocoder = CLGeocoder()
		
		geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude),
										completionHandler: { (placemarks, error) in
			if error == nil {
				let firstLocation = placemarks?.first
				completion(firstLocation)
			}
			else {
				completion(nil)
			}
		})
	}
	
	func getRoute(from source: CLLocationCoordinate2D,
				  to destination: CLLocationCoordinate2D,
				  transportType: MKDirectionsTransportType = [.automobile],
				  completion: @escaping(MapRoute)->()){
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
			var sourceInfo: CLPlacemark?
			var destinationInfo: CLPlacemark?
			
			self.getAddress(of: source){
				placemark in
				sourceInfo = placemark ?? sourcePlaceMark
				checkIfComplete()
			}
			
			self.getAddress(of: destination){
				placemark in
				destinationInfo = placemark ?? destPlaceMark
				checkIfComplete()
			}			
			
			func checkIfComplete(){
				if let sourceInfo = sourceInfo, let destinationInfo = destinationInfo{
					let mapRoute = MapRoute(source: source, destination: destination, route: route, sourceInfo: sourceInfo, destinationInfo: destinationInfo)
					completion(mapRoute)
				}
			}
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
				routes.append(route)
				
				if routes.count == routeCoordinate.count{
					var sortedRoutes = [MapRoute]()
					routeCoordinate.forEach{
						coordinate in
						if let route = routes.first(where: {
							$0.source.latitude == coordinate[0].latitude
							&& $0.source.longitude == coordinate[0].longitude
							&& $0.destination.latitude == coordinate[1].latitude
							&& $0.destination.longitude == coordinate[1].longitude
						}){
							sortedRoutes.append(route)
						}
					}
					completion(sortedRoutes)
				}
			}
		}
	}
}

