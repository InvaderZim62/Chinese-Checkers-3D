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
    static let nominalCameraDistance: Float = 3.6
    static let isOrthographicProjection = true
    static let marbleRadius: CGFloat = 0.08
    static let holeSpacing: Float = 0.254
    static let marbleHeight: Float = 0.09  // when on board
    static let bounciness: CGFloat = 0
}

struct RowCol: CustomStringConvertible {
    let row: Int
    let col: Int
    
    var description: String {
        "(\(row), \(col))"
    }
}

class GameViewController: UIViewController {

    lazy var scene = Scene(view: view)
    var hud = Hud()
    var selectedMarbleNode: MarbleNode!
    var initialBoardCoordinates = SCNVector3Zero
    var initialMarbleNodePosition = SCNVector3Zero

    var marbleNode: MarbleNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHud()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scene.scnView.addGestureRecognizer(pan)

        let boardNode = BoardNode()
        scene.scnScene.rootNode.addChildNode(boardNode)

        let marbleColor = UIColor.red
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 0, col: 0))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 0, col: 3))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 0, col: 6))
        scene.scnScene.rootNode.addChildNode(marbleNode)

        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 3, col: 0))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 3, col: 3))
        scene.scnScene.rootNode.addChildNode(marbleNode)

        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 3, col: 6))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 6, col: 0))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 6, col: 3))
        scene.scnScene.rootNode.addChildNode(marbleNode)
        
        marbleNode = MarbleNode(radius: Constant.marbleRadius, color: marbleColor)
        marbleNode.position = holePositionFor(rowCol: RowCol(row: 6, col: 6))
        scene.scnScene.rootNode.addChildNode(marbleNode)
    }
    
    private func holePositionFor(rowCol: RowCol) -> SCNVector3 {
        let holeSpacing = Constant.holeSpacing
        let halfSize: Float = 3
        let slantAngle: Float = 60.0 * .pi / 180.0
        let x = holeSpacing * ((Float(rowCol.col) - halfSize) * cos(slantAngle) - (Float(rowCol.row) - halfSize) * cos(slantAngle))
        let z = holeSpacing * ((Float(rowCol.col) - halfSize) * sin(slantAngle) + (Float(rowCol.row) - halfSize) * sin(slantAngle))
        return SCNVector3(x: x, y: Constant.marbleHeight, z: z)
    }
    
    private func setupHud() {
        hud = Hud(size: scene.scnView.bounds.size)
        hud.setup(touchHandler: handleTouch)
        scene.scnView.overlaySKScene = hud
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
        }
    }

    // *** mostly from BingBangBoing ***
    // if domino selected, move it along pan gesture, otherwise create string of dominos along pan gesture
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: scene.scnView)  // absolute 2D screen coordinates
        if let pannedMarbleNode = selectedMarbleNode {
            switch recognizer.state {
            case .began:
                if let boardCoordinates = getBoardCoordinatesAt(location) {
                    initialBoardCoordinates = boardCoordinates
                }
                initialMarbleNodePosition = pannedMarbleNode.position
            case .changed:
                // move pannedMarbleNode to pan location, in plane of board
                if let boardCoordinates = getBoardCoordinatesAt(location) {
                    let deltaBoardCoordinates = boardCoordinates - initialBoardCoordinates
                    pannedMarbleNode.position = initialMarbleNodePosition + deltaBoardCoordinates
                    pannedMarbleNode.position.y = Constant.marbleHeight
                }
            case .ended, .cancelled:
                // update model
//                updateMarbleModelFor(partNode: pannedMarbleNode)  // pws: check if DominoDraw does this easier
                selectedMarbleNode = nil
            default:
                break
            }
        }
    }

    // convert from screen to board/apron coordinates
    private func getBoardCoordinatesAt(_ location: CGPoint) -> SCNVector3? {
        var boardCoordinates: SCNVector3?
        let hitResults = scene.scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        if let result = hitResults.first(where: { $0.node.name == "Board" }) {
            boardCoordinates = result.localCoordinates
        }
        return boardCoordinates
    }

    // MARK: - Utility functions
    
    // get shape node at location provided by tap gesture (nil if none tapped)
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
