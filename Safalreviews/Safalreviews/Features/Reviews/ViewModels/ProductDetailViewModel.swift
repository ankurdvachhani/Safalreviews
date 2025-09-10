import Foundation
import SwiftUI

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetail?
    @Published var reviews: [ReviewPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var totalReviewsCount = 0
    
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
            let (reviews, totalCount) = try await reviewsTask
            
            if let firstReview = reviews.first {
                let ratingBreakdown = calculateRatingBreakdown(from: reviews)
                let averageRating = calculateAverageRating(from: reviews)
                
                productDetail = ProductDetail(
                    id: firstReview.product.id,
                    name: firstReview.product.name,
                    description: "This is \(firstReview.product.name.lowercased())",
                    displayImage: firstReview.imgs.first, // Use first review image as display image
                    category: firstReview.category.name,
                    subcategory: firstReview.subcategory.name,
                    brand: firstReview.brand.name,
                    averageRating: averageRating,
                    totalRatings: totalCount, // Use total count from API
                    ratingBreakdown: ratingBreakdown,
                    reviews: reviews
                )
            } else {
                // If no reviews found, set productDetail to nil to show "not reviewed" state
                productDetail = nil
            }
            
            self.reviews = reviews
            self.totalReviewsCount = totalCount
            currentPage = 1
            hasMorePages = reviews.count >= limit
            
        } catch {
            errorMessage = error.localizedDescription
            // Set productDetail to nil on error to show appropriate UI
            productDetail = nil
        }
        
        isLoading = false
    }
    
    func loadMoreReviews(productId: String) async {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let (newReviews, totalCount) = try await loadReviews(productId: productId, page: currentPage)
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
                    totalRatings: totalCount, // Use total count from API
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
    
    private func loadReviews(productId: String, page: Int) async throws -> (reviews: [ReviewPost], totalCount: Int) {
        let endpoint = Endpoint.reviewPosts(productId: productId, page: page, limit: limit)
        
        let response: ReviewPostResponse = try await networkManager.fetch(endpoint)
        
        return (response.data, response.pagination.totalCount)
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
    
    /// Creates a ProductDetail from ProductReview data when no reviews are found
    func createProductDetailFromProduct(_ product: ProductReview) {
        productDetail = ProductDetail(
            id: product.id,
            name: product.name,
            description: product.description,
            displayImage: product.mediaSignedUrls.first ?? product.media.first,
            category: product.brand.subCategory.category.name,
            subcategory: product.brand.subCategory.name,
            brand: product.brand.name,
            averageRating: product.averageRating,
            totalRatings: product.totalRatings,
            ratingBreakdown: createRatingBreakdown(from: product.ratings),
            reviews: []
        )
    }
    
    private func createRatingBreakdown(from ratings: [Int]) -> [Int: Int] {
        var breakdown: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for rating in ratings {
            if rating >= 1 && rating <= 5 {
                breakdown[rating, default: 0] += 1
            }
        }
        
        return breakdown
    }
    
    // MARK: - Like/Dislike Methods
    func likeReview(_ review: ReviewPost) async {
        print("👍 Liking review: \(review.id)")
        
        do {
            let endpoint = Endpoint(
                path: "/api/post/\(review.id)/like",
                method: .post
            )
            
            let response: ReviewPostLikeResponse = try await networkManager.fetch(endpoint)
            
            if response.success {
                // Update the review in the local array with new like data
                await updateReviewWithLikeData(response.data)
                print("✅ Review liked successfully")
            } else {
                errorMessage = "Failed to like review"
                print("❌ Failed to like review: \(response.message)")
            }
            
        } catch {
            print("❌ Error liking review: \(error)")
            errorMessage = "Failed to like review: \(error.localizedDescription)"
        }
    }
    
    func dislikeReview(_ review: ReviewPost) async {
        print("👎 Disliking review: \(review.id)")
        
        do {
            let endpoint = Endpoint(
                path: "/api/post/\(review.id)/dislike",
                method: .post
            )
            
            let response: ReviewPostDislikeResponse = try await networkManager.fetch(endpoint)
            
            if response.success {
                // Update the review in the local array with new dislike data
                await updateReviewWithDislikeData(response.data)
                print("✅ Review disliked successfully")
            } else {
                errorMessage = "Failed to dislike review"
                print("❌ Failed to dislike review: \(response.message)")
            }
            
        } catch {
            print("❌ Error disliking review: \(error)")
            errorMessage = "Failed to dislike review: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helper Methods
    @MainActor
    private func updateReviewWithLikeData(_ likeData: ReviewPostLikeData) {
        if let index = reviews.firstIndex(where: { $0.id == likeData.id }) {
            // Update the review with new like data
            reviews[index].likes = likeData.likes
            reviews[index].dislikes = likeData.dislikes
            reviews[index].likesCount = likeData.likesCount
            reviews[index].dislikesCount = likeData.dislikesCount
            
            // Also update in productDetail if it exists
            if var detail = productDetail {
                let updatedReviews = detail.reviews
                if let reviewIndex = updatedReviews.firstIndex(where: { $0.id == likeData.id }) {
                    var newReviews = updatedReviews
                    newReviews[reviewIndex].likes = likeData.likes
                    newReviews[reviewIndex].dislikes = likeData.dislikes
                    newReviews[reviewIndex].likesCount = likeData.likesCount
                    newReviews[reviewIndex].dislikesCount = likeData.dislikesCount
                    
                    productDetail = ProductDetail(
                        id: detail.id,
                        name: detail.name,
                        description: detail.description,
                        displayImage: detail.displayImage,
                        category: detail.category,
                        subcategory: detail.subcategory,
                        brand: detail.brand,
                        averageRating: detail.averageRating,
                        totalRatings: detail.totalRatings,
                        ratingBreakdown: detail.ratingBreakdown,
                        reviews: newReviews
                    )
                }
            }
            
            print("📊 Updated like count: \(likeData.likesCount), dislike count: \(likeData.dislikesCount)")
        }
    }
    
    @MainActor
    private func updateReviewWithDislikeData(_ dislikeData: ReviewPostDislikeData) {
        if let index = reviews.firstIndex(where: { $0.id == dislikeData.id }) {
            // Update the review with new dislike data
            reviews[index].likes = dislikeData.likes
            reviews[index].dislikes = dislikeData.dislikes
            reviews[index].likesCount = dislikeData.likesCount
            reviews[index].dislikesCount = dislikeData.dislikesCount
            
            // Also update in productDetail if it exists
            if var detail = productDetail {
                let updatedReviews = detail.reviews
                if let reviewIndex = updatedReviews.firstIndex(where: { $0.id == dislikeData.id }) {
                    var newReviews = updatedReviews
                    newReviews[reviewIndex].likes = dislikeData.likes
                    newReviews[reviewIndex].dislikes = dislikeData.dislikes
                    newReviews[reviewIndex].likesCount = dislikeData.likesCount
                    newReviews[reviewIndex].dislikesCount = dislikeData.dislikesCount
                    
                    productDetail = ProductDetail(
                        id: detail.id,
                        name: detail.name,
                        description: detail.description,
                        displayImage: detail.displayImage,
                        category: detail.category,
                        subcategory: detail.subcategory,
                        brand: detail.brand,
                        averageRating: detail.averageRating,
                        totalRatings: detail.totalRatings,
                        ratingBreakdown: detail.ratingBreakdown,
                        reviews: newReviews
                    )
                }
            }
            
            print("📊 Updated like count: \(dislikeData.likesCount), dislike count: \(dislikeData.dislikesCount)")
        }
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
