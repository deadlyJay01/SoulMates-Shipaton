//
//  CustomInputField.swift
//  SoulMates
//
//  Created by Jay on 10/09/26.
//

import SwiftUI

// MARK: - High Contrast Frosted Input Field
struct CustomInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFocused ? .white : .white.opacity(0.7))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.6)))
                    .submitLabel(.done)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.6)))
                    .submitLabel(.done)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    
            }

            if !text.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .colorScheme(.dark)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black.opacity(0.55))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            isFocused ? Color.white.opacity(0.5) : Color.white.opacity(0.12),
                            lineWidth: 1.2
                        )
                }
        }
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
