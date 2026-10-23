//
//  Scene.swift
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

import Foundation
import SceneKit

class Scene {
    
    var scnScene: SCNScene!
    var scnView: SCNView!
    var cameraNode: SCNNode!

    private var view: UIView!  // GameViewController's view

    init(view: UIView) {
        self.view = view
        setupScene()
        setupView()
        setupCamera()
    }

    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "Background_Diffuse.png"
    }
    
    private func setupView() {
        scnView = view as? SCNView
//        scnView.allowsCameraControl = true  // true: allow standard camera controls with panning, false: move camera programmatically
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = scnScene
//        scnView.debugOptions = .showPhysicsShapes  // for debugging
//        scnView.debugOptions = .showLightInfluences  // show location of lights
    }

    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        if Constant.isOrthographicProjection {
            // far marbles/holes same size as close, also ignores camera distance
            cameraNode.camera?.usesOrthographicProjection = true
            cameraNode.camera?.orthographicScale = 2.2
        }
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, -Float(Constant.cameraAngle), 1, 0, 0)
        let cameraDistance = Constant.nominalCameraDistance * (2 * Float(view.bounds.width) / 375.0 - 1)  // iPhone SE is 375 wide
        cameraNode.position = SCNVector3(0, cameraDistance * sin(Constant.cameraAngle), cameraDistance * cos(Constant.cameraAngle))
        if !Constant.isOrthographicProjection {
            cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(-0.06), 1, 0, 0)  // rotate camera a little more down, to move board up on screen
        }
        scnScene.rootNode.addChildNode(cameraNode)
    }
}
