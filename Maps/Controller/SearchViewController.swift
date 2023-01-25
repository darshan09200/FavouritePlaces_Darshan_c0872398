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
}

extension SearchViewController: UISheetPresentationControllerDelegate{
	func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
		searchViewDelegate?.controllerDidChangeSelectedDetentIdentifier(sheetPresentationController.selectedDetentIdentifier)
	}
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource{
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
//		if MapData.getInstance().history.count > 0 || isFiltering{
//		}
//		return 1
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if isFiltering{
			if section == 1 { return nil}
			return "Search Results"
		}else if section == 0 {
			return "Favourites"
		} else if section == 1 && MapData.getInstance().history.count > 0{
			return "Recent Searches"
		}
		return nil
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var count = 0
		var title = "No recent searches"
		if isFiltering {
			if section == 1 { return 0 }
			count = searchResults.count
			title = "No address available"
		} else {
			if section == 0 {
				return max(MapData.getInstance().favourites.count, 1)
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
		var selectionStyle: UITableViewCell.SelectionStyle = .default
		
		if isFiltering {
			let searchResult = searchResults[indexPath.row]
			title = searchResult.title
			subtitle = searchResult.subtitle
		} else if indexPath.section == 0{
			let data = MapData.getInstance().favourites
			if data.count > 0{
				let favourite = data[indexPath.row]
				title = favourite.title!
				subtitle = favourite.subtitle!
			}else{
				title = "No Favourites to show"
				subtitle = ""
				selectionStyle = .none
			}
		} else {
			let searchResult = MapData.getInstance().history[indexPath.row]
			title = searchResult.title!
			subtitle = searchResult.subtitle!
		}
		
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
		cell.selectionStyle = selectionStyle
		cell.textLabel?.text = title
		cell.detailTextLabel?.text = subtitle
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if !isFiltering{
			if indexPath.section == 0 {
				let data = MapData.getInstance().favourites
				if data.count == 0 {return}
				let favourite = data[indexPath.row]
				MapData.getInstance().addToHistory(favourite)
				
				dropPin(at: Pin(title: favourite.title!, subtitle: favourite.subtitle!, coordinate: CLLocationCoordinate2D(latitude: favourite.latitude, longitude: favourite.longitude)))
				return
			} else {
				let historyItem = MapData.getInstance().history[indexPath.row]
				MapData.getInstance().addToHistory(historyItem)
				dropPin(at: Pin(title: historyItem.title!, subtitle: historyItem.subtitle!, coordinate: CLLocationCoordinate2D(latitude: historyItem.latitude, longitude: historyItem.longitude)))
				return
			}
		}
		let result = searchResults[indexPath.row]
		let searchRequest = MKLocalSearch.Request(completion: result)
		
		let search = MKLocalSearch(request: searchRequest)
		search.start { (response, error) in
			if let mapItem = response?.mapItems.first{
				var record = Pin(title: mapItem.placemark.name ?? "",
								 subtitle: mapItem.placemark.getAddress(),
								 coordinate: mapItem.placemark.coordinate)
				self.dropPin(at: record)
				MapData.getInstance().addToHistory(record)
				
				tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
				
			}
		}
	}
	
	func dropPin(at pin: Pin){
		self.searchViewDelegate?.dropPin(at: pin)
		self.searchBar.text = ""
		self.searchBar(self.searchBar, textDidChange: self.searchBar.text ?? "")
		self.searchBar.resignFirstResponder()
		
	}
	
	func tableView(_ tableView: UITableView,
				   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		if isFiltering || (indexPath.section == 0 && MapData.getInstance().favourites.count == 0){
			return nil
		}
		let item: SearchHistory
		if indexPath.section == 0{
			item = MapData.getInstance().favourites[indexPath.row]
		} else {
			item = MapData.getInstance().history[indexPath.row]
		}
		
		let favourite = UIContextualAction(style: .destructive,
										   title: "Favourite") { (action, view, completionHandler) in
			
			MapData.getInstance().toggleFavourites(item)
			
			tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
			if indexPath.section != 0 {
				tableView.reloadRows(at: [indexPath], with: .automatic)
			}
			
			completionHandler(true)
		}
		favourite.image = UIImage(systemName: item.favourite ? "star.fill" : "star")
		favourite.backgroundColor = .systemYellow
		
		let trash = UIContextualAction(style: .destructive,
									   title: "Trash") { (action, view, completionHandler) in
			if indexPath.section == 0{
				MapData.getInstance().removeFrom(favourites: item)
			} else {
				MapData.getInstance().removeFrom(recents: item)
			}
			
			self.searchViewDelegate?.deleteAnnotation(location: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude))
			if indexPath.section == 0 && MapData.getInstance().favourites.count == 0 {
				tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
			} else {
				tableView.deleteRows(at: [indexPath], with: .automatic)
			}
			completionHandler(true)
		}
		trash.image = UIImage(systemName: "trash")
		trash.backgroundColor = .systemRed
		
		let configuration = UISwipeActionsConfiguration(actions: [trash, favourite])
		
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
	
	func dropPin( at place: Pin)
	
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
