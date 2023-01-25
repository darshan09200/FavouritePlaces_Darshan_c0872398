//
//  SearchHistory.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//
import MapKit
import CoreData

class MapData {
	static let instance = MapData()
	
	private(set) var history = [SearchHistory]()
	private(set) var favourites = [SearchHistory]()
	private(set) var routes = [MapRoute]()
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	private init(){
		loadHistory()
	}
	
	static func getInstance()->MapData{
		return instance;
	}
	
	func loadHistory(){
		let request: NSFetchRequest<SearchHistory> = SearchHistory.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "searchedOn", ascending: false)]
		
		do {
			let data = try context.fetch(request)
			history = data.filter{$0.recents}
			favourites = data.filter{$0.favourite}
		} catch {
			print("Error loading history \(error.localizedDescription)")
		}
	}
	
	func addToHistory(_ item: Pin){
		let existingRecords = getRecords(from: history, title: item.title)
		if let record = existingRecords?.first{
			record.setValue(Date.now, forKey: "searchedOn")
		} else {
			let record = SearchHistory(context: context)
			record.title = item.title
			record.subtitle = item.subtitle
			record.recents = true
			if let coordinate = item.coordinate{
				record.latitude = Double(coordinate.latitude)
				record.longitude = Double(coordinate.longitude)
			}
			record.searchedOn = Date.now
		}
		saveHistory()
		loadHistory()
	}
	
	func addToHistory(_ item: SearchHistory){
		let existingRecords = getRecords(from: history, title: item.title!)
		if let record = existingRecords?.first{
			record.setValue(Date.now, forKey: "searchedOn")
		}
		saveHistory()
		loadHistory()
	}
	
	func getRecords(from data: [SearchHistory], title: String? = nil, coordinate: CLLocationCoordinate2D? = nil) -> [SearchHistory]? {
		return data.filter{
			item in
			var didTitleMatch = true
			if let title = title{
				didTitleMatch = item.title == title
			}
			var didCoordMatch = true
			if let coordinate = coordinate {
				didCoordMatch = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(
					from: CLLocation(latitude: item.latitude, longitude: item.longitude)
				) < 10
			}
			return didTitleMatch && didCoordMatch
		}
	}
	
	func toggleFavourites(_ item: Pin) {
		let existingRecords = getRecords(from: favourites, title: item.title, coordinate: item.coordinate)
		if let record = existingRecords?.first{
			record.setValue(Date.now, forKey: "searchedOn")
			record.setValue(!record.favourite, forKey: "favourite")
			saveHistory()
			loadHistory()
		}
	}
	
	func removeFromRecents(_ item: SearchHistory, deleteRecord: Bool = false) {
		if deleteRecord {
			context.delete(item)
		}else{
			item.setValue(Date.now, forKey: "searchedOn")
			item.setValue(!item.recents, forKey: "recents")
		}
		saveHistory()
		loadHistory()
	}
	
	func saveHistory() {
		do {
			try context.save()
		} catch {
			print("Error saving the history \(error.localizedDescription)")
		}
	}
	
	
	func setRoutes(_ routes: [MapRoute]){
		self.routes = routes
	}
}
