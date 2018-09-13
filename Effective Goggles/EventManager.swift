//
//  EventManager.swift
//  Effective Goggles
//
//  Created by Yasha Mostofi on 9/13/18.
//  Copyright © 2018 Yasha Mostofi. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

struct Event {
    var name: String
    var startTime: Date
    var endTime: Date
    var isCheckin: Bool
    init(name: String, startTime: Date, endTime: Date, isCheckin: Bool = false) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.isCheckin = isCheckin
    }
}

class EventManager {
    static let sharedinstance = EventManager()
    var events = [Event]()
    var currentEvent: Event?
    
    func currentTime() -> Date {
        return Date(timeIntervalSinceNow: 0)
    }
    
    func checkInEvent() -> Event {
        return Event(name: "Check In", startTime: currentTime(), endTime: currentTime(), isCheckin: true)
    }
    
    func possibleEvents() -> [Event] {
        var result = [Event]()
        for event in events {
            if currentTime() >= event.startTime && currentTime() < event.endTime {
                result.append(event)
            }
        }
        return result
    }
    
    func getEvents() {
        let headers: HTTPHeaders = [
            "Authorization": jwt
        ]
        Alamofire.request("https://api.reflectionsprojections.org/event/",
                          headers: headers).validate().responseJSON { response in
                            switch response.result {
                            case .success:
                                if let data = response.data {
                                    do {
                                        let json = try JSON(data: data)
                                        self.events = [Event]()
                                        for jsonEvent in json["events"] {
                                            let name = jsonEvent.1["name"].stringValue
                                            let startTime = Date(timeIntervalSince1970: jsonEvent.1["startTime"].doubleValue)
                                            let endTime = Date(timeIntervalSince1970: jsonEvent.1["endTime"].doubleValue)
                                            self.events.append(Event(name: name, startTime: startTime, endTime: endTime))
                                        }
                                    } catch {
                                        print("Failure: \(data)")
                                    }
                                }
                            case .failure:
                                print("Failure")
                            }
        }
    }
    
    func parseEvents() {
        let startTime = Date(timeIntervalSinceNow: 0)
        let endTime = Date(timeInterval: 60*60*12, since: startTime)
        self.events.append(Event(name: "event 1", startTime: startTime, endTime: endTime))
        self.events.append(Event(name: "event 2", startTime: startTime, endTime: endTime))
    }
}
