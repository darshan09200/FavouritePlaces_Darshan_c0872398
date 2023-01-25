//
//  ViewController.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit

enum MapType{
	case layer
	case route
}

class MapViewController: UIViewController {
	
	static let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	
	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var mapConfigStackView: UIStackView!
	
	@IBOutlet weak var zoomStackView: UIStackView!
	@IBOutlet weak var zoomStackBottomConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var showRoutesBtn: UIButton!
	lazy var currentLocationBtn = MKUserTrackingButton(mapView: mapView)
	lazy var compassBtn = MKCompassButton(mapView: mapView)
	
	var locationManager = CLLocationManager()
	
	var currentLocation: CLLocationCoordinate2D?
	
	var annotations = [Annotation]()
	
	let mapPadding = UIEdgeInsets(top: 64, left: 64, bottom: 64, right: 64)
	
	var mapType: MapType = .route
	
	lazy var searchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
	
	lazy var stepsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StepsViewController") as! StepsViewController
	
	var mediumDetentId = UISheetPresentationController.Detent.Identifier("medium")
	lazy var mediumDetent = {
		let mediumDetent = UISheetPresentationController.Detent.custom(identifier: self.mediumDetentId) { context in
			return self.view.bounds.height * 0.25
		}
		
		return mediumDetent
	}
	
	var smallDetentId = UISheetPresentationController.Detent.Identifier("small")
	lazy var smallDetent = {
		let smallDetent = UISheetPresentationController.Detent.custom(identifier: self.smallDetentId) { context in
			return self.view.bounds.height * 0.1
		}
		
		return smallDetent
	}
	
	lazy var detents: [UISheetPresentationController.Detent] = [ smallDetent(), mediumDetent(), .large()]
	
	var shouldDrawOverlay = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		mapView.delegate = self
		locationManager.delegate = self
		searchVC.searchViewDelegate = self
		
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		
		mapView.setCameraZoomRange(MKMapView.CameraZoomRange(minCenterCoordinateDistance: MKMapCameraZoomDefault ,maxCenterCoordinateDistance: MKMapCameraZoomDefault), animated: true)
		
		currentLocationBtn.backgroundColor = .white
		currentLocationBtn.heightAnchor.constraint(equalTo: currentLocationBtn.widthAnchor, multiplier: 1).isActive = true
		currentLocationBtn.layer.cornerRadius = 4
		mapConfigStackView.addArrangedSubview(currentLocationBtn)
		
		mapView.showsCompass = false
		compassBtn.compassVisibility = .adaptive
		compassBtn.heightAnchor.constraint(equalTo: compassBtn.widthAnchor, multiplier: 1).isActive = true
		mapConfigStackView.addArrangedSubview(compassBtn)
		currentLocationBtn.widthAnchor.constraint(equalToConstant: compassBtn.frame.width).isActive = true
		
