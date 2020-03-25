//
//  AllCitiesTableViewController.swift
//  Weather365
//
//  Created by xinrui wang on 3/24/20.
//  Copyright © 2020 xinrui wang. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftSpinner
import SwiftyJSON
import PromiseKit
import RealmSwift

class AllCitiesTableViewController: UITableViewController {

    
    @IBOutlet var tblView: UITableView!
    
    var conditions=[CurrentWeather]()
    
    override func viewDidLoad() {
       initValues()
       super.viewDidLoad()
    }

  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return conditions.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text="\(conditions[indexPath.row].city), \(conditions[indexPath.row].condition), \(conditions[indexPath.row].temp)℉"

        return cell
    }
    
    
    func initValues(){
         getUpdatedWeather()
        .done { (results) in
            for result in results{
                self.conditions.append(result)
            }
            print(results)
            self.tableView.reloadData()
            
         }.catch{( error) in
            print(error.localizedDescription)
        }
        
    }
    func getUpdatedWeather()->Promise<[CurrentWeather]>{
        let locations = getLocations()
        let locationURLs = getCurrentWeatherURL(locations)
        var promises: [Promise<CurrentWeather>] = []
        for i in 0...locations.count-1{
            let url = locationURLs[i]
            let cityname = locations[i].cityName
            let locationkey = locations[i].locationKey
            promises.append(getCurrentConditions(for: url, key: locationkey, cityName: cityname))
            
        }
        return when(fulfilled: promises)
    }
    
    func getLocations() -> [LocationModel]{
        var arrLocKey = [LocationModel]()
        do{
            let realm = try! Realm()
            let locations = realm.objects(LocationModel.self)
            for location in locations{
                arrLocKey.append(location)
            }
        }catch{
            print("Error in reading from DB")
        }
        return arrLocKey
    }
    
    
    func getCurrentWeatherURL(_ locationKey: [LocationModel]) -> [String]{
        var arrURLs = [String]()
        for locationKey in locationKey{
            arrURLs.append("\(Constants.conditionURL)\(locationKey.locationKey)?apikey=\(Constants.apiKey)")
        }
        
        return arrURLs
    }

    func getCurrentConditions(for URL: String, key: String,cityName: String) -> Promise<CurrentWeather>{
        
        return Promise<CurrentWeather> { seal -> Void  in
            
                Alamofire.request(URL).responseJSON { response in
                    if response.error != nil {
                        seal.reject(response.error!)
                    }
                    
                    let currentJSON : JSON = JSON(response.result.value!)
                    
                    if  currentJSON[0]["WeatherText"].exists() &&
                        currentJSON[0]["Temperature"]["Imperial"]["Value"].exists() {
                        
                        let condition = currentJSON[0]["WeatherText"].stringValue
                        let temp = currentJSON[0]["Temperature"]["Imperial"]["Value"].stringValue
                        seal.fulfill(CurrentWeather(cityName,condition,temp, key))
                    }
            }// end of promise
        }// end of function
    
    }

}
