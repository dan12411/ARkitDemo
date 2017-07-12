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

class RecordVideoViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var recordButton: UIButton!
    
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
        screenRecord.startRecording(withFileName: "coolScreenRecording\(randomNumber)", recordingHandler: { error in
            print("Recording in progress")
        }) { error in
            print("Recording Complete")
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
        
        addRecordButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingSessionConfiguration()
        
        sceneView.session.run(configuration)
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
