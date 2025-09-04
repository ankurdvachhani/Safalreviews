import Foundation
import SwiftUI

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetail?
    @Published var reviews: [ReviewPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let networkManager = NetworkManager()
    private var currentPage = 1
    private let limit = 10
    private var hasMorePages = true
    
    func loadProductDetail(productId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load product details and reviews
            async let reviewsTask = loadReviews(productId: productId, page: 1)
            
            // For now, we'll create a mock product detail from the first review
            // In a real app, you'd have a separate API endpoint for product details
            let reviews = try await reviewsTask
            
            if let firstReview = reviews.first {
                let ratingBreakdown = calculateRatingBreakdown(from: reviews)
                let averageRating = calculateAverageRating(from: reviews)
                
                productDetail = ProductDetail(
                    id: firstReview.product.id,
                    name: firstReview.product.name,
                    description: "This is \(firstReview.product.name.lowercased())",
                    displayImage: nil, // You might want to add this to your product model
                    category: firstReview.category.name,
                    subcategory: firstReview.subcategory.name,
                    brand: firstReview.brand.name,
                    averageRating: averageRating,
                    totalRatings: reviews.count,
                    ratingBreakdown: ratingBreakdown,
                    reviews: reviews
                )
            }
            
            self.reviews = reviews
            currentPage = 1
            hasMorePages = reviews.count >= limit
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreReviews(productId: String) async {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let newReviews = try await loadReviews(productId: productId, page: currentPage)
            reviews.append(contentsOf: newReviews)
            hasMorePages = newReviews.count >= limit
            
            // Update product detail with new reviews
            if let detail = productDetail {
                let allReviews = reviews
                let ratingBreakdown = calculateRatingBreakdown(from: allReviews)
                let averageRating = calculateAverageRating(from: allReviews)
                
                productDetail = ProductDetail(
                    id: detail.id,
                    name: detail.name,
                    description: detail.description,
                    displayImage: detail.displayImage,
                    category: detail.category,
                    subcategory: detail.subcategory,
                    brand: detail.brand,
                    averageRating: averageRating,
                    totalRatings: allReviews.count,
                    ratingBreakdown: ratingBreakdown,
                    reviews: allReviews
                )
            }
            
        } catch {
            errorMessage = error.localizedDescription
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoading = false
    }
    
    private func loadReviews(productId: String, page: Int) async throws -> [ReviewPost] {
        let endpoint = Endpoint.reviewPosts(productId: productId, page: page, limit: limit)
        
        let response: ReviewPostResponse = try await networkManager.fetch(endpoint)
        
        return response.data
    }
    
    private func calculateRatingBreakdown(from reviews: [ReviewPost]) -> [Int: Int] {
        var breakdown: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for review in reviews {
            breakdown[review.rating, default: 0] += 1
        }
        
        return breakdown
    }
    
    private func calculateAverageRating(from reviews: [ReviewPost]) -> Double {
        guard !reviews.isEmpty else { return 0.0 }
        
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(reviews.count)
    }
    
    func refreshData(productId: String) async {
        currentPage = 1
        hasMorePages = true
        await loadProductDetail(productId: productId)
    }
}

// MARK: - Endpoint Extension

extension Endpoint {
    static func reviewPosts(productId: String, page: Int, limit: Int) -> Endpoint {
        return Endpoint(
            path: "/api/post",
            method: .get,
            queryItems: [
                URLQueryItem(name: "product", value: productId),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
    }
}
