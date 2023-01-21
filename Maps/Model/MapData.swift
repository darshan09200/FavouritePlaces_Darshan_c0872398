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
			history = try context.fetch(request)
		} catch {
			print("Error loading history \(error.localizedDescription)")
		}
	}
	
	func addToHistory(_ item: MKLocalSearchCompletion){
		addToHistory(Pin(title: item.title, subtitle: item.subtitle))
	}
	
	func addToHistory(_ item: Pin){
		let existingRecords = getRecords(title: item.title)
		if let record = existingRecords?.first{
			record.setValue(Date.now, forKey: "searchedOn")
		} else {
			let record = SearchHistory(context: context)
			record.title = item.title
			record.subtitle = item.subtitle
			record.searchedOn = Date.now
		}
		saveHistory()
		loadHistory()
	}
	
	func addToHistory(_ item: SearchHistory){
		let existingRecords = getRecords(title: item.title!)
		if let record = existingRecords?.first{
			record.setValue(Date.now, forKey: "searchedOn")
		}
		saveHistory()
		loadHistory()
	}
	
	func getRecords(title: String) -> [SearchHistory]? {
		let request: NSFetchRequest<SearchHistory> = SearchHistory.fetchRequest()
		let titlePredicate = NSPredicate(format: "title == %@", title)
		request.predicate = titlePredicate
		do {
			let results = try context.fetch( request)
			return results
		} catch {
			print("Error loading notes \(error.localizedDescription)")
			return nil
		}
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
