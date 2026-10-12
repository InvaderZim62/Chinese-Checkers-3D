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
    static let nominalCameraDistance: Float = 6
}

class GameViewController: UIViewController {

    lazy var scene = Scene(view: view)

    override func viewDidLoad() {
        super.viewDidLoad()
        let boardNode = ContactNode(part: "board", isSoundMaking: false, isConcave: true)
        scene.scnScene.rootNode.addChildNode(boardNode)
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
