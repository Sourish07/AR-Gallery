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
    @State var selectedItems: [PhotosPickerItem] = []
    @State var selectedPhotosData: [Data] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
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
                                NavBarIcon(image: Image(uiImage: image))
                            }
                        }
                    }

                }
            }
            .padding(20)
        }
    }
}

struct NavBarIcon: View {
    var image: Image

    var body: some View {
        image.resizable()
            .scaledToFit()
            .frame(height: 40)
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
