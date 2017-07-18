//
//  ViewController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/11.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SceneKit.ModelIO

class RecordVideoViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var recordButton: UIButton!
    var virtualObject: SCNNode = SCNNode()
    
    // MARK: Methods
    
    fileprivate func addRecordButton() {
        let width = view.frame.width
        let height = view.frame.height
        recordButton = UIButton()
        recordButton.frame = CGRect(x: (width - 50)/2, y: height - 150, width: 50, height: 50)
        recordButton.setImage(UIImage(named: "ic_videocam"), for: .normal)
        recordButton.setImage(UIImage(named: "ic_videocam_white"), for: .highlighted)
        recordButton.contentMode = .scaleAspectFill
        recordButton.addTarget(self, action: #selector(record), for: .touchUpInside)
        sceneView.addSubview(recordButton)
    }
    
    @objc fileprivate func record() {
        let screenRecord = ScreenRecordCoordinator()
        let randomNumber = arc4random_uniform(9999)
        screenRecord.viewOverlay.stopButtonColor = UIColor.red
        screenRecord.startRecording(withFileName: "coolScreenRecording\(randomNumber)", recordingHandler: { error in
            print("Recording in progress")
        }) { error in
            print("Recording Complete")
        }
    }
    
    // MARK: Lifecycle
    
    fileprivate func setupScene() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // load 3D model (obj file)
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: "Eevee", withExtension: "obj") else {
            fatalError("Failed to find model file")
        }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else {
            fatalError("Failed to get mesh from asset")
        }
        virtualObject = SCNNode.init(mdlObject: object)
        virtualObject.simdPosition = float3(0, -0.5, -0.5)
        virtualObject.scale = SCNVector3(0.1, 0.1, 0.1)
        
        let scene = SCNScene()
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
        sceneView.scene.rootNode.addChildNode(virtualObject)
    }
    
    @objc fileprivate func changePositionFrom(recognizer: UIPanGestureRecognizer) {
        let tapPoint = recognizer.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: .featurePoint)
        
        guard let hitResult = result.first else { return }
//        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
//        virtualObject.position = position
        let position = simd_float3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        virtualObject.simdPosition = position
    }
    
    fileprivate func setupRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(changePositionFrom(recognizer:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        addRecordButton()
        setupRecognizers()
        record()
    }
    
    fileprivate func setupSession() {
        let configuration = ARWorldTrackingSessionConfiguration()
        
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

extension RecordVideoViewController: ARSCNViewDelegate {
    
}
