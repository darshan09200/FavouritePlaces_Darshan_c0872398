//
//  LabelAnnotation.swift
//  MapDemo
//
//  Created by Darshan Jain on 2023-01-20.
//

import UIKit
import MapKit

class LabelAnnotationView: MKAnnotationView {

	override var annotation: MKAnnotation?{
		didSet{
			let label = UILabel()
			label.numberOfLines = 0
			label.text = annotation?.title ?? ""
			label.sizeToFit()
			
			let labelView = UIView(frame: CGRect(x: 0,
												 y: 0,
												 width: label.intrinsicContentSize.width + 16,
												 height: label.intrinsicContentSize.height + 16))
			labelView.addSubview(label)
			label.center = labelView.center
			label.textAlignment = .center
			
			labelView.backgroundColor = .systemBlue
			
			let image = labelView.asImage()
			self.image = image
		}
	}
	
	override var image: UIImage?{
		didSet{
			self.centerOffset = CGPoint(x: 0, y: -image!.size.height - 4)
		}
	}

}

extension UIView {
	
	func asImage() -> UIImage {
		let renderer = UIGraphicsImageRenderer(bounds: bounds)
		return renderer.image { rendererContext in
			layer.render(in: rendererContext.cgContext)
		}
	}
}
