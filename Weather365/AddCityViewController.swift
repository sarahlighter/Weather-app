//
//  AddCityViewController.swift
//  Weather365
//
//  Created by xinrui wang on 3/17/20.
//  Copyright © 2020 xinrui wang. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftSpinner
import SwiftyJSON
import PromiseKit
import RealmSwift

class AddCityViewController: UIViewController{
 
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tblView: UITableView!
    
    
   var arr = [LocationModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblView.delegate = self
        tblView.dataSource = self
        searchBar.delegate = self
        print(Realm.Configuration.defaultConfiguration.fileURL)
    }
    
}
extension AddCityViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
       }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(arr[indexPath.row].cityName),\(arr[indexPath.row].stateName),\(arr[indexPath.row].countryName)"
        return cell
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        addCityToDB(for: indexPath.row)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle  == .delete{
            let loc = arr[indexPath.row]
//            self.deleteCity(for: loc)
//            self.arr.remove(at: indexPath.row)
            tblView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func  deleteCity(for location: LocationModel){
        let realm = try! Realm()
        try! realm.write{
            realm.delete(location)
        }
    }
    func addCityToDB(for row:Int){
        let city = arr[row].cityName
        let alert = UIAlertController(title: "Add City", message: "Get Weather for \(city)", preferredStyle: .alert)
        let Ok = UIAlertAction(title: "OK",  style: .default){ action in
            print("OK")
            self.addCity(for: row)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel){action in
            print("cancel")
        }
        alert.addAction(Ok)
        alert.addAction(cancel)
        self.present(alert,animated:true, completion:nil)
    }

    func addCity( for index: Int){
        if isCityAdded(for: index){
            arr.removeAll()
            tblView.reloadData()
            return
        }
        
        let loc = arr[index]
        do {
            let realm = try Realm()
            try realm.write{
                realm.add(loc, update: Realm.UpdatePolicy.all)
            }
        }catch{
            print("Unable to add city in the database")
        }
        arr.removeAll()
        searchBar.text = ""
        tblView.reloadData()
    }
    func isCityAdded(for index: Int) -> Bool{
        let loc = arr[index]
        
        let realm = try! Realm()
        if realm.object(ofType: LocationModel.self, forPrimaryKey: loc.locationKey) != nil{
            return true
        }
        return false
    }
}


extension AddCityViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText:String){

        guard searchBar.text!.count>3 else{
           if searchBar.text!.isEmpty {
                arr.removeAll()
                tblView.reloadData()
                
            }
            return;
        }
        getAutoCompleteCities(for: searchBar.text!)
        
    }
    
    func getAutoCompleteCitiesURL(_ cityStr: String) -> String{
        return "\(Constants.autocompleteURL)?q=\(cityStr)&apikey=\(Constants.apiKey)"
     }
    func getAutoCompleteCities(for cityStr:String!){
        let autocompleteURL = getAutoCompleteCitiesURL(cityStr)
        Alamofire.request(autocompleteURL).responseJSON{ response in
            if response.error != nil{
                print("Error in getting response from autocomplete URL. Error: \(response.error?.localizedDescription)")
                return
            }
            let autocompleteJSON: [JSON] = JSON(response.result.value!).arrayValue
            self.arr.removeAll()
            for city in autocompleteJSON{
                let citydata = LocationModel()
                citydata.locationKey = city["Key"].stringValue
                citydata.cityName = city["LocalizedName"].stringValue
                citydata.countryName = city["Country"]["LocalizedName"].stringValue
                citydata.stateName = city["AdministrativeArea"]["ID"].stringValue
                self.arr.append(citydata)
            }
            self.tblView.reloadData()
        }
    }
}
