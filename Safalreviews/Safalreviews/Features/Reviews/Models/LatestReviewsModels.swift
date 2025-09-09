import Foundation
import SwiftUI

// MARK: - Latest Reviews Response Models

struct LatestReviewsResponse: Codable {
    let success: Bool
    let data: [Post]
    let pagination: PostPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct Post: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let imgs: [String]
    let videos: [String]
    var likes: [String]
    var dislikes: [String]
    let recommended: String
    let shares: [String]
    var reviews: [Review]
    let user: PostUser
    let price: Int?
    let rating: Int
    let categoryType: String
    let category: PostCategoryInfo?
    let subcategory: PostSubCategoryInfo?
    let brand: PostBrandInfo?
    let product: PostProductInfo?
    let customCategory: String?
    let customSubCategory: String?
    let customBrand: String?
    let customProduct: String?
    let slug: String
    let createdAt: String
    let updatedAt: String
    var likesCount: Int
    var dislikesCount: Int
    let sharesCount: Int
    var likesDetails: [PostUser]
    var dislikesDetails: [PostUser]
    let sharesDetails: [PostUser]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        imgs = try container.decode([String].self, forKey: .imgs)
        videos = try container.decode([String].self, forKey: .videos)
        likes = try container.decode([String].self, forKey: .likes)
        dislikes = try container.decode([String].self, forKey: .dislikes)
        recommended = try container.decode(String.self, forKey: .recommended)
        shares = try container.decode([String].self, forKey: .shares)
        reviews = try container.decode([Review].self, forKey: .reviews)
        user = try container.decode(PostUser.self, forKey: .user)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        rating = try container.decode(Int.self, forKey: .rating)
        categoryType = try container.decode(String.self, forKey: .categoryType)
        category = try container.decodeIfPresent(PostCategoryInfo.self, forKey: .category)
        subcategory = try container.decodeIfPresent(PostSubCategoryInfo.self, forKey: .subcategory)
        brand = try container.decodeIfPresent(PostBrandInfo.self, forKey: .brand)
        product = try container.decodeIfPresent(PostProductInfo.self, forKey: .product)
        customCategory = try container.decodeIfPresent(String.self, forKey: .customCategory)
        customSubCategory = try container.decodeIfPresent(String.self, forKey: .customSubCategory)
        customBrand = try container.decodeIfPresent(String.self, forKey: .customBrand)
        customProduct = try container.decodeIfPresent(String.self, forKey: .customProduct)
        slug = try container.decode(String.self, forKey: .slug)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        likesCount = try container.decode(Int.self, forKey: .likesCount)
        dislikesCount = try container.decode(Int.self, forKey: .dislikesCount)
        sharesCount = try container.decode(Int.self, forKey: .sharesCount)
        likesDetails = try container.decode([PostUser].self, forKey: .likesDetails)
        dislikesDetails = try container.decode([PostUser].self, forKey: .dislikesDetails)
        sharesDetails = try container.decode([PostUser].self, forKey: .sharesDetails)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, imgs, videos, likes, dislikes, recommended, shares, reviews, user
        case price, rating, categoryType, category, subcategory, brand, product
        case customCategory, customSubCategory, customBrand, customProduct
        case slug, createdAt, updatedAt, likesCount, dislikesCount, sharesCount
        case likesDetails, dislikesDetails, sharesDetails
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var displayImage: String? {
        return imgs.first
    }
    
    var hasImages: Bool {
        return !imgs.isEmpty
    }
    
    var hasVideos: Bool {
        return !videos.isEmpty
    }
    
    var categoryName: String {
        if let category = category {
            return category.name
        } else if let customCategory = customCategory {
            return customCategory
        }
        return "Unknown Category"
    }
    
    var subcategoryName: String {
        if let subcategory = subcategory {
            return subcategory.name
        } else if let customSubCategory = customSubCategory {
            return customSubCategory
        }
        return "Unknown Subcategory"
    }
    
    var brandName: String {
        if let brand = brand {
            return brand.name
        } else if let customBrand = customBrand {
            return customBrand
        }
        return "Unknown Brand"
    }
    
    var productName: String {
        if let product = product {
            return product.name
        } else if let customProduct = customProduct {
            return customProduct
        }
        return "Unknown Product"
    }
    
