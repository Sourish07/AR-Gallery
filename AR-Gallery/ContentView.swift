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
            // 1. Setup frame model
            
            // 1a. Create texture from UIImage
            let cgImage = applyOrientation(uiImage: uiImage)!
            let textureResource = try! TextureResource.generate(from: cgImage, options: TextureResource.CreateOptions(semantic: .raw))
            let imgTexture = MaterialParameters.Texture.init(textureResource)
            
            let imgHeight = Float(imgTexture.resource.height)
            let imgWidth = Float(imgTexture.resource.width)
            
            // 1b. Create material from texture
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white, texture: imgTexture)
            
            // 1c. Load in frame model
            let frameIdx = Int.random(in: 1..<5+1) // Interval is half open
            let frameModel = try! ModelEntity.loadModel(named: "frame\(frameIdx).usdz")
            
            // 1d. Rotate the frame model if image is in landscape
            if (imgHeight < imgWidth) {
                // Rotating the UV coordinates of the texture
                material.textureCoordinateTransform = .init(rotation: .pi / 2)
                frameModel.transform.rotation *= Transform(pitch: 0, yaw: -.pi/2, roll: 0).rotation
            }
            // 1e. Update mesh material to user's chosen picture
            // 1 is the index position for the material of the image plane inside the frame of these specific models
            frameModel.model?.materials[1] = material
            
            // 2. Create vertical plane anchor for the content
            let anchor = AnchorEntity(.plane(.vertical, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
            anchor.children.append(frameModel) // Attaching the virtual model to the anchor point in the real world
            
            // 3. Add the plane anchor to the scene
            uiView.scene.anchors.append(anchor)
            
            // Modify state during view update will cause undefined behavior, hence an asynchronous job
            Task {
                pictureToPlace = nil
            }
        }
    }
    
    func applyOrientation(uiImage: UIImage) -> CGImage? {
        var angle = 0
        if (uiImage.imageOrientation == .right) {
            angle = 90
        } else if (uiImage.imageOrientation == .down) {
            angle = 180
        } else if (uiImage.imageOrientation == .left) {
            angle = 270
        }
        return rotateImageClockwise(image: uiImage.cgImage!, angle: angle)
    }
    
    func rotateImageClockwise(image: CGImage, angle: Int) -> CGImage? {
        // Function only supports 90, 180, and 270 degree rotations
        if angle % 360 == 0 || angle % 90 != 0 {
            return image
        }
        
        // Calculate the new dimensions based on the rotation angle.
        // For 90 and 270 degrees, swap width and height.
        let isSwapDimensions = angle % 180 != 0
        let newWidth = isSwapDimensions ? image.height : image.width
        let newHeight = isSwapDimensions ? image.width : image.height
        
        // Create a new Core Graphics Context
        let context = CGContext(data: nil, width: newWidth, height: newHeight, bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0, space: image.colorSpace!, bitmapInfo: image.bitmapInfo.rawValue)
        
        // Move the origin to the middle of the context to prepare for rotation.
        context?.translateBy(x: .init(newWidth / 2), y: .init(newHeight / 2))
        // Apply the clockwise rotation. CGAffineTransform uses radians, so convert the angle.
        context?.rotate(by: -CGFloat(angle) * .pi / 180)
        // Move the origin back to the bottom-left corner, adjusting for the new dimensions.
        if angle == 180 {
            context?.translateBy(x: .init(-newWidth / 2), y: .init(-newHeight / 2))
        } else { // Dimensions are switched if rotation was 90 or 270 degrees
            context?.translateBy(x: .init(-newHeight / 2), y: .init(-newWidth / 2))
        }
        
        // Draw the original image in the new context
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        // Extract the rotated image
        return context?.makeImage()
    }
}

#Preview {
    ContentView()
}
