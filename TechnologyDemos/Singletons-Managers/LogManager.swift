//
//  LogSingleton.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation

let log = LogManager.shared

protocol LogSingletonDelegate: class {
    func update()
}

//MARK: -

// Handles all logging events vs printing to the debug panel, for viewing logs inside the app.
final class LogManager {
    static var shared = LogManager()

    private let dateFormatter = DateFormatter()

    typealias LogEntry = (date: String, logEventSource: EventSource, logEntry: String)
    var loglines = [LogEntry]()

    weak var delegate: LogSingletonDelegate?

    init() {
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
    }

    func appendLog(_ text: String, eventSource: EventSource) {
        let timeString = dateFormatter.string(from: Date())
        let logEntry = LogEntry(date: timeString, logEventSource: eventSource, logEntry: text)
        loglines.append(logEntry)
        print("\(timeString): \(eventSource.rawValue): \(text)")

        DispatchQueue.main.async {
            self.delegate?.update()
        }

        //prune
        while loglines.count > 100 {
            loglines.removeLast()
        }
    }

    func getLog() -> String {
        return loglines
            .map { (entry:LogEntry) -> String in
                return "\(entry.date): \(entry.logEventSource.rawValue): \(entry.logEntry)"
        }
        .joined(separator: "\n")
    }
}

//MARK: -

enum EventSource {
    case general
    case motionAccel
    case location
    case coreMotionViewController
    case locationMapViewController
    case locationsTableViewController
    case coreDataController
    case alertManager
}

extension EventSource: RawRepresentable {
    typealias RawValue = String
    init?(rawValue: String) {
        switch rawValue {
            case "General":
                self = .general

            case "Location":
                self = .location

            case "MotionAccel":
                self = .motionAccel

            case "CoreMotionViewController":
                self = .coreMotionViewController

            case "LocationMapViewController":
                self = .locationMapViewController

            case "LocationsTableViewController":
                self = .locationsTableViewController

            case "CoreDataController":
                self = .coreDataController

            default:
                self = .general
        }
    }

    var rawValue: String {
        switch self {
            case .general:
                return "General"

            case .location:
                return "Location"

            case .motionAccel:
                return "MotionAccel"

            case .coreMotionViewController:
                return "CoreMotionViewController"

            case .locationMapViewController:
                return "LocationMapViewController"

            case .locationsTableViewController:
                return "LocationsTableViewController"

            case .coreDataController:
                return "CoreDataController"

            case .alertManager:
                return "AlertManager"
        }
    }
}
