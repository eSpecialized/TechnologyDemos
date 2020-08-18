//
//  MasterViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import UIKit

final class MasterViewController: UITableViewController {
    // MARK: - Properties

    var managedObjectContext: NSManagedObjectContext? = nil

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
    }

    // MARK: - Segue handling

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocationsTableView" {
            if let destination = segue.destination as? LocationsTableViewController {
                destination.managedObjectContext = managedObjectContext
            }
        }

        if segue.identifier == "showLocationsOnMap" {
            if let destination = segue.destination as? LocationMapViewController {
                destination.managedObjectContext = managedObjectContext
            }
        }
    }
}
