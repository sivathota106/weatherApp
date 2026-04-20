//
//  Untitled.swift
//  NewWeatherAPP
//
//  Created by Siva Thota on 4/20/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

struct WeatherRootView: View {
    @StateObject private var viewModel: WeatherViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: WeatherViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .navigationTitle("Weather")
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 16) {
                searchPanel
                weatherPanel
            }
            .padding()
        }
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            searchPanel
                .frame(maxWidth: 360)
            weatherPanel
                .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search US City")
                .font(.headline)
            TextField("Example: Atlanta", text: $viewModel.cityInput)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Button(action: viewModel.searchTapped) {
                Text("Get Weather")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var weatherPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isLoading {
                ProgressView("Loading weather...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let weather = viewModel.weather {
                Text("\(weather.cityName), \(weather.country)")
                    .font(.title2.bold())
                if let weatherIcon = viewModel.weatherIcon {
                    Image(uiImage: weatherIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .accessibilityLabel(Text("Weather icon"))
                }
                Text(weather.description)
                    .font(.headline)
                Text(weather.temperatureText)
                    .font(.system(size: 42, weight: .semibold))
                Text(weather.feelsLikeText)
                Text(weather.humidityText)
            } else {
                Text("Search for a city to see weather details.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
