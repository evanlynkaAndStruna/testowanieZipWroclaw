//
//  ViewController.swift
//  testowanieZipWroclaw
//
//  Created by Karol Struniawski on 05/11/2019.
//  Copyright © 2019 Karol Struniawski. All rights reserved.
//

import UIKit
import Zip

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://www.wroclaw.pl/open-data/87b09b32-f076-4475-8ec9-6020ed1f9ac0/OtwartyWroclaw_rozklad_jazdy_GTFS.zip")!
        URLSession.shared.downloadTask(with: url) { (location, response, error) in
            if let tempLocalUrl = location, error == nil{
                let manager = FileManager()
                do{
                   let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                   let fileURL = documentDirectory.appendingPathComponent("wroclawData.zip")
                   print(fileURL)
                   try manager.copyItem(at: tempLocalUrl as URL, to: fileURL)
                   let _ = try Zip.quickUnzipFile(fileURL)
                   try manager.removeItem(at: fileURL)
                   try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("agency.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("calendar_dates.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("calendar.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("feed_info.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("route_types.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("routes.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("shapes.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("variants.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("vehicle_types.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("control_stops.txt"))
                }catch{
                    print(error)
                }

            }
        }.resume()
        //readStations()
    }
    
    func readStations(){
        let manager = FileManager()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("stops.txt")
            let content = try String(contentsOf: fileURL)
            
            var stations = [Station]()
            var contentTrunc = content.components(separatedBy: "\r\n")
            contentTrunc.removeFirst()
            contentTrunc.removeLast()
            for cont in contentTrunc{
                let row = cont.components(separatedBy: ",")
                let station = Station(zespol: row[0], slupek: "", nazwa_zespolu: String(row[2]).replacingOccurrences(of: "\"", with: ""), szer_geo: Double(row[3])!, dlug_geo: Double(row[4])!, distance: nil)
                stations.append(station)
                print(station.nazwa_zespolu)
            }
        }catch{
            print(error)
        }
    }
    
    func readLinesForStations(){
        let manager = FileManager()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("stops.txt")
            
        }catch{
            print(error)
        }
    }
}

class Station: Codable{
    internal init(zespol: String, slupek: String, nazwa_zespolu: String, szer_geo: Double, dlug_geo: Double, distance: Int?) {
        self.zespol = zespol
        self.slupek = slupek
        self.nazwa_zespolu = nazwa_zespolu
        self.szer_geo = szer_geo
        self.dlug_geo = dlug_geo
        self.distance = distance
    }
    
    var zespol : String
    var slupek : String
    var nazwa_zespolu : String
    var szer_geo : Double
    var dlug_geo : Double
    var distance : Int?
}