		let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(onMapLongTap(_ :)))
		mapView.addGestureRecognizer(longTapGesture)
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		openBottomSheet()
	}
	
	func dropPin(at location: CLLocationCoordinate2D,
						 title: String,
				 subtitle: String? = nil,
				 secondarySubtitle: String? = nil) {
		print(location)
		
		let annotationToAdd = Annotation()
		annotationToAdd.coordinate = location
		annotationToAdd.title = title
		annotationToAdd.subtitle = subtitle
		annotationToAdd.secondarySubtitle = secondarySubtitle
		if let index = annotations.firstIndex(where: {
			CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(
				from: CLLocation(latitude: location.latitude, longitude: location.longitude)
			) < 100
		}){
			mapView.removeAnnotation(annotations[index])
			annotations.remove(at: index)
		}
		mapView.addAnnotation(annotationToAdd)
		
		annotations.append(annotationToAdd)
		
		let camera = mapView.camera.copy() as! MKMapCamera
		camera.centerCoordinate = location
		camera.centerCoordinateDistance = 5000
		
		mapView.setCamera(camera, animated: true)
		
		redrawOverlay()
	}
	
	func generateAnnotationTitle(for index: Int? = nil) -> String{
		var position = annotations.filter({$0.type == .pin}).count
		if let index = index{
			position = index
		}
		return "Location \(String(MapViewController.characters[position]))"
	}
	
	@objc func onMapLongTap(_ sender: UILongPressGestureRecognizer){
		if sender.state == .ended {
			if mapView.selectedAnnotations.count == 0{
				let point = sender.location(in: mapView)
				let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
				
				addAnnotation(at: coordinate)
			}
		}
	}
	
	
	@IBAction func onMapConfigPress(_ sender: Any) {
		let alert = UIAlertController()
		
		alert.addAction(UIAlertAction(title: "Explore", style: .default , handler:{ (UIAlertAction)in
			self.mapView.mapType = .standard
		}))
		
		alert.addAction(UIAlertAction(title: "Satellite", style: .default , handler:{ (UIAlertAction)in
			self.mapView.mapType = .satelliteFlyover
		}))
		
		alert.addAction(UIAlertAction(title: "\(shouldDrawOverlay ? "Disable": "Enable") Draw", style: .default , handler:{ (UIAlertAction)in
			self.shouldDrawOverlay = !self.shouldDrawOverlay
			
			self.redrawOverlay()
		}))
		
		alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
		
		searchVC.present(alert, animated: true)
	}
	
	@IBAction func onDimensionClick(_ sender: UIButton) {
		let camera = self.mapView.camera
		let mapCamera = MKMapCamera()
		mapCamera.centerCoordinate = camera.centerCoordinate
		mapCamera.centerCoordinateDistance = camera.centerCoordinateDistance
		if camera.pitch > 0 {
			sender.setImage(UIImage(systemName: "view.3d"), for: .normal)
			mapCamera.pitch = 0
		} else {
			sender.setImage(UIImage(systemName: "view.2d"), for: .normal)
			mapCamera.pitch = 70
		}
		self.mapView.setCamera(mapCamera, animated: true)
	}
	
	@IBAction func onZoomInPress() {
		zoomMap(byFactor: 0.25)
	}
	
	@IBAction func onZoomOutPress() {
		zoomMap(byFactor: 4)
	}
	
	@IBAction func onLayerRoutePress(_ sender: UIButton) {
		if mapType == .layer{
			mapType = .route
			sender.setImage(UIImage(systemName: "triangle"), for: .normal)
		} else {
			mapType = .layer
			sender.setImage(UIImage(systemName: "car"), for: .normal)
		}
		
		annotations.forEach{
			annotation in
			if annotation.type == .pin {
				self.mapView.removeAnnotation(annotation)
				self.mapView.addAnnotation(annotation)
			} else if mapType == .route {
				removeAnnotation(annotation)
			}
		}
		
		redrawOverlay()
	}
	
	@IBAction func onShowRoutePress() {
		redrawOverlay()
		
		if searchVC.presentedViewController != nil{
			stepsVC.reloadData()
			if let sheet = stepsVC.sheetPresentationController {
				sheet.animateChanges {
					sheet.selectedDetentIdentifier = .large
				}
			}
		} else {
			if let sheet = stepsVC.sheetPresentationController {
				sheet.prefersGrabberVisible = true
				sheet.prefersEdgeAttachedInCompactHeight = true
				var detents = Array(detents)
				detents.remove(at: 0)
				sheet.detents = detents
				sheet.selectedDetentIdentifier = .large
				sheet.largestUndimmedDetentIdentifier = mediumDetentId
			}
			searchVC.present(stepsVC, animated: true)
		}
	}
	
}

extension MapViewController {
	func addAnnotation(at coordinate: CLLocationCoordinate2D){
		print(coordinate)
		MapHelper.getInstance().getAddress(of: coordinate){ placemark in
			let title = placemark?.name ?? self.generateAnnotationTitle()
			self.dropPin(at: placemark?.location?.coordinate ?? coordinate, title: title, secondarySubtitle: placemark?.getAddress() ?? "")
			
			MapData.getInstance().addToHistory(Pin(title: title, subtitle: placemark?.getAddress() ?? "", coordinate: placemark?.location?.coordinate ?? coordinate))
			self.searchVC.searchResultsTable.reloadData()
		}
	}
	
