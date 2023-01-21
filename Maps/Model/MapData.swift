//
//  SearchHistory.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//
import MapKit

class MapData {
	static let instance = MapData()
	
	private(set) var history = [MKLocalSearchCompletion]()
	private(set) var routes = [MapRoute]()
	
	private init(){}
	
	static func getInstance()->MapData{
		return instance;
	}
	
	func addToHistory(_ item: MKLocalSearchCompletion){
		if let index = history.firstIndex(of: item){
			history.remove(at: index)
		}
		history.insert(item, at: 0)
	}
	
	
	func setRoutes(_ routes: [MapRoute]){
		self.routes = routes
	}
}
