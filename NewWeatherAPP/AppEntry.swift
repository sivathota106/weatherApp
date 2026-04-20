//
//  AppEntry.swift
//  NewWeatherAPP
//
//  Created by Siva Thota on 4/20/26.
//

import SwiftUI
import UIKit

@main
struct NewWeatherAPPApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorContainerView()
        }
    }
}

struct CoordinatorContainerView: UIViewControllerRepresentable {
    @MainActor
    func makeUIViewController(context: Context) -> UINavigationController {
        let coordinator = AppCoordinator(dependencies: AppDependencies.makeDefault())
        coordinator.start()
        context.coordinator.appCoordinator = coordinator
        return coordinator.rootViewController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No-op.
    }

    func makeCoordinator() -> CoordinatorHolder {
        CoordinatorHolder()
    }

    final class CoordinatorHolder {
        var appCoordinator: AppCoordinator?
    }
}
