//
//  ButtonRP.swift
//  SoulMates
//
//  Created by Jay on 05/09/26.
//

import SwiftUI

// myy
//struct ButtonRP: View {
//    let Textt : String
//    var body: some View {
//        ZStack{
//            LinearGradient(colors: [.purple,.red], startPoint: .leading, endPoint: .trailing)
//                .opacity(0.7)
//                
//            Text("\(Textt)")
//            
//                .foregroundStyle(.white)
//                .font(.title2)
//                .fontWeight(.bold)
//                .fontDesign(.rounded)
//                .foregroundStyle(.white)
//        }
//        .frame(width: 250, height: 60)
//        .cornerRadius(20)
//        .shadow(radius: 30)
//        
//    }
//}







//                                               AI - 1
import SwiftUI

struct ButtonRP<Destination: View>: View {
    var Textt: String
    var destination: Destination? = nil
    var action: (() -> Void)? = nil
    
    // We use a custom init so you can omit the destination without generic type inference errors.
    init(Textt: String, destination: Destination? = EmptyView(), action: (() -> Void)? = nil) {
        self.Textt = Textt
        self.destination = (destination is EmptyView) ? nil : destination
        self.action = action
    }

    private let gradientColors = [
        Color(red: 0.65, green: 0.22, blue: 0.88),
        Color(red: 0.95, green: 0.25, blue: 0.42)
    ]
    
    var body: some View {
        if let dest = destination {
            NavigationLink(destination: dest) {
                buttonContent
            }
            .simultaneousGesture(TapGesture().onEnded {
                action?()
            })
            .buttonStyle(ScaleButtonStyle())
        } else {
            Button {
                action?()
            } label: {
                buttonContent
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Extracted Visual Label
    private var buttonContent: some View {
        HStack(spacing: 10) {
            Text(Textt)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background {
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                LinearGradient(
                    colors: [.white.opacity(0.25), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: gradientColors[1].opacity(0.35), radius: 10, x: 0, y: 10)
        .shadow(color: gradientColors[0].opacity(0.25), radius: 10, x: 10, y: 0)
        .padding(.horizontal, 24)
    }
}

// MARK: - Shared Scale Animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ButtonRP(Textt: "Add")
}


struct OnboardingActionButton: View {
    var title: String
    var isEnabled: Bool = true
    var action: () -> Void

    private let gradientColors = [
        Color(red: 0.65, green: 0.22, blue: 0.88),
        Color(red: 0.95, green: 0.25, blue: 0.42)
    ]
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                ZStack {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            }
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: gradientColors[1].opacity(0.35), radius: 10, x: 0, y: 10)
            .shadow(color: gradientColors[0].opacity(0.25), radius: 10, x: 10, y: 0)
            .opacity(isEnabled ? 1.0 : 0.45)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingActionButton(title: "Continue") {}
            .padding(.horizontal, 24)
    }
}
