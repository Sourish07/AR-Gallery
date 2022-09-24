//
//  FrameModel.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/16/22.
//

import SwiftUI
import RealityKit
import Combine
import ARKit

class FrameModel: ObservableObject {
    var modelName: String
    var fileExtension: String
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable?
    
    init(modelName: String, fileExtension: String = ".usdz.") {
        self.modelName = modelName
        self.fileExtension = fileExtension
        
        let filename = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletion in
                switch loadCompletion {
                case .failure(let error): print("Unable to load modelEntity. Error: \(error.localizedDescription)")
                case .finished:
                    break
                }
                // Handle error
                //print("DEBUG: Unable to load modelEntity for modelName: \(self.modelName)")
            }, receiveValue: { modelEntity in
                // Get modelEntity
                self.modelEntity = modelEntity
                print("DEBUG: Successfully loaded modelEntity for modelName: \(self.modelName)")
            })
    }
    
    static func initFrames() -> [FrameModel] {
        var frames: [FrameModel] = []
        for i in 1...5 {
            let filename = "frame\(i)"
            frames.append(.init(modelName: filename))
        }
        return frames
    }
}
