//
//  forecastModel.swift
//  Weather365
//
//  Created by xinrui wang on 3/24/20.
//  Copyright © 2020 xinrui wang. All rights reserved.
//

import Foundation
import RealmSwift

class ForecastModel : Object{
    @objc dynamic var Date: String = ""
    @objc dynamic var minTemperature: String = ""
    @objc dynamic var maxTemperature: String = ""
    @objc dynamic var DayPrecipitationType: String = ""
    @objc dynamic var DayPrecipitationIntensity: String = ""
    @objc dynamic var NightPrecipitationType: String = ""
    @objc dynamic var NightPrecipitationInstensity:String = ""
    
    override static func primaryKey() -> String? {
        return "Date"
    }
}
