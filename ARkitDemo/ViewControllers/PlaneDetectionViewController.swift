//
//  PlaneDetectionViewController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/13.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit
import ARKit

class PlaneDetectionViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var planes: Dictionary<UUID, Plane> = [:]
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
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

extension PlaneDetectionViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            return
        }
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = Plane(anchor: anchor as! ARPlaneAnchor)
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
