//
//  LocationsTableViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import UIKit
import CoreLocation

final class LocationsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectProtocol {
    // MARK: - Properties

    private let dateFormatter = DateFormatter()
    private let locationManager = LocationManager.shared

    var managedObjectContext: NSManagedObjectContext? = nil

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true

        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short

        let addButton =  UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearAllEvents))
        navigationItem.rightBarButtonItem = addButton

        navigationItem.prompt = "TripName: []"

        locationManager.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if locationManager.getAuthorization() {
            locationManager.start()
        }

        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(true, animated: false)
    }

    deinit {
        log.appendLog("de-init", eventSource: .locationsTableViewController)
    }

    // MARK: - Support Methods

    private func updateUI() {
        if let coreDataController = locationManager.coreDataController {
            if let tripEvent = coreDataController.tripEvent, let tripName = tripEvent.tripName {
                let count = tripEvent.geoevents?.count ?? 0
                navigationItem.prompt = "TripName: [\(tripName)][\(count)]"
            } else {
                navigationItem.prompt = "TripName: [][\(fetchedResultsController.sections![0].objects?.count ?? 0)]"
            }
        }

        let filterTrip = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(tripFilter))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let tripName = UIBarButtonItem(title: "New Trip", style: .plain, target: self, action: #selector(addTripName))

        navigationController?.toolbar.setItems([filterTrip, flexibleSpace, tripName], animated: true)
    }

    @objc
    private func clearAllEvents() {
        //we just want to clear all the visible cells.
        guard let allEvents = fetchedResultsController.sections![0].objects as? [GeoEvent] else { return }

        let context = fetchedResultsController.managedObjectContext

        allEvents.forEach { event in
            context.delete(event)
        }

        tableView.reloadData()
    }

    @objc
    private func tripFilter() {
        //get available trip names
        guard
            let coreDataController = locationManager.coreDataController,
            let tripEvents = coreDataController.getTripEvents()
        else { return }

        let alertTripFilters = UIAlertController(title: "Filter for Trip by", message: nil, preferredStyle: .actionSheet)

        //FIXME: Limit since there is a small space for action sheets.. OR show a tableview to select one.
        for tripEvent in tripEvents {
            guard let title = tripEvent.tripName else { continue }

            let action = UIAlertAction(title: title, style: .default) { action in
                //filtering is done automatically in the coreDataController if tripEvent is set
                coreDataController.tripEvent = tripEvent

                NSFetchedResultsController<GeoEvent>.deleteCache(withName: nil)
                self._fetchedResultsController?.delegate = nil
                self._fetchedResultsController = nil
                self.updateUI()
                self.tableView.reloadData()
            }
            alertTripFilters.addAction(action)
        }

        let actionClear = UIAlertAction(title: "Clear", style: .destructive) { action in
            coreDataController.tripEvent = nil

            NSFetchedResultsController<GeoEvent>.deleteCache(withName: nil)
            self._fetchedResultsController?.delegate = nil
            self._fetchedResultsController = nil
            self.updateUI()
            self.tableView.reloadData()
        }
        alertTripFilters.addAction(actionClear)

        let actionCancel = UIAlertAction(title: "Cancel", style: .destructive)
        alertTripFilters.addAction(actionCancel)

        present(alertTripFilters, animated: true, completion: nil)
    }

    @objc
    private func addTripName() {
        let tripAlert = UIAlertController(title: "Trip Name", message: "Type a Name for this trip", preferredStyle: .alert)

        tripAlert.addTextField { textfield in
            textfield.placeholder = "Type Name here"
        }

        let actionOk = UIAlertAction(title: "Add", style: .default) { action in
            guard
                let textfield = tripAlert.textFields?.first,
                let nameText = textfield.text
            else { return }

            self.addTripEvent(named: nameText)
        }
        tripAlert.addAction(actionOk)

        let actionCancel = UIAlertAction(title: "Cancel", style: .destructive)
        tripAlert.addAction(actionCancel)

        present(tripAlert, animated: true, completion: nil)
    }

    private func addTripEvent(named: String) {
        locationManager.coreDataController?.createTripEvent(named: named)

        NSFetchedResultsController<GeoEvent>.deleteCache(withName: nil)
        _fetchedResultsController?.delegate = nil

        _fetchedResultsController = nil
        updateUI()
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withIndex: indexPath, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))

            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, withIndex indexPath: IndexPath, withEvent event: GeoEvent) {
        let timeStamp = event.timestamp ?? Date()
        let timeString = dateFormatter.string(from: timeStamp)
        let locationString = String(format:"Lat: %.5f Long: %.5f",event.latitude, event.longitude)

        cell.textLabel!.text = String(format: "\(indexPath.row): \(timeString) MPH: %.1f", event.speedMPH)
        cell.detailTextLabel!.text = locationString
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<GeoEvent> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<GeoEvent> = GeoEvent.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)

        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.relationshipKeyPathsForPrefetching = ["TripEvent"]

        //filter by tripEvents here
        if let tripEvent = locationManager.coreDataController?.tripEvent, let tripName = tripEvent.tripName {
            let predicate = NSPredicate(format: "tripevent.tripName == %@", tripName)
            fetchRequest.predicate = predicate
        } else {
            let predicate = NSPredicate(format: "speedMPH > 2.0")
            fetchRequest.predicate = predicate
        }

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

    var _fetchedResultsController: NSFetchedResultsController<GeoEvent>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withIndex: indexPath!, withEvent: anObject as! GeoEvent)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withIndex: newIndexPath!, withEvent: anObject as! GeoEvent)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - LocationManagerDelegate

extension LocationsTableViewController: LocationManagerDelegate {
    func update(with location: CLLocation) {
        //TODO: update no op
    }
}
