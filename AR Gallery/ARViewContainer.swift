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

            var simpleMaterial = SimpleMaterial()
            simpleMaterial.color = .init(tint: .white, texture: imgTexture)
            simpleMaterial.roughness = 1
            simpleMaterial.metallic = 1
            
            let anchorEntity = AnchorEntity(plane: .any)
            let clonedFrameModel = frameModel.modelEntity!.clone(recursive: true)
            clonedFrameModel.model?.materials[1] = simpleMaterial
            
            let imgHeight = Float(imgTexture.resource.height)
            let imgWidth = Float(imgTexture.resource.width)
            
            var scaleTransform: Transform
            if (abs((imgHeight / imgWidth) - (4.0 / 3.0)) < 1e-8) {
                print("DEBUG: Input image is 4/3 aspect ratio")
            }
            
            let toMul = (4.0 / 3.0) / (imgHeight / imgWidth)
            scaleTransform = Transform(scale: simd_float3(x: toMul, y: 1, z: 1))
            
//            if imgHeight == imgWidth {
//                scaleTransform = Transform(scale: simd_float3(x: 4/3, y: 1, z: 1))
//            }
//            if imgTexture.resource.height > imgTexture.resource.width {
//                let toMul = (4.0 / 3.0) / (imgHeight / imgWidth)
//                scaleTransform = Transform(scale: simd_float3(x: toMul, y: 1, z: 1))
//            } else {
//                let toMul = (4.0 / 3.0) / (imgHeight / imgWidth)
//                scaleTransform = Transform(scale: simd_float3(x: toMul, y: 1, z: 1))
//            }
            
            clonedFrameModel.transform = scaleTransform
            
            if (uiImage.imageOrientation == .right) {
                print("DEBUG: Rotating model")
                clonedFrameModel.transform.rotation = Transform(pitch: 0, yaw: -.pi/2, roll: 0).rotation
            }
            
            // Enabling translation and rotation gestures
            clonedFrameModel.generateCollisionShapes(recursive: true)
            uiView.installGestures([.all], for: clonedFrameModel)
            
            anchorEntity.addChild(clonedFrameModel)
            uiView.scene.addAnchor(anchorEntity)
            
            DispatchQueue.main.async {
                self.confirmedImageForPlacement = nil
            }
        }
    }
}

class CustomARView: ARView {
    var focusEntity: FocusEntity?
    
    //let coachingOverlay = ARCoachingOverlayView()
    
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
