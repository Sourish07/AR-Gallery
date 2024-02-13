//
//  ContentView.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/12/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)        
        // 1. Create a plane model
        // 1a. Create a plane mesh
        let scale: Float = 0.5 // Setting it to float manually rather than double
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
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
    ContentView()
}
