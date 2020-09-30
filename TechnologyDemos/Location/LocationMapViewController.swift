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

final class LocationMapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, ManagedObjectProtocol {
    // MARK: - Properties

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

    private let SimplePinIdent = "SimplePinIdent"

    @objc
    private let locationManager = LocationManager.shared
    private let dateFormatter = DateFormatter()
    private var homeLocationObserver: NSKeyValueObservation?

    var managedObjectContext: NSManagedObjectContext? = nil

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short

        loadAllEvents()
        showPinsOnMap()

        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        locationManager.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset Home", style: .plain, target: self, action: #selector(resetHome))
        if locationManager.homeLocation != nil {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }

        homeLocationObserver = observe(
            \.locationManager.homeLocation,
            options: [.old, .new]) { object, change in
                if let _ = change.newValue {
                    print("new Home Location")
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if locationManager.getAuthorization() {
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        homeLocationObserver = nil
    }

    deinit {
        mapView.annotations.forEach { self.mapView.removeAnnotation($0) }
        mapView.delegate = nil

        log.appendLog("de-init", eventSource: .locationMapViewController)
    }

    // MARK: - Support Methods

    @objc
    private func resetHome() {
        locationManager.homeLocation = nil
        navigationItem.rightBarButtonItem?.isEnabled = false
        locationManager.stop()
        locationManager.start()
    }

    private func loadAllEvents() {
        if let allEvents = fetchedResultsController.sections![0].objects as? [GeoEvent] {
            print("Events retrieved = \(allEvents.count)")
            navigationItem.prompt = "Events Count = \(allEvents.count)"
            self.mapEvents = allEvents
        }
    }

    private func showPinsOnMap() {
        mapView.removeAnnotations(mapView.annotations)

        var viewRegion: MKCoordinateRegion?

        let annotations = mapEvents.compactMap { geoEvent -> GeoAnnotation? in
            guard let (annotation, viewRegionOut) = self.buildGeoAnnotation(with: geoEvent) else {
               return nil
            }

            viewRegion = viewRegionOut

            return annotation
        }

        mapView.addAnnotations(annotations)

        if let (annotation, homeViewRegion) = buildHomeAnnotation() {
            mapView.addAnnotation(annotation)

            // Only Set viewRegion if one wasn't set
            if viewRegion == nil {
                viewRegion = homeViewRegion
            }
        }

        if let viewRegion = viewRegion {
            mapView.setRegion(viewRegion, animated: true)
        }
    }

    func buildGeoAnnotation(with geoEvent: GeoEvent) -> (annotation: GeoAnnotation, viewRegion: MKCoordinateRegion)? {
        guard let timeStamp = geoEvent.timestamp else { return nil }

        let timeString = dateFormatter.string(from: timeStamp)
        let coordinate = CLLocationCoordinate2DMake(geoEvent.latitude, geoEvent.longitude)
        let annotation = GeoAnnotation(coordinate: coordinate)

        let mph = String(format: "mph: %.1f", geoEvent.speedMPH)

        annotation.title = "\(timeString) \(mph)"

        let centerCoordinates = CLLocationCoordinate2DMake(
            geoEvent.latitude,
            geoEvent.longitude
        )

        let meters_per_mile = 1609.3

        let radius: CLLocationDistance = 15 * meters_per_mile
        let viewRegion = MKCoordinateRegion(
            center: centerCoordinates,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )

        return (annotation, viewRegion)
    }

    func buildHomeAnnotation() -> (annotation: GeoAnnotation, viewRegion: MKCoordinateRegion)? {
        guard let homeLocation = locationManager.homeLocation else { return nil }

        let coordinate = CLLocationCoordinate2DMake(homeLocation.coordinate.latitude, homeLocation.coordinate.longitude)
        let annotation = GeoAnnotation(coordinate: coordinate)

        annotation.title = "Home"

        let centerCoordinates = CLLocationCoordinate2DMake(
            coordinate.latitude,
            coordinate.longitude
        )

        let meters_per_mile = 1609.3

        let radius: CLLocationDistance = 15 * meters_per_mile
        let viewRegion = MKCoordinateRegion(
            center: centerCoordinates,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )

        return (annotation, viewRegion)
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
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let newEvent = anObject as! GeoEvent
        let allAnnotations = mapView.annotations

        switch type {
            case .insert:
                log.appendLog("insert", eventSource: .locationMapViewController)
                mapEvents.insert(newEvent, at: newIndexPath!.row)
                if let (newAnnotation, mapViewRegion) = buildGeoAnnotation(with: newEvent) {
                    mapView.addAnnotation(newAnnotation)
                    mapView.setRegion(mapViewRegion, animated: true)
                }

                navigationItem.prompt = "Events Count = \(mapEvents.count)"

            case .delete:
                log.appendLog("delete", eventSource: .locationMapViewController)
                let existingAnnotation = allAnnotations[indexPath!.row]
                _ = mapEvents.remove(at: indexPath!.row)
                mapView.removeAnnotation(existingAnnotation)

            case .update:
                _ = mapEvents.remove(at: indexPath!.row)
                let existingAnnotation = allAnnotations[indexPath!.row]
                mapView.removeAnnotation(existingAnnotation)

                mapEvents.insert(newEvent, at: indexPath!.row)
                if let (newAnnotation, _) = buildGeoAnnotation(with: newEvent) {
                    mapView.addAnnotation(newAnnotation)
                }

            case .move:
                let orignalEvent = mapEvents.remove(at: indexPath!.row)
                mapEvents.insert(orignalEvent, at: newIndexPath!.row)

            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        log.appendLog("TODO controllerDidChangeContent but not handled.", eventSource: .locationMapViewController)
    }

    //MARK: - Mapview Delegate methods

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard view.annotation is GeoAnnotation
        else { return }

        log.appendLog("TODO clicked annotation but no info to present.", eventSource: .locationMapViewController)
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

//MARK: - LocationManagerDelegate

extension LocationMapViewController: LocationManagerDelegate {
    func update(with location: CLLocation) {
        //The coordinator should auto update this.
    }
}
