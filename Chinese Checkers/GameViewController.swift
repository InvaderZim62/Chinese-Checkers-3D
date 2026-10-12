//
//  GameViewController.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import UIKit
import QuartzCore
import SceneKit

struct Constant {
    static let nominalCameraDistance: Float = 4
    static let marbleRadius: CGFloat = 0.08
    static let bounciness: CGFloat = 1.02  // 1.02 keeps energy nearly neutral
}

struct ContactCategory {  // bit masks for contact/collision detection
    static let board = 1 << 0
    static let marble = 1 << 1
}

class GameViewController: UIViewController {

    lazy var scene = Scene(view: view)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let boardNode = BoardNode()
        scene.scnScene.rootNode.addChildNode(boardNode)
        
        let marbleNode = MarbleNode(radius: Constant.marbleRadius, color: UIColor.blue)
        marbleNode.position = SCNVector3(x: 0, y: 1, z: 0)
        scene.scnScene.rootNode.addChildNode(marbleNode)
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
