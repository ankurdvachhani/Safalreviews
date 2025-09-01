//
//  HomeView.swift
//  Safalreviews
//
//  Created by Apple on 01/09/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var reviewStore = ReviewStore()
    @State private var searchText = ""
    @State private var selectedSortOption: ReviewSortOption = .dateDesc
    @State private var showingSortSheet = false
    @State private var showingFilterSheet = false
    @State private var currentFilter = ReviewFilter()
    
    var body: some View {
        mainContent
            .navigationTitle("Discover Products & Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toast(message: $reviewStore.errorMessage, type: .error)
            .toast(message: $reviewStore.successMessage, type: .success)
            .sheet(isPresented: $showingSortSheet) {
                ReviewSortSheet(
                    selectedSortOption: $selectedSortOption,
                    isPresented: $showingSortSheet,
                    onSortChanged: { newSortOption in
                        Task {
                            await reviewStore.updateSortOption(newSortOption, filter: currentFilter)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilterSheet) {
                ReviewFilterSheet(
                    filter: $currentFilter,
                    reviewStore: reviewStore,
                    onApply: {
                        Task {
                            await reviewStore.updateFilter(currentFilter)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: searchText) { newValue in
                reviewStore.searchProductReviews(query: newValue)
            }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            searchAndSortSection
            contentBody
        }
    }
    
    // MARK: - Content Body
    @ViewBuilder
    private var contentBody: some View {
        ZStack {
            if reviewStore.isLoading && reviewStore.productReviews.isEmpty {
                reviewShimmerList
            } else if !searchText.isEmpty && filteredProducts.isEmpty {
                ReviewNoSearchResultsView(searchText: searchText) {
                    searchText = ""
                    reviewStore.searchProductReviews(query: "")
                }
            } else if reviewStore.productReviews.isEmpty && currentFilter.hasActiveFilters {
                ReviewNoFilterResultsView(currentFilter: currentFilter) {
                    // Clear filters action
                    currentFilter.clearAll()
                    Task {
                        await reviewStore.updateFilter(currentFilter)
                    }
                }
            } else if reviewStore.productReviews.isEmpty {
                emptyStateView
            } else {
                productsList
            }
        }
    }
    
    // MARK: - Search and Sort Section
    private var searchAndSortSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search products, places, or people...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _ in
                            reviewStore.searchProductReviews(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            reviewStore.searchProductReviews(query: "")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Sort Button
                Button {
                    showingSortSheet = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.dynamicAccent)
                    }
                }
                
                // Filter Button
                Button {
                    showingFilterSheet = true
                } label: {
                    ZStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.dynamicAccent)
                        
                        // Red dot indicator for active filters
                        if currentFilter.hasActiveFilters {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            
            // Results count
            HStack {
                Text("\(reviewStore.totalProducts) results found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Sort indicator
            if selectedSortOption != .dateDesc {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color.dynamicAccent)
                        .font(.caption2)
                    
                    Text("Sorted by: \(selectedSortOption.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Reset") {
                        selectedSortOption = .dateDesc
                        Task {
                            await reviewStore.updateSortOption(.dateDesc, filter: currentFilter)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color.dynamicAccent)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Filtered Products
    private var filteredProducts: [ProductReview] {
        var filtered = reviewStore.productReviews
        
        // Apply sort
        filtered = filtered.sorted(by: selectedSortOption.sortDescriptor)
        
        return filtered
    }
    
    // MARK: - Products List
    private var productsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredProducts) { product in
                    ProductReviewCard(product: product)
                        .task {
                            await reviewStore.loadMoreIfNeeded(currentItem: product)
                        }
                }
                
                if reviewStore.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading more products...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
        }
        .refreshable {
            try? await Task.sleep(nanoseconds: 500000000) // Add a small delay
            await reviewStore.refreshProductReviews()
        }
    }
    
    // MARK: - Shimmer List
    private var reviewShimmerList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0 ..< 6) { _ in
                    ProductReviewShimmerCard()
                }
            }
            .padding()
        }
        .disabled(true)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.square.on.square")
                .font(.system(size: 80))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Products Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? "Start exploring products and reviews" : "No products match your search")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Product Review Card
struct ProductReviewCard: View {
    let product: ProductReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                if let imageUrl = product.displayImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        )
                }
                
                // Product badge
                HStack(spacing: 4) {
                    Image(systemName: "cube.box")
                        .font(.caption2)
                    Text("Product")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .clipShape(Capsule())
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Product Info
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(product.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Description
                if !product.description.isEmpty {
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Rating
                HStack {
                    Text("Rating:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(product.averageRating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(index < Int(product.averageRating) ? .yellow : .gray)
                        }
                    }
                    
                    Text("(\(product.totalRatings))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Category, Subcategory, Brand
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Category: \(product.brand.subCategory.category.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Subcategory: \(product.brand.subCategory.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Brand: \(product.brand.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Product Review Shimmer Card
struct ProductReviewShimmerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image shimmer
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .homeshimmerEffect()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content shimmer
            VStack(alignment: .leading, spacing: 8) {
                ProductReviewShimmerBox(width: 200, height: 20)
                ProductReviewShimmerBox(width: 150, height: 16)
                ProductReviewShimmerBox(width: 120, height: 14)
                ProductReviewShimmerBox(width: 100, height: 14)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ProductReviewShimmerBox: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 4)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .homeshimmerEffect()
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
        }
    }
}
