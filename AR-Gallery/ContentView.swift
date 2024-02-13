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

struct ContentView : View {
    // State variable is set by a button and used by the ARViewContainer
    @State private var shouldPlace = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(shouldPlace: $shouldPlace).edgesIgnoringSafeArea(.all)
            Button(action: {
                shouldPlace = true
            }) {
                Text("Add picture!")
                    .fontWeight(.bold)
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 50)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var shouldPlace: Bool
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.vertical]
        arView.session.run(arConfig)
        
        _ = FocusEntity(on: arView, style: .classic())
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        if shouldPlace {
            // 1. Create a plane model
            // 1a. Create a plane mesh
            let scale: Float = 0.25 // Setting it to float manually rather than double
            let mesh = MeshResource.generatePlane(width: 16/9 * scale, depth: scale)
            // 1b. Create texture
            let cgImage = UIImage(named: "tahoe")?.cgImage
            // .raw means we're using the texture unmodified, rather than using it to store color or normal data
            let textureResource = try! TextureResource.generate(from: cgImage!, options: TextureResource.CreateOptions(semantic: .raw))
            let imgTexture = MaterialParameters.Texture.init(textureResource)
            // 1c. Create material
            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: imgTexture)
            // 1d. Create a model entity
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            // 2. Create vertical plane anchor for the content
            let anchor = AnchorEntity(.plane(.vertical, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
            anchor.children.append(model) // Attaching the virtual model to the anchor point in the real world
            
            // 3. Add the plane anchor to the scene
            uiView.scene.anchors.append(anchor)
            
            // Modify state during view update will cause undefined behavior, hence an asynchronous job
            Task {
                shouldPlace = false
            }
        }
    }
}

#Preview {
    ContentView()
}
