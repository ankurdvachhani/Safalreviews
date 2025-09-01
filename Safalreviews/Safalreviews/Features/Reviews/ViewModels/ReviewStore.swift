import Foundation
import SwiftUI

@MainActor
class ReviewStore: ObservableObject {
    @Published var productReviews: [ProductReview] = []
    @Published var categories: [Category] = []
    @Published var subcategories: [Subcategory] = []
    @Published var brands: [Brand] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let networkManager = NetworkManager()
    var currentPage = 1
    var limit = 15
    var hasMorePages = true
    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var isFetching = false
    @Published var totalProducts = 0
    private var currentSortOption: ReviewSortOption = .dateDesc
    private var currentFilter = ReviewFilter()
    
    // MARK: - Init
    init() {
        Task {
            await fetchProductReviews()
            await fetchCategories()
            await fetchSubcategories()
            await fetchBrands()
        }
    }
    
    // MARK: - Public Methods
    func loadMoreIfNeeded(currentItem: ProductReview?) async {
        guard let currentItem = currentItem,
              let lastItem = productReviews.last,
              currentItem.id == lastItem.id,
              !isLoading,
              hasMorePages,
              !isFetching
        else { return }
        
        print("📱 Triggering load more for page: \(currentPage)")
        print("📱 Current products count: \(productReviews.count)")
        print("📱 Total products available: \(totalProducts)")
        
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await fetchProductReviews(filter: currentFilter, sortOption: currentSortOption)
        }
        
        // Wait for the fetch task to complete
        await fetchTask?.value
    }
    
    func fetchProductReviews(filter: ReviewFilter? = nil, resetPages: Bool = false, sortOption: ReviewSortOption = .dateDesc) async {
        print("🔍 ReviewStore.fetchProductReviews - filter: \(filter?.hasActiveFilters ?? false)")
        
        if resetPages {
            currentPage = 1
            hasMorePages = true
            productReviews = []
            totalProducts = 0
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
            
            // Add filter query items
            if let filter = filter {
                queryItems.append(contentsOf: filter.toQueryItems())
            }
            
            // Add sort query items
            queryItems.append(URLQueryItem(name: "order", value: sortOption.apiOrder))
            queryItems.append(URLQueryItem(name: "orderBy", value: sortOption.apiOrderBy))
            
            let endpoint = Endpoint(
                path: "/api/admin/products/ratings/all",
                method: .get,
                queryItems: queryItems
            )
            
            let response: ProductReviewResponse = try await networkManager.fetch(endpoint)
            
            if resetPages {
                productReviews = response.data
            } else {
                productReviews.append(contentsOf: response.data)
            }
            
            totalProducts = response.pagination.totalCount
            hasMorePages = response.pagination.hasNextPage
            
            if hasMorePages {
                currentPage += 1
            }
            
            print("✅ Successfully fetched \(response.data.count) products")
            print("📊 Total products: \(totalProducts)")
            print("📄 Current page: \(currentPage)")
            print("🔄 Has more pages: \(hasMorePages)")
            
        } catch {
            print("❌ Error fetching product reviews: \(error)")
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
        }
        
        isLoading = false
        isFetching = false
    }
    
    func searchProductReviews(query: String) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create new search task with delay
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            if !Task.isCancelled {
                currentFilter.search = query
                await fetchProductReviews(filter: currentFilter, resetPages: true, sortOption: currentSortOption)
            }
        }
    }
    
    func updateFilter(_ filter: ReviewFilter) async {
        currentFilter = filter
        await fetchProductReviews(filter: currentFilter, resetPages: true, sortOption: currentSortOption)
    }
    
    func updateSortOption(_ sortOption: ReviewSortOption, filter: ReviewFilter? = nil) async {
        currentSortOption = sortOption
        let filterToUse = filter ?? currentFilter
        await fetchProductReviews(filter: filterToUse, resetPages: true, sortOption: sortOption)
    }
    
    func refreshProductReviews() async {
        refreshTask?.cancel()
        
        refreshTask = Task {
            await fetchProductReviews(filter: currentFilter, resetPages: true, sortOption: currentSortOption)
        }
        
        await refreshTask?.value
    }
    
    // MARK: - Filter Data Fetching
    func fetchCategories() async {
        do {
            let endpoint = Endpoint(
                path: "/api/admin/categories",
                method: .get,
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "limit", value: "100"),
                    URLQueryItem(name: "categoryType", value: "null")
                ]
            )
            
            let response: CategoryResponse = try await networkManager.fetch(endpoint)
            categories = response.data
            print("✅ Successfully fetched \(categories.count) categories")
            
        } catch {
            print("❌ Error fetching categories: \(error)")
        }
    }
    
    func fetchSubcategories() async {
        do {
            let endpoint = Endpoint(
                path: "/api/admin/subcategories",
                method: .get,
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "limit", value: "100"),
                    URLQueryItem(name: "categoryType", value: "null")
                ]
            )
            
            let response: SubcategoryResponse = try await networkManager.fetch(endpoint)
            subcategories = response.data
            print("✅ Successfully fetched \(subcategories.count) subcategories")
            
        } catch {
            print("❌ Error fetching subcategories: \(error)")
        }
    }
    
    func fetchBrands() async {
        do {
            let endpoint = Endpoint(
                path: "/api/admin/brands",
                method: .get,
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "limit", value: "100"),
                    URLQueryItem(name: "categoryType", value: "null")
                ]
            )
            
            let response: BrandResponse = try await networkManager.fetch(endpoint)
            brands = response.data
            print("✅ Successfully fetched \(brands.count) brands")
            
        } catch {
            print("❌ Error fetching brands: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    func getCategoryName(for id: String) -> String {
        return categories.first { $0.id == id }?.name ?? "Unknown Category"
    }
    
    func getSubcategoryName(for id: String) -> String {
        return subcategories.first { $0.id == id }?.name ?? "Unknown Subcategory"
    }
    
    func getBrandName(for id: String) -> String {
        return brands.first { $0.id == id }?.name ?? "Unknown Brand"
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        successMessage = nil
    }
}
