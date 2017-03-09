//
//  TrayViewCell.swift
//  dash-and-dine-mobile
//
//  Created by Matt Gordon on 3/5/17.
//  Copyright © 2017 Matt Gordon. All rights reserved.
//

import UIKit

class TrayViewCell: UITableViewCell {
    
    @IBOutlet weak var lbQty: UILabel!
    @IBOutlet weak var lbMealName: UILabel!
    @IBOutlet weak var lbSubTotal: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
        lbQty.layer.borderColor = UIColor.gray.cgColor
        lbQty.layer.borderWidth = 1.0
        lbQty.layer.cornerRadius = 10
    }

}
