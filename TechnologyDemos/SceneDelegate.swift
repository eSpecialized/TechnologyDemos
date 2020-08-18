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


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window else { return }
        guard let navigationController = window.rootViewController as? UINavigationController else { return }

        let controller = navigationController.topViewController as! MasterViewController
        controller.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext

        let locationManager = LocationManager.shared
        locationManager.managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
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

