//
//  AdvertisementModels.swift
//  Safalreviews
//
//  Created by Apple on 01/09/25.
//

import Foundation

// MARK: - Advertisement Settings Response
struct AdvertisementSettingsResponse: Codable {
    let success: Bool
    let data: [AdvertisementApplication]
}

struct AdvertisementApplication: Codable {
    let id: String
    let name: String
    let application: String?
    let pages: [AdvertisementPage]?
    let createdAt: String?
    let updatedAt: String?
    let value: String?
    let status: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, application, pages, createdAt, updatedAt, value, status
    }
}

struct AdvertisementPage: Codable {
    let name: String?
    let id: String?
    let value: String?
    let status: Bool?
    let sections: [AdvertisementSection]?
}

struct AdvertisementSection: Codable {
    let name: String?
    let id: String?
    let value: String?
    let status: Bool?
}

// MARK: - Advertisement List Response
struct AdvertisementListResponse: Codable {
    let success: Bool
    let data: [Advertisement]
}

struct Advertisement: Codable, Identifiable {
    let id: String
    let adId: String
    let adName: String
    let application: String
    let deviceType: [String]
    let adPage: String
    let redirectUrl: String
    let adContentText: String
    let description: String
    let status: String
    let adWebSection: String?
    let adMobileSection: String?
    let webImageUrl: String?
    let mobileImageUrl: String?
    let adType: String
    
    var isPublished: Bool {
        return status == "PUBLISHED"
    }
    
    var imageUrl: String? {
        return mobileImageUrl ?? webImageUrl
    }
}

// MARK: - Advertisement Configuration
struct AdvertisementConfiguration {
    let pageName: String
    let sectionName: String
    let displayInterval: Int
    let isEnabled: Bool
    
    static let dashboard = AdvertisementConfiguration(
        pageName: "Dashboard",
        sectionName: "Between the reviews card",
        displayInterval: 4,
        isEnabled: true
    )
    
    static let home = AdvertisementConfiguration(
        pageName: "Home",
        sectionName: "Between the reviews card",
        displayInterval: 3,
        isEnabled: true
    )
}
