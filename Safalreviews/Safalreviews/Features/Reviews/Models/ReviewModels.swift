import Foundation
import SwiftUI

// MARK: - Product Review Response Models

struct ProductReviewResponse: Codable {
    let success: Bool
    let data: [ProductReview]
    let pagination: ProductPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct ProductReview: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let media: [String]
    let category: String?
    let subCategory: String?
    let specifications: [String: String]
    let isActive: Bool
    let slug: String
    let createdAt: String
    let updatedAt: String
    let categoryType: String
    let brand: BrandInfo
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
        return mediaSignedUrls.first ?? media.first
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

struct BrandInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let subCategory: SubCategoryInfo
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug, subCategory
    }
}

struct SubCategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    let category: CategoryInfo
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug, category
    }
}

struct CategoryInfo: Codable {
    let id: String
    let name: String
    let slug: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, slug
    }
}

struct ProductPaginationInfo: Codable {
    let totalCount: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

// MARK: - Category Response Models

struct CategoryResponse: Codable {
    let success: Bool
    let data: [Category]
    let pagination: ProductPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let isActive: Bool
    let categoryType: String
    let slug: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, isActive, categoryType, slug, createdAt, updatedAt
    }
}

// MARK: - Subcategory Response Models

struct SubcategoryResponse: Codable {
    let success: Bool
    let data: [Subcategory]
    let pagination: ProductPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct Subcategory: Identifiable, Codable {
    let id: String
    let name: String
    let category: CategoryInfo
    let isActive: Bool
    let categoryType: String
    let slug: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, category, isActive, categoryType, slug, createdAt, updatedAt
    }
}

// MARK: - Brand Response Models

struct BrandResponse: Codable {
    let success: Bool
    let data: [Brand]
    let pagination: ProductPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct Brand: Identifiable, Codable {
    let id: String
    let name: String
    let subCategory: SubCategoryInfo
    let isActive: Bool
    let categoryType: String
    let slug: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, subCategory, isActive, categoryType, slug, createdAt, updatedAt
    }
}

// MARK: - Filter Models

struct ReviewFilter {
    var categoryType: String?
    var category: String?
    var subCategory: String?
    var brand: String?
    var search: String = ""
    
    var hasActiveFilters: Bool {
        return categoryType != nil || category != nil || subCategory != nil || brand != nil || !search.isEmpty
    }
    
    mutating func clearAll() {
        categoryType = nil
        category = nil
        subCategory = nil
        brand = nil
        search = ""
    }
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let categoryType = categoryType, categoryType != "All types" {
            items.append(URLQueryItem(name: "categoryType", value: categoryType))
        }
        
        if let category = category {
            items.append(URLQueryItem(name: "category", value: category))
        }
        
        if let subCategory = subCategory {
            items.append(URLQueryItem(name: "subCategory", value: subCategory))
        }
        
        if let brand = brand {
            items.append(URLQueryItem(name: "brand", value: brand))
        }
        
        if !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        
        return items
    }
}

// MARK: - Sort Options

enum ReviewSortOption: String, CaseIterable, Identifiable {
    case nameAsc = "Name A-Z"
    case nameDesc = "Name Z-A"
    case ratingDesc = "Highest Rated"
    case ratingAsc = "Lowest Rated"
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    
    var id: String { rawValue }
    
    var sortDescriptor: (ProductReview, ProductReview) -> Bool {
        switch self {
        case .nameAsc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .ratingDesc:
            return { $0.averageRating > $1.averageRating }
        case .ratingAsc:
            return { $0.averageRating < $1.averageRating }
        case .dateDesc:
            return { $0.createdAt > $1.createdAt }
        case .dateAsc:
            return { $0.createdAt < $1.createdAt }
        }
    }
    
    var apiOrder: String {
        switch self {
        case .nameAsc, .nameDesc:
            return "asc"
        case .ratingDesc, .ratingAsc:
            return "desc"
        case .dateDesc, .dateAsc:
            return "desc"
        }
    }
    
    var apiOrderBy: String {
        switch self {
        case .nameAsc, .nameDesc:
            return "name"
        case .ratingDesc, .ratingAsc:
            return "averageRating"
        case .dateDesc, .dateAsc:
            return "createdAt"
        }
    }
}
