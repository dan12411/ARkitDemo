//
//  Plane.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/13.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor
    var planeGeometry: SCNBox
    
    fileprivate func setTextureScale() {
        let width = Float(self.planeGeometry.width)
        let height = Float(self.planeGeometry.length)
        
        // As the width/height of the plane updates, we want our tron grid material to
        // cover the entire plane, repeating the texture over and over. Also if the
        // grid is less than 1 unit, we don't want to squash the texture to fit, so
        // scaling updates the texture co-ordinates to crop the texture in that case
        let material = planeGeometry.materials[4]
        let scaleFactor: Float = 1
        let m = SCNMatrix4MakeScale(width * scaleFactor, height * scaleFactor, 1)
        material.diffuse.contentsTransform = m
        material.roughness.contentsTransform = m
        material.metalness.contentsTransform = m
        material.normal.contentsTransform = m
    }
    
    init(anchor: ARPlaneAnchor, isHidden hidden: Bool, withMaterial material: SCNMaterial) {
        self.anchor = anchor
        let width = CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)

        let planeHeight: CGFloat = 0.01
        self.planeGeometry = SCNBox(width: width, height: planeHeight, length: length, chamferRadius: 0)
        
        super.init()
        
        // Instead of just visualizing the grid as a gray plane, we will render
        // it in some Tron style colours.
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        
        if hidden {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
        } else {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial]
        }
        
        let planeNode = SCNNode(geometry: self.planeGeometry)
        
        // Since our plane has some height, move it down to be at the actual surface
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        
        // Give the plane a physics body so that items we add to the scene interact with it
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        
        setTextureScale()
        self.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeMaterial() {
        // Static, all future cubes use this to have the same material
        currentMaterialIndex = (currentMaterialIndex + 1) % 5
        
        var material = Plane.currentMaterial()
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        if material == nil {
            material = transparentMaterial
        }
        let transform = self.planeGeometry.materials[4].diffuse.contentsTransform
        material!.diffuse.contentsTransform = transform
        material!.roughness.contentsTransform = transform
        material!.metalness.contentsTransform = transform
        material!.normal.contentsTransform = transform
        self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material!, transparentMaterial]
    }
    
    class func currentMaterial() -> SCNMaterial? {
        var materialName: String
        switch currentMaterialIndex {
        case 0:
            materialName = "tron"
        case 1:
            materialName = "oakfloor2"
        case 2:
            materialName = "sculptedfloorboards"
        case 3:
            materialName = "granitesmooth"
        case 4:
            // planes will be transparent
            return nil
        default:
            return nil
        }
        
        return PBRMaterial.materialNamed(name: materialName)
    }
    
    func update(anchor: ARPlaneAnchor) {
        // As the user moves around the extend and location of the plane
        // may be updated. We need to update our 3D geometry to match the
        // new parameters of the plane.
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.length = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes
        // transform contains the translation parameters. As the plane is updated
        // the planes translation remains the same but it's center is updated so
        // we need to update the 3D geometry position
        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        if let node = self.childNodes.first {
            node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        }
        self.setTextureScale()
    }
    
    func hide() {
        let transparentMaterial: SCNMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = [UIColor(white:1.0 ,alpha:0)]
        planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
    }
}
