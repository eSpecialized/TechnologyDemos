//
//  MasterViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import CoreData
import UIKit

final class MasterViewController: UITableViewController, ManagedObjectProtocol {
    // MARK: - Properties

    @IBOutlet weak var bartext: UIBarButtonItem!
    var managedObjectContext: NSManagedObjectContext? = nil

    // MARK: - Init and View Management

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true

        updateUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CoreMotionManager.shared.delegate = self
    }

    // MARK: - Segue handling

    @objc
    private func toggleNavigation() {
        if LocationManager.shared.isLocationUpdating {
            LocationManager.shared.stop()
        } else {
            LocationManager.shared.start()
        }

        updateUI()
    }

    private func updateUI() {
        if LocationManager.shared.isLocationUpdating {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop Location", style: .plain, target: self, action: #selector(toggleNavigation))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start Location", style: .plain, target: self, action: #selector(toggleNavigation))
        }
    }

    // MARK: - Segue handling

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }

        guard let destination = segue.destination as? ManagedObjectProtocol else {
            assertionFailure("No ManagedObjectProtocol configured for \(identifier)")
            return
        }

        destination.managedObjectContext = managedObjectContext
    }
}

extension MasterViewController: CoreMotionManagerDelegate {
    func updatedDateAvailable(sample: CoreMotionManager.SampleData) {
        DispatchQueue.main.async { [weak self] in
            //update UI
            self?.bartext.title = CoreMotionManager.shared.lastActivityDescription
        }
    }
}
