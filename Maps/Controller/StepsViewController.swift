//
//  StepsTableViewController.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-21.
//

import UIKit

class StepsViewController: UIViewController {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var estimatedTimeLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		reloadData()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		reloadData()
	}
	
	func reloadData(){
		tableView.setContentOffset(.zero, animated: true)

		tableView.reloadData()
		let routes = getRoutes()
		
		var travelTime = 0.0
		var distance = 0.0
		var viaLabel = ""
		for (index, route) in routes.enumerated(){
			travelTime += route.route.expectedTravelTime
			distance += route.route.distance
			if index == routes.endIndex - 1 {
				titleLabel.text = "\(routes.count > 1 ? "Round Trip": "") To \(route.title) \(viaLabel)".trimmingCharacters(in: .whitespacesAndNewlines)
			} else{
				if index == 0{
					viaLabel += "via "
				}else if index > 0 {
					viaLabel += ", "
				}
				if index > 0 && index == routes.endIndex - 2{
					if index == 1{
						let index = viaLabel.index(viaLabel.endIndex, offsetBy: -2)
						viaLabel = String(viaLabel[..<index])
					}
					viaLabel += " and "
				}
				viaLabel += route.title
			}
		}
		
		estimatedTimeLabel.text = travelTime.asTimeString(style: .brief)
		distanceLabel.text = String(format: "%.2f km", distance / 1000)
		
	}
	
	@IBAction func onDonePress() {
		dismiss(animated: true)
	}
	
	func getRoutes() -> [MapRoute]{
		return MapData.getInstance().routes
	}
}
extension StepsViewController: UITableViewDelegate, UITableViewDataSource{
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return getRoutes().count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if getRoutes().count > 1{
			let route = getRoutes()[section].route
			return "Stop \(section+1) - \(route.expectedTravelTime.asTimeString(style: .brief)), \(String(format: "%.2f km", route.distance / 1000))"
		}
		return nil
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return getRoutes()[section].formattedSteps.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "routeSteps", for: indexPath) as! StepsTableViewCell
		
		let step = getRoutes()[indexPath.section].formattedSteps[indexPath.row]
		
		if step.type == .direction{
			let distance = step.distance
			var distanceLabel = "\(String(format:"%.2f", distance)) m"
			if distance > 999 {
				distanceLabel = "\(String(format: "%.2f", distance/100)) km"
			}
			cell.stepImage.image = UIImage()
			cell.titleLabel.text = distanceLabel
			cell.descriptionLabel.text = step.instructions
		} else{
			cell.stepImage.image = UIImage(systemName: "mappin")
			cell.titleLabel.text = step.name
			cell.descriptionLabel.text = step.address
		}
		
		return cell
	}
}

extension Double {
	func asTimeString(style: DateComponentsFormatter.UnitsStyle) -> String {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute]
		if self < 60 {
			formatter.allowedUnits = [.minute, .second]
		}
		formatter.unitsStyle = style
		return formatter.string(from: self) ?? ""
	}
}
