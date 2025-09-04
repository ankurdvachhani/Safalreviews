import Foundation

// MARK: - Comment Models

struct PostCommentResponse: Codable {
    let success: Bool
    let data: [PostComment]
    let pagination: CommentPaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct SingleCommentResponse: Codable {
    let success: Bool
}

struct PostComment: Identifiable, Codable {
    let id: String
    let userId: String
    let postId: CommentPostInfo
    let comment: String
    var likes: [String]
    var dislikes: [String]
    let imgs: [String]
    let createdAt: String
    let updatedAt: String
    var likesCount: Int
    var dislikesCount: Int
    let user: PostCommentUser
    let likesDetails: [PostCommentUser]
    let dislikesDetails: [PostCommentUser]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, postId, comment, likes, dislikes, imgs, createdAt, updatedAt
        case likesCount, dislikesCount, user, likesDetails, dislikesDetails
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var isLiked: Bool {
        guard let currentUserId = TokenManager.shared.getUserId() else { return false }
        return likes.contains(currentUserId)
    }
    
    var isDisliked: Bool {
        guard let currentUserId = TokenManager.shared.getUserId() else { return false }
        return dislikes.contains(currentUserId)
    }
}

struct CommentPostInfo: Codable {
    let id: String
    let title: String
    let likesCount: Int
    let dislikesCount: Int
    let sharesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, likesCount, dislikesCount, sharesCount
    }
}

struct PostCommentUser: Codable {
    let id: String
    let companySlug: String?
    let applicationSlug: String?
    let firstName: String
    let lastName: String
    let email: String
    let emailVerifiedId: String?
    let phoneNumber: String?
    let role: String?
    let country: String?
    let state: String?
    let userSlug: String?
    let metadata: PostCommentUserMetadata?
    let status: String?
    let applicationOnly: Bool?
    let auth2faBackup: [String]?
    let isDeleted: Bool?
    let comment: [String]
    let createdAt: String
    let updatedAt: String
    let profilePicture: String?
    let isDelete: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case companySlug, applicationSlug, firstName, lastName, email, emailVerifiedId
        case phoneNumber, role, country, state, userSlug, metadata, status, applicationOnly
        case auth2faBackup, isDeleted, comment, createdAt, updatedAt, profilePicture, isDelete
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return fullName
    }
}

struct PostCommentUserMetadata: Codable {
    let dob: String?
    let username: String?
    let gender: String?
}

struct CommentPaginationInfo: Codable {
    let totalCount: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

// MARK: - Comment Request Models

struct AddCommentRequest: Codable {
    let postId: String
    let comment: String
    let imgs: [String]
}

struct CommentLikeResponse: Codable {
    let success: Bool
    let data: CommentLikeData
}

struct CommentDislikeResponse: Codable {
    let success: Bool
    let data: CommentDislikeData
}

struct CommentLikeData: Codable {
    let id: String
    let likes: [String]
    let dislikes: [String]
    let likesCount: Int
    let dislikesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case likes, dislikes, likesCount, dislikesCount
    }
}

struct CommentDislikeData: Codable {
    let id: String
    let likes: [String]
    let dislikes: [String]
    let likesCount: Int
    let dislikesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case likes, dislikes, likesCount, dislikesCount
    }
}

// MARK: - Comment Image Upload Models

struct CommentImageUploadRequest: Codable {
    let fileName: String
    let folder: String
}

struct CommentImageUploadResponse: Codable {
    let status: String
    let data: CommentUploadData
}

struct CommentUploadData: Codable {
    let uploadUrl: String
    let fileUrl: String
}


