//
//  ViewController.swift
//  Weather365
//
//  Created by xinrui wang on 3/10/20.
//  Copyright © 2020 xinrui wang. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftSpinner
import SwiftyJSON
import PromiseKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var lblCityName: UILabel!
    
    @IBOutlet weak var lblCurrentCondition: UILabel!
    
    @IBOutlet weak var lblTemperature: UILabel!
    
    
    let locationManager = CLLocationManager()
    let apiKey = "bGnXMys87L5QHJhvgjwbRTXikjQAXf1H"
    let locationURL = "https://dataservice.accuweather.com/locations/v1/cities/geoposition/search"
    let conditionURL = "https://dataservice.accuweather.com/currentconditions/v1/"
    //http://dataservice.accuweather.com/currentconditions/v1/
    //api key :bGnXMys87L5QHJhvgjwbRTXikjQAXf1H
    //location key: 2628276
    //http://dataservice.accuweather.com/currentconditions/v1/2628276?apikey=bGnXMys87L5QHJhvgjwbRTXikjQAXf1H
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate=self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func getLoationURL(_ latLgn: String) -> String{
        return "\(locationURL)?q=\(latLgn)&apikey=\(apiKey)"
    }
    
    func getConditionURL(_ key:String) -> String{
        return "\(conditionURL)\(key)?apikey=\(apiKey)"
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currLocation = locations.last {
            let lat = currLocation.coordinate.latitude
            let lng = currLocation.coordinate.longitude
            let currLocationURL = getLoationURL("\(lat),\(lng)")
            
            getCurrentLocationKey(for: currLocationURL)
            .done{ (locKey,city) in
                
                self.lblCityName.text = city
                
                let currConditionURL = self.getConditionURL(locKey)
                
                self.getCurrentConditions(for: currConditionURL)
                .done{ (temp,condition) in
                    self.lblTemperature.text="\(temp)F"
                    self.lblCurrentCondition.text = condition
                    
                }
                .catch{ (error) in
                    print(error)
                }
            }
            .catch{ error in
                print(error)
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error in getting location \(error)")
    }
}

extension ViewController{
    
    func getCurrentLocationKey(for URL: String) -> Promise<(String,String)>{
        return Promise<(String,String)> { seal -> Void in
            Alamofire.request(URL).responseJSON { response in
                
                let locationJSON : JSON = JSON(response.result.value!)
                
                if locationJSON["Key"].exists() && locationJSON["LocalizedName"].exists(){
                    let locKey = locationJSON["Key"].stringValue
                    let city = locationJSON["LocalizedName"].stringValue
                    seal.fulfill((locKey,city))
                }
                
                if response.error != nil {
                    seal.reject(response.error!)
                }
                
            }// end of AlamoFile
        }//End of promise
    }//End of function
    
    
    func getCurrentConditions(for URL:String) -> Promise<(String, String)>{
        return Promise<(String,String)>{ seal -> Void in
            Alamofire.request(URL).responseJSON { response in
                if response.error != nil {
                    seal.reject(response.error!)
                }
                    
                let conditionJSON : JSON = JSON(response.result.value!)
                
                if conditionJSON[0]["Temperature"]["Imperial"]["Value"].exists() &&
                    conditionJSON[0]["WeatherText"].exists(){
                    let temperature = conditionJSON[0]["Temperature"]["Imperial"]["Value"].stringValue
                    let weatherType = conditionJSON[0]["WeatherText"].stringValue
                    
                    seal.fulfill((temperature,weatherType))
                }
                    
            }
        
        }
            
    }
}
