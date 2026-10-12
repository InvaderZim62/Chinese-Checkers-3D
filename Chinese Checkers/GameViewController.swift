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
    static let marbleHeight: Float = 0.09
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
    
    var marbleNode: MarbleNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
