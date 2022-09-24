//
//  ContentView.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/14/22.
//

import SwiftUI
import PhotosUI

import RealityKit


struct ContentView : View {
    @State private var selectedImageForPlacement: UIImage?
    @State private var confirmedImageForPlacement: UIImage?
    @State private var planeDetected: Bool? = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotosData: [Data]?

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(selectedImageForPlacement: $selectedImageForPlacement, confirmedImageForPlacement: $confirmedImageForPlacement, planeDetected: $planeDetected).edgesIgnoringSafeArea(.all)
            NavBar(selectedImageForPlacement: $selectedImageForPlacement, confirmedImageForPlacement: $confirmedImageForPlacement, selectedItems: $selectedItems, selectedPhotosData: $selectedPhotosData, planeDetected: $planeDetected)
        }
    }
}





//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif
