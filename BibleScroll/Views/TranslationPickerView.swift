//
//  TranslationPickerView.swift
//  BibleScroll
//
//  Select Bible translation/version
//

import SwiftUI

struct TranslationPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTranslation: BibleTranslation
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(BibleTranslation.allCases, id: \.self) { translation in
                    Button(action: {
                        selectedTranslation = translation
                        isPresented = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(translation.shortName)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    if translation.isOffline {
                                        Text("Offline")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.green))
                                    }
                                }
                                
                                Text(translation.fullName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if translation == selectedTranslation {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            .background(Color.white)
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

// MARK: - Bible Translation Enum

enum BibleTranslation: String, CaseIterable {
    case kjv = "kjv-offline"           // Local/Offline
    case nkjv = "de4e12af7f28f599-01"  // NKJV from API.Bible
    case nlt = "65eec8e0b60e656b-01"   // NLT from API.Bible
    
    var shortName: String {
        switch self {
        case .kjv: return "KJV"
        case .nkjv: return "NKJV"
        case .nlt: return "NLT"
        }
    }
    
    var fullName: String {
        switch self {
        case .kjv: return "King James Version"
        case .nkjv: return "New King James Version"
        case .nlt: return "New Living Translation"
        }
    }
    
    var isOffline: Bool {
        return self == .kjv
    }
    
    var apiId: String? {
        switch self {
        case .kjv: return nil  // No API needed
        case .nkjv: return "de4e12af7f28f599-01"
        case .nlt: return "65eec8e0b60e656b-01"
        }
    }
}

#Preview {
    TranslationPickerView(
        isPresented: .constant(true),
        selectedTranslation: .constant(.kjv)
    )
}
