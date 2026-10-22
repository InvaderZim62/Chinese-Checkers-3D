//
//  GameViewController.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//
//  SceneKit axes
//       y (height)
//       |
//       |___ x (width)    note: game board is in x-z plane
//      /
//     z (length)
//
//  To do...
//  - maybe add sinusoidal height bias to marble when panning (rather than Constant.moveHeight),
//    so marble moves up from one hole and down to the next.  Might not look good dipping down
//    into occupied holes.
//

import UIKit
import QuartzCore
import SceneKit

struct Constant {
    static let humanColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let computerColor = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
    static let boardSize = 7
    static let playerSize = 4  // starting triangle dimension
    static let marbleRadius: CGFloat = 0.08
    static let snapDistance: CGFloat = 0.12
    static let holeSpacing: Float = 0.254  // found empirically to match Blender model
    static let marbleHeight: Float = 0.09  // when on board
    static let moveHeight = SCNVector3(x: 0, y: Float(1.5 * marbleRadius), z: 0)  // while panning
    static let pathRadius: CGFloat = 0.02
    static let farMoveTime: TimeInterval = 0.5  // used for computer's move and returning marbles during restart
    static let closeMoveTime: TimeInterval = 0.3  // used to return marble, if unmoved
    static let upDownTime: TimeInterval = 0.1  // lifting and lowering marble
    static let pathFadeTime: TimeInterval = 0.5

    static let nominalCameraDistance: Float = 3.6
    static let cameraAngle: Float = 50 * .pi / 180  // angle above horizon
    static let isOrthographicProjection = false  // false: marble size decreases with distance from camera
}

class GameViewController: UIViewController {
    
    let globalData = GlobalData.shared

    lazy var scene = Scene(view: view)
    var hud = Hud()
    var board = Board()
    var computer = Computer()
    var marbleNodes = [MarbleNode]()
    let pathNode = PathNode()
    var turnIndicatorNode: MarbleNode!
    var selectedMarbleNode: MarbleNode!
    var isGameOver = false
    var whoseTurn: Player! {
        didSet {
            turnIndicatorNode.player = whoseTurn
            if whoseTurn == .computer && !isGameOver {
                computerMove()
            }
        }
    }
    var isHardPlay = false {
        didSet {
            globalData.searchDepth = isHardPlay ? 3 : 1  // only use odd numbers (5 is slow)
            saveDefaults()
        }
    }

    // panning vars
    var availableEndpoints = [RowCol]()
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero
    
    // computer's move cancellation vars
    var item: DispatchWorkItem!
    var computerMarbleNode: MarbleNode!

    var spinner = UIActivityIndicatorView(style: .large)

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        getDefaults()
        setupHud()
        createMarbleNodes()
        createTurnIndicatorNode()
        whoseTurn = Player.random()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scene.scnView.addGestureRecognizer(pan)

        let boardNode = BoardNode()
        scene.scnScene.rootNode.addChildNode(boardNode)
        scene.scnScene.rootNode.addChildNode(pathNode)
        