    var formattedPrice: String {
        guard let price = price else { return "N/A" }
        return "$\(price)"
    }
    
    var ratingText: String {
        return "(\(rating)/5)"
    }
    
    var isLiked: Bool {
        // This would need to be updated based on current user ID
        // For now, we'll check if the current user ID is in the likes array
        // You would need to get the current user ID from your authentication system
        let currentUserId = getCurrentUserId() // This should be implemented based on your auth system
        return likes.contains(currentUserId)
    }
    
    var isDisliked: Bool {
        // This would need to be updated based on current user ID
        // For now, we'll check if the current user ID is in the dislikes array
        let currentUserId = getCurrentUserId() // This should be implemented based on your auth system
        return dislikes.contains(currentUserId)
    }
    
    // Helper method to get current user ID
    private func getCurrentUserId() -> String {
        return TokenManager.shared.getUserId() ?? ""
    }
}

struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let postId: String
    let comment: String
    let likes: [String]
    let dislikes: [String]
    let imgs: [String]
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let dislikesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, postId, comment, likes, dislikes, imgs, createdAt, updatedAt, likesCount, dislikesCount
    }
    
    static var mockReview: Review {
        Review(
            id: "mock-review-id",
            userId: "mock-user-id",
            postId: "mock-post-id",
            comment: "Mock comment",
            likes: [],
            dislikes: [],
            imgs: [],
            createdAt: "2024-01-01T00:00:00.000Z",
            updatedAt: "2024-01-01T00:00:00.000Z",
            likesCount: 0,
            dislikesCount: 0
        )
    }
}

struct PostUser: Identifiable, Codable {
    let id: String
    let companySlug: String
    let applicationSlug: String
    let firstName: String
    let lastName: String
    let email: String
    let emailVerifiedId: String?
    let phoneNumber: String?
    let phoneNumberVerifiedId: String?
    let dob: String?
    let country: String?
    let state: String?
    let userSlug: String?
    let metadata: PostUserMetadata?
    let status: String?
    let applicationOnly: Bool?
    let comment: [PostUserComment]?
    let createdAt: String?
    let updatedAt: String?
    let isDelete: Bool?
    let isDeleted: Bool?
    let profilePicture: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        companySlug = try container.decode(String.self, forKey: .companySlug)
        applicationSlug = try container.decode(String.self, forKey: .applicationSlug)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        emailVerifiedId = try container.decodeIfPresent(String.self, forKey: .emailVerifiedId)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        phoneNumberVerifiedId = try container.decodeIfPresent(String.self, forKey: .phoneNumberVerifiedId)
        dob = try container.decodeIfPresent(String.self, forKey: .dob)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        userSlug = try container.decodeIfPresent(String.self, forKey: .userSlug)
        metadata = try container.decodeIfPresent(PostUserMetadata.self, forKey: .metadata)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        applicationOnly = try container.decodeIfPresent(Bool.self, forKey: .applicationOnly)
        comment = try container.decodeIfPresent([PostUserComment].self, forKey: .comment) ?? []
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        isDelete = try container.decodeIfPresent(Bool.self, forKey: .isDelete)
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case companySlug, applicationSlug, firstName, lastName, email, emailVerifiedId
        case phoneNumber, phoneNumberVerifiedId, dob, country, state, userSlug, metadata
        case status, applicationOnly, comment, createdAt, updatedAt, isDelete, isDeleted, profilePicture
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return fullName
    }
}

struct PostUserMetadata: Codable {
    let username: String?
    let gender: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
    }
}

struct PostUserComment: Codable {
    let newAction: String
    let oldAction: String
    let comment: String
    let createdAt: String
    let updatedAt: String
}

struct PostCategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct PostSubCategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct PostBrandInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct PostProductInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct PostPaginationInfo: Codable {
    let totalCount: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

// MARK: - Filter Models for Latest Reviews

struct LatestReviewsFilter {
    var categoryType: String = "All"
    var search: String = ""
    
    var hasActiveFilters: Bool {
        return categoryType != "All" || !search.isEmpty
    }
    
    mutating func clearAll() {
        categoryType = "All"
        search = ""
    }
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if categoryType != "All" {
            items.append(URLQueryItem(name: "categoryType", value: categoryType.lowercased()))
        }
        
        if !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        
        return items
    }
}

