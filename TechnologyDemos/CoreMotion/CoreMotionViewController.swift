//
//  CoreMotionViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import UIKit

final class CoreMotionViewController: UIViewController {
    // MARK: - Properties

    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var xaccelLabel: UILabel!
    @IBOutlet weak var yaccelLabel: UILabel!
    @IBOutlet weak var zaccelLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var warningsLabel: UILabel!
    @IBOutlet weak var backgroundSwitch: UISwitch!

    private var warningResetTimer: Timer?
    private var updateAccelerometerHandler:  ((AccelerometerModel) -> ())?
    private var model = AccelerometerModel(xAccel: 0, yAccel: 0, zAccel: 0)

    let motion = CoreMotionManager.shared

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        warningsLabel.text = ""
        warningsLabel.textColor = .systemRed

        log.appendLog("viewDidLoad", eventSource: .coreMotionViewController)

        backgroundSwitch.setOn(motion.backgroundUpdates, animated: true)

        updateAccelerometerHandler = { [weak self] model in
            self?.updateUI(with: model)
        }
        motion.updateAccelerometerHandler = updateAccelerometerHandler

        motion.start()

        logView.text = log.getLog()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateAccelerometerHandler = nil
    }

    deinit {
        log.appendLog("de-init", eventSource: .coreMotionViewController)

        if !backgroundSwitch.isOn {
            motion.stop()
        }
    }

    // MARK: - Support Methods

    @IBAction func backgroundSwitchChanged(_ sender: Any) {
        motion.backgroundUpdates = backgroundSwitch.isOn
        motion.stop()
        motion.start()
    }

    private func updateUI(with model: AccelerometerModel) {
        guard Thread.isMainThread
        else {
            DispatchQueue.main.async {
                self.updateUI(with: model)
            }
            return
        }

        let limits = 3.0
        let oldModel = self.model
        self.model = model

        let forceX = fabs(oldModel.xAccel) - fabs(model.xAccel)
        let forceY = fabs(oldModel.yAccel) - fabs(model.yAccel)
        let forceZ = fabs(oldModel.zAccel) - fabs(model.zAccel)

        if forceX > limits || forceY > limits || forceZ > limits {
            var forceText = ""
            if forceX > limits {
                forceText = String(format:"X %.3f", forceX)
            }

            if forceY > limits {
                forceText = String(format:"Y %.3f", forceY)
            }

            if forceZ > limits {
                forceText = String(format:"Z %.3f", forceZ)
            }

            warningsLabel.text = "Force exceeded limits \(forceText)"
            warningResetTimer?.invalidate()
            warningResetTimer = nil

            DispatchQueue.main.async { [weak self] in
                self?.warningResetTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    self?.warningsLabel.text = ""
                }
            }
        }

        xaccelLabel.text = "xAccel \(model.xAccel)"
        yaccelLabel.text = "yAccel \(model.yAccel)"
        zaccelLabel.text = "zAccel \(model.zAccel)"

        logView.text = log.getLog()

        let maxModel = motion.maxModel

        let maxText = """
        MaxX = \(maxModel.xAccel)
        MaxY = \(maxModel.yAccel)
        MaxZ = \(maxModel.zAccel)
        """

        maxLabel.text = maxText
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
