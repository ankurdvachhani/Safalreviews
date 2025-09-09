import Foundation
import SwiftUI

@MainActor
class LatestReviewsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedCategoryType: CategoryType = .all
    @Published var searchText = ""
    @Published var isMyPosts = false
    @Published var currentUserId: String?
    
    private let networkManager = NetworkManager()
    private var currentPage = 1
    private let limit = 10
    private var hasMorePages = true
    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var isFetching = false
    @Published var totalPosts = 0
    
    // MARK: - Init
    init() {
        Task {
            await fetchLatestReviews()
        }
    }
    
    // MARK: - Configuration Methods
    func configureForMyPosts(userId: String) {
        isMyPosts = true
        currentUserId = userId
        Task {
            await fetchLatestReviews(resetPages: true)
        }
    }
    
    func configureForAllPosts() {
        isMyPosts = false
        currentUserId = nil
        Task {
            await fetchLatestReviews(resetPages: true)
        }
    }
    
    // MARK: - Public Methods
    func loadMoreIfNeeded(currentItem: Post?) async {
        guard let currentItem = currentItem,
              let lastItem = posts.last,
              currentItem.id == lastItem.id,
              !isLoading,
              hasMorePages,
              !isFetching
        else { return }
        
        print("📱 Triggering load more for page: \(currentPage)")
        print("📱 Current posts count: \(posts.count)")
        print("📱 Total posts available: \(totalPosts)")
        
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await fetchLatestReviews()
        }
        
        // Wait for the fetch task to complete
        await fetchTask?.value
    }
    
    func fetchLatestReviews(resetPages: Bool = false) async {
        print("🔍 LatestReviewsViewModel.fetchLatestReviews")
        
        if resetPages {
            currentPage = 1
            hasMorePages = true
            posts = []
            totalPosts = 0
        }
        
        guard hasMorePages else {
            print("⚠️ No more pages available, skipping...")
            return
        }
        
        isLoading = true
        isFetching = true
        errorMessage = nil
        
        print("🔄 Starting fetch for page \(currentPage)")
        
        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "page", value: "\(currentPage)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            
            // Add user filter for "My Posts"
            if isMyPosts, let userId = currentUserId {
                queryItems.append(URLQueryItem(name: "userId", value: userId))
            }
            
            // Add category type filter
            if selectedCategoryType != .all {
                queryItems.append(URLQueryItem(name: "categoryType", value: selectedCategoryType.apiValue))
            }
            
            // Add search filter
            if !searchText.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: searchText))
            }
            
            let endpoint = Endpoint(
                path: "/api/post",
                method: .get,
                queryItems: queryItems
            )
            
            let response: LatestReviewsResponse = try await networkManager.fetch(endpoint)
            
            if resetPages {
                posts = response.data
            } else {
                posts.append(contentsOf: response.data)
            }
            
            totalPosts = response.pagination.totalCount
            hasMorePages = response.pagination.hasNextPage
            
            if hasMorePages {
                currentPage += 1
            }
            
            print("✅ Successfully fetched \(response.data.count) posts")
            print("📊 Total posts: \(totalPosts)")
            print("📄 Current page: \(currentPage)")
            print("🔄 Has more pages: \(hasMorePages)")
            
        } catch {
            print("❌ Error fetching latest reviews: \(error)")
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
        }
        
        isLoading = false
        isFetching = false
    }
    
    func searchPosts(query: String) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create new search task with delay
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            if !Task.isCancelled {
                searchText = query
                await fetchLatestReviews(resetPages: true)
            }
        }
    }
    
    func updateCategoryType(_ categoryType: CategoryType) async {
        selectedCategoryType = categoryType
        await fetchLatestReviews(resetPages: true)
    }
    
    func refreshPosts() async {
        refreshTask?.cancel()
        
        refreshTask = Task {
            await fetchLatestReviews(resetPages: true)
        }
        
        await refreshTask?.value
    }
    
    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        successMessage = nil
    }
    
    // MARK: - Like/Dislike Methods
    func likePost(_ post: Post) async {
        print("👍 Liking post: \(post.id)")
        
        do {
            let endpoint = Endpoint(
                path: "/api/post/\(post.id)/like",
                method: .post
            )
            
            let response: PostLikeResponse = try await networkManager.fetch(endpoint)
            
            if response.success {
                // Update the post in the local array with new like data
                await updatePostWithLikeData(response.data)
                print("✅ Post liked successfully")
            } else {
                errorMessage = "Failed to like post"
                print("❌ Failed to like post: \(response.message)")
            }
            
        } catch {
            print("❌ Error liking post: \(error)")
            errorMessage = "Failed to like post: \(error.localizedDescription)"
        }
    }
    
    func dislikePost(_ post: Post) async {
        print("👎 Disliking post: \(post.id)")
        
        do {
            let endpoint = Endpoint(
                path: "/api/post/\(post.id)/dislike",
                method: .post
            )
            
            let response: PostDislikeResponse = try await networkManager.fetch(endpoint)
            
            if response.success {
                // Update the post in the local array with new dislike data
                await updatePostWithDislikeData(response.data)
                print("✅ Post disliked successfully")
            } else {
                errorMessage = "Failed to dislike post"
                print("❌ Failed to dislike post: \(response.message)")
            }
            
        } catch {
            print("❌ Error disliking post: \(error)")
            errorMessage = "Failed to dislike post: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helper Methods
    @MainActor
    private func updatePostWithLikeData(_ likeData: PostLikeData) {
        if let index = posts.firstIndex(where: { $0.id == likeData.id }) {
            // Update the post with new like data
            posts[index].likes = likeData.likes
            posts[index].dislikes = likeData.dislikes
            posts[index].likesCount = likeData.likesCount
            posts[index].dislikesCount = likeData.dislikesCount
            
            print("📊 Updated like count: \(likeData.likesCount), dislike count: \(likeData.dislikesCount)")
        }
    }
    
    @MainActor
    private func updatePostWithDislikeData(_ dislikeData: PostDislikeData) {
        if let index = posts.firstIndex(where: { $0.id == dislikeData.id }) {
            // Update the post with new dislike data
            posts[index].likes = dislikeData.likes
            posts[index].dislikes = dislikeData.dislikes
            posts[index].likesCount = dislikeData.likesCount
            posts[index].dislikesCount = dislikeData.dislikesCount
            
            print("📊 Updated like count: \(dislikeData.likesCount), dislike count: \(dislikeData.dislikesCount)")
        }
    }
    
    func sharePost(_ post: Post) {
        // TODO: Implement share functionality
        print("📤 Sharing post: \(post.id)")
    }
    
    func commentOnPost(_ post: Post) {
        // TODO: Implement comment functionality
        print("💬 Commenting on post: \(post.id)")
    }
    
    // MARK: - My Posts Methods
    func deletePost(_ post: Post) async {
        print("🗑️ Deleting post: \(post.id)")
        
        do {
            let endpoint = Endpoint(
                path: "/api/post/\(post.id)",
                method: .delete
            )
            
            let response: DeletePostResponse = try await networkManager.fetch(endpoint)
            
            if response.success {
                // Remove the post from the local array
                posts.removeAll { $0.id == post.id }
                successMessage = "Post deleted successfully"
                print("✅ Post deleted successfully")
            } else {
                errorMessage = "Failed to delete post"
                print("❌ Failed to delete post: \(response.message)")
            }
            
        } catch {
            print("❌ Error deleting post: \(error)")
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }
    
    func editPost(_ post: Post) {
        // TODO: Implement edit functionality
        print("✏️ Editing post: \(post.id)")
    }
}
