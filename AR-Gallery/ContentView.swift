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

        // 1. Create a cube model
        
        // 1a. Create a cube mesh
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        // 1b. Create material
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        // 1c. Create a model entity with the mesh & material
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05 // Translating up by 0.05 so cube sits flush on plane
        
        // 2. Create horizontal plane anchor for the content
        // Looking for a horizontal plane anywhere (e.g. ceiling, floor, table, seat, etc.)
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model) // Attaching the virtual model to the anchor point in the real world
        
        // 3. Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
    ContentView()
}
