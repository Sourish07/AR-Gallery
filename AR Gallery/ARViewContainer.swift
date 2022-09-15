//
//  CustomARView.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/15/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedImageForPlacement: ModelEntity?
    @Binding var confirmedImageForPlacement: ModelEntity?
    
    func makeUIView(context: Context) -> CustomARView {

        let arView = CustomARView(frame: .zero)
        //arView.debugOptions.insert(.showStatistics)
        return arView

    }

    func updateUIView(_ uiView: CustomARView, context: Context) {
        uiView.focusEntity?.isEnabled = self.selectedImageForPlacement != nil
        if let modelEntity = confirmedImageForPlacement {
            
            let anchorEntity = AnchorEntity(plane: .any)
            anchorEntity.addChild(modelEntity.clone(recursive: true))
            
            uiView.scene.addAnchor(anchorEntity)
            
            DispatchQueue.main.async {
                self.confirmedImageForPlacement = nil
            }
        }
    }
}

class CustomARView: ARView {
    var focusEntity: FocusEntity?
    
    let coachingOverlay = ARCoachingOverlayView()
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        focusEntity = FocusEntity(on: self, focus: .classic)
        
        self.setupARView()
    }
    
    @MainActor @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        self.session.run(config)
    }
}
