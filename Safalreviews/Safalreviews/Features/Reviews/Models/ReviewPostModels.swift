import Foundation
import SwiftUI

// MARK: - Review Post Response Models

struct ReviewPostResponse: Codable {
    let success: Bool
    let data: [ReviewPost]
    let pagination: ReviewPostPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct ReviewPost: Identifiable, Codable {
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
    let user: ReviewUser
    let rating: Int
    let categoryType: String
    let category: ReviewCategory
    let subcategory: ReviewSubcategory
    let brand: ReviewBrand
    let product: ReviewProduct
    let slug: String
    let createdAt: String
    let updatedAt: String
    let likesCount: Int
    let dislikesCount: Int
    let sharesCount: Int
    let likesDetails: [String]
    let dislikesDetails: [String]
    let sharesDetails: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, imgs, videos, likes, dislikes, recommended
        case shares, reviews, user, rating, categoryType, category, subcategory
        case brand, product, slug, createdAt, updatedAt, likesCount, dislikesCount
        case sharesCount, likesDetails, dislikesDetails, sharesDetails
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var displayImage: String? {
        return imgs.first
    }
    
    var cleanDescription: String {
        // Remove HTML tags from description
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    var userDisplayName: String {
        let firstName = user.firstName.isEmpty ? "" : user.firstName
        let lastName = user.lastName.isEmpty ? "" : user.lastName
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

struct ReviewUser: Codable {
    let id: String
    let companySlug: String?
    let applicationSlug: String?
    let firstName: String
    let lastName: String
    let email: String
    let emailVerifiedId: String
    let phoneNumber: String
    let role: String
    let country: String
    let state: String?
    let userSlug: String?
    let metadata: ProductUserMetadata?
    let status: String?
    let applicationOnly: Bool?
    let auth2faBackup: [String]?
    let isDeleted: Bool?
    let comment: [String]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case companySlug, applicationSlug, firstName, lastName, email
        case emailVerifiedId, phoneNumber, role, country, state, userSlug
        case metadata, status, applicationOnly, auth2faBackup, isDeleted
        case comment, createdAt, updatedAt
    }
}

struct ProductUserMetadata: Codable {
    let dob: String
    let username: String
}

struct ReviewCategory: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct ReviewSubcategory: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct ReviewBrand: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct ReviewProduct: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct ReviewPostPaginationInfo: Codable {
    let totalCount: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

// MARK: - Product Detail Models

struct ProductDetail: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let displayImage: String?
    let category: String
    let subcategory: String
    let brand: String
    let averageRating: Double
    let totalRatings: Int
    let ratingBreakdown: [Int: Int] // rating -> count
    let reviews: [ReviewPost]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, displayImage, category, subcategory, brand
        case averageRating, totalRatings, ratingBreakdown, reviews
    }
    
    var ratingText: String {
        if totalRatings == 0 {
            return "No ratings yet"
        } else {
            return String(format: "%.1f", averageRating)
        }
    }
    
    var isRated: Bool {
        return totalRatings > 0
    }
}
