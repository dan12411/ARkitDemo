//
//  ScreenRecordCoordinator.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/12.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import Foundation

class ScreenRecordCoordinator: NSObject {
    let viewOverlay = WindowUtility()
    let screenRecorder = ScreenRecorder()
    var recordCompleted: ((Error?) -> Void)?
    
    override init() {
        super.init()
        viewOverlay.onStopClick = {
            self.stopRecording()
        }
    }
    
    func startRecording(withFileName fileName: String, recordingHandler: @escaping (Error?) -> Void, onCompletion: @escaping (Error?)->Void) {
        self.viewOverlay.show()
        screenRecorder.startRecording(withFileName: fileName) { (error) in
            recordingHandler(error)
            self.recordCompleted = onCompletion
        }
    }
    
    func stopRecording() {
        screenRecorder.stopRecording { (error) in
            self.viewOverlay.hide()
            self.recordCompleted?(error)
        }
    }
    
    class func listAllReplays() -> Array<URL> {
        return ReplayFileUtility.fetchAllReplays()
    }
    
}

