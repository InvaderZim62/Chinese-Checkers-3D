//
//  HolePositions.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//
//  usage: let globalData = GlobalData.shared
//

import UIKit
import SceneKit

class GlobalData: NSObject {
    
    static let shared = GlobalData()
    
    private override init() { }  // private to prevent: let globalData = GlobalData() (a non-shared instance)
    
    var holePositions = [RowCol: SCNVector3]()
    var searchDepth = 1  // controlled by switch (1: easy, 3: hard)
}