        spinner.center = scene.scnView.center
        scene.scnView.addSubview(spinner)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hud.isHardPlay = isHardPlay  // don't move to viewDidLoad (hud doesn't exist, yet)
    }

    private func getDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isHardPlay") != nil {
            isHardPlay = defaults.bool(forKey: "isHardPlay")
        }
    }
    
    private func saveDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isHardPlay, forKey: "isHardPlay")
    }

    private func setupHud() {
        hud = Hud(size: scene.scnView.bounds.size)
        hud.setup(difficultyHandler: difficultySelected, restartHandler: restartSelected, touchHandler: handleTouch)
        scene.scnView.overlaySKScene = hud
    }

    private func createMarbleNodes() {
        for marble in board.marbles {
            let marbleNode = MarbleNode(radius: Constant.marbleRadius, player: marble.player)
            marbleNode.position = globalData.holePositions[marble.rowCol]!
            marbleNodes.append(marbleNode)
            scene.scnScene.rootNode.addChildNode(marbleNode)
        }
    }
    
    private func createTurnIndicatorNode() {
        turnIndicatorNode = MarbleNode(radius: Constant.marbleRadius)
        turnIndicatorNode.position = SCNVector3(x: -0.95, y: 0, z: -1.25)
        scene.scnScene.rootNode.addChildNode(turnIndicatorNode)
    }

    // MARK: - Gesture Recognizers
    
    // select marble, if any gesture begins on it (touch is called before pan);
    // touch is intercepted by hud, which calls this handler
    func handleTouch(hudLocation: CGPoint) {
        guard whoseTurn == .human, isGameOver == false else { return }  // must be human's turn to pan
        let location = CGPoint(x: hudLocation.x, y: scene.scnView.bounds.height - hudLocation.y)  // hud origin: lower left, scene origin: upper left
        if let touchedMarbleNode = getMarbleNodeAt(location), touchedMarbleNode.player == .human {
            // marble touched (select it)
            selectedMarbleNode = touchedMarbleNode
            startRowCol = board.holeRowCol(near: selectedMarbleNode.position) ?? RowCol.center
        }
    }

    // move selected marble along pan gesture; snap marble to legal move holes
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: scene.scnView)  // absolute 2D screen coordinates
        guard var boardCoordinates = getBoardCoordinatesAt(location) else { return }
        boardCoordinates += SCNVector3(x: 0, y: 0, z: 0.05 * boardCoordinates.z - 0.225)  // offset marble to see around finger
        
        if let pannedMarbleNode = selectedMarbleNode {
            switch recognizer.state {
            case .began:
                availableEndpoints = board.availableEndpoints(from: startRowCol, forPlayer: .human)
                endRowCol = startRowCol
            case .changed:
                // move pannedMarbleNode to pan location, in plane of board
                let nearbyRowCol = board.holeRowCol(near: boardCoordinates)  // nil if no holes nearby
                
                if let nearbyRowCol, nearbyRowCol == startRowCol || availableEndpoints.contains(nearbyRowCol) {
                    // panning near starting hole or any legal move hole - snap position, set end point
                    pannedMarbleNode.position = globalData.holePositions[nearbyRowCol]!
                    endRowCol = nearbyRowCol
                    let moveSequence = board.shortestSequence(from: startRowCol, to: endRowCol, forPlayer: .human)
                    pathNode.createPathThroughSequence(moveSequence, color: Constant.humanColor)
                } else if nearbyRowCol != nil {
                    // panning near any other hole - keep panning
                    pannedMarbleNode.position = boardCoordinates + Constant.moveHeight
                } else {
                    // panning away from all holes - reset end point
                    pannedMarbleNode.position = boardCoordinates + Constant.moveHeight
                    endRowCol = startRowCol
                }
            case .ended, .cancelled:
                if endRowCol == startRowCol {
                    // marble left unsnapped - move it back to startPosition
                    pannedMarbleNode.runAction(SCNAction.move(to: globalData.holePositions[startRowCol]!, duration: Constant.closeMoveTime))
                } else {
                    // marble successfully moved
                    board.updateMarbleLocationForMove(Move(from: startRowCol, to: endRowCol))  // update model
                    print(board)
                    print("Human move: from: \(startRowCol), to: \(endRowCol)")
                    checkProgress()
                    whoseTurn.next()
                }
                selectedMarbleNode = nil
                fadeOutPathNode()
            default:
                break
            }
        }
    }

    // convert from screen to board coordinates
    private func getBoardCoordinatesAt(_ location: CGPoint) -> SCNVector3? {
        var boardCoordinates: SCNVector3?
        let hitResults = scene.scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        if let result = hitResults.first(where: { $0.node is BoardNode }) {
            boardCoordinates = result.localCoordinates
            boardCoordinates?.y = Constant.marbleHeight
        }
        return boardCoordinates
    }

    // MARK: - Utility functions
    
    // get marble node at location provided by tap gesture (nil if none tapped)
    private func getMarbleNodeAt(_ location: CGPoint) -> MarbleNode? {
        var marbleNode: MarbleNode?
        let hitResults = scene.scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        if let result = hitResults.first(where: { $0.node is MarbleNode }) {
            marbleNode = result.node as? MarbleNode
        }
        return marbleNode
    }
    
    private func getMarbleNodeAt(_ rowCol: RowCol) -> MarbleNode? {
        let holePosition = globalData.holePositions[rowCol]
        let marbleNode = marbleNodes.first(where: { $0.position.distance(to: holePosition!) < Constant.snapDistance })
        return marbleNode
    }
    
    private func performRestart() {
        isGameOver = false
        hud.winner = nil
        turnIndicatorNode.isHidden = false
        moveAllMarblesBackToStartingPositions()
        if whoseTurn == .computer {
            computerMove()
        }
    }

    private func moveAllMarblesBackToStartingPositions() {
        let fromRowCols = board.marbles.map { $0.rowCol }
        board.updateAllMarbleLocationsToStartingPositions()
        let toRowCols = board.marbles.map { $0.rowCol }
        for (index, fromRowCol) in fromRowCols.enumerated() {
            let toRowCol = toRowCols[index]
            if !moveMarbleNode(from: fromRowCol, to: toRowCol) {
                // no marble at fromRowCol (movingMarbleNode stuck between holes when actions cancelled during restart)
                let toPosition = globalData.holePositions[toRowCol]!
                let move = SCNAction.move(to: toPosition, duration: Constant.farMoveTime)
                computerMarbleNode.runAction(move)
            }
        }
    }
    
    // assumes a marbleNode is at fromRowCol, otherwise return false
    private func moveMarbleNode(from fromRowCol: RowCol, to toRowCol: RowCol) -> Bool {
        if let marbleNode = getMarbleNodeAt(fromRowCol) {
            let toPosition = globalData.holePositions[toRowCol]!
            let move = SCNAction.move(to: toPosition, duration: Constant.farMoveTime)
            marbleNode.runAction(move)
            return true
        } else {
            return false
        }
    }

    private func checkProgress() {
        if let winner = board.winner() {
            isGameOver = true
            hud.winner = winner
            turnIndicatorNode.isHidden = true
        } else {
            hud.winner = nil
        }
    }
    
    private func fadeOutPathNode() {
        pathNode.runAction(SCNAction.fadeOut(duration: Constant.pathFadeTime))
    }

    // MARK: - Hud callbacks
    
    // reset game
    private func restartSelected() {
        print("\nRestart")
        if item != nil { cancelComputerMove() }
        performRestart()
    }
    
    private func difficultySelected() {
        isHardPlay = hud.isHardPlay
    }

    // MARK: - Computer
    
    // If restarting game during computer's move, need to stop move actions, and prevent executing
    // of completion handler. DispatchWorkItem encapsulates a queue and can be cancelled.
    
    private func cancelComputerMove() {
        item?.cancel()
        computerMarbleNode.removeAllActions()  // stops moving marble in place
        fadeOutPathNode()
        spinner.stopAnimating()
        whoseTurn.next()
        item = nil
    }

    private func computerMove() {
        spinner.startAnimating()
        item = DispatchWorkItem(qos: .userInitiated) { [weak self] in  // weak self needed to prevent potential reference cycle (memory leak)
            //-------------------------------------------------------------------------------------
            let bestMoveSequence = self?.computer.bestMoveSequenceOn(board: self?.board ?? Board())
            //-------------------------------------------------------------------------------------
            // build move actions
            var actions = [SCNAction]()
            for move in bestMoveSequence ?? [] {
                let to = self?.globalData.holePositions[move.to]
                let riseAction = SCNAction.move(to: move.midPoint + Constant.moveHeight * 1.5, duration: Constant.farMoveTime / 2)
                let lowerAction = SCNAction.move(to: to!, duration: Constant.farMoveTime / 2)
                let waitAction = SCNAction.wait(duration: Constant.farMoveTime)
                actions.append(contentsOf: [riseAction, lowerAction, waitAction])
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constant.pathFadeTime) {  // allow time for human's fadeOutPathNode to complete
                self?.spinner.stopAnimating()
                if self?.item?.isCancelled ?? true { self?.item = nil; return }
                self?.pathNode.createPathThroughSequence(bestMoveSequence ?? [], color: Constant.computerColor)
                self?.computerMarbleNode = self?.getMarbleNodeAt(bestMoveSequence?.first?.from ?? RowCol.none)
                
                // animate computer's move
                self?.computerMarbleNode?.runAction(SCNAction.sequence(actions)) {
                    bestMoveSequence?.forEach { self?.board.updateMarbleLocationForMove($0) }  // update model
                    self?.fadeOutPathNode()
                    self?.checkProgress()
                    self?.whoseTurn.next()
                    Task { @MainActor in  // @MainActor needed here to use board's CustomStringConvertible
                        print(self?.board ?? "")
                        print("Computer Sequence: \(bestMoveSequence ?? [])")
                    }
                    self?.item = nil
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: item!)
    }
}

extension Move {
    var midPoint: SCNVector3 {
        let globalData = GlobalData.shared
        let from = globalData.holePositions[from]
        let to = globalData.holePositions[to]
        return (from! + to!) / 2
    }
    
    var distance: Double {
        let globalData = GlobalData.shared
        let from = globalData.holePositions[from]
        let to = globalData.holePositions[to]
        return from!.distance(to: to!)
    }
    
    var bearing: Float {
        let globalData = GlobalData.shared
        let from = globalData.holePositions[from]
        let to = globalData.holePositions[to]
        return from!.bearing(to: to!)
    }
}
