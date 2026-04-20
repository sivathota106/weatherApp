//
//  WeatherViewModel.swift
//  NewWeatherAPP
//
//  Created by Jasmitha Moukthika on 4/20/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import CoreLocation

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var cityInput: String = ""
    @Published private(set) var weather: WeatherData?
    @Published private(set) var weatherIcon: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let weatherService: WeatherServiceProtocol
    private let locationProvider: LocationProviderProtocol
    private let cityStore: CityStoreProtocol

    init(weatherService: WeatherServiceProtocol, locationProvider: LocationProviderProtocol, cityStore: CityStoreProtocol) {
        self.weatherService = weatherService
        self.locationProvider = locationProvider
        self.cityStore = cityStore
    }

    func onAppear() {
        Task {
            await loadStartupWeather()
        }
    }

    func searchTapped() {
        let trimmed = cityInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a US city."
            return
        }
        Task {
            await loadWeatherForCity(trimmed)
        }
    }

    private func loadStartupWeather() async {
        clearError()
        await locationProvider.requestWhenInUsePermission()
        let status = locationProvider.permissionStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            await loadWeatherForCurrentLocation()
            return
        }
        if let city = cityStore.lastCity() {
            cityInput = city
            await loadWeatherForCity(city)
        }
    }

    private func loadWeatherForCurrentLocation() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let coordinate = try await locationProvider.requestSingleLocation()
            let weather = try await weatherService.fetchWeather(for: coordinate)
            self.weather = weather
            await refreshIcon(using: weather.iconCode)
        } catch {
            present(error: error)
        }
    }

    private func loadWeatherForCity(_ city: String) async {
        isLoading = true
        defer { isLoading = false }
        clearError()
        do {
            let location = try await weatherService.lookupUSCity(city)
            let weather = try await weatherService.fetchWeather(for: location.coordinate)
            self.weather = weather
            cityStore.saveLastCity(city)
            await refreshIcon(using: weather.iconCode)
        } catch {
            present(error: error)
        }
    }

    private func refreshIcon(using code: String) async {
        do {
            let data = try await weatherService.fetchIconData(code: code)
            weatherIcon = UIImage(data: data)
        } catch {
            weatherIcon = nil
        }
    }

    private func clearError() {
        errorMessage = nil
    }

    private func present(error: Error) {
        if let weatherError = error as? WeatherError {
            errorMessage = weatherError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
