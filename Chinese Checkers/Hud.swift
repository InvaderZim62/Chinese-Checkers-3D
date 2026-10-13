//
//  Hud.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import Foundation
import SpriteKit
import SceneKit

class Hud: SKScene {
    
    var touchedHudAt: ((CGPoint) -> Void)?  // callback used to pass touch location to GameViewController

    func setup(touchHandler: @escaping (CGPoint) -> Void) {
        touchedHudAt = touchHandler
    }

    // call callback when rotation labels touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchedHudAt?(location)
    }
}
