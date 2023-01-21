//
//  Step.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-21.
//

import MapKit

enum StepType{
	case start
	case end
	case direction
}

class Step {
	var instructions: String?
	var distance: CLLocationDistance
	var type: StepType
	var name: String?
	var address: String?
	
	init(instructions: String? = nil, distance: CLLocationDistance, type: StepType, name: String? = nil, address: String? = nil) {
		self.instructions = instructions
		self.distance = distance
		self.type = type
		self.name = name
		self.address = address
	}
}
