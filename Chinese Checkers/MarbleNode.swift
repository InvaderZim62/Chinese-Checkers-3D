//
//  MarbleNode.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//
//  SceneKit axes
//       y (height) green
//       |
//       |___ x (width) red
//      /
//     z (length) blue
//

import UIKit
import SceneKit

class MarbleNode: SCNNode {
    
    override init() {
        super.init()
    }

    init(radius: CGFloat, color: UIColor) {
        super.init()
        name = "Marble"
        
        geometry = SCNSphere(radius: radius)
        geometry?.firstMaterial?.diffuse.contents = color

        physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
//        physicsBody?.friction = 0  // 0: slippery, 1: sticky (default: 0.5)
//        physicsBody?.restitution = Constant.bounciness  // 0: inelastic, 1: perfectly elastic (default: 0.5)
        physicsBody?.categoryBitMask = ContactCategory.marble
        physicsBody?.contactTestBitMask = ContactCategory.marble | ContactCategory.board
//        physicsBody?.collisionBitMask = ContactCategory.marble | ContactCategory.board
        physicsBody?.continuousCollisionDetectionThreshold = 1  // supposed to keep fast moving parts from passing through structure
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
