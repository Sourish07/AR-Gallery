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

        // 1. Import the earth model
        // Make sure the usdz file is in the same directory as ContentView
        let model = try! ModelEntity.loadModel(named: "Earth.usdz")

        // Calculating the height of the model's mesh
        let height = (model.model?.mesh.bounds.max.y)! - (model.model?.mesh.bounds.min.y)!
        model.transform.translation.y = height / 2 // Translating up so the model sits on plane
        
        // Grabbing transform object and modifying rotation component so scale and translation are preserved
        var transform = model.transform
        transform.rotation = Transform(pitch: 0, yaw: .pi * 4.9, roll: 0).rotation // Yaw (rotation around vertical axis) cannot be multiple of 2 PI otherwise animation doesn't happen
        
        // Creating the animation object that will repeat forever
        let animationDefinition = FromToByAnimation(to: transform, duration: 10.0, bindTarget: .transform).repeatingForever()
        let animationResource = try! AnimationResource.generate(with: animationDefinition)
        model.playAnimation(animationResource)
        
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
