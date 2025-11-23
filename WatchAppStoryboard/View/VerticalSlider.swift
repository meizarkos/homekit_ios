//
//  VerticalSlider.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 23/11/2025.
//


import SwiftUI

struct VerticalSlider: View {
    @Binding var houseParameter: Int
    var setHouseParameterInHomekit:(()->(Void))
    var icon : String
    var height: CGFloat = 200
    var width : CGFloat = 80
    var cornerRadius : CGFloat = 20
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .cornerRadius(cornerRadius)
            
                Rectangle()
                    .fill(.white)
                    .frame(width: width, height: CGFloat(Double(houseParameter)/100) * height)
                    .cornerRadius(cornerRadius)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width / 3, height: width / 3)
                    .foregroundColor(.gray)
                    .padding(.bottom, 15)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = geo.size.height - gesture.location.y //Flip so 0 is at bottom
                        let newValue = min(max(Double(location / height * 100), 0), 100)
                        houseParameter = Int(newValue)
                        setHouseParameterInHomekit()
                    }
            )
        }
        .frame(width: width, height: height)
    }
}

