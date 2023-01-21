//
//  StepsTableViewCell.swift
//  Maps
//
//  Created by Darshan Jain on 2023-01-21.
//

import UIKit
import MapKit

class StepsTableViewCell: UITableViewCell {
	
	@IBOutlet weak var stepImage: UIImageView!
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code		
    }

}
