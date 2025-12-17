//
//  Extensions.swift
//  BibleScroll
//

import SwiftUI

// MARK: - Crown Loading View

struct CrownLoadingView: View {
    var size: CGFloat = 24
    var tint: Color = .black
    
    @State private var isRotating = false
    
    var body: some View {
        Image("crown-icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(tint)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 1.2)
                .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

