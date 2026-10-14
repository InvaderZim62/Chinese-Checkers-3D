//
//  Computer.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/18/26.
//
//  Best move is a recursive algorithm that determines the computer move giving best board
//  position (score), assuming the human will move to minimize computer's advantage.  It uses
//  a brute-force approach by looking at all possible moves and counter-moves and assigning
//  a score to the final board positions.  The scores are returned to the top, alternating
//  between maximizing and minimizing scores based on whose turn it is (see diagrams, below).
//
//  Moves:
//
//    level      ,----'-----,
//      1        C1         C2       all computer moves
//              / \        / \
//      2      H   H      H   H      all human counter-moves
//            / \ / \    / \ / \
//      3    C  C C  C  C  C C  C    all computer counter-counter-moves
//
//  Scores: (start from the bottom)
//                    C1             best move
//    level      ,----'-----,
//      1        4          3        return move with highest score to top
//              / \        / \
//      2      4   5      3   6      return lowest scores to level 1 (assumes human plays defensively)
//            / \ / \    / \ / \
//      3    3  4 2  5  1  3 6  4    compute scores - return highest scores to level 2
//
//  Note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
//

import UIKit

class Computer {

    let globalData = GlobalData.shared

    func bestMoveSequenceOn(board: Board) -> [Move] {
        // note: best move may be the end point of a jump sequence
        var bestMove = Move(from: RowCol.zero, to: RowCol.zero)
        //---------------------------------------------------------------------------------------
        _ = tryMoves(player: .computer, board: board, level: 1, bestMove: &bestMove)
        //---------------------------------------------------------------------------------------
        // best sequence is the one that starts with bestMove.from and ends in bestMove.to
        let bestSequence = board.shortestSequence(from: bestMove.from, to: bestMove.to, forPlayer: .computer)
        return bestSequence
    }
    
    private func tryMoves(player: Player, board: Board, level: Int, bestMove: inout Move) -> Int {
        var bestScore = player == .computer ? -100 : 100  // computer seeks max deep score, player seeks min deep score
        let availableMoves = board.availableBeginningToEndMoves(for: player)
        var thisLevelScores = [Int]()
        var deeperLevelScores = [Int]()
        for move in availableMoves {
            var boardCopy = board  // use a fresh copy before making each move
            boardCopy.updateMarbleLocationForMove(move)
            // save scores at this level for tie-breaker, in case all deeper-levels return same score
            var score = boardCopy.netScore(for: player)
            thisLevelScores.append(score)

            if boardCopy.winner() == player {
                // game winning move - set score to extreme
                score = player == .computer ? 100 : -100
                thisLevelScores[thisLevelScores.endIndex - 1] = score  // replace this level score
            } else if level < globalData.searchDepth {
                // not at search depth - go to next level (else keep this level score)
                //---------------------------------------------------------------------------------------------
                score = tryMoves(player: player.other, board: boardCopy, level: level + 1, bestMove: &bestMove)
                //---------------------------------------------------------------------------------------------
                deeperLevelScores.append(score)
            }
            if level == 1 {
                // save best move (as well as best score), if level 1
                if score == bestScore {
                    if Bool.random() {  // don't always make same moves
                        bestMove = move
                    }
                } else if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            } else if player == .computer && score > bestScore {
                bestScore = score
            } else if player == .human && score < bestScore {
                bestScore = score
            }
        }
        // at level 1 (computer's move), if all deeper-level scores are the same, use computer's best first move
        if level == 1 && deeperLevelScores.allSatisfy({ $0 == deeperLevelScores.first }) {
            let maxScoreIndices = thisLevelScores.allIndices(of: thisLevelScores.max()!)
            let maxScoreIndex = maxScoreIndices.randomElement()!
            bestMove = availableMoves[maxScoreIndex]
        }
        return bestScore
    }
}
