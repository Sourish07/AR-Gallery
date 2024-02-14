//
//  ContentView.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/12/24.
//

import SwiftUI
import RealityKit
import PhotosUI
import Combine

struct ContentView : View {
    @State private var showPhotoPicker: Bool = true
    @State private var planeDetected: Bool = false
    @State private var pictureToPlace: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(pictureToPlace: $pictureToPlace, showPhotoPicker: $showPhotoPicker, planeDetected: $planeDetected).edgesIgnoringSafeArea(.all)
            PhotosPickerContainer(showPhotoPicker: $showPhotoPicker, pictureToPlace: $pictureToPlace, planeDetected: $planeDetected)
        }
    }
}