	func redrawOverlay(){
		removeOverlay("polygon")
		removeOverlay("route")
		removeAllDistanceLabel()
		
		var points = [MKMapPoint]()
		
		self.annotations.forEach{ annotation in
			if annotation.type == .pin {
				points.append(MKMapPoint(annotation.coordinate))
			}
		}
		var coordinates = annotations.map { $0.coordinate }
		if coordinates.count < 2 {
			self.showRoutesBtn.isHidden = true
			MapData.getInstance().setRoutes([])
			if self.searchVC.presentedViewController != nil{
				self.stepsVC.onDonePress()
			}
			return
		}
		if shouldDrawOverlay {
			if coordinates.count > 2 {
				coordinates.append(coordinates.first!)
			}
			
			if mapType == .layer{
				showRoutesBtn.isHidden = true
				if coordinates.count > 2 {
					let polygon = MKPolygon(points: &points, count: points.count)
					polygon.title = "polygon"
					mapView.addOverlay(polygon)
					mapView.setVisibleMapRect(polygon.boundingMapRect, edgePadding: mapPadding, animated: true)
					MapHelper.getInstance().getBatchRoutes(from: coordinates){mapRoutes in
						mapRoutes.forEach{
							mapRoute in
							let route = mapRoute.route
							let centerLat = (mapRoute.source.latitude + mapRoute.destination.latitude) / 2
							let centerLong = (mapRoute.source.longitude + mapRoute.destination.longitude) / 2
							self.addDistanceLabel(for: route, at: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong))
							
						}
					}
				}
			} else {
				MapHelper.getInstance().getBatchRoutes(from: coordinates){mapRoutes in
					mapRoutes.forEach{
						mapRoute in
						let route = mapRoute.route
						
						route.polyline.title = "route"
						self.mapView.addOverlay(route.polyline)
						self.addDistanceLabel(for: route)
					}
					
					MapData.getInstance().setRoutes(mapRoutes)
					self.mapView.setVisibleMapRect(mapRoutes.last!.route.polyline.boundingMapRect,
												   edgePadding: self.mapPadding, animated: true)
					if mapRoutes.count > 0 {
						self.showRoutesBtn.isHidden = false
					}
					if self.searchVC.presentedViewController != nil{
						if mapRoutes.count > 0{
							self.stepsVC.reloadData()
						}else{
							self.stepsVC.onDonePress()
						}
					}
				}
			}
		}
	}
	
	func removeOverlay(_ title: String){
		mapView.overlays.forEach {overlay in
			if overlay.title == title{
				mapView.removeOverlay(overlay)
			}
		}
	}
	
	func removeAnnotation(_ annotation: Annotation){
		self.mapView.removeAnnotation(annotation)
		if let index = annotations.firstIndex(of: annotation){
			annotations.remove(at: index)
		}
	}
	
	func addDistanceLabel(for route: MKRoute, at coordinate: CLLocationCoordinate2D? = nil){
		let distanceLabel = Annotation()
		distanceLabel.type = .label
		if let coordinate = coordinate{
			distanceLabel.coordinate = coordinate
		}else{
			distanceLabel.coordinate = route.polyline.points()[route.polyline.pointCount/2].coordinate
		}
		let distance = String(format: "%.2f", route.distance / 1000)
		distanceLabel.title = "\(distance) km"
		self.mapView.addAnnotation(distanceLabel)
		self.annotations.append(distanceLabel)
	}
	
	func removeAllDistanceLabel(){
		self.annotations.forEach{ annotation in
			if annotation.type == .label {
				removeAnnotation(annotation)
			}
		}
	}
}

extension MapViewController: MKMapViewDelegate{
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let overlay = overlay as? MKPolygon{
			let renderer = MKPolygonRenderer(overlay: overlay)
			renderer.strokeColor = .green
			renderer.fillColor = .red.withAlphaComponent(0.5)
			renderer.lineWidth = 1
			return renderer
		} else if let overlay = overlay as? MKPolyline{
			let renderer = MKPolylineRenderer(overlay: overlay)
			renderer.strokeColor = UIColor(named: "AccentColor")
			return renderer
		} else{
			return MKOverlayRenderer()
		}
		
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		if let annotation = annotation as? Annotation {
			if annotation.type == .label{
				var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Label")
				if annotationView == nil{
					annotationView =  LabelAnnotationView(annotation: annotation, reuseIdentifier: "Label")
				} else{
					annotationView?.annotation = annotation
				}
				return annotationView
			}
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKMarkerAnnotationView
			
			if annotationView == nil {
				annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
			} else {
				annotationView?.annotation = annotation
			}
			
			annotationView?.displayPriority = .defaultHigh
			annotationView!.isDraggable = true
			if annotation.subtitle != nil{
				annotationView!.titleVisibility = .visible
				annotationView!.subtitleVisibility = .visible
			}
			annotationView!.canShowCallout = true
			
			let additionalBtn = AnnotationButton(type: .custom)
			additionalBtn.annotation = annotation
			additionalBtn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
			additionalBtn.addTarget(self, action: #selector(onExtraPress), for: .touchUpInside)
			
			additionalBtn.sizeToFit()
			
			annotationView!.rightCalloutAccessoryView = additionalBtn
			
			return annotationView
		}
		return nil
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
		if newState == .starting{
			removeAllDistanceLabel()
			removeOverlay("polygon")
			removeOverlay("route")
			mapView.deselectAnnotation(view.annotation!, animated: true)
		}
		view.setDragState(newState, animated: true)
		if newState == .ending, let annotation = view.annotation as? Annotation{
			let coordinate = annotation.coordinate
			addAnnotation(at: coordinate)
		}
	}
	
