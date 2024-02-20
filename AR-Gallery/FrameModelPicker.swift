//
//  FrameModelPicker.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/13/24.
//

import SwiftUI
import RealityKit
import Combine
import ARKit

class FrameModelPicker {
    private var frameModels: [FrameModel]

    init(numOfFrames: Int = 5) {
        self.frameModels = (1...numOfFrames).map { FrameModel(modelName: "frame\($0)") }
    }

    func getRandomFrameModel() -> ModelEntity? {
        return frameModels.randomElement()?.modelEntity?.clone(recursive: true)
    }

    func getFrameModel(index: Int) -> ModelEntity? {
        guard index >= 0 && index < frameModels.count else { return nil }
        return frameModels[index].modelEntity?.clone(recursive: true)
    }
}

class FrameModel {
    var modelName: String
    var modelEntity: ModelEntity?
    private var cancellable: AnyCancellable?

    init(modelName: String, fileExtension: String = ".usdz") {
        self.modelName = modelName
        let filename = modelName + fileExtension
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletion in
                if case .failure(let error) = loadCompletion {
                    print("Unable to load modelEntity \(filename). Error: \(error.localizedDescription)")
                }
            }, receiveValue: { modelEntity in
                self.modelEntity = modelEntity
                print("Successfully loaded modelEntity for modelName: \(self.modelName)")
            })
    }
}
