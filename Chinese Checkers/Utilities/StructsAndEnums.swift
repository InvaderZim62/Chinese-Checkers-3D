//
//  StructsAndEnums.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//

import Foundation

enum Player: String, CaseIterable {
    case human, computer
    
    var other: Player {
        self == .human ? .computer : .human
    }
}

nonisolated struct RowCol: Hashable, CustomStringConvertible {  // nonisolated allows CustomStringConvertible to work in background tasks
    let row: Int
    let col: Int
    
    var description: String {
        "(\(row), \(col))"
    }
    
    static let zero = RowCol(row: 0, col: 0)
    static let none = RowCol(row: -1, col: -1)
    static let center = RowCol(row: 3, col: 3)
    
    // straight-line distance on board (in multiples of one move distance)
    // usage: RowCol(row: 1, col: 1).distance(to: RowCol(row: 0, col: 2))  // = 1.00
    //        RowCol(row: 1, col: 1).distance(to: RowCol(row: 0, col: 0))  // = 1.73
    func distanceTo(_ rowCol: RowCol) -> Double {
        let angle = Double.pi / 3  // angle between rows and columns on board (60 degrees)
        let deltaCol = Double(self.col - rowCol.col)
        let deltaRow = Double(self.row - rowCol.row)
        let deltaX = (deltaCol - deltaRow) * cos(angle)
        let deltaY = (deltaCol + deltaRow) * sin(angle)
        return Double(round(sqrt(pow(deltaX, 2) + pow(deltaY, 2)) * 100)) / 100  // round to two decimal places
    }
    
    // number of moves to another position, assuming each move is in column or row direction only (ie. diagonal, not horizontal)
    // usage: RowCol(row: 1, col: 1).numberOfMovesTo(RowCol(row: 0, col: 2))  // = 2
    //        RowCol(row: 1, col: 1).numberOfMovesTo(RowCol(row: 0, col: 0))  // = 2
    func numberOfMovesTo(_ rowCol: RowCol) -> Int {
        abs(self.row - rowCol.row) + abs(self.col - rowCol.col)
    }
}

struct Marble {
    let player: Player
    var rowCol: RowCol
}

nonisolated struct Move: Equatable, CustomStringConvertible {
    let from: RowCol
    let to: RowCol

    var isOnePosition: Bool {
        abs(from.distanceTo(to)) == 1
    }

    var isTwoPosition: Bool {
        abs(from.distanceTo(to)) == 2
    }

    // only good for two-position moves
    var midpoint: RowCol {
        RowCol(row: Int(Double(from.row + to.row) / 2),
               col: Int(Double(from.col + to.col) / 2))
    }

    var description: String {
        "from: \(from), to: \(to)"
    }
}
