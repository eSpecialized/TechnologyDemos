//
//  SceneDelegate.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    var alertManager: AlertManager!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard
            let window = window,
            let navigationController = window.rootViewController as? UINavigationController,
            let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        else { return }

        let controller = navigationController.topViewController as! MasterViewController
        let context = appDelegate.persistentContainer.viewContext

        controller.managedObjectContext = context

        let coreDataController = CoreDataController(managedObjectContext: context)
        let locationManager = LocationManager.shared
        locationManager.managedObjectContext = context
        locationManager.coreDataController = coreDataController

        alertManager = AlertManager(navigationController: navigationController)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        CoreMotionManager.shared.start()
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        CoreMotionManager.shared.start()
    }
}
