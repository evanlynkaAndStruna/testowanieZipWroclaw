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
        group.enter()
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
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("shapes.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("variants.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("vehicle_types.txt"))
                    try manager.removeItem(at: documentDirectory.appendingPathComponent("wroclawData").appendingPathComponent("control_stops.txt"))
                    group.leave()
                }catch{
                    print(error)
                    group.leave()
                }
            }
        }.resume()
        
        group.notify(queue: .main) {
            self.readAllData()
        }
        
    }
    
    func readAllData(){
        let stations = readStations()
        //getLines(for: [stations![0]])
        let el = getScheduleFor(station: stations![0])
        
    }
    
    func getLines(for stations: [Station]){
        let stopTimes = readStop_times()
        let trips = readTrips()
        
        for station in stations{
            let stopTimesChosen = stopTimes?.filter(){$0.zespol == station.zespol}
            guard stopTimesChosen != nil else {continue}
            var lineArr = [String]()
            for stopTime in stopTimesChosen!{
                let newTripChosen = trips?.filter({$0.trip_id == stopTime.trip_id})
                guard newTripChosen != nil, newTripChosen!.first != nil else {continue}
                lineArr.append((newTripChosen?.first!.linia)!)
            }
            let lineSet = Set<String>(lineArr)
            station.lines = lineSet.compactMap({return Lines(value: $0)})
        }
    }
    
    func getScheduleFor(station : Station) -> [ScheduleElement]?{
        let stopTimes = readStop_times()
        let trips = readTrips()
        var elements = [ScheduleElement]()
        
        let stopTimesChosen = stopTimes?.filter(){$0.zespol == station.zespol}
        guard stopTimesChosen != nil else {return nil}
        for stopTime in stopTimesChosen!{
            let newTripChosen = trips?.filter({$0.trip_id == stopTime.trip_id})
            guard newTripChosen != nil, newTripChosen!.first != nil else {continue}//, newTripChosen!.first!.linia == line.value else {continue}
            let trip = newTripChosen!.first!
            elements.append(ScheduleElement(line: trip.linia, direction: trip.kierunek, arrivalTimeString: stopTime.odjazd, arrivalTimeInt: changeStringToDateNumber(arrivalTimeString: stopTime.odjazd), brigade: trip.brygada))
        }
        guard elements.count > 0 else {return nil}
        return elements
    }
    
    func getStations() -> [Station]?{
        return readStations()
    }
    
    func changeStringToDateNumber(arrivalTimeString:String) -> Int{
        let index0 = arrivalTimeString.index(arrivalTimeString.startIndex, offsetBy: 0)
        let hours10: Int = Int(String(arrivalTimeString[index0]))!

        let index1 = arrivalTimeString.index(arrivalTimeString.startIndex, offsetBy: 1)
        let hours: Int = Int(String(arrivalTimeString[index1]))!

        let index3 = arrivalTimeString.index(arrivalTimeString.startIndex, offsetBy: 3)
        let minutes10: Int = Int(String(arrivalTimeString[index3]))!

        let index4 = arrivalTimeString.index(arrivalTimeString.startIndex, offsetBy: 4)
        let minutes: Int = Int(String(arrivalTimeString[index4]))!

        let arrivalTimeInt = hours10*10*60 + hours * 60 + minutes10 * 10 + minutes
        return arrivalTimeInt
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
    
    func readStop_times() -> Set<Stop_times>?{
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
        return Set<Stop_times>(stopTimes)
    }
    
    func readTrips() -> Set<Trip>?{
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
        return Set<Trip>(trips)
    }
    
    func readRoutes() -> Set<Routes>?{
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
        return Set<Routes>(routes)
    }
    
}

class Routes : Hashable{
    static func == (lhs: Routes, rhs: Routes) -> Bool {
        lhs.route_id == rhs.route_id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(route_id)
    }
    
    internal init(route_id: String, linia: String) {
        self.route_id = route_id
        self.linia = linia
    }
    
    let route_id : String
    let linia : String
}

class Trip: Hashable{
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.trip_id == rhs.trip_id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(trip_id)
    }
    
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

class Stop_times: Hashable{
    static func == (lhs: Stop_times, rhs: Stop_times) -> Bool {
        lhs.trip_id == rhs.trip_id && lhs.zespol == rhs.zespol
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(trip_id)
        hasher.combine(zespol)
    }
    
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

class Stops : Hashable{
    static func == (lhs: Stops, rhs: Stops) -> Bool {
        lhs.zespol == rhs.zespol
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(zespol)
    }
    
    internal init(zespol: String, nazwa_zespolu: String, lon: Double, lat: Double, stop_times: Set<Stop_times>?) {
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
    var stop_times : Set<Stop_times>?
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

class ScheduleElement{
    init(line: String, direction: String, arrivalTimeString: String, arrivalTimeInt: Int, brigade: String) {
        self.line = line
        self.direction = direction
        self.arrivalTimeString = arrivalTimeString
        self.arrivalTimeInt = arrivalTimeInt
        self.brigade = brigade
    }
    
    static func == (lhs: ScheduleElement, rhs: ScheduleElement) -> Bool {
           return lhs.line == rhs.line && lhs.brigade == rhs.brigade && lhs.direction == rhs.direction && lhs.arrivalTimeString == rhs.arrivalTimeString
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return ScheduleElement(line: line, direction: direction, arrivalTimeString: arrivalTimeString, arrivalTimeInt: arrivalTimeInt, brigade: brigade)
    }
    
    var line : String
    var direction : String
    var arrivalTimeString : String
    var arrivalTimeInt : Int
    var brigade : String
    var arrivalTime : Int?
    var status : Status?
    
    enum Status{
        case past
        case present
        case future
        
        var backgroundColor : UIColor{
            switch self {
            case .past:
                return UIColor.systemGray5
            case .present:
                return UIColor.systemBackground
            case .future:
                return UIColor.systemGray6
            }
        }
        
        var textColor : UIColor{
            switch self {
            case .past:
                return UIColor(red:0.50, green:0.00, blue:0.01, alpha:1.00)
            case .present:
                return UIColor(red:0.99, green:0.49, blue:0.04, alpha:1.00)
            case .future:
                return UIColor(red:0.05, green:0.50, blue:0.25, alpha:1.00)
            }
        }
    }
}
