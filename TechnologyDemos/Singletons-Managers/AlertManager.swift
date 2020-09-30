//
//  AlertManager.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/24/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import UIKit

final class AlertManager {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    //Allows showing alert on any screen other than if the CoreMotionViewController is on screen.
    func showAlertExceededGForce(_ messageText: String?) {
        guard
            let topViewController = navigationController.topViewController,
            topViewController.isViewLoaded,
            topViewController.view.window != nil
        else {
            assertionFailure("Unable to display `showAlertExceededGForce`")
            return
        }

        let alert = UIAlertController(title: "Max G's Exceeded", message: messageText, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)

        topViewController.present(alert, animated: true, completion: nil)
    }

    func sendLocalNotification(title: String, body: String) {

        var notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = UNNotificationSound.default

        let triggerInHalfSecond = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        let noteRequest = UNNotificationRequest(
            identifier: "TechnologyDemo",
            content: notification,
            trigger: triggerInHalfSecond
        )


        UNUserNotificationCenter.current().add(noteRequest) { errors in
            if let errors = errors {
                log.appendLog("Error with local notification \(errors.localizedDescription)", eventSource: .alertManager)
            }
        }
    }
}
