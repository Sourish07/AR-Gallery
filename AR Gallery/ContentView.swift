//
//  ContentView.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/14/22.
//

import SwiftUI
import PhotosUI

import RealityKit
import ARKit

import FocusEntity


struct ContentView : View {
    @State private var selectedImageForPlacement: ModelEntity?
    @State private var confirmedImageForPlacement: ModelEntity?
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotosData: [Data]?

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(selectedImageForPlacement: $selectedImageForPlacement, confirmedImageForPlacement: $confirmedImageForPlacement).edgesIgnoringSafeArea(.all)
            if (selectedImageForPlacement == nil) {
                NavBarPhotos(selectedItems: $selectedItems, selectedPhotosData: $selectedPhotosData, selectedImageForPlacement: $selectedImageForPlacement)
            } else {
                NavBarConfirmImagePlacement(selectedImageForPlacement: $selectedImageForPlacement, confirmedImageForPlacement: $confirmedImageForPlacement)
            }
        }
    }
}

struct NavBarConfirmImagePlacement: View {
    @Binding var selectedImageForPlacement: ModelEntity?
    @Binding var confirmedImageForPlacement: ModelEntity?
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                selectedImageForPlacement = nil
            }) {
                NavBarIcon(image: Image(systemName: "xmark.circle.fill"))
            }
            Spacer()
            Button(action: {
                confirmedImageForPlacement = selectedImageForPlacement
                selectedImageForPlacement = nil
            }) {
                NavBarIcon(image: Image(systemName: "checkmark.circle.fill"))
            }
            Spacer()
        }
    }
}

struct NavBarPhotos: View {
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedPhotosData: [Data]?
    
    @Binding var selectedImageForPlacement: ModelEntity?
    
    var body: some View {
        HStack {
            PhotosPicker(
                selection: $selectedItems,
                matching: .images
            ) {
                NavBarIcon(image: Image(systemName: "photo.fill"))
            }
            .onChange(of: selectedItems) { newItems in
                selectedPhotosData = []
                for newItem in newItems {
                    print("LOADING IMAGE")
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            selectedPhotosData!.append(data)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedPhotosData ?? [], id: \.self) { photoData in
                        if let image = UIImage(data: photoData) {
                            NavBarPictureButton(image: image, selectedImageForPlacement: $selectedImageForPlacement)
                        }
                    }
                }
            }
        }
        .padding(20)
    }
}

struct NavBarIcon: View {
    var image: Image
    
    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(height: 40)
            .font(.system(size: 45))
            .foregroundColor(.white)
            .buttonStyle(PlainButtonStyle())
            .padding(10)
    }
}

struct NavBarPictureButton: View {
    var image: UIImage
    
    @Binding var selectedImageForPlacement: ModelEntity?
    
    var body: some View {
        Button(action: {
            print("NAV BAR PICTURE TAPPED")
            let cgImage = image.cgImage
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
            selectedImageForPlacement = ModelEntity(mesh: mesh, materials: [material])
            
            if (image.imageOrientation == .right) {
                selectedImageForPlacement!.transform = Transform(pitch: 0, yaw: -.pi/2, roll: 0)
            }
            
            
        }, label: {
            NavBarIcon(image: Image(uiImage: image))
        })
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedImageForPlacement: ModelEntity?
    @Binding var confirmedImageForPlacement: ModelEntity?
    
    func makeUIView(context: Context) -> CustomARView {

        let arView = CustomARView(frame: .zero)
        //arView.debugOptions.insert(.showStatistics)
        return arView

    }

    func updateUIView(_ uiView: CustomARView, context: Context) {
        uiView.focusEntity?.isEnabled = self.selectedImageForPlacement != nil
        if let modelEntity = confirmedImageForPlacement {
            
            let anchorEntity = AnchorEntity(plane: .any)
            anchorEntity.addChild(modelEntity.clone(recursive: true))
            
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
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        self.session.run(config)
    }
}

//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif
