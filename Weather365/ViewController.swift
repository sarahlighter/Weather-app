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
import RealmSwift

class ViewController: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var lblCityName: UILabel!
    
    @IBOutlet weak var lblCurrentCondition: UILabel!
    
    @IBOutlet weak var lblTemperature: UILabel!
    
    @IBOutlet weak var tblView: UITableView!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var arr = [LocationModel]()
    var forecastArr = [ForecastModel]()
    
    let locationManager = CLLocationManager()
    //http://dataservice.accuweather.com/currentconditions/v1/
    //api key :bGnXMys87L5QHJhvgjwbRTXikjQAXf1H
    //location key: 2628276
    //http://dataservice.accuweather.com/currentconditions/v1/2628276?apikey=bGnXMys87L5QHJhvgjwbRTXikjQAXf1H
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate=self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        tblView.delegate = self
        tblView.dataSource=self
        pickerView.delegate=self
        pickerView.dataSource=self
        loadCites()
        print(Realm.Configuration.defaultConfiguration.fileURL)
    }
    override func viewDidAppear(_ animated: Bool) {
        loadCites()
    }
    func loadCites(){
        arr.removeAll()
        let dummyLoc = LocationModel()
        dummyLoc.locationKey = "-1"
        dummyLoc.cityName = "Seattle"
        dummyLoc.countryName="US"
        dummyLoc.stateName="WA"
        arr.append(dummyLoc)
        do{
            let realm = try! Realm()
            let locations = realm.objects(LocationModel.self)
            for location in locations{
                arr.append(location)
            }
            tblView.reloadData()
            pickerView.reloadAllComponents()
        }catch{
            print("Error in reading from DB")
        }
    }
    
    func getLoationURL(_ latLgn: String) -> String{
        return "\(Constants.locationURL)?q=\(latLgn)&apikey=\(Constants.apiKey)"
    }
    
    func getConditionURL(_ key:String) -> String{
        return "\(Constants.conditionURL)\(key)?apikey=\(Constants.apiKey)"
    }
    
    func get5DayForecastURL(_ key:String) ->String{
        return "\(Constants.forecastURL)\(key)?apikey=\(Constants.apiKey)"
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currLocation = locations.last {
            let lat = currLocation.coordinate.latitude
            let lng = currLocation.coordinate.longitude
            let currLocationURL = getLoationURL("\(lat),\(lng)")
            
            getCurrentLocationKey(for: currLocationURL)
            .done{ (locKey,city) in
                
                self.lblCityName.text = city
                self.updateCurrentTempAndCondition(locKey)
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
extension ViewController: UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate,UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecastArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for:indexPath)
        cell.textLabel?.numberOfLines = 0;
//        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel?.text = "\(forecastArr[indexPath.row].Date)     \(forecastArr[indexPath.row].minTemperature)℉ - \(forecastArr[indexPath.row].maxTemperature)℉      \nDay: \(forecastArr[indexPath.row].DayPrecipitationType)   \(forecastArr[indexPath.row].DayPrecipitationIntensity)     Night: \(forecastArr[indexPath.row].NightPrecipitationType)  \(forecastArr[indexPath.row].NightPrecipitationInstensity)"
        return cell
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arr.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "Current Location"
        }
        return "\(arr[row].cityName),\(arr[row].stateName)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0{
            print("Current Location selected")
        }else{
            let locKey = arr[row].locationKey
            //set the city name
            self.lblCityName.text = "\(arr[row].cityName) , \(arr[row].stateName)"
            updateCurrentTempAndCondition(locKey)
        }
    }
    
    func updateCurrentTempAndCondition(_ locKey: String){
        
        //get valuew for current condition and temp
        let currConditionURL = self.getConditionURL(locKey)
        
        self.getCurrentConditions(for: currConditionURL)
        .done{ (temp,condition) in
            self.lblTemperature.text="\(temp) ℉"
            self.lblCurrentCondition.text = condition
            
        }
        .catch{ (error) in
            print(error)
        }
        
        let forecastURL = self.get5DayForecastURL(locKey)
        

        self.getExtendedForecast(for: forecastURL)
        .done{ (tempArr) in
            self.forecastArr=tempArr
            self.tblView.reloadData()
        }
        .catch{ (error) in
            print(error)
        }
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
    
    func getExtendedForecast(for URL:String)-> Promise<Array<ForecastModel>>{
        return Promise<Array<ForecastModel>>{ seal -> Void in
            Alamofire.request(URL).responseJSON { response in
                if response.error != nil {
                    seal.reject(response.error!)
                }
                    
                let conditionJSON : JSON = JSON(response.result.value!)
                let dailyForecastsJSON = conditionJSON["DailyForecasts"]
                var tempArr = [ForecastModel]()
                for forecast in dailyForecastsJSON {
                    let forecastData = ForecastModel()
                    forecastData.Date = String(forecast.1["Date"].stringValue.prefix(10))
                    forecastData.minTemperature = forecast.1["Temperature"]["Minimum"]["Value"].stringValue
                    forecastData.maxTemperature = forecast.1["Temperature"]["Maximum"]["Value"].stringValue
                    forecastData.DayPrecipitationType = forecast.1["Day"]["PrecipitationType"].stringValue
                    forecastData.DayPrecipitationIntensity = forecast.1["Day"]["recipitationIntensity"].stringValue
                    forecastData.NightPrecipitationType = forecast.1["Night"]["PrecipitationType"].stringValue
                    forecastData.NightPrecipitationInstensity = forecast.1["Night"]["recipitationIntensity"].stringValue
                    tempArr.append(forecastData)
                    
                }
                seal.fulfill(tempArr)
                    
            }
        
        }
    }
}
