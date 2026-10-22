//
//  PathNode.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/20/26.
//
//  Note: Default SCNPlane nodes are xy-planes (perpendicular to z-axis).
//

import UIKit
import SceneKit

class PathNode: SCNNode {
    
    let globalData = GlobalData.shared
    
    func createPathThroughSequence(_ moveSequence: [Move], color: UIColor) {
        childNodes.forEach { $0.removeFromParentNode() }
        for move in moveSequence {
            let planeNode = SCNNode()
            let plane = SCNPlane(width: move.distance, height: Constant.pathWidth)
            plane.firstMaterial?.diffuse.contents = color
//            plane.firstMaterial?.isDoubleSided = true
            planeNode.geometry = plane
            planeNode.transform = SCNMatrix4Rotate(planeNode.transform, -.pi / 2, 1, 0, 0)  // rotate before setting position
            planeNode.transform = SCNMatrix4Rotate(planeNode.transform, move.bearing, 0, 0, 1)  // 0 deg along x-axis, 90 deg along z-axis
            planeNode.position = move.midPoint// - SCNVector3(x: 0, y: 0.05, z: 0)  // flush with board
            addChildNode(planeNode)

//            createDot(at: globalData.holePositions[move.from]!, color: .green)
//            createDot(at: move.midPoint, color: .blue)
//            createDot(at: globalData.holePositions[move.to]!, color: .red)
        }
    }
    
    func createDot(at position: SCNVector3, color: UIColor) {
        let dot = SCNSphere(radius: 0.02)
        dot.firstMaterial?.diffuse.contents = color
        let dotNode = SCNNode(geometry: dot)
        dotNode.position = position
        addChildNode(dotNode)
    }

    override init() {
        super.init()
        name = "Path"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
