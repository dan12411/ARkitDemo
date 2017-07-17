//
//  Cube.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/17.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit
import ARKit

var currentMaterialIndex = 0

class Cube: SCNNode {
    init(_ position: SCNVector3, with material: SCNMaterial) {
        super.init()
        
        let dimension: Float = 0.1
        let cube = SCNBox(width: CGFloat(dimension), height: CGFloat(dimension), length: CGFloat(dimension), chamferRadius: 0)
        cube.materials = [material]
        let node = SCNNode(geometry: cube)
        
        // The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = CollisionCategory.cube.rawValue
        node.position = position
        
        self.addChildNode(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func currentMaterial() -> SCNMaterial {
        var materialName: String
        switch currentMaterialIndex {
        case 0:
            materialName = "rustediron-streaks"
        case 1:
            materialName = "carvedlimestoneground"
        case 2:
            materialName = "granitesmooth"
        case 3:
            materialName = "old-textured-fabric"
        default:
            materialName = "rustediron-streaks"
        }
        
        return PBRMaterial.materialNamed(name: materialName)
    }
    
    func changeMaterial() {
        // Static, all future cubes use this to have the same material
        currentMaterialIndex = (currentMaterialIndex + 1) % 4
        self.childNodes.first?.geometry?.materials = [Cube.currentMaterial()]
    }
}

