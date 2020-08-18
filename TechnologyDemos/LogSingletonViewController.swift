//
//  LogSingletonViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import UIKit

final class LogSingletonViewController: UIViewController, LogSingletonDelegate {
    // MARK: - Properties

    @IBOutlet weak var logView: UITextView!

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        logView.text = log.getLog()
        log.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom()
    }

    deinit {
        log.appendLog("de-init LogSingletonViewController", eventSource: .general)
    }

    // MARK: - Supporting Methods

    private func scrollToBottom() {
        guard !logView.text.isEmpty else { return }

        let bottom = NSRange(location: logView.text.count - 1, length: 1)
        UIView.animate(withDuration: 1) {
            self.logView.scrollRangeToVisible(bottom)
        }
    }

    //MARK: - LogSingletonDelegate

    func update() {
        guard UIApplication.shared.applicationState == .active else { return }

        logView.text = log.getLog()
        scrollToBottom()
    }
}
