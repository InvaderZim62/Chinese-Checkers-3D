//
//  Extensions.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import UIKit
import SceneKit

extension Array where Element: Equatable {
    // usage: [1, 2, 3, 1, 0].allIndices(of: 1)  // = [0, 3]
    func allIndices(of target: Element) -> [Int] {
        self.enumerated().filter { $0.element == target }.map { $0.offset }
    }
}

extension SCNVector3 {
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func +=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = lhs + rhs
    }
    
    static func *(lhs: SCNVector3, scaler: Float) -> SCNVector3 {
        return SCNVector3(x: lhs.x * scaler, y: lhs.y * scaler, z: lhs.z * scaler)
    }
    
    static func /(lhs: SCNVector3, scaler: Float) -> SCNVector3 {
        return SCNVector3(x: lhs.x / scaler, y: lhs.y / scaler, z: lhs.z / scaler)
    }

    static prefix func -(rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(x: -rhs.x, y: -rhs.y, z: -rhs.z)
    }
    
    static var zero: SCNVector3 {
        SCNVector3(x: 0, y: 0, z: 0)
    }
    
    func distance(to point: SCNVector3) -> Double {
        Double(sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2) + pow((self.z - point.z), 2)))
    }
    
    // return bearing in x-z plane from -pi to +pi, where 0 is to the right, positive is clockwise
    func bearing(to point: SCNVector3) -> Float {
        atan2(Float(point.z - self.z), Float(point.x - self.x))
    }

    func dot(_ rhs: SCNVector3) -> Float {
        return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
    }
    
    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
}

// extension for enums using CaseIterable
extension CaseIterable where Self: Equatable {  // Equatable needed for firstIndex(of:)
    mutating func next() {
        let allCases = Self.allCases
        let thisIndex = allCases.firstIndex(of: self)!
        let nextIndex = allCases.index(after: thisIndex)
        self = allCases[nextIndex == allCases.endIndex ? allCases.startIndex : nextIndex]
    }

    static func random() -> AllCases.Element {
        .allCases.randomElement()!
    }
}
