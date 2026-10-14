//
//  Board.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
//  Board is the model.
//

import Foundation
import SceneKit

struct Board: CustomStringConvertible {
    
    let globalData = GlobalData.shared

    var marbles = [Marble]()  // first half is computer's marbles, second half is humans's marbles

    private var marbleStartingPositions = [RowCol]()  // used for restart; one for each marble; first half is computer, second half is human

    init() {
        initializeBoard()
    }
    
    private mutating func initializeBoard() {
        for row in 0..<Constant.boardSize {
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                globalData.holePositions[rowCol] = holePositionFor(rowCol: rowCol)
                // top triangle (computer's side)
                if col < Constant.playerSize - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .computer, rowCol: rowCol))
                }
                // bottom triangle (human's side)
                if col > 2 * Constant.boardSize - Constant.playerSize - 2 - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .human, rowCol: rowCol))
                }
            }
        }
    }

    private func holePositionFor(rowCol: RowCol) -> SCNVector3 {
        let holeSpacing = Constant.holeSpacing
        let halfSize: Float = 3
        let slantAngle: Float = 60.0 * .pi / 180.0
        let x = holeSpacing * ((Float(rowCol.col) - halfSize) * cos(slantAngle) - (Float(rowCol.row) - halfSize) * cos(slantAngle))
        let z = holeSpacing * ((Float(rowCol.col) - halfSize) * sin(slantAngle) + (Float(rowCol.row) - halfSize) * sin(slantAngle))
        return SCNVector3(x: x, y: Constant.marbleHeight, z: z)
    }

    mutating func updateMarbleLocationForMove(_ move: Move) {
        if let marbleIndex = marbles.firstIndex(where: { $0.rowCol == move.from }) {
            marbles[marbleIndex].rowCol = move.to
        }
    }
    
    mutating func updateAllMarbleLocationsToStartingPositions() {
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[$0] }
    }
    
    func isOccupied(_ rowCol: RowCol) -> Bool {
        marbles.contains { $0.rowCol == rowCol }
    }
    
    func isOccupied(_ rowCol: RowCol, byPlayer player: Player) -> Bool {
        marbles(for: player).contains { $0.rowCol == rowCol }
    }
    
    func winner() -> Player? {
        let isHumanWinner = isWinner(.human)
        let isComputerWinner = isWinner(.computer)
        if !isHumanWinner && !isComputerWinner {
            return nil
        } else {
            return isHumanWinner ? .human : .computer
        }
    }
    
    private func isWinner(_ player: Player) -> Bool {
        // check if all player's home positions are occupied (even if by other
        // player, to prevent other player from stalling by blocking your home);
        // home can't include more than one of other player
        let isHomeFilledByAnyPlayer = homePositions(for: player).allSatisfy { isOccupied($0) }
        let isHomeContainNoMoreThanOneOfOtherPlayer = homePositions(for: player).filter { isOccupied($0, byPlayer: player.other) }.count <= 1
        return isHomeFilledByAnyPlayer && isHomeContainNoMoreThanOneOfOtherPlayer
    }

    func availableEndpoints(from fromRowCol: RowCol, forPlayer player: Player) -> [RowCol] {
        let sequences = availableSequences(from: fromRowCol, forPlayer: player)
        return sequences.map { $0.last!.to }
    }
    
    func shortestSequence(from: RowCol, to: RowCol, forPlayer player: Player) -> [Move] {
        let allSequences = availableSequences(from: from, forPlayer: player)
        let sequences = allSequences.filter { $0.last!.to == to }  // may be more than one path
        return sequences.min(by: { $0.count < $1.count }) ?? []  // pick shortest path
    }

    private func isOnBoard(_ rowCol: RowCol) -> Bool {
        rowCol.row >= 0 && rowCol.row < Constant.boardSize && rowCol.col >= 0 && rowCol.col < Constant.boardSize
    }
    
    private func isHome(_ rowCol: RowCol, forPlayer player: Player) -> Bool {
        homePositions(for: player).contains(rowCol)
    }
    
    private func startingPositions(for player: Player) -> [RowCol] {
        if player == .computer {
            Array(marbleStartingPositions.prefix(marbles.count / 2))  // first half
        } else {
            Array(marbleStartingPositions.suffix(marbles.count / 2))  // second half
        }
    }
    
    private func homePositions(for player: Player) -> [RowCol] {
        startingPositions(for: player.other)
    }
    
    private func marbles(for player: Player) -> [Marble] {
        marbles.filter { $0.player == player }
    }

    // legal if: stays on board, destination unoccupied, didn't move out of home, and move is one position or jump
    private func isLegalMove(_ move: Move, forPlayer player: Player) -> Bool {
        guard isOnBoard(move.to) else { return false }
        guard !isOccupied(move.to) else { return false }
        guard !isHome(move.from, forPlayer: player) || isHome(move.to, forPlayer: player) else { return false }
        let isJump = move.isTwoPosition && isOccupied(move.midpoint)
        return move.isOnePosition || isJump
    }

    private func printMoveSequences(_ sequences: [[Move]]) {
        for sequence in sequences {
            print(sequence)
        }
    }

    // MARK: - Computer

    // start to end positions of the move sequences
    func availableBeginningToEndMoves(for player: Player) -> [Move] {
        let availableMoveSequences = availableSequences(for: player)
        return availableMoveSequences.map { Move(from: $0.first!.from, to: $0.last!.to) }
    }

    private func availableSequences(for player: Player) -> [[Move]] {
        var sequences = [[Move]]()
        for marble in marbles where marble.player == player {
            //---------------------------------------------------------------------
            sequences += availableSequences(from: marble.rowCol, forPlayer: player)
            //---------------------------------------------------------------------
        }
        return sequences
    }

    // return sequences from beginning to end, including all intermediate sequences
    private func availableSequences(from fromRowCol: RowCol, forPlayer player: Player, currentSequence: [Move] = []) -> [[Move]] {
        var allSequences = [[Move]]()
        var positionDeltas = [(Int, Int)]()
        if currentSequence.isEmpty {
            positionDeltas = [(-1, 1), (0, 1), (1, 0), (1, -1), (0, -1), (-1, 0),
                              (-2, 2), (0, 2), (2, 0), (2, -2), (0, -2), (-2, 0)]
        } else {
            positionDeltas = [(-2, 2), (0, 2), (2, 0), (2, -2), (0, -2), (-2, 0)]  // only allow jumps after first move
        }
        for (deltaRow, deltaCol) in positionDeltas {
            if let toRowCol = destinationIfLegalMoveToPosition(deltaRow: deltaRow, deltaCol: deltaCol, from: fromRowCol, forPlayer: player) {
                let move = Move(from: fromRowCol, to: toRowCol)
                if currentSequence.contains(where: { $0.from == toRowCol }) { continue }  // don't allow move to prior position in current sequence
                allSequences.append([move])
                if move.isTwoPosition {
                    //--------------------------------------------------------------------------------------------------------------
                    var sequences = availableSequences(from: toRowCol, forPlayer: player, currentSequence: currentSequence + [move])
                    //--------------------------------------------------------------------------------------------------------------
                    if !sequences.isEmpty {
                        // add move to front of each returned sequence, before adding to allSequences
                        sequences.indices.forEach { sequences[$0].insert(contentsOf: [move], at: 0) }
                    }
                    allSequences.append(contentsOf: sequences)
                }
            }
        }
        return allSequences
    }
    
    private func destinationIfLegalMoveToPosition(deltaRow: Int, deltaCol: Int, from fromRowCol: RowCol, forPlayer player: Player) -> RowCol? {
        let toRowCol = RowCol(row: fromRowCol.row + deltaRow, col: fromRowCol.col + deltaCol)
        if isLegalMove(Move(from: fromRowCol, to: toRowCol), forPlayer: player) {
            return toRowCol
        } else {
            return nil
        }
    }
    
    // higher is better
    func netScore(for player: Player) -> Int {
        numberOfMovesRemaining(for: player.other) - numberOfMovesRemaining(for: player)
    }

    // number of moves remaining to fill every open hole at home;
    // algorithm adds moves from open holes to closest marble not yet home
    private func numberOfMovesRemaining(for player: Player) -> Int {
        var movesRemaining = 0
        let homePositions = homePositions(for: player)
        var marblesNotYetHome = marbles(for: player).filter { !homePositions.contains($0.rowCol) }
        let openHomePositions = homePositions.filter { !isOccupied($0, byPlayer: player) }
        for openHomePosition in openHomePositions {
            let closestMarbleIndex = indexOfClosestMarbleTo(target: openHomePosition, in: marblesNotYetHome)
            let closestMarble = marblesNotYetHome[closestMarbleIndex]
            movesRemaining += closestMarble.rowCol.numberOfMovesTo(openHomePosition)
            marblesNotYetHome.remove(at: closestMarbleIndex)
        }
        return movesRemaining
    }
    
    // index of marble closest to target hole, in terms of number of moves
    private func indexOfClosestMarbleTo(target: RowCol, in marbles: [Marble]) -> Int {
        let distancesToTarget = marbles.map { $0.rowCol.numberOfMovesTo(target) }
        return distancesToTarget.firstIndex(of: distancesToTarget.min()!)!
    }

    // MARK: - CustomStringConvertible
    
    var description: String {
        var string = "\n  "
        string += Array(0..<Constant.boardSize).map { "\($0)" }.joined(separator: " ")
        for row in 0..<Constant.boardSize {
            string += "\n\(row)"
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                if let marble = marbles.first(where: { $0.rowCol == rowCol }) {
                    string += marble.player == .human ? " h" : " c"
                } else {
                    string += " ."
                }
            }
        }
        return string
    }
}
