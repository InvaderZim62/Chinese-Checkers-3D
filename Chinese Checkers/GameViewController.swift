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
    static let nominalCameraDistance: Float = 3.6
    static let cameraAngle: Float = 50 * .pi / 180  // angle above horizon
    static let isOrthographicProjection = false  // false: marble size decreases with distance from camera
    static let bounciness: CGFloat = 0
}

class GameViewController: UIViewController {
    
    let globalData = GlobalData.shared

    lazy var scene = Scene(view: view)
    var hud = Hud()
    var board = Board()
    var computer = Computer()
    var marbleNodes = [MarbleNode]()
    var selectedMarbleNode: MarbleNode!
    
    // panning vars
    var availableEndpoints = [RowCol]()
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHud()
        createMarbleNodes()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scene.scnView.addGestureRecognizer(pan)

        let boardNode = BoardNode()
        scene.scnScene.rootNode.addChildNode(boardNode)
    }

    private func setupHud() {
        hud = Hud(size: scene.scnView.bounds.size)
        hud.setup(touchHandler: handleTouch)
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

    // *** mostly from BingBangBoing ***
    // update transform of partModel associated with partNode
//    private func updateMarbleModelFor(partNode: MarbleNode) {
//        if let marbleIndex = partModels.firstIndex(where: { $0.id == partNode.modelId }) {
//            partModels[marbleIndex].setTransform(to: partNode.transform)
//        }
//    }

    // MARK: - Gesture Recognizers
    
    // select marble, if any gesture begins on it (touch is always called first);
    // touch is intercepted by hud, which calls this handler
    func handleTouch(hudLocation: CGPoint) {
        let location = CGPoint(x: hudLocation.x, y: scene.scnView.bounds.height - hudLocation.y)  // hud origin: lower left, scene origin: upper left
        if let touchedShapeNode = getMarbleNodeAt(location) {
            // shape touched (select it)
            selectedMarbleNode = touchedShapeNode
            startRowCol = board.holeRowCol(near: selectedMarbleNode.position) ?? RowCol.center
        }
    }

    // *** mostly from BingBangBoing ***
    // if domino selected, move it along pan gesture, otherwise create string of dominos along pan gesture
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
                } else if nearbyRowCol == nil {
                    pannedMarbleNode.position = boardCoordinates
                } else {
                    pannedMarbleNode.position = boardCoordinates
                    endRowCol = startRowCol
                }
            case .ended, .cancelled:
                if endRowCol == startRowCol {
                    // marble left unsnapped - move it back to startPosition
                    pannedMarbleNode.position = globalData.holePositions[startRowCol]!
                } else {
                    // marble successfully moved
                    board.updateMarbleLocationForMove(Move(from: startRowCol, to: endRowCol))  // update model
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
}
