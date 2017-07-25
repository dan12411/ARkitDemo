//
//  SceneKitViewController.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/19.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import SceneKit
import GPUImage
import Photos

class SceneKitViewController: UIViewController {
    
    // Renders a scene (and shows it on the screen)
    var scnView: SCNView!
    
    // Another renderer
    var secondaryRenderer: SCNRenderer?
    
    // Abducts image data via an OpenGL texture
    var textureInput: GPUImageTextureInput?
    
    // Recieves image data from textureInput, shows it on screen
    var gpuImageView: GPUImageView!
    
    // Recieves image data from the textureInput, writes to a file
    var movieWriter: GPUImageMovieWriter?
    
    // Where to write the output file
    var path = NSTemporaryDirectory().appending("tmp.mp4")
    
    // Output file dimensions
    let videoSize = CGSize(width: 800.0, height: 600.0)
    
    // EAGLContext in the sharegroup with GPUImage
    var eaglContext: EAGLContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let group = GPUImageContext.sharedImageProcessing().context.sharegroup
        self.eaglContext = EAGLContext(api: .openGLES2, sharegroup: group )
        let options = ["preferredRenderingAPI": SCNRenderingAPI.openGLES2]
        
        // Main view with 3d in it
        self.scnView = SCNView(frame: CGRect.zero, options: options)
        self.scnView.preferredFramesPerSecond = 60
        self.scnView.eaglContext = eaglContext
        self.scnView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scnView)
        
        // Secondary renderer for rendering to an OpenGL framebuffer
        self.secondaryRenderer = SCNRenderer(context: eaglContext, options: options)
        
        // Output of the GPUImage pipeline
        self.gpuImageView = GPUImageView()
        self.gpuImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.gpuImageView)
        
        self.setupConstraints()
        
        self.setupScene()
        
        self.setupMovieWriter()
        
        DispatchQueue.main.async {
            self.setupOpenGL()
        }
    }
    
    func setupConstraints() {
        let relativeWidth: CGFloat = 0.8
        
        self.view.addConstraint(NSLayoutConstraint(item: self.scnView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: relativeWidth, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.scnView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: self.gpuImageView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: relativeWidth, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.gpuImageView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==30.0)-[scnView]-(==30.0)-[gpuImageView]", options: [], metrics: [:], views: ["gpuImageView": gpuImageView, "scnView": scnView]))
        
        let videoRatio = self.videoSize.width / self.videoSize.height
        self.view.addConstraint(NSLayoutConstraint(item: self.scnView, attribute: .width, relatedBy: .equal, toItem: self.scnView, attribute: .height, multiplier: videoRatio, constant: 1))
        self.view.addConstraint(NSLayoutConstraint(item: self.gpuImageView, attribute: .width, relatedBy: .equal, toItem: self.gpuImageView, attribute: .height, multiplier: videoRatio, constant: 1))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.cameraBoxNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0.0, y: -2 * CGFloat.pi, z: 0.0, duration: 8.0)
                )!
        )
        
        self.scnView.isPlaying = true
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: {
            timer in
            self.startRecording()
        })
    }
    
    var scene: SCNScene!
    var geometryNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraBoxNode: SCNNode!
    var imageMaterial: SCNMaterial!
    func setupScene() {
        self.imageMaterial = SCNMaterial()
        self.imageMaterial.isDoubleSided = true
        self.imageMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        self.imageMaterial.diffuse.wrapS = .repeat
        self.imageMaterial.diffuse.contents = UIImage(named: "tron_grid")
        
        self.scene = SCNScene()
        
        let sphere = SCNSphere(radius: 100.0)
        sphere.materials = [imageMaterial!]
        self.geometryNode = SCNNode(geometry: sphere)
        self.geometryNode.position = SCNVector3Make(0.0, 0.0, 0.0)
        scene.rootNode.addChildNode(self.geometryNode)
        
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.fieldOfView = 72.0
        self.cameraNode.position = SCNVector3Make(0, 0, 0)
        self.cameraNode.eulerAngles = SCNVector3Make(0.0, 0.0, 0.0)
        
        self.cameraBoxNode = SCNNode()
        self.cameraBoxNode.addChildNode(self.cameraNode)
        scene.rootNode.addChildNode(self.cameraBoxNode)
        
        self.scnView.scene = scene
        self.scnView.backgroundColor = UIColor.darkGray
        self.scnView.autoenablesDefaultLighting = true
    }
    
    func setupMovieWriter() {
//        let _ = FileUtil.mkdirUsingFile(path)
//        let _ = FileUtil.unlink(path)
        let randomNumber = arc4random_uniform(9999)
        let filePath = FileUtil.filePath("ScreenRecording\(randomNumber)")
        self.path = filePath
        let url = URL(fileURLWithPath: filePath)
        self.movieWriter = GPUImageMovieWriter(movieURL: url, size: self.videoSize)
    }
    
    let glRenderQueue = GPUImageContext.sharedContextQueue()!
    var outputTexture: GLuint = 0
    var outputFramebuffer: GLuint = 0
    func setupOpenGL() {
        self.glRenderQueue.sync {
            let context = EAGLContext.current()
            if context != self.eaglContext {
                EAGLContext.setCurrent(self.eaglContext)
            }
            
            glGenFramebuffers(1, &self.outputFramebuffer)
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.outputFramebuffer)
            
            glGenTextures(1, &self.outputTexture)
            glBindTexture(GLenum(GL_TEXTURE_2D), self.outputTexture)
        }
        
        // Pipe the texture into GPUImage-land
        self.textureInput = GPUImageTextureInput(texture: self.outputTexture, size: self.videoSize)
        
        let rotate = GPUImageFilter()
        rotate.setInputRotation(kGPUImageFlipVertical, at: 0)
        self.textureInput?.addTarget(rotate)
        rotate.addTarget(self.gpuImageView)
        
        if let writer = self.movieWriter {
            rotate.addTarget(writer)
        }
        
        // Call me back on every render
        self.scnView.delegate = self
    }
    
    func renderToFramebuffer(atTime time: TimeInterval) {
        self.glRenderQueue.sync {
            let context = EAGLContext.current()
            if context != self.eaglContext {
                EAGLContext.setCurrent(self.eaglContext)
            }
            
            objc_sync_enter(self.eaglContext)
            
            let width = GLsizei(self.videoSize.width)
            let height = GLsizei(self.videoSize.height)
            
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.outputFramebuffer)
            glBindTexture(GLenum(GL_TEXTURE_2D), self.outputTexture)
            
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, width, height, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
            
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            
            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), self.outputTexture, 0)
            
            glViewport(0, 0, width, height)
            
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
            
            self.secondaryRenderer?.render(atTime: time)
            
            self.videoBuildingQueue.sync {
                self.textureInput?.processTexture(withFrameTime: CMTime(seconds: time, preferredTimescale: 100000))
            }
            
            objc_sync_exit(self.eaglContext)
        }
        
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
            //inOrientation: CGAffineTransform(scaleX: 1.0, y: -1.0)
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
//        assert(FileUtil.fileExists(self.path), "Check for file output")
        
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

extension SceneKitViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        self.secondaryRenderer?.scene = scene
        self.secondaryRenderer?.pointOfView = (renderer as! SCNView).pointOfView
        self.renderToFramebuffer(atTime: time)
    }
}
