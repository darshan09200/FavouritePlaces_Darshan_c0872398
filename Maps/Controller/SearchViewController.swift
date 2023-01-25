//
//  SearchViewController.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit

class SearchViewController: UIViewController {
	
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var searchResultsTable: UITableView!
	
	var searchViewDelegate: SearchViewDelegate?
	
	var searchCompleter = MKLocalSearchCompleter()
	var searchResults = [MKLocalSearchCompletion]()
	
	var favouriteScrollOffset = 0.0
	
	var isFiltering: Bool{
		return searchBar.text?.count ?? 0 > 0
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		searchCompleter.delegate = self
		searchBar.delegate = self
		
		searchBar.backgroundImage = UIImage()
		
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		sheetPresentationController?.delegate = self
		searchViewDelegate?.controllerDidChangeSelectedDetentIdentifier(sheetPresentationController?.selectedDetentIdentifier)
	}
	
	@objc func applicationDidBecomeActive(notification: NSNotification){
		searchViewDelegate?.controllerDidChangeSelectedDetentIdentifier(sheetPresentationController?.selectedDetentIdentifier)
	}
	
	func handleMoveToTrash(_ item: SearchHistory, deleteRecord: Bool = false){
		MapData.getInstance().removeFromRecents(item, deleteRecord: deleteRecord)
		
		searchViewDelegate?.deleteAnnotation(location: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude))
	}
}

extension SearchViewController: UISheetPresentationControllerDelegate{
	func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
		searchViewDelegate?.controllerDidChangeSelectedDetentIdentifier(sheetPresentationController.selectedDetentIdentifier)
	}
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource{
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Favourites"
		} else if section == 1{
			if !isFiltering && MapData.getInstance().history.count > 0{
				return "Recent Searches"
			} else if isFiltering{
				return "Search Results"
			}
		}
		return nil
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var count = 0
		var title = "No recent searches"
		if isFiltering {
			count = searchResults.count
			title = "No address available"
		} else {
			if section == 0 {
				return MapData.getInstance().favourites.count
			}
			count = MapData.getInstance().history.count
		}
		if count == 0 {
			tableView.setEmptyView(title: title)
			return 0
		}
		tableView.restore()
		return count
	}
	
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let title: String
		let subtitle: String
		if indexPath.section == 0{
			let favourite = MapData.getInstance().favourites[indexPath.row]
			title = favourite.title!
			subtitle = favourite.subtitle!
		} else if isFiltering {
			let searchResult = searchResults[indexPath.row]
			title = searchResult.title
			subtitle = searchResult.subtitle
		} else {
			let searchResult = MapData.getInstance().history[indexPath.row]
			title = searchResult.title!
			subtitle = searchResult.subtitle!
		}
		
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
		
		cell.textLabel?.text = title
		cell.detailTextLabel?.text = subtitle
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let searchRequest: MKLocalSearch.Request
		
		var record: Pin?
		if indexPath.section == 0{
			let favourite = MapData.getInstance().favourites[indexPath.row]
			MapData.getInstance().addToHistory(favourite)
			searchRequest = MKLocalSearch.Request()
			searchRequest.naturalLanguageQuery = favourite.title! + " " + favourite.subtitle!
		} else if isFiltering {
			let result = searchResults[indexPath.row]
			record = Pin(title: result.title, subtitle: result.subtitle)
			searchRequest = MKLocalSearch.Request(completion: result)
		} else {
			let record = MapData.getInstance().history[indexPath.row]
			MapData.getInstance().addToHistory(record)
			searchRequest = MKLocalSearch.Request()
			searchRequest.naturalLanguageQuery = record.title! + " " + record.subtitle!
		}
		if indexPath.row > 0{
			tableView.beginUpdates()
			
			tableView.deleteRows(at: [indexPath], with: .automatic)
			tableView.insertRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .automatic)
			
			tableView.endUpdates()
		}
		let search = MKLocalSearch(request: searchRequest)
		search.start { (response, error) in
			if let mapItem = response?.mapItems.first{
				self.searchViewDelegate?.dropPin(at: mapItem)
				self.searchBar.text = ""
				self.searchBar(self.searchBar, textDidChange: self.searchBar.text ?? "")
				self.searchBar.resignFirstResponder()
				if var record = record{
					record.coordinate = mapItem.placemark.coordinate
					MapData.getInstance().addToHistory(record)
				}
			}
		}
	}
	
	func tableView(_ tableView: UITableView,
				   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		if isFiltering {
			return nil
		}
		let trash = UIContextualAction(style: .destructive,
									   title: "Trash") { (action, view, completionHandler) in
			let item: SearchHistory
			if indexPath.section == 0{
				item = MapData.getInstance().favourites[indexPath.row]
			} else {
				item = MapData.getInstance().history[indexPath.row]
			}
			self.handleMoveToTrash(item, deleteRecord: indexPath.section == 0)
			tableView.deleteRows(at: [indexPath], with: .automatic)
			completionHandler(true)
		}
		trash.image = UIImage(systemName: "trash")
		trash.backgroundColor = .systemRed
		
		let configuration = UISwipeActionsConfiguration(actions: [trash])
		
		return configuration
	}
}

extension SearchViewController: UISearchBarDelegate{
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		searchCompleter.queryFragment = searchText
		if searchText.isEmpty {
			searchResults = []
			searchResultsTable.reloadData()
		}
	}
}

extension SearchViewController: MKLocalSearchCompleterDelegate{
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		searchResults = completer.results
		searchResultsTable.reloadData()
	}
	
	
}

protocol SearchViewDelegate {
	func controllerDidChangeSelectedDetentIdentifier(_ selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier?)
	
	func dropPin( at place: MKMapItem)
	
	func deleteAnnotation(location: CLLocationCoordinate2D)
}

extension UITableView {
	func setEmptyView(title: String) {
		let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
		let titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = UIColor.label
		emptyView.addSubview(titleLabel)
		titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
		titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
		titleLabel.text = title
		titleLabel.adjustsFontSizeToFitWidth = true
		titleLabel.textAlignment = .center
		self.backgroundView = emptyView
		self.separatorStyle = .none
	}
	func restore() {
		self.backgroundView = nil
		self.separatorStyle = .singleLine
	}
}
