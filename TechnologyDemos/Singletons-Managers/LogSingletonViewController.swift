//
//  LogSingletonViewController.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import UIKit

let log = LogSingleton.shared

enum EventSource {
    case general
    case motionAccel
    case location
    case coreMotionViewController
    case locationViewController
    case locationsTableViewController
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

            case "LocationViewController":
                self = .locationViewController

            case "LocationsTableViewController":
                self = .locationsTableViewController

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

            case .locationViewController:
                return "LocationViewController"

            case .locationsTableViewController:
                return "LocationsTableViewController"
        }
    }
}

protocol LogSingletonDelegate: class {
    func update()
}

class LogSingleton {
    static var shared = LogSingleton()

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
    }

    func getLog() -> String {
        return loglines
            .map { (entry:LogEntry) -> String in
                return "\(entry.date): \(entry.logEventSource.rawValue): \(entry.logEntry)"
            }
            .joined(separator: "\n")
    }
}

class LogSingletonViewController: UIViewController, LogSingletonDelegate {
    @IBOutlet weak var logView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        logView.text = log.getLog()
        log.delegate = self
    }

    deinit {
        log.appendLog("de-init LogSingletonViewController", eventSource: .general)
    }

    private func scrollToBottom() {
        guard !logView.text.isEmpty else { return }

        let bottom = NSRange(location: logView.text.count - 1, length: 1)
        UIView.animate(withDuration: 1) {
            self.logView.scrollRangeToVisible(bottom)
        }
    }

    //MARK: - LogSingletonDelegate

    func update() {
        guard UIApplication.shared.applicationState == .active else { return }

        logView.text = log.getLog()
        scrollToBottom()
    }
}
