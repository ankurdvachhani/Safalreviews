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
    
    func likePost(_ post: Post) {
        // TODO: Implement like functionality
        print("👍 Liking post: \(post.id)")
    }
    
    func dislikePost(_ post: Post) {
        // TODO: Implement dislike functionality
        print("👎 Disliking post: \(post.id)")
    }
    
    func sharePost(_ post: Post) {
        // TODO: Implement share functionality
        print("📤 Sharing post: \(post.id)")
    }
    
    func commentOnPost(_ post: Post) {
        // TODO: Implement comment functionality
        print("💬 Commenting on post: \(post.id)")
    }
}
