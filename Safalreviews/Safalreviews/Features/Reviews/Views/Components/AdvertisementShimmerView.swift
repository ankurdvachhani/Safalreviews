//
//  AdvertisementShimmerView.swift
//  Safalreviews
//
//  Created by Apple on 01/09/25.
//

import SwiftUI

struct AdvertisementShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Image placeholder with shimmer
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: isAnimating ? .leading : .trailing,
                        endPoint: isAnimating ? .trailing : .leading
                    )
                )
                .frame(height: 120)
                .cornerRadius(8)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.3)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 16)
                    .cornerRadius(4)
                
                // Content placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 12)
                    .cornerRadius(3)
                
                // Description placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 10)
                    .cornerRadius(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - List Style Shimmer
struct AdvertisementListShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: isAnimating ? .leading : .trailing,
                        endPoint: isAnimating ? .trailing : .leading
                    )
                )
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.3)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 16)
                    .cornerRadius(4)
                
                // Content placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 12)
                    .cornerRadius(3)
                
                // Description placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 10)
                    .cornerRadius(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 8, height: 8)
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Compact Shimmer
struct AdvertisementCompactShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Small image placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: isAnimating ? .leading : .trailing,
                        endPoint: isAnimating ? .trailing : .leading
                    )
                )
                .frame(width: 60, height: 60)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 3) {
                // Title placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.3)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 14)
                    .cornerRadius(3)
                
                // Content placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(height: 10)
                    .cornerRadius(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AdvertisementShimmerView()
        AdvertisementListShimmerView()
        AdvertisementCompactShimmerView()
    }
    .padding()
}
