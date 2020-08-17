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

protocol LocationManagerDelegate: class {
    func update(with location: CLLocation)
}

class LocationManager: NSObject, NSFetchedResultsControllerDelegate {
    static var shared = LocationManager()

    var managedObjectContext: NSManagedObjectContext? = nil

    private var locationManager = CLLocationManager()
    private var locationUpdating = false
    private var _lastLocation: CLLocation?
    weak var delegate: LocationManagerDelegate?

    var isLocationUpdating: Bool {
        return locationUpdating
    }

    override init() {
        super.init()

        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        locationManager.allowsBackgroundLocationUpdates = true
    }

    func start() {
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

    func stop() {
        locationManager.stopUpdatingLocation()
        locationUpdating = false
        log.appendLog("stopUpdatingLocation", eventSource: .location)
    }

    private var fetchedResultsController: NSFetchedResultsController<GeoEvent> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<GeoEvent> = GeoEvent.fetchRequest()

        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

        fetchRequest.sortDescriptors = [sortDescriptor]

        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let nserror = error as NSError
            assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return _fetchedResultsController!
    }

    private var _fetchedResultsController: NSFetchedResultsController<GeoEvent>? = nil
}

// MARK: - Location Manager delegates

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }

        delegate?.update(with: firstLocation)

        let coordinate = firstLocation.coordinate

        let locationText = "Lat:\(coordinate.latitude) Long:\(coordinate.longitude)"

        // This firstLocation.speed is in meters per second.
        let speedMeasure = Measurement<UnitSpeed>(value: firstLocation.speed, unit: .metersPerSecond)

        log.appendLog("didUpdateLocations \(locationText) speed MPH = \(speedMeasure.converted(to: .milesPerHour).value)", eventSource: .location)

//        if let lastLocation = _lastLocation {
//            let distanceInMeters = Measurement<UnitLength>(value: firstLocation.distance(from: lastLocation), unit: .meters)

            //I only want to record distances of travel so when pins are dropped on the map, they have some spacing.
            // also a speed greater than 3.0 meters (6.7mph) per second would be good.
//            if  distanceInMeters.value > 1 || lastLocation.speed > 3.0 {
                let context = self.fetchedResultsController.managedObjectContext
                let newGeoEvent = GeoEvent(context: context)

                newGeoEvent.timestamp = Date()
                newGeoEvent.latitude = coordinate.latitude
                newGeoEvent.longitude = coordinate.longitude

                newGeoEvent.speedMPH = speedMeasure.converted(to: .milesPerHour).value

                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    log.appendLog("Unresolved error \(nserror)", eventSource: .location)
                }
//            } else {
//                log.appendLog("No significant distance travelled", eventSource: .location)
//            }
//        }

        //this causes skipping the first location delivered.
        //for GPS warmups on some devices, we would want to skip a few readings actually.
        _lastLocation = firstLocation
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
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
