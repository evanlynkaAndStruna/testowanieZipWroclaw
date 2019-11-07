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
        
        let group = DispatchGroup()
        
        let url = URL(string: "https://www.wroclaw.pl/open-data/87b09b32-f076-4475-8ec9-6020ed1f9ac0/OtwartyWroclaw_rozklad_jazdy_GTFS.zip")!
        URLSession.shared.downloadTask(with: url) { (location, response, error) in
            if let tempLocalUrl = location, error == nil{
                let manager = FileManager()
                do{
                   group.enter()
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
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("shapes.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("variants.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("vehicle_types.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("control_stops.txt"))
                    group.leave()
                }catch{
                    print(error)
                }
            }
        }.resume()
        
        group.notify(queue: .main) {
            self.readAllData()
        }
        
    }
    
    func readAllData(){
        let stations = readStations()
        let stopTimes = readStop_times(stationID: stations![0].zespol)
        let trips = readTrips()
        let routes = readRoutes()
    }
    
    func getLines(for station: Station){
        let stopTimes = readStop_times(stationID: station.zespol)
        let trips = readTrips()
        var tripsFiltered = [Trip]()
        if let trips = trips, let stopTimes = stopTimes{
            for time in stopTimes{
                tripsFiltered += trips.filter(){$0.trip_id == time.trip_id}
            }
        }
        
        var
    }
    
    func readStations() -> [Station]?{
        let manager = FileManager()
        var stations = [Station]()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("stops.txt")
            let content = try String(contentsOf: fileURL)
            
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
            return nil
        }
        return stations
    }
    
    func readStop_times(stationID : String) -> [Stop_times]?{
        let manager = FileManager()
        var stopTimes = [Stop_times]()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("stop_times.txt")
            let content = try String(contentsOf: fileURL)
            
            var contentTrunc = content.components(separatedBy: "\r\n")
            contentTrunc.removeFirst()
            contentTrunc.removeLast()
            for cont in contentTrunc{
                let row = cont.components(separatedBy: ",")
                guard row[3] == stationID else {continue}
                let stopTime = Stop_times(odjazd: row[2], zespol: row[3], trip_id: row[0])
                stopTimes.append(stopTime)
                print(stopTime.odjazd)
            }
        }catch{
            print(error)
            return nil
        }
        return stopTimes
    }
    
    func readTrips() -> [Trip]?{
        let manager = FileManager()
        var trips = [Trip]()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("trips.txt")
            let content = try String(contentsOf: fileURL)
            
            var contentTrunc = content.components(separatedBy: "\r\n")
            contentTrunc.removeFirst()
            contentTrunc.removeLast()
            for cont in contentTrunc{
                let row = cont.components(separatedBy: ",")
                let trip = Trip(route_id: row[0], trip_id: row[2], kierunek: row[3], brygada: row[6])
                trips.append(trip)
                print(trip.brygada)
            }
        }catch{
            print(error)
            return nil
        }
        return trips
    }
    
    func readRoutes() -> [Routes]?{
        let manager = FileManager()
        var routes = [Routes]()
        do{
            let documentDirectory = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("routes.txt")
            let content = try String(contentsOf: fileURL)
            
            var contentTrunc = content.components(separatedBy: "\r\n")
            contentTrunc.removeFirst()
            contentTrunc.removeLast()
            for cont in contentTrunc{
                let row = cont.components(separatedBy: ",")
                let route = Routes(route_id: row[0], linia: row[2])
                routes.append(route)
                print(route.linia)
            }
        }catch{
            print(error)
            return nil
        }
        return routes
    }
    
}

struct Routes{
    let route_id : String
    let linia : String
}

struct Trip{
    let route_id : String
    let trip_id : String
    let kierunek : String
    let brygada : String
}

struct Stop_times{
    var odjazd : String
    var zespol : String
    var trip_id : String
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
