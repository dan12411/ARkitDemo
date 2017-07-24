//
//  GPUImageViewController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/19.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit
import GPUImage
import Photos
import ARKit

class GPUImageViewController: UIViewController {
    
//    @IBOutlet weak var previewView: GPUImageView!
    @IBOutlet weak var previewView: ARSCNView!
    // Recieves image data from textureInput, shows it on screen
    var gpuImageView: GPUImageView! = GPUImageView()
    
    var videoCamera: GPUImageVideoCamera?
    var filter: GPUImageFilter?
    
    // Recieves image data from the textureInput, writes to a file
    var movieWriter: GPUImageMovieWriter?
    
    // Where to write the output file
    var path = NSTemporaryDirectory().appending("tmp.mp4")
    
    // Output file dimensions
    let videoSize = CGSize(width: floor(UIScreen.main.bounds.size.width / 16) * 16, height: floor(UIScreen.main.bounds.size.height / 16) * 16)
    
    func setupMovieWriter() {
        let randomNumber = arc4random_uniform(9999)
        let filePath = FileUtil.filePath("ScreenRecording\(randomNumber)")
        self.path = filePath
        let url = URL(fileURLWithPath: filePath)
        self.movieWriter = GPUImageMovieWriter(movieURL: url, size: self.videoSize)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.delegate = self
        previewView.showsStatistics = true
        previewView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let scene = SCNScene(named: "Assets.scnassets/ship.scn")!
        previewView.scene = scene
        
        let uielement = GPUImageUIElement(view: self.previewView)
        
        self.videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: .back)
        self.videoCamera!.outputImageOrientation = .portrait
        self.filter = GPUImageFilter()
        self.videoCamera?.addTarget(filter)
//        self.filter?.addTarget(self.previewView)
        self.videoCamera?.startCapture()
        
        setupMovieWriter()
        if let writer = self.movieWriter {
            self.filter?.addTarget(writer)
        }
        
        uielement?.frameProcessingCompletionBlock = {filter, time in
            uielement?.update()
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: {
            timer in
            self.startRecording()
        })
    }
    
    func startRecording() {
        self.startRecord()
        Timer.scheduledTimer(withTimeInterval: 24.0, repeats: false, block: {
            timer in
            self.stopRecord()
        })
    }
    
    let videoBuildingQueue = DispatchQueue.global(qos: .default)
    
    func startRecord() {
        self.videoBuildingQueue.sync {
            self.movieWriter?.startRecording()
        }
    }
    
    var renderStartTime: TimeInterval = 0
    
    func stopRecord() {
        self.videoBuildingQueue.sync {
            self.movieWriter?.finishRecording(completionHandler: {
                self.saveFileToCameraRoll()
            })
        }
    }
    
    func saveFileToCameraRoll() {
        
        DispatchQueue.global(qos: .utility).async {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: self.path))
            }) { (done, err) in
                if err != nil {
                    print("Error creating video file in library")
                    print(err.debugDescription)
                } else {
                    print("Done writing asset to the user's photo library")
                }
            }
        }
    }
    
}

// MARK: ARSCNViewDelegate

extension GPUImageViewController: ARSCNViewDelegate {
    
}

