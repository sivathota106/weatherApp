# weatherApp

iOS weather app with **MVVM-C** using **UIKit + SwiftUI** (no storyboards), powered by the OpenWeather Geocoding and Weather APIs.

## Features

- Search weather by US city name
- Location-first startup weather (with permission)
- Auto-load last searched city
- Weather icon download with memory + disk caching
- Adaptive UI for compact and regular size classes
- Unit tests for Model and ViewModel layers

## Requirements

- Xcode 26+
- iOS 26+ simulator/device target
- OpenWeather API key

## Setup

1. Open `NewWeatherAPP/NetworkModule.swift`
2. Set your API key in `AppDependencies`:

```swift
static let apiKey = "YOUR_OPENWEATHER_API_KEY"
```

3. Open `NewWeatherAPP.xcodeproj` in Xcode
4. Build and run the `NewWeatherAPP` scheme

## Architecture

- **Coordinator:** `AppCoordinator`
- **ViewModel:** `WeatherViewModel`
- **Services:** `OpenWeatherService`, `CoreLocationProvider`, `LastCityStore`, `IconCache`
- **View:** `WeatherRootView`

## Tests

Run tests with:

```bash
xcodebuild test -project "NewWeatherAPP.xcodeproj" -scheme "NewWeatherAPP" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:NewWeatherAPPTests
```
