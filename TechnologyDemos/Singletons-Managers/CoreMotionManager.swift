//
//  CoreMotionSingleton.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation
import CoreMotion


/// A singleton to Manage all CoreMotion events.
public final class CoreMotionManager {
    // MARK: - Properties

    private var motionManager = CMMotionManager()
    private(set) var maxModel = AccelerometerModel.zero()

    public static var shared = CoreMotionManager()
    public var backgroundUpdates = true
    public var updateAccelerometerHandler: ((AccelerometerModel) -> ())?

    // MARK: - Initializers

    public init() {
        log.appendLog("start", eventSource: .motionAccel)
    }

    // MARK: - Support Methods

    /// Starts Core Motion Updates, updates are through the `updateAccelerometerHandler`
    public func start() {
        let operationQueue: OperationQueue = {
            if self.backgroundUpdates {
                let newQueue = OperationQueue()
                newQueue.name = "Background"
                newQueue.maxConcurrentOperationCount = 1
                log.appendLog("OperationQueue Serial Queue", eventSource: .motionAccel)
                return newQueue
            }

            return .main
        }()

        if motionManager.isAccelerometerAvailable {
            log.appendLog("Accelerometer Is Available, starting updates", eventSource: .motionAccel)
            motionManager.startAccelerometerUpdates(to: operationQueue) { accelData, errors in
                guard let accelData = accelData else {
                    if let errors = errors {
                        log.appendLog(errors.localizedDescription, eventSource: .motionAccel)
                    }
                    return
                }

                self.handleAccelerometerUpdates(accelData)
            }
        } else {
            log.appendLog("Accelerometer unavailable", eventSource: .motionAccel)
        }
    }

    /// Stops Core Motion Updates. Resets the `updateAccelerometerHandler` to nil
    public func stop() {
        motionManager.stopAccelerometerUpdates()
        updateAccelerometerHandler = nil
    }

    // MARK: - Private methods and handling

    private func handleAccelerometerUpdates(_ accelData: CMAccelerometerData) {

        var oldMaxModel = maxModel

        let xAbs = fabs(accelData.acceleration.x)
        let yAbs = fabs(accelData.acceleration.y)
        let zAbs = fabs(accelData.acceleration.z)

        if Double.maximum(oldMaxModel.xAccel, xAbs) > oldMaxModel.xAccel {
            oldMaxModel = AccelerometerModel(with: oldMaxModel, xAccel: xAbs)
        }

        if Double.maximum(oldMaxModel.yAccel, yAbs) > oldMaxModel.yAccel {
            oldMaxModel = AccelerometerModel(with: oldMaxModel, yAccel: yAbs)
        }

        if Double.maximum(oldMaxModel.zAccel, zAbs) > oldMaxModel.zAccel {
            oldMaxModel = AccelerometerModel(with: oldMaxModel, zAccel: zAbs)
        }

        if xAbs > 2.0 {
            log.appendLog("Extreme Xaccel Event \(xAbs)", eventSource: .motionAccel)
        }

        if yAbs > 2.0 {
            log.appendLog("Extreme Yaccel Event \(yAbs)", eventSource: .motionAccel)
        }

        if zAbs > 2.0 {
            log.appendLog("Extreme Zaccel Event \(zAbs)", eventSource: .motionAccel)
        }

        maxModel = oldMaxModel

        guard let updateAccelerometerHandler = updateAccelerometerHandler else { return }

        let model = AccelerometerModel(xAccel: accelData.acceleration.x, yAccel: accelData.acceleration.y, zAccel: accelData.acceleration.z)
        updateAccelerometerHandler(model)
    }
}
