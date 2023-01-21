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
	
	var mapType: MapType = .layer
	
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
						 subtitle: String? = nil) {
		let annotationToAdd = Annotation()
		annotationToAdd.title = title
		annotationToAdd.subtitle = subtitle
		annotationToAdd.coordinate = location
		
		if let index = annotations.firstIndex(where: {
			$0.coordinate.latitude == annotationToAdd.coordinate.latitude
			&& $0.coordinate.longitude == annotationToAdd.coordinate.longitude
		}){
			annotations.remove(at: index)
			mapView.removeAnnotation(annotationToAdd)
		}
		mapView.addAnnotation(annotationToAdd)
		
		annotations.append(annotationToAdd)
		
		let camera = mapView.camera.copy() as! MKMapCamera
		camera.centerCoordinate = location
		camera.centerCoordinateDistance = 5000
		
		mapView.setCamera(camera, animated: true)
		
		onAnnotationsUpdated()
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
			let point = sender.location(in: mapView)
			let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
			
			MapHelper.getInstance().getAddress(of: coordinate){ placemark in
				self.dropPin(at: coordinate, title: placemark?.name ?? self.generateAnnotationTitle())
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
		
		onAnnotationsUpdated()
	}
	
	@IBAction func onShowRoutePress() {
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

extension MapViewController{
	
	func onAnnotationsUpdated(){
		removeOverlay("overlay")
		removeOverlay("route")
		
		var points = [MKMapPoint]()
		
		self.annotations.forEach{ annotation in
			if annotation.type == .pin {
				points.append(MKMapPoint(annotation.coordinate))
			} else {
				removeAnnotation(annotation)
			}
		}
		var coordinates = annotations.map { $0.coordinate }
		if coordinates.count < 2 {
			self.showRoutesBtn.isHidden = true
			MapData.getInstance().setRoutes([])
			return
		}
		if coordinates.count > 2 {
			coordinates.append(coordinates.first!)
		}
		
		if mapType == .layer{
			showRoutesBtn.isHidden = true
			if points.count == 3 {
				let polygon = MKPolygon(points: &points, count: points.count)
				polygon.title = "overlay"
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
			} else if points.count > 3 {
				let lastAdded = annotations.last(where: {$0.type == .pin}) ?? Annotation()
				annotations.forEach{ annotation in
					self.mapView.removeAnnotation(annotation)
					if annotation == lastAdded {
						annotation.title = generateAnnotationTitle(for: 0)
						self.mapView.addAnnotation(annotation)
						self.annotations = [annotation]
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
				if mapRoutes.count > 0 {
					self.showRoutesBtn.isHidden = false
				}
				self.mapView.setVisibleMapRect(mapRoutes.last!.route.polyline.boundingMapRect,
											   edgePadding: self.mapPadding, animated: true)
				if self.searchVC.presentedViewController != nil{
					self.stepsVC.reloadData()
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
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
			
			if annotationView == nil {
				annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
			} else {
				annotationView?.annotation = annotation
			}
			if mapType == .layer{
				annotationView!.canShowCallout = true
				let btn = UIButton(type: .detailDisclosure)
				annotationView!.rightCalloutAccessoryView = btn
			} else {
				annotationView!.canShowCallout = false
				annotationView!.rightCalloutAccessoryView = nil
			}
			return annotationView
		}
		return nil
	}
	
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if let userLocation = currentLocation {
			if let annotation = view.annotation{
				MapHelper.getInstance().getRoute(from: userLocation, to: annotation.coordinate){
					mapRoute in
					let distance = String(format: "%.2f", mapRoute.route.distance / 1000)
					let ac = UIAlertController(
						title: "Location: \(annotation.title! ?? "")",
						message: "Distance from your current location is \(distance) kms",
						preferredStyle: .alert
					)
					ac.addAction(UIAlertAction(title: "OK", style: .default))
					self.searchVC.present(ac, animated: true)
				}
				return
			}
		}
	
		let ac = UIAlertController(
			title: "Warning",
			message: "User Location not found",
			preferredStyle: .alert
		)
		ac.addAction(UIAlertAction(title: "OK", style: .default))
		self.searchVC.present(ac, animated: true)
	}
	
	func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
		if mapType == .route, let annotation = annotation as? Annotation, annotation.type == .pin {
			removeAnnotation(annotation)
			onAnnotationsUpdated()
		}
	}
	
	func zoomMap(byFactor delta: Double) {
		let camera = mapView.camera.copy() as! MKMapCamera
		camera.centerCoordinateDistance *= delta
		mapView.setCamera(camera, animated: true)
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
	
	func dropPin(at place: MKMapItem) {
		
		let placemark = place.placemark
		
		dropPin(
			at: placemark.coordinate,
			title: placemark.name ?? generateAnnotationTitle()
		)
	}
	
}
