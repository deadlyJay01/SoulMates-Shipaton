//
//  MilestonePhotoCard.swift
//  SoulMates
//
//  Created by Jay on 10/09/26.
//

import SwiftUI

// MARK: - Sample Roadmap Node Model
struct MemoryNode: Identifiable, Equatable {
    let id: Int
    let imageName: String
    let title: String
    let dateText: String
    let accentColor: Color
}
// MARK: - Styled Photo Milestone Card (Stable Text + Smooth Drift)
struct MilestonePhotoCard: View {
    let node: MemoryNode
    
    @State private var isDrifting: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Milestone Photo Thumbnail
            Image(node.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Stable Milestone Labels
            VStack(alignment: .leading, spacing: 3) {
                Text(node.dateText.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(node.accentColor)
                    .tracking(0.8)
                
                Text(node.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack{
                    Text("Saved Memory")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                    Spacer()
                    Text("You")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        // Gentle, linear vertical drift without rotational jitter
        .offset(y: isDrifting ? -2.5 : 2.5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
                .delay(Double(node.id) * 0.35)
            ) {
                isDrifting = true
            }
        }
    }
}

// MARK: - Mini Photo Pin Node with Gentle Pulse
struct NodePin: View {
    let color: Color
    let nodeId: Int
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isPulsing ? 0.35 : 0.15))
                .frame(width: isPulsing ? 24 : 20, height: isPulsing ? 24 : 20)
            
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .frame(width: 24, height: 24) // Rigid frame prevents layout pushing
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: true)
                .delay(Double(nodeId) * 0.3)
            ) {
                isPulsing = true
            }
        }
    }
}