// MARK: - Category Type Options

enum CategoryType: String, CaseIterable, Identifiable {
    case all = "All"
    case product = "Products"
    case place = "Places"
    case person = "People"
    
    var id: String { rawValue }
    
    var displayName: String {
        return rawValue
    }
    
    var apiValue: String {
        switch self {
        case .all:
            return ""
        case .product:
            return "product"
        case .place:
            return "place"
        case .person:
            return "person"
        }
    }
}

// MARK: - Like/Dislike Response Models

struct PostLikeResponse: Codable {
    let success: Bool
    let data: PostLikeData
    let errors: [String]
    let timestamp: String
    let message: String
}

struct PostDislikeResponse: Codable {
    let success: Bool
    let data: PostDislikeData
    let errors: [String]
    let timestamp: String
    let message: String
}

struct PostLikeData: Codable {
    let id: String
    let title: String
    let description: String
    let imgs: [String]
    let videos: [String]
    let likes: [String]
    let dislikes: [String]
    let recommended: String
    let shares: [String]
    let reviews: [String]
    let user: String
    let price: Int?
    let rating: Int
    let categoryType: String
    let category: String?
    let subcategory: String?
    let brand: String?
    let product: String?
    let slug: String
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let dislikesCount: Int
    let sharesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, imgs, videos, likes, dislikes, recommended, shares, reviews, user
        case price, rating, categoryType, category, subcategory, brand, product
        case slug, createdAt, updatedAt, likesCount, dislikesCount, sharesCount
    }
}

struct PostDislikeData: Codable {
    let id: String
    let title: String
    let description: String
    let imgs: [String]
    let videos: [String]
    let likes: [String]
    let dislikes: [String]
    let recommended: String
    let shares: [String]
    let reviews: [String]
    let user: String
    let price: Int?
    let rating: Int
    let categoryType: String
    let category: String?
    let subcategory: String?
    let brand: String?
    let product: String?
    let slug: String
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let dislikesCount: Int
    let sharesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, imgs, videos, likes, dislikes, recommended, shares, reviews, user
        case price, rating, categoryType, category, subcategory, brand, product
        case slug, createdAt, updatedAt, likesCount, dislikesCount, sharesCount
    }
}

// MARK: - Mock Data for Preview
extension Post {
    static var mockPost: Post {
        let mockData = """
        {
            "_id": "mock-post-id",
            "title": "Sample Product Review",
            "description": "This is a sample product review with detailed information about the product quality, features, and user experience.",
            "imgs": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
            "videos": [],
            "likes": [],
            "dislikes": [],
            "recommended": "safal",
            "shares": [],
            "reviews": [],
            "user": {
                "_id": "user1",
                "companySlug": "company1",
                "applicationSlug": "app1",
                "firstName": "John",
                "lastName": "Doe",
                "email": "john.doe@example.com",
                "emailVerifiedId": "verified1",
                "phoneNumber": "1234567890",
                "role": "User",
                "country": "USA",
                "state": "CA",
                "userSlug": "john-doe",
                "metadata": {
                    "username": "johndoe",
                    "gender": "male"
                },
                "status": "Active",
                "applicationOnly": true,
                "comment": [],
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2024-01-01T00:00:00.000Z",
                "isDeleted": false,
                "profilePicture": "https://example.com/profile.jpg"
            },
            "price": 99,
            "rating": 4,
            "categoryType": "product",
            "category": {
                "_id": "cat1",
                "name": "Electronics",
                "slug": "electronics"
            },
            "subcategory": {
                "_id": "subcat1",
                "name": "Smartphones",
                "slug": "smartphones"
            },
            "brand": {
                "_id": "brand1",
                "name": "Sample Brand",
                "slug": "sample-brand"
            },
            "product": {
                "_id": "prod1",
                "name": "Sample Product",
                "slug": "sample-product"
            },
            "slug": "sample-product-review",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z",
            "likesCount": 0,
            "dislikesCount": 0,
            "sharesCount": 0,
            "likesDetails": [],
            "dislikesDetails": [],
            "sharesDetails": []
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        return try! decoder.decode(Post.self, from: mockData)
    }
}

// MARK: - Delete Post Response Model

struct DeletePostResponse: Codable {
    let success: Bool
    let message: String
    let errors: [String]?
    let timestamp: String?
}


