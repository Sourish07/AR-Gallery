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
    
    @Binding var planeDetected: Bool?
    
    
    var frameModels: [FrameModel] = FrameModel.initFrames()
    @State var frameModelCounter: Counter = Counter(upperBound: 5)
    
    var sceneObserver: CancellableWrapper = CancellableWrapper()
    
    func makeUIView(context: Context) -> CustomARView {

        let arView = CustomARView(frame: .zero)
        
        sceneObserver.cancel = arView.scene.subscribe(to: SceneEvents.Update.self, { (event) in
            self.updateScene(for: arView)
        })
        
        return arView

    }
    
    func updateScene(for arView: CustomARView) {
        // Only display focusEntity when the user has selected a model for placement
        arView.focusEntity?.isEnabled = self.selectedImageForPlacement != nil
        
        if (arView.focusEntity != nil) {
            planeDetected = arView.focusEntity?.onPlane
        }
    }

    func updateUIView(_ uiView: CustomARView, context: Context) {
               
        if let uiImage = confirmedImageForPlacement {
            let cgImage = uiImage.cgImage
            let textureResource = try! TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: .raw))
            let imgTexture = MaterialParameters.Texture.init(textureResource)
            
            let imgHeight = Float(imgTexture.resource.height)
            let imgWidth = Float(imgTexture.resource.width)

            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white, texture: imgTexture)
            material.roughness = .init(floatLiteral: 1)
            material.metallic = .init(floatLiteral: 1)
            
            let frameIdx = self.frameModelCounter.getAndIncrement()
            let clonedFrameModel = frameModels[frameIdx].modelEntity!.clone(recursive: true)
            
            // Picture is landscape
            if (imgHeight < imgWidth) {
                material.textureCoordinateTransform = .init(rotation: .pi / 2)
                clonedFrameModel.transform.rotation *= Transform(pitch: 0, yaw: -.pi/2, roll: 0).rotation
            }
            
            // Updating mesh material to user's chosen picture
            clonedFrameModel.model?.materials[1] = material
            
            // Calculating scale factor to make frame model match picture's aspect ratio
            let toMul = (4.0 / 3.0) / (max(imgHeight, imgWidth) / min(imgHeight, imgWidth))
            clonedFrameModel.transform.scale = Transform(scale: simd_float3(x: toMul, y: 1, z: 1)).scale
            
            // Ensuring the picture is orientated correctly
            if (uiImage.imageOrientation == .right) {
                clonedFrameModel.transform.rotation *= Transform(pitch: 0, yaw: -.pi/2, roll: 0).rotation
            }
            
            // Enabling translation and rotation gestures
            clonedFrameModel.generateCollisionShapes(recursive: true)
            uiView.installGestures([.all], for: clonedFrameModel)
            
            // Adding to scene
            let anchorEntity = AnchorEntity(plane: .any)
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
        config.planeDetection = [.vertical]//[.vertical, .horizontal]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        self.session.run(config)
    }
}
