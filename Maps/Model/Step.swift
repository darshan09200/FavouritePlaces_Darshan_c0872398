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

struct Step {
	var instructions: String?
	var distance: CLLocationDistance
	var type: StepType
	var name: String?
	var address: String?
}
