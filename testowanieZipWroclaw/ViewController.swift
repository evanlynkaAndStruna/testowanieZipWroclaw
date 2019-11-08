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
        getLines(for: Array(repeating: stations![0], count: 10))
    }
    
    func getLines(for stations: [Station]){
        let stopTimes = readStop_times()
        let trips = readTrips()
        //let routes = readRoutes()
    
        let stops = stations.compactMap(){return Stops(zespol: $0.zespol, nazwa_zespolu: $0.nazwa_zespolu, lon: $0.dlug_geo, lat: $0.szer_geo, stop_times: nil)}
        
        var lines = [Lines]()
        
        for stop in stops{
            stop.stop_times = stopTimes?.filter(){$0.zespol == stop.zespol}
            guard stop.stop_times != nil else {continue}
            for time in stop.stop_times!{
                time.trip = trips?.first(where: {$0.trip_id == time.trip_id})
                guard time.trip != nil else {continue}
                if !lines.contains(where: {$0.value == time.trip!.linia}){
                    lines.append(Lines(value:time.trip!.linia))
                }
            }
        }
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
            }
        }catch{
            print(error)
            return nil
        }
        return stations
    }
    
    func readStop_times() -> [Stop_times]?{
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
                let stopTime = Stop_times(odjazd: row[2], zespol: row[3], trip_id: row[0], trip: nil)
                stopTimes.append(stopTime)
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
                let kier = row[3].replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\\", with: "")
                let trip = Trip(linia: row[0], trip_id: row[2], kierunek: kier, brygada: row[6])
                trips.append(trip)
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
            }
        }catch{
            print(error)
            return nil
        }
        return routes
    }
    
}

class Routes{
    internal init(route_id: String, linia: String) {
        self.route_id = route_id
        self.linia = linia
    }
    
    let route_id : String
    let linia : String
}

class Trip{
    internal init(linia: String, trip_id: String, kierunek: String, brygada: String) {
        self.linia = linia
        self.trip_id = trip_id
        self.kierunek = kierunek
        self.brygada = brygada
    }
    
    let linia : String
    let trip_id : String
    let kierunek : String
    let brygada : String
}

class Stop_times{
    internal init(odjazd: String, zespol: String, trip_id: String, trip: Trip?) {
        self.odjazd = odjazd
        self.zespol = zespol
        self.trip_id = trip_id
        self.trip = trip
    }
    
    let odjazd : String
    let zespol : String
    let trip_id : String
    var trip : Trip?
}

class Stops{
    internal init(zespol: String, nazwa_zespolu: String, lon: Double, lat: Double, stop_times: [Stop_times]?) {
        self.zespol = zespol
        self.nazwa_zespolu = nazwa_zespolu
        self.lon = lon
        self.lat = lat
        self.stop_times = stop_times
    }
    
    let zespol : String
    let nazwa_zespolu : String
    let lon : Double
    let lat : Double
    var stop_times : [Stop_times]?
}


class Lines : Codable{
    internal init(value: String) {
        self.value = value
    }
    
    let value : String
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
    var lines : [Lines]?
}
