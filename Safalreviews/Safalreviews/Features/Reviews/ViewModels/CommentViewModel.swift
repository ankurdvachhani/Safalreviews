import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [PostComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedImages: [UIImage] = []
    @Published var commentText = ""
    @Published var isAddingComment = false
    var onCommentAdded: (() -> Void)?
    
    private let networkManager = NetworkManager()
    private var currentPage = 1
    private let limit = 20
    private var hasMorePages = true
    private var isFetching = false
    private let folderName = "reviews/comments/images"
    
    // MARK: - Public Methods
    
    func fetchComments(for postId: String, resetPages: Bool = false) async {
        if resetPages {
            currentPage = 1
            hasMorePages = true
            comments = []
        }
        
        guard hasMorePages && !isFetching else { return }
        
        isLoading = true
        isFetching = true
        errorMessage = nil
        
        do {
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "postId", value: postId),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "sort[0][orderBy]", value: "createdAt"),
                URLQueryItem(name: "sort[0][order]", value: "desc")
            ]
            
            let endpoint = Endpoint(
                path: "/api/comment",
                method: .get,
                queryItems: queryItems
            )
         
            let response: PostCommentResponse = try await networkManager.fetch(endpoint)
            
            if currentPage == 1 {
                comments = response.data
            } else {
                // Filter out duplicates before appending
                let newComments = response.data.filter { newComment in
                    !comments.contains { $0.id == newComment.id }
                }
                comments.append(contentsOf: newComments)
            }
            
            hasMorePages = response.pagination.hasNextPage
            if hasMorePages {
                currentPage += 1
            }
            
            print("✅ Successfully fetched \(response.data.count) comments")
            
        } catch {
            print("❌ Error fetching comments: \(error)")
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        
        isLoading = false
        isFetching = false
    }
    
    func addComment(to postId: String) async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a comment"
            return
        }
        
        isAddingComment = true
        errorMessage = nil
        
        do {
            // Upload images first if any
            var uploadedImageURLs: [String] = []
            
            for image in selectedImages {
                if let imageURL = try await uploadCommentImage(image) {
                    uploadedImageURLs.append(imageURL)
                }
            }
            
            // Create comment request
            let request = AddCommentRequest(
                postId: postId,
                comment: commentText.trimmingCharacters(in: .whitespacesAndNewlines),
                imgs: uploadedImageURLs
            )

            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + "/api/comment") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let response = try decoder.decode(SingleCommentResponse.self, from: data)
                
                if response.success {
                    // Add new comment to the beginning of the list
                 //   comments.insert(response.data, at: 0)
                    successMessage = "Comment added successfully"
                    
                    // Clear form
                    commentText = ""
                    selectedImages = []
                    
                    // Call the callback to update parent view
                    onCommentAdded?()
                    
                    // Refresh comments to get updated data
                    await refreshComments(for: postId)
                } else {
                    errorMessage = "Failed to add comment"
                }
            } else {
                throw NetworkError.apiError("Failed to add comment: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Missing key '\(key.stringValue)' – \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type '\(type)' – \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found for type '\(type)' – \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to decode server response"
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred"
        }
        
        isAddingComment = false
    }
    
    func likeComment(_ comment: PostComment) async {
        do {
            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + "/api/comment/\(comment.id)/like") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let response = try JSONDecoder().decode(CommentLikeResponse.self, from: data)
                
                if response.success {
                    await updateCommentWithLikeData(response.data)
                    print("✅ Comment liked successfully")
                } else {
                    errorMessage = "Failed to like comment"
                }
            } else {
                throw NetworkError.apiError("Failed to like comment: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "Failed to like comment: \(error.localizedDescription)"
        }
    }
    
    func dislikeComment(_ comment: PostComment) async {
        do {
            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + "/api/comment/\(comment.id)/dislike") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let response = try JSONDecoder().decode(CommentDislikeResponse.self, from: data)
                
                if response.success {
                    await updateCommentWithDislikeData(response.data)
                    print("✅ Comment disliked successfully")
                } else {
                    errorMessage = "Failed to dislike comment"
                }
            } else {
                throw NetworkError.apiError("Failed to dislike comment: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "Failed to dislike comment: \(error.localizedDescription)"
        }
    }
    
    func refreshComments(for postId: String) async {
        await fetchComments(for: postId, resetPages: true)
    }
    
    // MARK: - Image Handling
    
    func addImage(_ image: UIImage) {
        guard selectedImages.count < 4 else {
            errorMessage = "Maximum 4 images allowed"
            return
        }
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages.removeAll()
    }
    
    func resizedImage(_ image: UIImage, maxWidth: CGFloat = 1080) -> UIImage {
          let scale = maxWidth / image.size.width
          let newHeight = image.size.height * scale
          let newSize = CGSize(width: maxWidth, height: newHeight)
          
          UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
          image.draw(in: CGRect(origin: .zero, size: newSize))
          let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          
          return resizedImage ?? image
      }
    
    // MARK: - Private Methods
    
    private func uploadCommentImage(_ image: UIImage) async throws -> String? {
        let smallImage = resizedImage(image)
               guard let imageData = smallImage.jpegData(compressionQuality: 0.2) else {
                   throw NetworkError.invalidData
               }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "comment_image_\(timestamp).jpg"
        
        print("📤 Uploading comment image: \(uniqueFileName)")
        
        let uploadRequest = CommentImageUploadRequest(
            fileName: uniqueFileName,
            folder: folderName
        )
        
        // Create the URL request for comment image upload
        guard let url = URL(string: APIConfig.baseURL + "/api/s3/upload-url") else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
        urlRequest.httpBody = try JSONEncoder().encode(uploadRequest)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log the response
        NetworkLogger.log(response: response, data: data, error: nil)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let uploadUrlResponse = try JSONDecoder().decode(CommentImageUploadResponse.self, from: data)
            
            print("Got signed URL for upload: \(uploadUrlResponse.data.uploadUrl)")
            
            // Upload image using NetworkManager
            try await networkManager.uploadFile(
                url: uploadUrlResponse.data.uploadUrl,
                data: imageData,
                contentType: "image/jpeg"
            )
            
            print("✅ Comment image uploaded successfully")
            return uploadUrlResponse.data.fileUrl
        } else {
            throw NetworkError.apiError("Failed to get upload URL: \(httpResponse.statusCode)")
        }
    }
    
    @MainActor
    private func updateCommentWithLikeData(_ likeData: CommentLikeData) {
        if let index = comments.firstIndex(where: { $0.id == likeData.id }) {
            comments[index].likes = likeData.likes
            comments[index].dislikes = likeData.dislikes
            comments[index].likesCount = likeData.likesCount
            comments[index].dislikesCount = likeData.dislikesCount
        }
    }
    
    @MainActor
    private func updateCommentWithDislikeData(_ dislikeData: CommentDislikeData) {
        if let index = comments.firstIndex(where: { $0.id == dislikeData.id }) {
            comments[index].likes = dislikeData.likes
            comments[index].dislikes = dislikeData.dislikes
            comments[index].likesCount = dislikeData.likesCount
            comments[index].dislikesCount = dislikeData.dislikesCount
        }
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        successMessage = nil
    }
}
