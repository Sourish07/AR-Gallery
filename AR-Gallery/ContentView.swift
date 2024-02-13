//
//  ContentView.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/12/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import PhotosUI

struct ContentView : View {
    @State private var showPhotoPicker: Bool = true
    @State private var photosPickerItem: [PhotosPickerItem] = []
    @State private var pictureToPlace: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(pictureToPlace: $pictureToPlace).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showPhotoPicker = !showPhotoPicker
                    }) {
                        Image(systemName: "photo.artframe").resizable().scaledToFit().frame(width: 50)
                    }.padding().buttonStyle(.plain)
                }
                Spacer()
                if (showPhotoPicker) {
                    // Setting to continuous selection behavior to fix bug where user can't select same image multiple times in a row
                    PhotosPicker("Photo Picker", selection: $photosPickerItem, selectionBehavior: .continuous, matching: .images)
                        .photosPickerStyle(.inline)
                        .ignoresSafeArea()
                        .frame(height: 250)
                        .photosPickerAccessoryVisibility(.hidden, edges: [.bottom, .leading])
                        .photosPickerDisabledCapabilities(.selectionActions)
                    .onChange(of: photosPickerItem) {
                        Task {
                            // The expected max length of the photosPickerItem array is 1 because we'll immediately place the image in the world and then clear the array
                            if photosPickerItem.count > 0, let imageData = try? await photosPickerItem[0].loadTransferable(type: Data.self) {
                                pictureToPlace = UIImage(data: imageData)
                            }
                            photosPickerItem.removeAll()
                        }
                    }
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var pictureToPlace: UIImage?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.vertical]
        
        // Used to create a cube map of environment for reflections
        arConfig.environmentTexturing = .automatic
        
        // Enables humans and real objects to occlude virtual object
        arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Shows real-time mesh that's created by ARKit
        // arView.debugOptions.insert(.showSceneUnderstanding)
        
        // Uses LiDAR if available for increased AR stability
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            arConfig.sceneReconstruction = .mesh
        }
        
        arView.session.run(arConfig)
        
        _ = FocusEntity(on: arView, style: .classic())
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        if let uiImage = pictureToPlace {
            // 1. Create a plane model
            
            // 1a. Create texture from UIImage
            let cgImage = uiImage.cgImage!
            let textureResource = try! TextureResource.generate(from: cgImage, options: TextureResource.CreateOptions(semantic: .raw))
            let imgTexture = MaterialParameters.Texture.init(textureResource)
            
            let imgHeight = Float(imgTexture.resource.height)
            let imgWidth = Float(imgTexture.resource.width)
            
            // Create material from texture
            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: imgTexture)
            
            // 1b. Create a plane mesh
            let scale: Float = 0.25 // Setting it to float manually rather than double
            // Scaling image to have height of 1 and then multiplying by scale factor
            let mesh = MeshResource.generatePlane(width: imgWidth / imgHeight * scale, depth: imgHeight / imgHeight * scale)
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            // 2. Create vertical plane anchor for the content
            let anchor = AnchorEntity(.plane(.vertical, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
            anchor.children.append(model) // Attaching the virtual model to the anchor point in the real world
            
            // 3. Add the plane anchor to the scene
            uiView.scene.anchors.append(anchor)
            
            // Modify state during view update will cause undefined behavior, hence an asynchronous job
            Task {
                pictureToPlace = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
