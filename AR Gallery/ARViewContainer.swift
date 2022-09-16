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

import Combine

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedImageForPlacement: UIImage?
    @Binding var confirmedImageForPlacement: UIImage?
    
    var frameModel: FrameModel = FrameModel(modelName: "frame")
    
    func makeUIView(context: Context) -> CustomARView {

        let arView = CustomARView(frame: .zero)
        return arView

    }

    func updateUIView(_ uiView: CustomARView, context: Context) {
        uiView.focusEntity?.isEnabled = self.selectedImageForPlacement != nil
        if let uiImage = confirmedImageForPlacement {
            
            let cgImage = uiImage.cgImage
            let textureResource = try! TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: .raw))
            let imgTexture = MaterialParameters.Texture.init(textureResource)

            let longerLength: Float = 0.5
            var planeHeight: Float? = nil
            var planeWidth: Float? = nil
            if imgTexture.resource.height > imgTexture.resource.width {
                planeHeight = longerLength
                planeWidth = Float(imgTexture.resource.width) / (Float(imgTexture.resource.height) / longerLength)
            } else {
                planeWidth = longerLength
                planeHeight = Float(imgTexture.resource.height) / (Float(imgTexture.resource.width) / longerLength)
            }

            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: imgTexture)
            material.roughness = 1
            material.metallic = 1

            let mesh = MeshResource.generatePlane(width: planeWidth!, depth: planeHeight!)
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
            if (uiImage.imageOrientation == .right) {
                modelEntity.transform = Transform(pitch: 0, yaw: -.pi/2, roll: 0)
            }
            
            
            let anchorEntity = AnchorEntity(plane: .any)
            //anchorEntity.addChild(modelEntity.clone(recursive: true))
            anchorEntity.addChild((frameModel.modelEntity!.clone(recursive: true)))
            
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
        config.planeDetection = [.vertical, .horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        self.session.run(config)
    }
}
