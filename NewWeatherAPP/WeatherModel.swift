//
//  WeatherModel.swift
//  NewWeatherAPP
//
//  Created by Siva Thota on 4/20/26.
//

import CoreLocation
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Models

struct Coordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

struct CityLocation: Equatable {
    let name: String
    let state: String?
    let country: String
    let coordinate: Coordinate
}

struct WeatherData: Equatable {
    let cityName: String
    let country: String
    let temperatureFahrenheit: Double
    let feelsLikeFahrenheit: Double
    let humidityPercent: Int
    let description: String
    let iconCode: String
}

extension WeatherData {
    var temperatureText: String { "\(Int(temperatureFahrenheit.rounded()))°F" }
    var feelsLikeText: String { "Feels like \(Int(feelsLikeFahrenheit.rounded()))°F" }
    var humidityText: String { "Humidity \(humidityPercent)%" }
}

enum WeatherError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidCity
    case network(String)
    case decoding
    case noLocationPermission
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenWeather API key in AppDependencies.apiKey."
        case .invalidCity:
            return "Could not find a matching US city. Try another city name."
        case .network(let message):
            return "Network error: \(message)"
        case .decoding:
            return "Unable to parse weather data from the server."
        case .noLocationPermission:
            return "Location permission was denied. Search for a city instead."
        case .locationUnavailable:
            return "Current location is unavailable right now."
        }
    }
}

// MARK: - API DTOs

public struct GeocodeResponse: Decodable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}

public struct WeatherResponse: Decodable {
    struct MainInfo: Decodable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int

        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
        }
    }

    struct WeatherInfo: Decodable {
        let description: String
        let icon: String
    }

    struct SysInfo: Decodable {
        let country: String
    }

    let name: String
    let weather: [WeatherInfo]
    let main: MainInfo
    let sys: SysInfo
}
