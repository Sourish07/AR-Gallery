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
                // Handle our error
                print("DEBUG: Unable to load modelEntity for modelName: \(self.modelName)")
            }, receiveValue: { modelEntity in
                // Get our modelEntity
                self.modelEntity = modelEntity
                print("DEBUG: Successfully loaded modelEntity for modelName: \(self.modelName)")
            })
    }
}