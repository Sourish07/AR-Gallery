//
//  NavBar.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/15/22.
//

import SwiftUI
import RealityKit
import PhotosUI

struct NavBar: View {
    @Binding var selectedImageForPlacement: UIImage?
    @Binding var confirmedImageForPlacement: UIImage?
    
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedPhotosData: [Data]?
    
    @Binding var planeDetected: Bool?
    
    var body: some View {
        if (selectedImageForPlacement == nil) {
            NavBarPhotos(selectedItems: $selectedItems, selectedPhotosData: $selectedPhotosData, selectedImageForPlacement: $selectedImageForPlacement)
        } else {
            NavBarConfirmImagePlacement(selectedImageForPlacement: $selectedImageForPlacement, confirmedImageForPlacement: $confirmedImageForPlacement, planeDetected: $planeDetected)
        }
    }
}

struct NavBarPhotos: View { // The row of chosen images at the bottom of the user's screen
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedPhotosData: [Data]?
    
    @Binding var selectedImageForPlacement: UIImage?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading){
                if (selectedPhotosData == nil) {
                    HStack{
                        Text("     ")
                        Image(systemName: "arrow.down")
                        Text("Add some pictures from your camera roll to put on your wall!")
                    }
                }
                PhotosPicker(
                    selection: $selectedItems,
                    matching: .images
                ) {
                    NavBarIcon(image: Image(systemName: "photo.fill"))
                }
                .onChange(of: selectedItems) { newItems in
                    selectedPhotosData = []
                    for newItem in newItems {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                selectedPhotosData!.append(data)
                            }
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

struct NavBarConfirmImagePlacement: View { // Buttons when confirming or cancelling image placement; Appears after an image has been chosen
    @Binding var selectedImageForPlacement: UIImage?
    @Binding var confirmedImageForPlacement: UIImage?
    
    @Binding var planeDetected: Bool?
    
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
                if !(planeDetected ?? true) {
                    return
                }
                confirmedImageForPlacement = selectedImageForPlacement
                selectedImageForPlacement = nil
            }) {
                NavBarIcon(image: Image(systemName: "checkmark.circle.fill"))
            }
            Spacer()
        }
    }
}

struct NavBarPictureButton: View { // Buttons for the nav bar that have the picture as its icon and sets the tapped picture as the selected picture for placement
    var image: UIImage
    
    @Binding var selectedImageForPlacement: UIImage?
    
    var body: some View {
        Button(action: {
            selectedImageForPlacement = image
        }, label: {
            NavBarIcon(image: Image(uiImage: image))
        })
    }
}

struct NavBarIcon: View { // Icon formatting for all of the nav bar icons
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
