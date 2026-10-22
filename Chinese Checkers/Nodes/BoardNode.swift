//
//  BoardNode.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import UIKit
import SceneKit

class BoardNode: SCNNode {
    
    override init() {
        super.init()
        name = "Board"
        
        let fileName = "art.scnassets/board.scn"
        let scene = SCNScene(named: fileName)!
        let boardNode = scene.rootNode.childNode(withName: "board", recursively: true)!
        
        geometry = boardNode.geometry
        
//        physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
