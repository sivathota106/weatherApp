//
//  AppCoordinator.swift
//  NewWeatherAPP
//
//  Created by Siva Thota on 4/20/26.
//

import SwiftUI
import UIKit

@MainActor
protocol Coordinator {
    func start()
}

@MainActor
final class AppCoordinator: Coordinator {
    let rootViewController: UINavigationController
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.rootViewController = UINavigationController()
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = WeatherViewModel(
            weatherService: dependencies.weatherService,
            locationProvider: dependencies.locationProvider,
            cityStore: dependencies.cityStore
        )

        let rootView = WeatherRootView(viewModel: viewModel)
        let rootController = UIHostingController(rootView: rootView)
        rootController.title = "Weather"
        rootViewController.setViewControllers([rootController], animated: false)
    }
}
