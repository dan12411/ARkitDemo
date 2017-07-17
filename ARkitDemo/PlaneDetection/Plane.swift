//
//  Plane.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/13.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import ARKit

class Plane: SCNNode {
    var anchor: ARPlaneAnchor?
    var planeGeometry: SCNBox = SCNBox()
    
    fileprivate func setTextureScale() {
        let width: CGFloat = self.planeGeometry.width
        let height: CGFloat = self.planeGeometry.length
        
        // As the width/height of the plane updates, we want our tron grid material to
        // cover the entire plane, repeating the texture over and over. Also if the
        // grid is less than 1 unit, we don't want to squash the texture to fit, so
        // scaling updates the texture co-ordinates to crop the texture in that case
        let material: SCNMaterial = self.planeGeometry.materials[4]
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
    
    init(anchor: ARPlaneAnchor, isHidden hidden: Bool) {
        super.init()
        self.anchor = anchor
        let width: CGFloat = CGFloat(anchor.extent.x)
        let length: CGFloat = CGFloat(anchor.extent.z)
        let planeHeight: CGFloat = 0.01
        self.planeGeometry = SCNBox(width: width, height: planeHeight, length: length, chamferRadius: 0)
        
        // Instead of just visualizing the grid as a gray plane, we will render
        // it in some Tron style colours.
        let material = SCNMaterial()
        let img = UIImage(named:"tron_grid")
        material.diffuse.contents = img
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white:1.0, alpha: 0)
        
        if hidden {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial]
        } else {
            self.planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial,  material, transparentMaterial]
        }
        
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        
        setTextureScale()
        self.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
