//
//  ARViewContainer.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/13/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import Combine

struct ARViewContainer: UIViewRepresentable {
    @Binding var pictureToPlace: UIImage?
    @Binding var showPhotoPicker: Bool
    @Binding var planeDetected: Bool

    var frameModels: FrameModelPicker = FrameModelPicker()
    
    // Necessary because makeUIView cannot edit instance variables
    var sceneObserver: CancellableWrapper = CancellableWrapper()
    
    func makeUIView(context: Context) -> MyARView {
        
        let arView = MyARView(frame: .zero)
        
        sceneObserver.cancel = arView.scene.subscribe(to: SceneEvents.Update.self, { (event) in
            self.updateScene(for: arView)
        })
        
        return arView
        
    }
    
    func updateScene(for arView: MyARView) {
        // Only display focusEntity when the PhotosPicker is visible
        arView.focusEntity?.isEnabled = showPhotoPicker
        
        // Check if FocusEntity has detected a plane and update the state variable
        if (arView.focusEntity != nil) {
            planeDetected = arView.focusEntity!.onPlane
        }
    }
    
    func updateUIView(_ uiView: MyARView, context: Context) {
        
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
            let frameModel = frameModels.getRandomFrameModel()!
            
            // 1d. Rotate the frame model if image is in landscape
            if (imgHeight < imgWidth) {
                // Rotating the UV coordinates of the texture
                material.textureCoordinateTransform = .init(rotation: .pi / 2)
                frameModel.transform.rotation *= Transform(pitch: 0, yaw: -.pi/2, roll: 0).rotation
            }
            
            // 1e. Update mesh material to user's chosen picture
            // 1 is the index position for the material of the image plane inside the frame of these specific models
            frameModel.model?.materials[1] = material
            
            // 1f. Scale the short side of the frame model to preserve image's original aspect ratio
            // Currently, all images will be stretched/squished to fit the 4:3 ratio of the picture frame model
            let imageAspectRatio = max(imgHeight, imgWidth) / min(imgHeight, imgWidth) // This is the target aspect ratio
            let frameAspectRatio = Float(4.0 / 3.0) // This is the current aspect ratio
            let scaleFactor = frameAspectRatio / imageAspectRatio // Calculating how much we need to stretch or squish by
            frameModel.transform.scale *= Transform(scale: simd_float3(x: scaleFactor, y: 1, z: 1)).scale
            
            // 1g. Enable translation and rotation gestures
            frameModel.generateCollisionShapes(recursive: true)
            uiView.installGestures([.all], for: frameModel)
            
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

class CancellableWrapper {
    var cancel: Cancellable?
}
