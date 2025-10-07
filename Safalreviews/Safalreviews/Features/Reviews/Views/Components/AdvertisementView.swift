//
//  AdvertisementView.swift
//  Safalreviews
//
//  Created by Apple on 01/09/25.
//

import SwiftUI

struct AdvertisementView: View {
    let advertisement: Advertisement
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment:.leading,spacing: 8) {
                Text("Advertisement")
                    .font(.caption)
                    .foregroundColor(.gray)
                if let imageUrl = advertisement.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
                }
                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(advertisement.adName)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(2)
//                    
//                    if !advertisement.adContentText.isEmpty {
//                        Text(advertisement.adContentText)
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .lineLimit(3)
//                    }
//                    
//                    if !advertisement.description.isEmpty {
//                        Text(advertisement.description)
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advertisement List Item
struct AdvertisementListItem: View {
    let advertisement: Advertisement
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let imageUrl = advertisement.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(advertisement.adName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !advertisement.adContentText.isEmpty {
                        Text(advertisement.adContentText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if !advertisement.description.isEmpty {
                        Text(advertisement.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        AdvertisementView(
            advertisement: Advertisement(
                id: "1",
                adId: "ad1",
                adName: "Sample Advertisement",
                application: "SafalReviews",
                deviceType: ["ios"],
                adPage: "Home",
                redirectUrl: "https://example.com",
                adContentText: "This is a sample advertisement content",
                description: "Sample description",
                status: "PUBLISHED",
                adWebSection: nil,
                adMobileSection: nil,
                webImageUrl: nil,
                mobileImageUrl: "https://picsum.photos/300/200",
                adType: "banner"
            ),
            onTap: {}
        )
        
        AdvertisementListItem(
            advertisement: Advertisement(
                id: "2",
                adId: "ad2",
                adName: "Sample List Advertisement",
                application: "SafalReviews",
                deviceType: ["ios"],
                adPage: "Home",
                redirectUrl: "https://example.com",
                adContentText: "This is a sample list advertisement",
                description: "Sample list description",
                status: "PUBLISHED",
                adWebSection: nil,
                adMobileSection: nil,
                webImageUrl: nil,
                mobileImageUrl: "https://picsum.photos/100/100",
                adType: "list"
            ),
            onTap: {}
        )
    }
    .padding()
}
