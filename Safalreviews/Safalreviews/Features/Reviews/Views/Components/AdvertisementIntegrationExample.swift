//
//  AdvertisementIntegrationExample.swift
//  Safalreviews
//
//  Created by Apple on 01/09/25.
//

import SwiftUI

/// Example showing how to integrate AdvertisementService with a list view
struct AdvertisementIntegrationExample: View {
    @StateObject private var advertisementService = AdvertisementService()
    @State private var reviews: [ProductReview] = []
    @State private var currentPage = "Home"
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                        // Show review item
                        ReviewItemView(review: review)
                        
                        // Check if we should show an advertisement at this index
                        if advertisementService.shouldShowAdvertisement(
                            at: index,
                            configuration: advertisementService.getConfiguration(for: currentPage)
                        ) {
                            // Get the advertisement to display
                            if let advertisement = advertisementService.getAdvertisementForIndex(
                                index,
                                configuration: advertisementService.getConfiguration(for: currentPage)
                            ) {
                                AdvertisementView(advertisement: advertisement) {
                                    advertisementService.openAdvertisementURL(advertisement.redirectUrl)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reviews with Ads")
            .task {
                await loadData()
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private func loadData() async {
        // Load advertisement settings and ads for current page
        await advertisementService.fetchAdvertisementSettings()
        await advertisementService.fetchAdvertisements(for: currentPage)
        
        // Load your reviews data here
        // reviews = await loadReviews()
    }
    
    private func refreshData() async {
        await advertisementService.refreshData(for: currentPage)
        // Refresh your reviews data here
        // reviews = await loadReviews()
    }
}

/// Example showing how to use AdvertisementService in a LazyVGrid
struct AdvertisementGridExample: View {
    @StateObject private var advertisementService = AdvertisementService()
    @State private var items: [String] = []
    @State private var currentPage = "Dashboard"
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        // Show regular item
                        ItemView(item: item)
                        
                        // Check if we should show an advertisement
                        if advertisementService.shouldShowAdvertisement(
                            at: index,
                            configuration: advertisementService.getConfiguration(for: currentPage)
                        ) {
                            // Get the advertisement to display
                            if let advertisement = advertisementService.getAdvertisementForIndex(
                                index,
                                configuration: advertisementService.getConfiguration(for: currentPage)
                            ) {
                                AdvertisementView(advertisement: advertisement) {
                                    advertisementService.openAdvertisementURL(advertisement.redirectUrl)
                                }
                                .gridCellColumns(2) // Span both columns
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Grid with Ads")
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        await advertisementService.fetchAdvertisementSettings()
        await advertisementService.fetchAdvertisements(for: currentPage)
        
        // Load your items data here
        // items = await loadItems()
    }
}

/// Example showing how to use AdvertisementService with manual control
struct AdvertisementManualExample: View {
    @StateObject private var advertisementService = AdvertisementService()
    @State private var currentIndex = 0
    @State private var items: [String] = []
    
    var body: some View {
        VStack {
            Text("Current Index: \(currentIndex)")
            
            if let advertisement = getCurrentAdvertisement() {
                AdvertisementView(advertisement: advertisement) {
                    advertisementService.openAdvertisementURL(advertisement.redirectUrl)
                }
            }
            
            HStack {
                Button("Previous") {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }
                .disabled(currentIndex <= 0)
                
                Button("Next") {
                    currentIndex += 1
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private func getCurrentAdvertisement() -> Advertisement? {
        let configuration = advertisementService.getConfiguration(for: "Home")
        return advertisementService.getAdvertisementForIndex(currentIndex, configuration: configuration)
    }
    
    private func loadData() async {
        await advertisementService.fetchAdvertisementSettings()
        await advertisementService.fetchAdvertisements(for: "Home")
        
        // Load your items data here
        // items = await loadItems()
    }
}

// MARK: - Helper Views
struct ReviewItemView: View {
    let review: ProductReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Review Item")
                .font(.headline)
            Text("This is a sample review item")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ItemView: View {
    let item: String
    
    var body: some View {
        VStack {
            Text(item)
                .font(.headline)
            Text("Sample item content")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    AdvertisementIntegrationExample()
}
