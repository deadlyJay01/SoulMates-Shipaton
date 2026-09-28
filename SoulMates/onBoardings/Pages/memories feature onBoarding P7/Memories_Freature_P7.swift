//
//  Memories_Freature_P7.swift
//  SoulMates
//
//  Created by Jay on 09/09/26.
//

import SwiftUI

struct Memories_Freature_P7: View {
    @State private var animateContent: Bool = false
    
    private let sampleMilestones: [MemoryNode] = [
        MemoryNode(
            id: 1,
            imageName: "mem4",
            title: "First Trip Together",
            dateText: "Day 42",
            accentColor: Color(red: 0.95, green: 0.25, blue: 0.45)
        ),
        MemoryNode(
            id: 2,
            imageName: "mem5",
            title: "Sunset by the Beach",
            dateText: "Day 120",
            accentColor: Color(red: 0.65, green: 0.22, blue: 0.88)
        ),
        MemoryNode(
            id: 3,
            imageName: "mem9",
            title: "Anniversary Dinner",
            dateText: "Day 365",
            accentColor: Color(red: 0.18, green: 0.52, blue: 0.95)
        ),
        MemoryNode(
            id: 4,
            imageName: "mem10",
            title: "Disney Land",
            dateText: "Day 390",
            accentColor: Color(red: 0.18, green: 0.52, blue: 0.95)
        )
    ]
    
    var body: some View {
        ZStack {
            onBoarding_Background()
            
            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Capture Your Shared Journey.")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Text("Save photos together on an evolving timeline and watch your love story grow.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateContent)
                
                Spacer()
                
                // Leading Roadmap Visualizer
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.25, blue: 0.45).opacity(0.8),
                                    Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.8),
                                    Color(red: 0.18, green: 0.52, blue: 0.95).opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .offset(x: 10.5)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeIn(duration: 0.6).delay(0.15), value: animateContent)
                        .padding(.vertical, 40)
                    
                    VStack(spacing: 20) {
                        ForEach(Array(sampleMilestones.enumerated()), id: \.element.id) { index, node in
                            HStack(spacing: 16) {
                                NodePin(color: node.accentColor, nodeId: node.id)
                                MilestonePhotoCard(node: node)
                            }
                            .offset(y: animateContent ? 0 : 25)
                            .opacity(animateContent ? 1 : 0)
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.75)
                                .delay(0.2 + (Double(index) * 0.14)),
                                value: animateContent
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateContent = true
        }
    }
}

#Preview {
    Memories_Freature_P7()
        .environmentObject(AppStorageManager())
}