	func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
		if mapType == .route, let annotation = annotation as? Annotation, annotation.type == .pin {
			removeAnnotation(annotation)
			redrawOverlay()
		}
	}
	
	func zoomMap(byFactor delta: Double) {
		let camera = mapView.camera.copy() as! MKMapCamera
		camera.centerCoordinateDistance *= delta
		mapView.setCamera(camera, animated: true)
	}
	
	@objc func onExtraPress(sender: AnnotationButton){
		if let annotation = sender.annotation{
			let data = MapData.getInstance().getRecords(from: MapData.getInstance().favourites, title: annotation.title, coordinate: annotation.coordinate)
			var title = "Add to Favourite"
			var imageName = "star"
			if let item = data?.first, item.favourite {
				title = "Remove from Favourite"
				imageName = "star.fill"
			}
			
			let favouriteAction = UIAlertAction(title: title, style: .default){
				_ in self.onFavouritePress(annotation)
			}
			
			favouriteAction.setValue(UIImage(systemName: imageName), forKey: "image")
			
			let infoAction = UIAlertAction(title: "Info", style: .default){
				_ in self.onInfoPress(annotation)
			}
			infoAction.setValue(UIImage(systemName: "info.circle"), forKey: "image")
			
			let deleteAction = UIAlertAction(title: "Delete", style: .destructive){
				_ in self.onDeletePress(annotation)
			}
			deleteAction.setValue(UIImage(systemName: "trash"), forKey: "image")
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
			
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			alert.addAction(favouriteAction)
			alert.addAction(infoAction)
			alert.addAction(deleteAction)
			alert.addAction(cancelAction)
			
			searchVC.present(alert, animated: true)
			
		}
	}
	
	func onInfoPress(_ annotation: Annotation){
		if let userLocation = currentLocation {
			MapHelper.getInstance().getRoute(from: userLocation, to: annotation.coordinate){
				mapRoute in
				let distance = String(format: "%.2f", mapRoute.route.distance / 1000)
				let ac = UIAlertController(
					title: "Location: \(annotation.title! )",
					message: "Distance from your current location is \(distance) kms",
					preferredStyle: .alert
				)
				ac.addAction(UIAlertAction(title: "OK", style: .default))
				self.searchVC.present(ac, animated: true)
			}
			return
			
		}

		let ac = UIAlertController(
			title: "Warning",
			message: "User Location not found",
			preferredStyle: .alert
		)
		ac.addAction(UIAlertAction(title: "OK", style: .default))
		self.searchVC.present(ac, animated: true)
	}
	
	func onFavouritePress(_ annotation: Annotation){
		MapData.getInstance().toggleFavourites(Pin(title: annotation.title!,
												  subtitle: annotation.secondarySubtitle!,
												  coordinate: annotation.coordinate))
		
		self.searchVC.searchResultsTable.reloadData()
	}
	
	func onDeletePress(_ annotation: Annotation){
		removeAnnotation(annotation)
	}
	
}

extension MapViewController: CLLocationManagerDelegate{
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let userLocation = locations.first{
			if currentLocation == nil {
				let camera = mapView.camera.copy() as! MKMapCamera
				camera.centerCoordinateDistance = 5000
				camera.centerCoordinate = userLocation.coordinate
				mapView.setCamera(camera, animated: true)
			}
			currentLocation = userLocation.coordinate
		}
	}
	
}

extension MapViewController: SearchViewDelegate{
	
	
	func openBottomSheet(){
		if let sheet = searchVC.sheetPresentationController {
			sheet.prefersGrabberVisible = true
			sheet.prefersEdgeAttachedInCompactHeight = true
			sheet.detents = detents
			sheet.selectedDetentIdentifier = mediumDetentId
			sheet.largestUndimmedDetentIdentifier = mediumDetentId
		}
		
		searchVC.isModalInPresentation = true
		self.present(searchVC, animated: true)
	}
	
	
	func controllerDidChangeSelectedDetentIdentifier(_ selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier?) {
		if let identifier = selectedDetentIdentifier{
			if identifier == smallDetentId {
				self.zoomStackBottomConstraint.constant = self.view.bounds.height * 0.1 + 16
				
			} else if identifier == mediumDetentId {
				self.zoomStackBottomConstraint.constant = self.view.bounds.height * 0.25 + 16
				
			}
			UIView.animate(withDuration: 0.5){
				self.view.layoutIfNeeded()
			}
		}
	}
	
	func dropPin(at pin: Pin) {
		
		searchVC.sheetPresentationController?.animateChanges {
			searchVC.sheetPresentationController?.selectedDetentIdentifier = mediumDetentId
			controllerDidChangeSelectedDetentIdentifier(mediumDetentId)
		}
		dropPin(
			at: pin.coordinate!,
			title: pin.title,
			secondarySubtitle: pin.subtitle
		)
	}
	
	func deleteAnnotation(location: CLLocationCoordinate2D){
		if let index = annotations.firstIndex(where: {
			$0.coordinate.latitude ==  location.latitude && $0.coordinate.longitude == location.longitude
		}){
			mapView.removeAnnotation(annotations[index])
			annotations.remove(at: index)
		}
	}
	
}
