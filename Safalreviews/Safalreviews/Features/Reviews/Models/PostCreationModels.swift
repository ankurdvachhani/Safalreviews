import Foundation
import SwiftUI

// MARK: - Post Creation Request Models

struct CreatePostRequest: Codable {
    let title: String
    let description: String
    let imgs: [String]
    let videos: [String]
    let categoryType: String
    let category: String?
    let subcategory: String?
    let brand: String?
    let product: String?
    let customCategory: String?
    let customSubCategory: String?
    let customBrand: String?
    let customProduct: String?
    let recommended: String
    let rating: Int
    let price: Int?
    
    enum CodingKeys: String, CodingKey {
        case title, description, imgs, videos, categoryType, category, subcategory
        case brand, product, customCategory, customSubCategory, customBrand, customProduct
        case recommended, rating, price
    }
}

struct CreatePostResponse: Codable {
    let success: Bool
    let data: CreatePostData
    let errors: [String]
    let timestamp: String
    let message: String
}

struct CreatePostData: Codable {
    let id: String
    let title: String
    let description: String
    let imgs: [String]
    let videos: [String]
    let recommended: String
    let slug: String
    let dislikesCount: Int
    let likes: [String]
    let brand: String
    let shares: [String]
    let likesCount: Int
    let category: String
    let createdAt: String
    let sharesCount: Int
    let reviews: [String]
    let subcategory: String
    let updatedAt: String
    let user: String
    let dislikes: [String]
    let product: String
    let price: Int
    let rating: Int
    let categoryType: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, imgs, videos, recommended, slug
        case dislikesCount, likes, brand, shares, likesCount, category
        case createdAt, sharesCount, reviews, subcategory, updatedAt
        case user, dislikes, product, price, rating, categoryType
    }
}

// MARK: - Product List Response Models

struct ProductListResponse: Codable {
    let success: Bool
    let data: [ProductListItem]
    let pagination: ProductPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct ProductListItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let media: [String]
    let category: String
    let subCategory: String
    let specifications: [String: String]
    let isActive: Bool
    let slug: String
    let createdAt: String
    let updatedAt: String
    let categoryType: String
    let brand: ProductBrandInfo
    let averageRating: Double
    let totalRatings: Int
    let ratings: [Int]
    let mediaSignedUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, media, category, subCategory, specifications
        case isActive, slug, createdAt, updatedAt, categoryType, brand
        case averageRating, totalRatings, ratings, mediaSignedUrls
    }
}

struct ProductBrandInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let subCategory: ProductSubCategoryInfo
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug, subCategory
    }
}

struct ProductSubCategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let category: ProductCategoryInfo
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug, category
    }
}

struct ProductCategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

// MARK: - Media Upload Models

struct PostImageUploadRequest: Codable {
    let fileName: String
    let folder: String
}

struct PostVideoUploadRequest: Codable {
    let fileName: String
    let folder: String
}

struct PostImageUploadResponse: Codable {
    let status: String
    let data: PostUploadData
}

struct PostVideoUploadResponse: Codable {
    let status: String
    let data: PostUploadData
}

struct PostUploadData: Codable {
    let uploadUrl: String
    let fileUrl: String
}

// MARK: - Post Creation State Models

struct PostCreationState {
    var title: String = ""
    var description: String = ""
    var selectedImages: [UIImage] = []
    var selectedVideos: [URL] = []
    var uploadedImageURLs: [String] = []
    var uploadedVideoURLs: [String] = []
    var categoryType: String = "Product"
    var selectedCategory: Category?
    var selectedSubcategory: Subcategory?
    var selectedBrand: Brand?
    var selectedProduct: ProductListItem?
    var customCategory: String = ""
    var customSubCategory: String = ""
    var customBrand: String = ""
    var customProduct: String = ""
    var recommended: String = "safal"
    var rating: Int = 5
    var price: String = ""
    var isUsingCustomCategory: Bool = false
    
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               rating > 0 &&
               rating <= 5 &&
               (!isUsingCustomCategory || !customCategory.isEmpty)
    }
    
    var formattedPrice: Int? {
        guard !price.isEmpty else { return nil }
        return Int(price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }
}

// MARK: - Recommendation Options

enum RecommendationType: String, CaseIterable {
    case safal = "safal"
    case unsafal = "unsafal"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var iconName: String {
        switch self {
        case .safal:
            return "suf"
        case .unsafal:
            return "unsf"
        }
    }
    
    var color: Color {
        switch self {
        case .safal:
            return .green
        case .unsafal:
            return .red
        }
    }
}
