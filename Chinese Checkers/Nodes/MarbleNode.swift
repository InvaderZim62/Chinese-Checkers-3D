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
    
    var player: Player!
    
    var color: UIColor {
        player == .computer ? Constant.computerColor : Constant.humanColor
    }

    override init() {
        super.init()
    }

    init(radius: CGFloat, player: Player) {
        super.init()
        self.player = player
        
        name = "Marble"
        
        geometry = SCNSphere(radius: radius)
        geometry?.firstMaterial?.diffuse.contents = color

        physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
