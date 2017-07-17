//
//  ARCubeController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/14.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit
import ARKit

class ARCubeViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var planes: [UUID:Plane] = [:]
    var boxes: Array<SCNNode> = []
    
    // MARK: Lifecycle
    
    fileprivate func setupScene() {
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        // Turn on debug options to show the world origin and also render all of the feature points ARKit is tracking
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    fileprivate func setupPhysics() {
        // For our physics interactions, we place a large node a couple of meters below the world
        // origin, after an explosion, if the geometry we added has fallen onto this surface which
        // is place way below all of the surfaces we would have detected via ARKit then we consider
        // this geometry to have fallen out of the world and remove it
        let bottomPlane = SCNBox(width: 1000, height: 0.5, length: 1000, chamferRadius: 0)
        let bottomMaterial = SCNMaterial()
        
        // Make it transparent so you can't see it
        bottomMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0)
        bottomPlane.materials = [bottomMaterial]
        let bottomNode = SCNNode(geometry: bottomPlane)
        
        // Place it way below the world origin to catch all falling cubes
        bottomNode.position = SCNVector3Make(0, -10, 0)
        bottomNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bottomNode.physicsBody?.categoryBitMask = CollisionCategory.bottom.rawValue
        bottomNode.physicsBody?.contactTestBitMask = CollisionCategory.cube.rawValue
        
        let scene = sceneView.scene
        scene.rootNode.addChildNode(bottomNode)
        scene.physicsWorld.contactDelegate = self
    }
    
    fileprivate func insertGeometry(_ hitResult: ARHitTestResult) {
        let dimension: CGFloat = 0.1
        let cube = SCNBox(width: dimension, height: dimension, length: dimension, chamferRadius: 0)
        let node = SCNNode(geometry: cube)
        
        // The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = CollisionCategory.cube.rawValue
        
        // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
        // using the physics engine
        let insertionYOffset: Float = 0.5
        node.position = SCNVector3Make(hitResult.worldTransform[3].x,
                                       hitResult.worldTransform[3].y + insertionYOffset,
                                       hitResult.worldTransform[3].z)
        sceneView.scene.rootNode.addChildNode(node)
        boxes.append(node)
    }
    
    @objc fileprivate func insertCubeFrom(_ recognizer: UITapGestureRecognizer) {
        let tapPoint = recognizer.location(in: sceneView)
        let result: Array<ARHitTestResult> = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        guard let hitResult = result.first else { return }
        insertGeometry(hitResult)
    }
    
    fileprivate func explode(_ hitResult: ARHitTestResult) {
        let explosionYOffset: Float = 0.1
        let position = SCNVector3Make(hitResult.worldTransform[3].x,
                                      hitResult.worldTransform[3].y - explosionYOffset,
                                      hitResult.worldTransform[3].z)
        for cubeNode in boxes {
            var distance = SCNVector3Make(cubeNode.worldPosition.x - position.x,
                                          cubeNode.worldPosition.y - position.y,
                                          cubeNode.worldPosition.z - position.z)
            
            let len: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            let maxDistance: Float = 2
            var scale: Float = max(0, (maxDistance - len))
            
            // Scale the force of the explosion
            scale = scale * scale * 2
            
            // Scale the distance vector to the appropriate scale
            distance.x = distance.x / len * scale
            distance.y = distance.y / len * scale
            distance.z = distance.z / len * scale
            
            // Apply a force to the geometry. We apply the force at one of the corners of the cube
            // to make it spin more, vs just at the center
            cubeNode.physicsBody?.applyForce(distance, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
        }
    }
    
    @objc fileprivate func explodeFrom(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != UIGestureRecognizerState.began { return }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // a plane.
        let holdPoint = recognizer.location(in: sceneView)
        let result: Array<ARHitTestResult> = sceneView.hitTest(holdPoint, types: .existingPlaneUsingExtent)
        
        guard let hitResult = result.first else { return }
        explode(hitResult)
    }
    
    @objc fileprivate func handleHidePlaneFrom(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != UIGestureRecognizerState.began { return }
        
        // Hide all the planes
        for (planeID, _) in planes {
            planes[planeID]?.hide()
        }
        
        // Stop detecting new planes or updating existing ones.
        let configuration = ARWorldTrackingSessionConfiguration()
        sceneView.session.run(configuration)
    }
    
    fileprivate func setupRecognizers() {
        // Single tap will insert a new piece of geometry into the scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(insertCubeFrom(_:)))
        let explosionGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(explodeFrom(_:)))
        let hidePlanesGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleHidePlaneFrom(_:)))
        hidePlanesGestureRecognizer.minimumPressDuration = 1
        hidePlanesGestureRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(explosionGestureRecognizer)
        sceneView.addGestureRecognizer(hidePlanesGestureRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupPhysics()
        setupRecognizers()
    }
    
    fileprivate func setupSession() {
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: ARSession
    
    func session(_ session: ARSession, didFailWithError error: Error) {
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
    }
    
}

// MARK: ARSCNViewDelegate

extension ARCubeViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            return
        }
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = Plane(anchor: anchor as! ARPlaneAnchor, isHidden: false)
        self.planes[anchor.identifier] = plane
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = self.planes[anchor.identifier] else { return }
        // When an anchor is updated we need to also update our 3D geometry too. For example
        // the width and height of the plane detection may have changed so we need to update
        // our SceneKit geometry to match that
        plane.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Nodes will be removed if planes multiple individual planes that are detected to all be
        // part of a larger plane are merged.
        self.planes.removeValue(forKey: anchor.identifier)
    }
}

// MARK: SCNPhysicsContactDelegate

extension ARCubeViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Here we detect a collision between pieces of geometry in the world, if one of the pieces
        // of geometry is the bottom plane it means the geometry has fallen out of the world. just remove it
        guard let physicsBodyA = contact.nodeA.physicsBody, let physicsBodyB = contact.nodeB.physicsBody else {
            return
        }
        
        let categoryA = CollisionCategory.init(rawValue: physicsBodyA.categoryBitMask)
        let categoryB = CollisionCategory.init(rawValue: physicsBodyB.categoryBitMask)
        
        let contactMask: CollisionCategory? = [categoryA, categoryB]
        
        if contactMask == [CollisionCategory.bottom, CollisionCategory.cube] {
            if categoryA == CollisionCategory.bottom {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
}

