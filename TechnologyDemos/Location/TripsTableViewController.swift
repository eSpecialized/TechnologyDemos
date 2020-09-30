//
//  TripsTableViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/24/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import UIKit

final class TripsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectProtocol {
    // MARK: - Properties

    private let locationManager = LocationManager.shared

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter
    }()

    var managedObjectContext: NSManagedObjectContext? = nil

    // MARK: - View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        if let rightBarButton = navigationItem.rightBarButtonItem as UIBarButtonItem? {
            rightBarButton.action = #selector(promptForTripName(_:))
        }
    }

    // MARK: - Support Methods

    @objc
    func promptForTripName(_ sender: Any) {
        let promptAlert = UIAlertController(title: "Trip Name:", message: nil, preferredStyle: .alert)

        promptAlert.addTextField { textField in
            textField.placeholder = "Trip Name Here"
        }

        let okAction = UIAlertAction(title: "Add", style: .default) { action in
            guard let textField = promptAlert.textFields?.first, let tripName = textField.text else { return }

            self.insertNewTrip(tripName)
        }
        promptAlert.addAction(okAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        promptAlert.addAction(cancelAction)

        present(promptAlert, animated: true, completion: nil)
    }

    private func insertNewTrip(_ named: String) {
        let context = self.fetchedResultsController.managedObjectContext
        let newEvent = TripEvent(context: context)

        newEvent.timeStamp = Date()
        newEvent.tripName = named

        locationManager.coreDataController?.tripEvent = newEvent

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripCell1", for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withEvent: event)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))

            do {
                try context.save()
            } catch {

                let nserror = error as NSError
                assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tripEvent = fetchedResultsController.object(at: indexPath) as TripEvent? else { return }

        locationManager.coreDataController?.tripEvent = tripEvent
    }

    func configureCell(_ cell: UITableViewCell, withEvent event: TripEvent) {
        guard let timeStemp = event.timeStamp else { return }

        cell.textLabel?.text = event.tripName
        cell.detailTextLabel?.text = dateFormatter.string(from: timeStemp)
        cell.accessoryType = .detailDisclosureButton

        if let tripEvent = locationManager.coreDataController?.tripEvent, event == tripEvent {
            cell.isSelected = true
        } else {
            cell.isSelected = false
        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<TripEvent> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<TripEvent> = TripEvent.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)

        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.relationshipKeyPathsForPrefetching = ["GeoEvent"]

        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<TripEvent>? = nil

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
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! TripEvent)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! TripEvent)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
