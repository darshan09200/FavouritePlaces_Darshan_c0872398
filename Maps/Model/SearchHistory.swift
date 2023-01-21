//
//  SearchHistory.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//
import MapKit

class SearchHistory {
	static let instance = SearchHistory()
	
	private(set) var history = [MKLocalSearchCompletion]()
	
	private init(){}
	
	static func getInstance()->SearchHistory{
		return instance;
	}
	
	func addToHistory(_ item: MKLocalSearchCompletion){
		if let index = history.firstIndex(of: item){
			history.remove(at: index)
		}
		history.insert(item, at: 0)
	}
	
}
