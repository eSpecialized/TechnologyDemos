//
//  LocationManager.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import CoreLocation
import Foundation

/// LocationManagerDelegate call back for update when location changes.
public protocol LocationManagerDelegate: class {
    func update(with location: CLLocation)
}

/// Location manager for handling all CLLocationManager setup, location updates and more.
public final class LocationManager: NSObject {
    // MARK: - Helper Types

    //Struct for storing home location in NSUserDefaults easily.
    private struct Location2D: Codable  {
        let latitude: Double
        let longitude: Double
    }

    // MARK: - Properties

    private var discardCount = 0
    private var locationManager = CLLocationManager()
    private var locationUpdating = false
    private var lastLocation: CLLocation?
    @objc dynamic var homeLocation: CLLocation?

    public static var shared = LocationManager()

    public var managedObjectContext: NSManagedObjectContext? = nil {
        didSet {
            if let managedObjectContext = managedObjectContext {
                coreDataController = CoreDataController(managedObjectContext: managedObjectContext)
            }
        }
    }

    public var coreDataController: CoreDataController?

    public weak var delegate: LocationManagerDelegate?

    public var isLocationUpdating: Bool {
        return locationUpdating
    }

    // MARK: - Initialization

    public override init() {
        super.init()

        locationManager.delegate = self

        //for lower power consumption.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLHeadingFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true

        let userDefaults = UserDefaults.standard
        let decoder = JSONDecoder()
        do {
            guard let locationData = userDefaults.object(forKey: "homeLocation") as? Data
            else {
                log.appendLog("Unable to load home locstion data", eventSource: .location)
                return
            }

            let homeLocation2D = try decoder.decode(Location2D.self, from: locationData)

            homeLocation = CLLocation(latitude: homeLocation2D.latitude, longitude: homeLocation2D.longitude)
        } catch {
            log.appendLog("\(error)", eventSource: .location)
        }
    }

    // MARK: - Support Methods

    /// If we were already authorized, return true so we can call startup()
    public func getAuthorization() -> Bool {
        guard
            CLLocationManager.authorizationStatus() != .authorizedAlways ||
            CLLocationManager.authorizationStatus() != .authorizedWhenInUse
        else {
            return true
        }

        locationManager.requestAlwaysAuthorization()
        return false
    }

    /// Starts Location Tracking
    public func start() {
        guard
            !locationUpdating,
            CLLocationManager.authorizationStatus() == .authorizedAlways ||
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse
        else {
            return
        }

        locationManager.startUpdatingLocation()
        locationUpdating = true
        log.appendLog("startUpdatingLocation", eventSource: .location)
    }

    /// Stops location Tracking
    public func stop() {
        locationManager.stopUpdatingLocation()
        locationUpdating = false
        log.appendLog("stopUpdatingLocation", eventSource: .location)
    }

    private func addHomeLocation(_ location: CLLocation) {
        let userDefaults = UserDefaults.standard
        let location2d = Location2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let encoder = JSONEncoder()
        do {
            let encodedLocation = try encoder.encode(location2d)
            userDefaults.set(encodedLocation, forKey: "homeLocation")
            userDefaults.synchronize()
            homeLocation = location
        } catch {
            print(error)
        }
    }
}

// MARK: - Location Manager delegates

extension LocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }

        //if there is low accuracy or the timestemp has been to old, discard the reading
        guard firstLocation.horizontalAccuracy < 100, Date().timeIntervalSince(firstLocation.timestamp) < 60.0 else {
                discardCount += 1
                log.appendLog("Discard Location Count \(discardCount) horizontalAccuracy = \(firstLocation.horizontalAccuracy)", eventSource: .location)
                return
        }

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.update(with: firstLocation)
        }

        let coordinate = firstLocation.coordinate
        let locationText = "Lat:\(coordinate.latitude) Long:\(coordinate.longitude)"
        let speedMeasure = Measurement<UnitSpeed>(value: firstLocation.speed, unit: .metersPerSecond).converted(to: .milesPerHour)
        let mphValue = fabs(speedMeasure.value)
        let mphString = String(format: "%.1f", mphValue)
        log.appendLog("didUpdateLocations \(locationText) speed MPH = \(mphString)", eventSource: .location)

        let homeDistanceInMeters = fabs(homeLocation?.distance(from: firstLocation) ?? 0.0)

        //Only record if the distance from Home is 200 or more meters.
        if fabs(homeDistanceInMeters) > 200.0 && mphValue > 1.0 {
            coreDataController?.createGeoEvent(location: firstLocation)
        } else {
            log.appendLog("No significant distance travelled. Distance from home = \(homeDistanceInMeters) meters", eventSource: .location)
        }

        if homeLocation == nil {
            addHomeLocation(firstLocation)
            coreDataController?.createGeoEvent(location: firstLocation)
        }

        lastLocation = firstLocation
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let statusText: String = {
            switch status {
                case .authorizedAlways:
                return "authorizedAlways"
                case .authorizedWhenInUse:
                return "authorizedWhenInUse"
                case .denied:
                return "denied"
                case .notDetermined:
                return "notDetermined"
                case .restricted:
                return "restricted"
                @unknown default:
                return "unknown"
            }
        }()

        log.appendLog("didChangeAuthorization \(statusText)", eventSource: .location)

        //try to startup
        start()
    }
}
