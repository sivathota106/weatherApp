//
//  NewWeatherAPPTests.swift
//  NewWeatherAPPTests
//
//  Created by Siva Thota on 4/20/26.
//

import CoreLocation
import XCTest
@testable import NewWeatherAPP

final class NewWeatherAPPTests: XCTestCase {
    func testWeatherDataFormatting() {
        let weather = WeatherData(
            cityName: "Austin",
            country: "US",
            temperatureFahrenheit: 72.4,
            feelsLikeFahrenheit: 70.5,
            humidityPercent: 48,
            description: "Clear Sky",
            iconCode: "01d"
        )

        XCTAssertEqual(weather.temperatureText, "72°F")
        XCTAssertEqual(weather.feelsLikeText, "Feels like 71°F")
        XCTAssertEqual(weather.humidityText, "Humidity 48%")
    }

    @MainActor
    func testSearchTappedLoadsWeatherAndSavesCity() async {
        let mockService = MockWeatherService()
        let mockLocation = MockLocationProvider()
        let store = MockCityStore()
        let viewModel = WeatherViewModel(weatherService: mockService, locationProvider: mockLocation, cityStore: store)

        viewModel.cityInput = "Austin"
        viewModel.searchTapped()
        try? await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(mockService.lookupQueries, ["Austin"])
        XCTAssertEqual(store.savedCity, "Austin")
        XCTAssertEqual(viewModel.weather?.cityName, "Austin")
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testStartupFallsBackToLastCityWhenLocationDenied() async {
        let mockService = MockWeatherService()
        let mockLocation = MockLocationProvider(permissionStatus: .denied)
        let store = MockCityStore(lastCity: "Dallas")
        let viewModel = WeatherViewModel(weatherService: mockService, locationProvider: mockLocation, cityStore: store)

        viewModel.onAppear()
        try? await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(viewModel.cityInput, "Dallas")
        XCTAssertEqual(mockService.lookupQueries, ["Dallas"])
        XCTAssertEqual(viewModel.weather?.cityName, "Austin")
    }
}

private final class MockWeatherService: WeatherServiceProtocol {
    var lookupQueries: [String] = []

    func lookupUSCity(_ query: String) async throws -> CityLocation {
        lookupQueries.append(query)
        return CityLocation(
            name: "Austin",
            state: "TX",
            country: "US",
            coordinate: Coordinate(latitude: 30.2672, longitude: -97.7431)
        )
    }

    func fetchWeather(for coordinate: Coordinate) async throws -> WeatherData {
        WeatherData(
            cityName: "Austin",
            country: "US",
            temperatureFahrenheit: 75,
            feelsLikeFahrenheit: 73,
            humidityPercent: 40,
            description: "Sunny",
            iconCode: "01d"
        )
    }

    func fetchIconData(code: String) async throws -> Data {
        Data()
    }
}

@MainActor
private final class MockLocationProvider: LocationProviderProtocol {
    var permissionStatus: CLAuthorizationStatus

    init(permissionStatus: CLAuthorizationStatus = .notDetermined) {
        self.permissionStatus = permissionStatus
    }

    func requestWhenInUsePermission() async { }

    func requestSingleLocation() async throws -> Coordinate {
        Coordinate(latitude: 32.7767, longitude: -96.7970)
    }
}

private final class MockCityStore: CityStoreProtocol {
    private(set) var savedCity: String?
    private var storedCity: String?

    init(lastCity: String? = nil) {
        self.storedCity = lastCity
    }

    func saveLastCity(_ city: String) {
        savedCity = city
        storedCity = city
    }

    func lastCity() -> String? {
        storedCity
    }
}
