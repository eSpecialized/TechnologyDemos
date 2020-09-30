//
//  ManagedObjectProtocol.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/24/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation
import CoreData

protocol ManagedObjectProtocol: class {
    var managedObjectContext: NSManagedObjectContext? { get set }
}
