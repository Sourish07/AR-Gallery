//
//  PhotosPickerContainer.swift
//  AR-Gallery
//
//  Created by Sourish Kundu on 2/13/24.
//

import SwiftUI
import PhotosUI

struct PhotosPickerContainer : View {
    @State private var photosPickerItem: [PhotosPickerItem] = []
    @Binding var showPhotoPicker: Bool
    @Binding var pictureToPlace: UIImage?
    @Binding var planeDetected: Bool
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    showPhotoPicker = !showPhotoPicker
                }) {
                    Image(systemName: "photo.artframe").resizable().scaledToFit().frame(width: 50)
                }.padding().buttonStyle(.plain)
            }
            Spacer()
            if (showPhotoPicker) {
                // Setting to continuous selection behavior to fix bug where user can't select same image multiple times in a row
                PhotosPicker("Photo Picker", selection: $photosPickerItem, selectionBehavior: .continuous, matching: .images)
                    .photosPickerStyle(.inline)
                    .ignoresSafeArea()
                    .frame(height: 250)
                    .photosPickerAccessoryVisibility(.hidden, edges: [.bottom, .leading])
                    .photosPickerDisabledCapabilities(.selectionActions)
                .onChange(of: photosPickerItem) {
                    Task {
                        // The expected max length of the photosPickerItem array is 1 because we'll immediately place the image in the world and then clear the array
                        // Also, make sure plane has been detected before loading image
                        if photosPickerItem.count > 0, planeDetected, let imageData = try? await photosPickerItem[0].loadTransferable(type: Data.self) {
                            pictureToPlace = UIImage(data: imageData)
                        }
                        photosPickerItem.removeAll()
                    }
                }
            }
        }
    }
}
