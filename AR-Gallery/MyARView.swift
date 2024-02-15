//
//  MyARView.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/13/24.
//

import RealityKit
import ARKit
import FocusEntity

class MyARView: ARView {
    var focusEntity: FocusEntity?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        // Creates FocusEntity and attaches it to the ARView
        focusEntity = FocusEntity(on: self, focus: .classic)
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.vertical]
        
        // Used to create a cube map of environment for reflections
        arConfig.environmentTexturing = .automatic
        
        // Enables humans and real objects to occlude virtual object
        arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        self.environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Shows real-time mesh that's created by ARKit
        // arView.debugOptions.insert(.showSceneUnderstanding)
        
        // Uses LiDAR if available for increased AR stability
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            arConfig.sceneReconstruction = .mesh
        }
        self.session.run(arConfig)

        // Installing double tap gesture to delete model
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.deleteImage(_:)))
        tapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapGesture)
    }

    @objc func deleteImage(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: self) else {
            return
        }

        guard let frameModel = self.entity(at: touchInView) as? ModelEntity else {
            return
        }

        self.scene.removeAnchor(frameModel.anchor!)
    }
    
    // Function must be provided by subclass of ARView
    @MainActor @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
