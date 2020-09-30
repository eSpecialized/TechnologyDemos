//
//  CoreMotionSingleton.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit

protocol CoreMotionManagerDelegate: class {
    func updatedDateAvailable(sample: CoreMotionManager.SampleData)
}

/// A singleton to Manage all CoreMotion events.
public final class CoreMotionManager {
    struct SampleData {
        let accelData: CMAccelerometerData
        let gyroData: CMGyroData
        let magnetometerData: CMMagnetometerData
        let motionData: CMDeviceMotion?
        let location: CLLocation?
    }

    // MARK: - Properties

    private let operationQueue: OperationQueue = {
        let newQueue = OperationQueue()
        newQueue.name = "Technology Demos Queue"
        newQueue.maxConcurrentOperationCount = 1
        newQueue.qualityOfService = .default
        return newQueue
    }()

    weak var delegate: CoreMotionManagerDelegate?
    private var motionActivityManager = CMMotionActivityManager()
    private(set) var lastActivity: CMMotionActivity?
    private(set) var lastActivityDescription = ""
    private var motionManager = CMMotionManager()
    private(set) var maxModel = AccelerometerModel.zero()

    public static var shared = CoreMotionManager()
    public var updateAccelerometerHandler: ((AccelerometerModel) -> ())?

    var samplesLock = NSLock()
    private var sampleListBacking = [SampleData]() //don't access directly, allow locking to work for you
    //use this in any accessible thread
    var samplesList: [SampleData] {
        get {
            samplesLock.lock()
            let returnValue = sampleListBacking
            samplesLock.unlock()
            return returnValue
        }
        set {
            samplesLock.lock()
            sampleListBacking = newValue
            samplesLock.unlock()
        }
    }

    var indexOfSample = 0
    let maxSamples = 200

    var sampleCounter = 0
    var previous100SampleDate = Date()

    // MARK: - Initializers

    public init() {
        log.appendLog("start", eventSource: .motionAccel)
    }

    // MARK: - Support Methods

    /// Starts Core Motion Updates, updates are through the `updateAccelerometerHandler`
    public func start() {
        if motionManager.isAccelerometerAvailable {
            log.appendLog("Accelerometer Is Available, starting updates", eventSource: .motionAccel)
            motionManager.startGyroUpdates()
            motionManager.startMagnetometerUpdates()
            motionManager.startAccelerometerUpdates()
            motionManager.startDeviceMotionUpdates()

            motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motionData, error in
                self?.handleUpdates()
            }
        } else {
            log.appendLog("Accelerometer unavailable", eventSource: .motionAccel)
        }

        previous100SampleDate = Date()


        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yearFromNow = today.addingTimeInterval(86400 * 365)

        motionActivityManager.queryActivityStarting(from: today, to: yearFromNow, to: .main) { [weak self] activity, error in
            if let error = error as NSError?, error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                print("motionActivityManager NotAuthorized")
            } else {
                self?.startActivityUpdates()
            }
        }
    }

    private func startActivityUpdates() {
        motionActivityManager.startActivityUpdates(to: .main, withHandler: { [weak self] activity in
            guard let activity = activity else { return }

            self?.lastActivity = activity

            var stationary = "moving"
            if activity.stationary {
                stationary = "stationary"
            }


            var confidence = "- confidence = "
            switch activity.confidence.rawValue {
                case 0:
                    confidence += "Low"
                case 1:
                    confidence += "Medium"
                case 2:
                    confidence += "High"
                default:
                    confidence += "Unknown = \(activity.confidence.rawValue) "
            }

            var activityText = ""
            if activity.automotive {
                activityText = "automotive \(stationary) \(confidence)"
            } else if activity.walking {
                activityText = "walking \(stationary) \(confidence)"
            } else if activity.unknown {
                activityText = "unknown \(stationary) \(confidence)"
            } else if activity.cycling {
                activityText = "cycling \(stationary) \(confidence)"
            } else if activity.running {
                activityText = "running \(stationary) \(confidence)"
            } else if activity.stationary {
                activityText = "stationary \(confidence)"
            }

            self?.lastActivityDescription = activityText
        })
    }

    /// Stops Core Motion Updates. Resets the `updateAccelerometerHandler` to nil
    public func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()

        motionActivityManager.stopActivityUpdates()
        updateAccelerometerHandler = nil
    }

    // MARK: - Private methods and handling

    private func handleUpdates() {
        guard
            let accelData = motionManager.accelerometerData,
            let gyroData = motionManager.gyroData,
            let magnetometerData = motionManager.magnetometerData
        else {
            print("Invalid Sample data")
            return
        }

        let sample = SampleData(
            accelData: accelData,
            gyroData: gyroData,
            magnetometerData: magnetometerData,
            motionData: motionManager.deviceMotion,
            location: LocationManager.shared.lastLocation
        )

        sampleCounter += 1

        if sampleCounter % 100 == 0 {
            delegate?.updatedDateAvailable(sample: sample)

            sampleCounter = 0
            let timeInterval = previous100SampleDate.timeIntervalSinceNow * 100_000 * -1
            print("+ 100hz samples at \(Date().debugDescription) - \(String(format: "%.2f ms", timeInterval))")
        }

        previous100SampleDate = Date()


        if samplesList.count < maxSamples {
            //crash here when concurrent threads > 1
            samplesList.append(sample)
        } else {
            //crash here when concurrent threads > 1
            samplesList[indexOfSample] = sample
            indexOfSample += 1
            if indexOfSample >= maxSamples {
                indexOfSample = 0
            }
        }

        handleAccelerometerUpdates(accelData)
    }

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

        guard let updateAccelerometerHandler = updateAccelerometerHandler
        else {
//            DispatchQueue.main.async {
//                if
//                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                    let sceneDelegate = windowScene.delegate as? SceneDelegate,
//                    let alertManager = sceneDelegate.alertManager {
//                    alertManager.showAlertExceededGForce(nil)
//                }
//            }
            
            return
        }

        let model = AccelerometerModel(xAccel: accelData.acceleration.x, yAccel: accelData.acceleration.y, zAccel: accelData.acceleration.z)
        updateAccelerometerHandler(model)
    }
}
