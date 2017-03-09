//
//  DriverOrder.swift
//  dash-and-dine-mobile
//
//  Created by Matt Gordon on 3/6/17.
//  Copyright © 2017 Matt Gordon. All rights reserved.
//

import Foundation
import SwiftyJSON

class DriverOrder {

    var id: Int?
    var customerName: String?
    var customerAddress: String?
    var customerAvatar: String?
    var restaurantName: String?
    
    init(json: JSON) {
        
        self.id = json["id"].int
        self.customerName = json["customer"]["name"].string
        self.customerAddress = json["customer"]["address"].string
        self.customerAvatar = json["customer"]["avatar"].string
        self.restaurantName = json["restaurant"]["name"].string
    }
}
