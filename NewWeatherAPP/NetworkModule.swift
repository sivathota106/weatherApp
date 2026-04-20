//
//  NetworkModule.swift
//  NewWeatherAPP
//
//  Created by Siva Thota on 4/20/26.
//

import CoreLocation
import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Protocols

protocol WeatherServiceProtocol {
    func lookupUSCity(_ query: String) async throws -> CityLocation
    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherData
    func fetchIconData(code: String) async throws -> Data
}

protocol CityStoreProtocol {
    func saveLastCity(_ city: String)
    func lastCity() -> String?
}

@MainActor
protocol LocationProviderProtocol: AnyObject {
    var permissionStatus: CLAuthorizationStatus { get }
    func requestWhenInUsePermission() async
    func requestSingleLocation() async throws -> Coordinate
}

// MARK: - Services

final class OpenWeatherService: WeatherServiceProtocol {
    private let apiKey: String
    private let session: URLSession
    private let iconCache: IconCache
    private let decoder = JSONDecoder()

    init(apiKey: String, session: URLSession = .shared, iconCache: IconCache = IconCache()) {
        self.apiKey = apiKey
        self.session = session
        self.iconCache = iconCache
    }

    func lookupUSCity(_ query: String) async throws -> CityLocation {
        try validateKey()
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(encoded),US&limit=1&appid=\(apiKey)"
        let response: [GeocodeResponse] = try await fetch(urlString: urlString)

        guard let city = response.first else {
            throw WeatherError.invalidCity
        }

        return CityLocation(
            name: city.name,
            state: city.state,
            country: city.country,
            coordinate: Coordinate(latitude: city.lat, longitude: city.lon)
        )
    }

    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherData {
        try validateKey()
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=imperial&appid=\(apiKey)"
        let response: WeatherResponse = try await fetch(urlString: urlString)
        guard let firstWeather = response.weather.first else { throw WeatherError.decoding }
        return WeatherData(
            cityName: response.name,
            country: response.sys.country,
            temperatureFahrenheit: response.main.temp,
            feelsLikeFahrenheit: response.main.feelsLike,
            humidityPercent: response.main.humidity,
            description: firstWeather.description.capitalized,
            iconCode: firstWeather.icon
        )
    }

    func fetchIconData(code: String) async throws -> Data {
        if let cached = iconCache.imageData(for: code) {
            return cached
        }
        let urlString = "https://openweathermap.org/img/wn/\(code)@2x.png"
        guard let url = URL(string: urlString) else { throw WeatherError.network("Invalid icon URL") }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WeatherError.network("Unable to download weather icon.")
        }
        iconCache.store(imageData: data, for: code)
        return data
    }

    private func validateKey() throws {
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw WeatherError.missingAPIKey
        }
    }

    private func fetch<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw WeatherError.network("Invalid URL.") }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw WeatherError.network("Server returned an error.")
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw WeatherError.decoding
            }
        } catch let weatherError as WeatherError {
            throw weatherError
        } catch {
            throw WeatherError.network(error.localizedDescription)
        }
    }
}

final class IconCache {
    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: FileManager
    private let baseFolderURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSTemporaryDirectory())
        let baseFolderURL = cacheDirectory.appending(path: "WeatherIconCache", directoryHint: .isDirectory)
        if !fileManager.fileExists(atPath: baseFolderURL.path()) {
            try? fileManager.createDirectory(at: baseFolderURL, withIntermediateDirectories: true)
        }
        self.baseFolderURL = baseFolderURL
    }

    func imageData(for code: String) -> Data? {
        if let memoryData = memoryCache.object(forKey: code as NSString) {
            return memoryData as Data
        }
        let fileURL = baseFolderURL.appending(path: "\(code).png")
        guard let diskData = try? Data(contentsOf: fileURL) else { return nil }
        memoryCache.setObject(diskData as NSData, forKey: code as NSString)
        return diskData
    }

    func store(imageData: Data, for code: String) {
        memoryCache.setObject(imageData as NSData, forKey: code as NSString)
        let fileURL = baseFolderURL.appending(path: "\(code).png")
        try? imageData.write(to: fileURL, options: .atomic)
    }
}

final class LastCityStore: CityStoreProtocol {
    private let defaults: UserDefaults
    private let key = "lastSearchedCity"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveLastCity(_ city: String) {
        defaults.set(city, forKey: key)
    }

    func lastCity() -> String? {
        defaults.string(forKey: key)
    }
}

@MainActor
final class CoreLocationProvider: NSObject, LocationProviderProtocol {
    private let manager = CLLocationManager()
    private var permissionContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<Coordinate, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    var permissionStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestWhenInUsePermission() async {
        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    func requestSingleLocation() async throws -> Coordinate {
        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            throw WeatherError.noLocationPermission
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }
}

extension CoreLocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionContinuation?.resume()
        permissionContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationContinuation?.resume(throwing: WeatherError.locationUnavailable)
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: WeatherError.network(error.localizedDescription))
        locationContinuation = nil
    }
}

struct AppDependencies {
    let weatherService: WeatherServiceProtocol
    let locationProvider: LocationProviderProtocol
    let cityStore: CityStoreProtocol

    static let apiKey = ""

    @MainActor
    static func makeDefault() -> AppDependencies {
        AppDependencies(
            weatherService: OpenWeatherService(apiKey: apiKey),
            locationProvider: CoreLocationProvider(),
            cityStore: LastCityStore()
        )
    }
}
