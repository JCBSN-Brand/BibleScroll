//
//  LaunchScreenView.swift
//  BibleScroll
//
//  Simple launch screen with app branding
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Pure white background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // App icon/logo placeholder
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.black)
                
                Text("Scroll The Bible")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}


