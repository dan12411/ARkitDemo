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
    var cubes: [Cube] = []
    var config = Config()
    var arConfig = ARWorldTrackingSessionConfiguration()
    
    // MARK: Lifecycle
    
    fileprivate func setupScene() {
        sceneView.delegate = self
        
        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
        
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
    
    fileprivate func setupLights() {
        // Turn off all the default lights SceneKit adds since we are handling it ourselves
        self.sceneView.autoenablesDefaultLighting = false
        self.sceneView.automaticallyUpdatesLighting = false
        
        let env = UIImage(named: "./Assets.scnassets/Environment/spherical.jpg")
        self.sceneView.scene.lightingEnvironment.contents = env
    }
    
    fileprivate func insertCube(_ hitResult: ARHitTestResult) {
        // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
        // using the physics engine
        let insertionYOffset: Float = 0.5
        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y.advanced(by: insertionYOffset), hitResult.worldTransform.columns.3.z)
        
        let cube = Cube.init(position, with: Cube.currentMaterial())
        self.cubes.append(cube)
        self.sceneView.scene.rootNode.addChildNode(cube)
    }
    
    @objc fileprivate func insertCubeFrom(_ recognizer: UITapGestureRecognizer) {
        // Take the screen space tap coordinates and pass them to the hitTest method on the ARSCNView instance
        let tapPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        // If the intersection ray passes through any plane geometry they will be returned, with the planes
        // ordered by distance from the camera
        // If there are multiple hits, just pick the closest plane
        guard let hitResult = result.first else { return }
        insertCube(hitResult)
    }
    
    fileprivate func explode(_ hitResult: ARHitTestResult) {
        // For an explosion, we take the world position of the explosion and the position of each piece of geometry
        // in the world. We then take the distance between those two points, the closer to the explosion point the
        // geometry is the stronger the force of the explosion.
        
        // The hitResult will be a point on the plane, we move the explosion down a little bit below the
        // plane so that the goemetry fly upwards off the plane
        let explosionYOffset: Float = 0.1
        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y.advanced(by: -explosionYOffset), hitResult.worldTransform.columns.3.z)
        
        // We need to find all of the geometry affected by the explosion, ideally we would have some
        // spatial data structure like an octree to efficiently find all geometry close to the explosion
        // but since we don't have many items, we can just loop through all of the current geometry
        for cubeNode in cubes {
            var distance = SCNVector3Make(cubeNode.worldPosition.x - position.x, cubeNode.worldPosition.y - position.y, cubeNode.worldPosition.z - position.z)
            let len: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            
            // Set the maximum distance that the explosion will be felt, anything further than 2 meters from
            // the explosion will not be affected by any forces
            let maxDistance: Float = 2
            var scale: Float = max(0, maxDistance - len)
            
            // Scale the force of the explosion
            scale = scale * scale * 5
            
            // Scale the distance vector to the appropriate scale
            distance.x = distance.x / len * scale
            distance.y = distance.y / len * scale
            distance.z = distance.z / len * scale
            
            // Apply a force to the geometry. We apply the force at one of the corners of the cube
            // to make it spin more, vs just at the center
            cubeNode.childNodes.first?.physicsBody?.applyForce(distance, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
        }
    }
    
    @objc fileprivate func explodeFrom(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != UIGestureRecognizerState.began { return }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // a plane.
        let holdPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(holdPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        guard let hitResult = result.first else { return }
        explode(hitResult)
    }
    
    @objc func geometryConfigFrom(recognizer: UITapGestureRecognizer) {
        if recognizer.state != UIGestureRecognizerState.began { return }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // any 3D geometry in the scene, if so we will open a config menu for that
        // geometry to customize the appearance
        let holdPoint = recognizer.location(in: self.sceneView)
        let result = self.sceneView.hitTest(holdPoint, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.firstFoundOnly : true])
        
        guard let hitResult = result.first else { return }
        
        // We add all the geometry as children of the Plane/Cube SCNNode object, so we can
        // get the parent and see what type of geometry this is
        let parentNode = hitResult.node.parent
        if (parentNode?.isKind(of: Cube.classForCoder()))! {
            (parentNode as! Cube).changeMaterial()
        } else {
            (parentNode as! Plane).changeMaterial()
        }
    }
    
    fileprivate func setupRecognizers() {
        // Single tap will insert a new piece of geometry into the scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(insertCubeFrom))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Press and hold will open a config menu for the selected geometry
        let materialGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(geometryConfigFrom))
        materialGestureRecognizer.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(materialGestureRecognizer)
        
        // Press and hold with two fingers causes an explosion
        let explodeGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(explodeFrom))
        explodeGestureRecognizer.minimumPressDuration = 1
        explodeGestureRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(explodeGestureRecognizer)    }
    
    fileprivate func updateConfig() {
        var opts = SCNDebugOptions.init(rawValue: 0)
        let config = self.config
        if (config.showWorldOrigin) {
            opts = [opts, ARSCNDebugOptions.showWorldOrigin]
        }
        if (config.showFeaturePoints) {
            opts = ARSCNDebugOptions.showFeaturePoints
        }
        if (config.showPhysicsBodies) {
            opts = [opts, SCNDebugOptions.showPhysicsShapes]
        }
        self.sceneView.debugOptions = opts
        if (config.showStatistics) {
            self.sceneView.showsStatistics = true
        } else {
            self.sceneView.showsStatistics = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupPhysics()
        setupLights()
        setupRecognizers()
        
        // Create a ARSession configuration object we can re-use
        arConfig = ARWorldTrackingSessionConfiguration()
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
        
        let config = Config()
        config.showStatistics = false
        config.showWorldOrigin = true
        config.showFeaturePoints = true
        config.showPhysicsBodies = false
        config.detectPlanes = true
        self.config = config
        updateConfig()
        
        // Stop the screen from dimming while we are using the app
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Run the view's session
        self.sceneView.session.run(self.arConfig)
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
    
    private func disableTracking(disabled: Bool) {
        // Stop detecting new planes or updating existing ones.
        
        if disabled {
            self.arConfig.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.init(rawValue: 0)
        } else {
            self.arConfig.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
        }
        
        self.sceneView.session.run(self.arConfig)
    }
    
    @IBAction func settingsUnwind(segue: UIStoryboardSegue) {
        // Called after we navigate back from the config screen
        
        let configView = segue.source as! ConfigViewController
        let config = self.config
        
        config.showPhysicsBodies = configView.physicsBodies.isOn
        config.showFeaturePoints = configView.featurePoints.isOn
        config.showWorldOrigin = configView.worldOrigin.isOn
        config.showStatistics = configView.statistics.isOn
        self.updateConfig()
    }
    
    @IBAction func detectPlanesChanged(_ sender: Any) {
        let enabled = (sender as! UISwitch).isOn
        
        if enabled == self.config.detectPlanes {
            return
        }
        
        self.config.detectPlanes = enabled
        if enabled {
            self.disableTracking(disabled: false)
        } else {
            self.disableTracking(disabled: true)
        }
    }
    
}

// MARK: ARSCNViewDelegate

extension ARCubeViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = self.sceneView.session.currentFrame?.lightEstimate else {
            return
        }
        
        // A value of 1000 is considered neutral, lighting environment intensity normalizes
        // 1.0 to neutral so we need to scale the ambientIntensity value
        let intensity = estimate.ambientIntensity / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.classForCoder()) {
            return
        }
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = Plane(anchor: anchor as! ARPlaneAnchor, isHidden: false, withMaterial: Plane.currentMaterial()!)
        planes[anchor.identifier] = plane
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

