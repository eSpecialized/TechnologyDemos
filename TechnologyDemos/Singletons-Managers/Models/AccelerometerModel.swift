//
//  AccelerometerModel.swift
//  TechnologyDemos
//
//  Created by William Thompson on 8/17/20.
//  Copyright © 2020 William Thompson. All rights reserved.
//

import Foundation

public struct AccelerometerModel: Equatable {
    // MARK: - Properties

    public let xAccel: Double
    public let yAccel: Double
    public let zAccel: Double

    // MARK: - Initializers

    public init(xAccel: Double, yAccel: Double, zAccel: Double) {
        self.xAccel = xAccel
        self.yAccel = yAccel
        self.zAccel = zAccel
    }

    public init(with model: AccelerometerModel, xAccel: Double? = nil, yAccel: Double? = nil, zAccel: Double? = nil) {
        self.xAccel = xAccel ?? model.xAccel
        self.yAccel = yAccel ?? model.yAccel
        self.zAccel = zAccel ?? model.zAccel
    }

    // MARK: - Supporting methods

    public static func zero() -> AccelerometerModel {
        return AccelerometerModel(xAccel: 0, yAccel: 0, zAccel: 0)
    }
}
