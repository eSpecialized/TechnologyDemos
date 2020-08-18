//
//  CoreDataController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/18/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

public final class CoreDataController: NSObject {
    //MARK: - Properties

    private let managedObjectContext: NSManagedObjectContext
    public var tripEvent: TripEvent?

    //MARK: - Initialization

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    //MARK: - Support Methods

    @discardableResult
    public func createTripEvent(named: String) -> TripEvent {
        let newTripEvent = TripEvent(context: managedObjectContext)

        newTripEvent.tripName = named
        newTripEvent.timeStamp = Date()

        tripEvent = newTripEvent

        saveContext()

        return newTripEvent
    }

    @discardableResult
    public func createGeoEvent(location: CLLocation) -> GeoEvent {
        let coordinate = location.coordinate

        let speedMeasure = Measurement<UnitSpeed>(value: location.speed, unit: .metersPerSecond)

        let newGeoEvent = GeoEvent(context: managedObjectContext)

        newGeoEvent.timestamp = Date()
        newGeoEvent.latitude = coordinate.latitude
        newGeoEvent.longitude = coordinate.longitude
        newGeoEvent.tripevent = tripEvent

        newGeoEvent.speedMPH = speedMeasure.converted(to: .milesPerHour).value

        if let tripEvent = tripEvent {
            let mutableGeoEvents = tripEvent.mutableSetValue(forKey: "geoevents")
            mutableGeoEvents.addObjects(from: [newGeoEvent])
        }

        saveContext()

        return newGeoEvent
    }

    public func getGeoEvents(for tripEvent: TripEvent) -> [GeoEvent]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GeoEvent")
        let predicate = NSPredicate(format: "tripevent == %@", tripEvent)
        fetchRequest.relationshipKeyPathsForPrefetching = ["TripEvent"]
        fetchRequest.predicate = predicate

        do {
            guard let records = try managedObjectContext.fetch(fetchRequest) as? [GeoEvent] else { return nil }

            print("getGeoEvents fetched \(records.count)" )
            return records
        } catch {
            let nserror = error as NSError
            let errorString = "Unresolved error \(nserror), \(nserror.userInfo)"
            log.appendLog(errorString, eventSource: .coreDataController)
            assertionFailure(errorString)
        }

        return nil
    }

    public func getTripEvents() -> [TripEvent]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TripEvent")

        do {
            guard let records = try managedObjectContext.fetch(fetchRequest) as? [TripEvent] else { return nil }

            let names = records.compactMap( { $0.tripName } )
            print("getGeoEvents fetched \(records.count) [\(names)]" )

            return records
        } catch {
            let nserror = error as NSError
            let errorString = "Unresolved error \(nserror), \(nserror.userInfo)"
            log.appendLog(errorString, eventSource: .coreDataController)
            assertionFailure(errorString)
        }

        return nil
    }

    /// This removes all core data elements for TripEvent and GeoEvent
    public func clearAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GeoEvent")
        let fetchRequestTrips = NSFetchRequest<NSFetchRequestResult>(entityName: "TripEvent")

        do {
            if let recordsGeoEvent = try managedObjectContext.fetch(fetchRequest) as? [GeoEvent] {
                print("clearAll recordsGeoEvent fetched \(recordsGeoEvent.count)" )
                recordsGeoEvent.forEach { event in
                    if let tripEvent = event.tripevent {
                        let geoEvents = tripEvent.mutableSetValue(forKey: "geoevents")
                        geoEvents.remove(event)
                    }

                    managedObjectContext.delete(event)
                }
            }

            if let recordsTripEvent = try managedObjectContext.fetch(fetchRequestTrips) as? [GeoEvent] {
                print("clearAll recordsTripEvent fetched \(recordsTripEvent.count)" )
                recordsTripEvent.forEach { event in
                    managedObjectContext.delete(event)
                }
            }

            saveContext()
        } catch {
            let nserror = error as NSError
            let errorString = "Unresolved error \(nserror), \(nserror.userInfo)"
            log.appendLog(errorString, eventSource: .coreDataController)
            assertionFailure(errorString)
        }
    }

    private func saveContext() {
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            let errorString = "Unresolved error \(nserror), \(nserror.userInfo)"
            log.appendLog(errorString, eventSource: .coreDataController)
            assertionFailure(errorString)
        }
    }
}
