//
//  WeatherGetter.swift
//  hoods
//
//  Created by Andrew Carvajal on 1/17/17.
//  Copyright © 2017 YugeTech. All rights reserved.
//

import Foundation
import MapKit

class WeatherGetter {
    
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "10abd2dcd8626a4d75165599ff7c8625"
    var visitingWeatherID: Int?
    var visitingWeatherTemp: Double?
    var tappedWeatherID: Int?
    var tappedWeatherTemp: Double?
    var searchedAddressWeatherID: Int?
    var searchedAddressWeatherTemp: Double?
    
    func weatherEmojis(id: Int) -> String {
        switch id {
            
        // thunderstorm
        case 200: return "⛈"
        case 201: return "⛈⛈"
        case 202: return "⛈⛈⛈"
        case 210: return "🌩"
        case 211: return "🌩🌩"
        case 212: return "🌩🌩🌩"
        case 221: return "🌩  🌩"
        case 230: return "🌩☔️"
        case 231: return "🌩☔️☔️"
        case 232: return "🌩☔️☔️☔️"
            
        // drizzle
        case 300: return "☔️"
        case 301: return "☔️"
        case 302: return "💦☔️"
        case 310: return "☔️🌧"
        case 311: return "☔️🌧"
        case 312: return "💦☔️🌧"
        case 313: return "💦☔️🌧"
        case 314: return "💦☔️🌧"
        case 321: return "💦☔️"
            
        // rain
        case 500: return "🌧"
        case 501: return "🌧🌧"
        case 502: return "🌧🌧🌧"
        case 503: return "💦🌧🌧🌧"
        case 504: return "🌊"
        case 511: return "⛄️🌧"
        case 520: return "🌧"
        case 521: return "🌧🌧"
        case 522: return "🌧🌧🌧"
        case 531: return "🌧🌧"
            
        // snow
        case 600: return "🌨"
        case 601: return "🌨🌨"
        case 602: return "🌨🌨🌨"
        case 611: return "💦🌨"
        case 612: return "💦🌨🌨"
        case 615: return "🌧🌨"
        case 616: return "🌧🌨"
        case 620: return "☃️🌨"
        case 621: return "☃️🌨🌨☃️"
        case 622: return "☃️🌨🌨🌨☃️"
            
        // atmosphere
        case 701: return "🌫"
        case 711: return "💨"
        case 721: return "🌫"
        case 731: return "🌬"
        case 741: return "🌫"
        case 751: return "🏖"
        case 761: return "🌬"
        case 762: return "🌋"
        case 771: return "🌬"
        case 781: return "🌪"
            
        // clear sky
        case 800: return clearWeatherEmojiForNow()
            
        // clouds
        case 801: return "☁️"
        case 802: return "☁️☁️"
        case 803: return "☁️☁️"
        case 804: return "☁️💦☁️"
            
        // extreme
        case 900: return "🌪"
        case 901: return "🌊🌊"
        case 902: return "🌊🌊🌊"
        case 903: return "❄️"
        case 904: return "🔥"
        case 905: return "🌬"
        case 906: return "❄️🌧"
            
        // additional
        case 951: return clearWeatherEmojiForNow()
        case 952: return "🌬"
        case 953: return "🌬"
        case 954: return "🌬"
        case 955: return "🌬"
        case 956: return "🌬💨"
        case 957: return "🌬💨💨"
        case 958: return "🌬💨💨"
        case 959: return "🌬💨💨💨"
        case 960: return "🌊"
        case 961: return "🌊🌊"
        case 962: return "🌊🌊🌊"
            
        // clear
        default: return clearWeatherEmojiForNow()
        }
    }
    
    func clearWeatherEmojiForNow() -> String {
        let hoursFormatter = DateFormatter()
        hoursFormatter.dateFormat = "HH"
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: date)
        switch components.hour! {
        case 6...17:
            return "☀️"
        default:
            return "🌙"
        }
    }
    
    func updateWeatherIDAndTemp(coordinate: CLLocationCoordinate2D, from: String) {
        let session = URLSession.shared
        let weatherRequestURL = URL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)")!
        
        // get data
        let dataTask = session.dataTask(with: weatherRequestURL as URL) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            // if error...
            if let error = error {
                print("Error:\n\(error)")
                
            // else success
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:AnyObject]
                    if let weather = json?["weather"] as? [[String:AnyObject]] {
                        if let id = weather.first?["id"] {
                            switch from {
                            case "tap":
                                self.tappedWeatherID = id as? Int
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GotWeatherFromTap"), object: nil)
                            case "search":
                                self.searchedAddressWeatherID = id as? Int
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GotWeatherFromSearch"), object: nil)
                            default:
                                self.visitingWeatherID = id as? Int
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GotWeatherFromVisit"), object: nil)
                            }
                        }
                    }
                    if let temperature = json?["main"]?["temp"] as? Double {
                        switch from {
                        case "tap":
                            self.tappedWeatherTemp = temperature * 9 / 5 - 459.67
                        case "search":
                            self.searchedAddressWeatherTemp = temperature * 9 / 5 - 459.67
                        default:
                            self.visitingWeatherTemp = temperature * 9 / 5 - 459.67
                        }
                    }
                } catch {
                    print("Error:\n\(error)")
                }
            }
        }
        dataTask.resume()
    }
}
