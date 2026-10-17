//
//  GameViewController.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//
//  SceneKit axes
//       y (height)
//       |
//       |___ x (width)
//      /
//     z (length)
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
    static let snapDistance: CGFloat = 0.10
    static let holeSpacing: Float = 0.254  // found empirically to match Blender model
    static let marbleHeight: Float = 0.09  // when on board
    static let moveHeight = SCNVector3(x: 0, y: Float(marbleRadius), z: 0)
    static let farMoveTime: TimeInterval = 0.4  // used for computer's move and returning marbles during restart
    static let closeMoveTime: TimeInterval = 0.3  // used to return marble, if unmoved
    static let upDownTime: TimeInterval = 0.1  // lifting and lowering marble
    static let lineFadeTime: TimeInterval = 0.5

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

    // panning vars
    var availableEndpoints = [RowCol]()
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero

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
        setupHud()
        createMarbleNodes()
        createTurnIndicatorNode()
        whoseTurn = Player.random()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scene.scnView.addGestureRecognizer(pan)

        let boardNode = BoardNode()
        scene.scnScene.rootNode.addChildNode(boardNode)
    }

    private func setupHud() {
        hud = Hud(size: scene.scnView.bounds.size)
        hud.setup(restartCallback: restartSelected, touchHandler: handleTouch)
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
        guard let boardCoordinates = getBoardCoordinatesAt(location) else { return }
        
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
                    whoseTurn.next()
                }
                selectedMarbleNode = nil
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

    // MARK: - Hud callbacks
    
    // reset game
    private func restartSelected() {
        isGameOver = false
        hud.winner = nil
        turnIndicatorNode.isHidden = false
        // move all marbles back to their starting positions
//        board.updateAllMarbleLocationsToStartingPositions()
//        UIView.animate(withDuration: Constant.farMoveTime, delay: 0, animations: {
//            self.updateViewFromModel()
//        }, completion: { _ in
//            if self.whoseTurn == .computer {
//                self.computerMove()
//            }
//        }
//        )
    }

    // MARK: - Computer
    
    private func computerMove() {
//        spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            //------------------------------------------------------------------------
            let bestMoveSequence = self.computer.bestMoveSequenceOn(board: self.board)
            //------------------------------------------------------------------------
            let marbleNode = self.getMarbleNodeAt(bestMoveSequence.first!.from)
            // build move actions
            var actions = [SCNAction]()
            for move in bestMoveSequence {
                self.board.updateMarbleLocationForMove(move)
                let from = self.globalData.holePositions[move.from]
                let to = self.globalData.holePositions[move.to]
                let midPoint = from! * 0.5 + to! * 0.5 + Constant.moveHeight * 2
                let riseAction = SCNAction.move(to: midPoint, duration: Constant.farMoveTime / 2)
                let lowerAction = SCNAction.move(to: to!, duration: Constant.farMoveTime / 2)
                let waitAction = SCNAction.wait(duration: Constant.farMoveTime)
                actions.append(contentsOf: [riseAction, lowerAction, waitAction])
            }
            marbleNode?.runAction(SCNAction.sequence(actions)) {
//                self.fadeOutMoveView()
//                self.checkProgress()
//                self.spinner.stopAnimating()
                self.whoseTurn.next()
                Task { @MainActor in  // @MainActor needed here to use board's CustomStringConvertible
                    print(self.board)
                    print("Computer Sequence: \(bestMoveSequence)")
                }
            }
        }
    }
}
