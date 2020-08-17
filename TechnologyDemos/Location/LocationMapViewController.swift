//
//  LocationMapViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class LocationMapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    // MARK: - Properties
    private let SimplePinIdent = "SimplePinIdent"
    var managedObjectContext: NSManagedObjectContext? = nil

    private let locationManager = LocationManager.shared

    @IBOutlet weak var mapView: MKMapView!

    private var _mapEvents = [GeoEvent]()
    private var mapEvents: [GeoEvent] {
        get {
            mapEventsLock.lock()
            let events = _mapEvents
            mapEventsLock.unlock()
            return events
        }
        set {
            mapEventsLock.lock()
            _mapEvents = newValue
            mapEventsLock.unlock()
        }
    }

    private var mapEventsLock = NSLock()
    private let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short

        loadAllEvents()
        showPinsOnMap()

        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        locationManager.delegate = self
    }

    deinit {
        log.appendLog("de-init", eventSource: .locationViewController)
    }

    // MARK: -

    private func loadAllEvents() {
        if let allEvents = fetchedResultsController.sections![0].objects as? [GeoEvent] {
            print("Events retrieved = \(allEvents.count)")
            navigationItem.prompt = "Events retrieved = \(allEvents.count)"
            self.mapEvents = allEvents
        }
    }

    private func showPinsOnMap() {
        mapView.removeAnnotations(mapView.annotations)

        var viewRegion: MKCoordinateRegion?

        let annotations = mapEvents.compactMap { geoEvent -> GeoAnnotation? in
            guard let timeStamp = geoEvent.timestamp else { return nil }

            let timeString = dateFormatter.string(from: timeStamp)
            let coordinate = CLLocationCoordinate2DMake(geoEvent.latitude, geoEvent.longitude)
            let annotation = GeoAnnotation(coordinate: coordinate)

            annotation.title = "\(timeString) \(geoEvent.speedMPH)"

            let centerCoordinates = CLLocationCoordinate2DMake(
                geoEvent.latitude,
                geoEvent.longitude
            )

            let meters_per_mile = 1609.3

            let radius: CLLocationDistance = 15 * meters_per_mile
            viewRegion = MKCoordinateRegion(
                center: centerCoordinates,
                latitudinalMeters: radius,
                longitudinalMeters: radius
            )

            return annotation
        }

        mapView.addAnnotations(annotations)

        if let viewRegion = viewRegion {
            mapView.setRegion(viewRegion, animated: true)
        }
    }

    // MARK: - Fetched results controller

    private var fetchedResultsController: NSFetchedResultsController<GeoEvent> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<GeoEvent> = GeoEvent.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

        fetchRequest.sortDescriptors = [sortDescriptor]

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return _fetchedResultsController!
    }

    private var _fetchedResultsController: NSFetchedResultsController<GeoEvent>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //TODO: Lock isn't required with getter/setter locking the events.
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let newEvent = anObject as! GeoEvent
        switch type {
            case .insert:
                mapEvents.insert(newEvent, at: newIndexPath!.row)
            case .delete:
                mapEvents.remove(at: indexPath!.row)
            case .update:
                _ = mapEvents.remove(at: indexPath!.row)
                mapEvents.insert(newEvent, at: indexPath!.row)
            case .move:
                let orignalEvent = mapEvents.remove(at: indexPath!.row)
                mapEvents.insert(orignalEvent, at: newIndexPath!.row)

            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //TODO: Reload pins here?
        log.appendLog("TODO controllerDidChangeContent but not handled.", eventSource: .locationViewController)
    }

    //MARK: - Mapview methods

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard view.annotation is GeoAnnotation
        else { return }

        log.appendLog("TODO clicked annotation but no info to present.", eventSource: .locationViewController)
        //performSegue(withIdentifier: "presentWebInfo", sender: self)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard
            let quakeView = view as? GeoAnnotationView,
            let annotation = quakeView.annotation as? GeoAnnotation
        else { return }

        print("didSelect view \(annotation.title ?? "No title")")
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let geoAnnotation = annotation as? GeoAnnotation else { return nil }

        let customPinview: GeoAnnotationView = {
            mapView.dequeueReusableAnnotationView(withIdentifier: SimplePinIdent) as? GeoAnnotationView
            ?? GeoAnnotationView(annotation: geoAnnotation, reuseIdentifier: SimplePinIdent)
        }()
        customPinview.annotation = geoAnnotation

        return customPinview
    }

    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        log.appendLog("\(error.localizedDescription)", eventSource: .coreMotionViewController)
    }

    //MARK: - Map Functionality

    private func zoomToFitMapAnnotations(mapView: MKMapView) {
        guard !mapView.annotations.isEmpty else { return }

        // this looks strange
        mapView.showAnnotations(mapView.annotations, animated: true)

        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)

        mapView.annotations.forEach { annotation in
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude)

            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude)
        }

        let centerCoordinate = CLLocationCoordinate2DMake(
            (topLeftCoord.latitude + bottomRightCoord.latitude) / 2,
            (topLeftCoord.longitude + bottomRightCoord.longitude) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.4,
            longitudeDelta: fabs(topLeftCoord.longitude - bottomRightCoord.longitude) * 1.4
        )
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)

        mapView.setRegion(region, animated: true)
    }
}

extension LocationMapViewController: LocationManagerDelegate {
    func update(with location: CLLocation) {
        //The coordinator should auto update this.
    }
}
