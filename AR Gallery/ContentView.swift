//
//  ContentView.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/14/22.
//

import SwiftUI
import RealityKit
import PhotosUI

struct ContentView : View {
    @State private var selectedImageForPlacement: ModelEntity?
    @State private var confirmedImageForPlacement: ModelEntity?

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            if (selectedImageForPlacement == nil) {
                NavBarPhotos(selectedImageForPlacement: $selectedImageForPlacement)
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
                //confirmedImageForPlacement = selectedImageForPlacement
                selectedImageForPlacement = nil
            }) {
                NavBarIcon(image: Image(systemName: "checkmark.circle.fill"))
            }
            Spacer()
        }
    }
}

struct NavBarPhotos: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotosData: [Data] = []
    
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
                selectedPhotosData.removeAll()
                for newItem in newItems {
                    print("LOADING IMAGE")
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            selectedPhotosData.append(data)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedPhotosData, id: \.self) { photoData in
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
            
        }, label: {
            NavBarIcon(image: Image(uiImage: image))
        })
    }
}

struct ARViewContainer: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {

        let arView = ARView(frame: .zero)
        return arView

    }

    func updateUIView(_ uiView: ARView, context: Context) {


    }

}

//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif
