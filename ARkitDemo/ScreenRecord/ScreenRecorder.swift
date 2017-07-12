//
//  ScreenRecorder.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/12.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import Foundation
import ReplayKit
import AVKit
import Photos


class ScreenRecorder {
    var assetWriter:AVAssetWriter!
    var videoInput:AVAssetWriterInput!
    
    let viewOverlay = WindowUtility()
    
    //MARK: Screen Recording
    
    func startRecording(withFileName fileName: String, recordingHandler:@escaping (Error?)-> Void) {
        
        let fileURL = URL(fileURLWithPath: ReplayFileUtility.filePath(fileName))
        assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType:
            AVFileType.mp4)
        let videoOutputSettings: Dictionary<String, Any> = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : UIScreen.main.bounds.size.width,
            AVVideoHeightKey : UIScreen.main.bounds.size.height
        ]
        
        videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        assetWriter.add(videoInput)
        
        RPScreenRecorder.shared().startCapture(handler: { (sample, bufferType, error) in
            recordingHandler(error)
            
            if CMSampleBufferDataIsReady(sample) {
                if self.assetWriter.status == AVAssetWriterStatus.unknown {
                    self.assetWriter.startWriting()
                    self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                }
                
                if self.assetWriter.status == AVAssetWriterStatus.failed {
                    print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
                    return
                }
                
                if (bufferType == .video) {
                    if self.videoInput.isReadyForMoreMediaData {
                        self.videoInput.append(sample)
                    }
                }
            }
            
        }) { (error) in
            recordingHandler(error)
        }
    }
    
    fileprivate func saveToPhotoLibrary() {
        let urls = ReplayFileUtility.fetchAllReplays()
        for videoURL in urls {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { saved, error in
                if saved {
                    print("Your video was successfully saved")
                }
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    func stopRecording(handler: @escaping (Error?) -> Void) {
        RPScreenRecorder.shared().stopCapture { (error) in
            handler(error)
            self.assetWriter.finishWriting {
                print(ReplayFileUtility.fetchAllReplays())
                self.saveToPhotoLibrary()
            }
        }
    }
    
}
