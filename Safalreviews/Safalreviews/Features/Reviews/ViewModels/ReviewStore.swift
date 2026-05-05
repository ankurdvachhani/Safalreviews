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
        // Check if categoryType changed
        let categoryTypeChanged = currentFilter.categoryType != filter.categoryType
        
        currentFilter = filter
        await fetchProductReviews(filter: currentFilter, resetPages: true, sortOption: currentSortOption)
        
        // If categoryType changed, refresh filter data
        if categoryTypeChanged {
            await fetchCategories(categoryType: filter.categoryType)
            await fetchSubcategories(categoryType: filter.categoryType)
            await fetchBrands(categoryType: filter.categoryType)
        }
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
    func fetchCategories(categoryType: String? = nil) async {
        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100")
            ]
            
            if let categoryType = categoryType, categoryType != "All types" {
                queryItems.append(URLQueryItem(name: "categoryType", value: categoryType))
            }
            
            let endpoint = Endpoint(
                path: "/api/admin/categories",
                method: .get,
                queryItems: queryItems
            )
            
            let response: CategoryResponse = try await networkManager.fetch(endpoint)
            categories = response.data
            print("✅ Successfully fetched \(categories.count) categories")
            
        } catch {
            print("❌ Error fetching categories: \(error)")
        }
    }
    
    func fetchSubcategories(categoryType: String? = nil) async {
        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100")
            ]
            
            if let categoryType = categoryType, categoryType != "All types" {
                queryItems.append(URLQueryItem(name: "categoryType", value: categoryType))
            }
            
            let endpoint = Endpoint(
                path: "/api/admin/subcategories",
                method: .get,
                queryItems: queryItems
            )
            
            let response: SubcategoryResponse = try await networkManager.fetch(endpoint)
            subcategories = response.data
            print("✅ Successfully fetched \(subcategories.count) subcategories")
            
        } catch {
            print("❌ Error fetching subcategories: \(error)")
        }
    }
    
    func fetchBrands(categoryType: String? = nil) async {
        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100")
            ]
            
            if let categoryType = categoryType, categoryType != "All types" {
                queryItems.append(URLQueryItem(name: "categoryType", value: categoryType))
            }
            
            let endpoint = Endpoint(
                path: "/api/admin/brands",
                method: .get,
                queryItems: queryItems
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





@MainActor
class AdvertisementService: ObservableObject {
    @Published var settings: AdvertisementSettingsResponse?
    @Published var advertisements: [Advertisement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager()
    private var advertisementCache: [String: [Advertisement]] = [:]
    private var settingsCache: AdvertisementSettingsResponse?
    
    // MARK: - Fetch Advertisement Settings
    func fetchAdvertisementSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Use APIConfig for consistent URL building
            var components = URLComponents(string: APIConfig.utilitiesUrl + APIConfig.Path.advertisementSettings)
            components?.queryItems = [
                URLQueryItem(name: "application", value: "SafalReviews")
            ]
            
            guard let url = components?.url else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
            
            let response: AdvertisementSettingsResponse = try await networkManager.fetch(Endpoint(path: ""), urlRequest: request)
            self.settings = response
            self.settingsCache = response
            print("✅ Successfully fetched advertisement settings")
        } catch {
            self.errorMessage = "Failed to fetch advertisement settings: \(error.localizedDescription)"
            print("❌ Advertisement settings error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Advertisements
    func fetchAdvertisements(for page: String, includeScheduled: Bool = false) async {
        // Check cache first
        if let cachedAds = advertisementCache[page], !cachedAds.isEmpty {
            self.advertisements = cachedAds
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use APIConfig for consistent URL building
            var components = URLComponents(string: APIConfig.utilitiesUrl + APIConfig.Path.advertisementList)
            components?.queryItems = [
                URLQueryItem(name: "application", value: "SafalReviews"),
                URLQueryItem(name: "device", value: "ios"),
                URLQueryItem(name: "section", value: "Between the reviews card")
            ]
            
            guard let url = components?.url else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
            
            let response: AdvertisementListResponse = try await networkManager.fetch(Endpoint(path: ""), urlRequest: request)
            
            // Filter advertisements for the specific page and published status
            // For Home page, include both PUBLISHED and SCHEDULED ads
            let filteredAds = response.data.filter { ad in
                ad.adPage == page && (ad.isPublished || ad.status == "SCHEDULED")
            }
            
            print("🔍 Filtering ads for page: \(page)")
            print("📊 Total ads from API: \(response.data.count)")
            print("📊 Ads for page '\(page)': \(response.data.filter { $0.adPage == page }.count)")
            print("📊 Available ads (PUBLISHED + SCHEDULED) for page '\(page)': \(filteredAds.count)")
            
            // Debug: Print each ad's details
            for ad in response.data {
                print("📋 Ad: \(ad.adName) | Page: \(ad.adPage) | Status: \(ad.status) | Published: \(ad.isPublished)")
            }
            
            self.advertisements = filteredAds
            self.advertisementCache[page] = filteredAds
            
            print("✅ Successfully fetched \(filteredAds.count) advertisements for page: \(page)")
        } catch {
            self.errorMessage = "Failed to fetch advertisements: \(error.localizedDescription)"
            print("❌ Advertisement fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Get Configuration for Page
    func getConfiguration(for page: String) -> AdvertisementConfiguration {
        // Use cached settings if available
        let settingsToUse = settings ?? settingsCache
        
        print("🔍 Getting configuration for page: \(page)")
        
        guard let settings = settingsToUse,
              let application = settings.data.first(where: { $0.application == "SafalReviews" || $0.name == "SafalReviews" }),
              let pages = application.pages,
              let pageData = pages.first(where: { $0.id == page }),
              let sections = pageData.sections,
              let section = sections.first(where: { $0.id == "Between the reviews card" }) else {
            print("⚠️ Using default configuration for page: \(page)")
            // Return default configuration
            return page == "Dashboard" ? .dashboard : .home
        }
        
        let interval = Int(section.value ?? "") ?? (page == "Dashboard" ? 4 : 3)
        let isEnabled = section.status ?? true
        
        print("✅ Found configuration for page '\(page)': interval=\(interval), enabled=\(isEnabled)")
        
        return AdvertisementConfiguration(
            pageName: page,
            sectionName: section.name ?? "Between the reviews card",
            displayInterval: interval,
            isEnabled: isEnabled
        )
    }
    
    // MARK: - Get Advertisement for Index (Fixed Logic)
    func getAdvertisementForIndex(_ index: Int, configuration: AdvertisementConfiguration) -> Advertisement? {
        guard configuration.isEnabled && !advertisements.isEmpty else { return nil }
        
        // Calculate which advertisement to show based on display interval
        // If displayInterval is 3, show ad at indices: 2, 5, 8, 11, etc.
        let shouldShowAd = (index + 1) % configuration.displayInterval == 0
        
        guard shouldShowAd else { return nil }
        
        // Calculate which ad to show (cycle through available ads)
        let adPosition = (index / configuration.displayInterval) % advertisements.count
        
        return advertisements[adPosition]
    }
    
    // MARK: - Check if Index Should Show Advertisement
    func shouldShowAdvertisement(at index: Int, configuration: AdvertisementConfiguration) -> Bool {
        guard configuration.isEnabled && !advertisements.isEmpty else { 
            print("⚠️ Advertisement not shown at index \(index): enabled=\(configuration.isEnabled), ads count=\(advertisements.count)")
            return false 
        }
        
        // Show advertisement every 'displayInterval' items
        let shouldShow = (index + 1) % configuration.displayInterval == 0
        if shouldShow {
            print("📢 Showing advertisement at index \(index) (interval: \(configuration.displayInterval))")
        }
        return shouldShow
    }
    
    // MARK: - Get Advertisement Position in List
    func getAdvertisementPosition(for index: Int, configuration: AdvertisementConfiguration) -> Int {
        guard configuration.isEnabled && !advertisements.isEmpty else { return -1 }
        
        // Calculate which ad to show (cycle through available ads)
        let adPosition = (index / configuration.displayInterval) % advertisements.count
        return adPosition
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        advertisementCache.removeAll()
        settingsCache = nil
        advertisements = []
        settings = nil
    }
    
    // MARK: - Get All Advertisements (for debugging)
    func getAllAdvertisements(for page: String) -> [Advertisement] {
        return advertisementCache[page] ?? []
    }
    
    // MARK: - Get Advertisement Statistics
    func getAdvertisementStats(for page: String) -> (total: Int, published: Int, scheduled: Int) {
        let allAds = advertisementCache[page] ?? []
        let published = allAds.filter { $0.isPublished }.count
        let scheduled = allAds.filter { $0.status == "SCHEDULED" }.count
        
        return (total: allAds.count, published: published, scheduled: scheduled)
    }
    
    // MARK: - Refresh Data
    func refreshData(for page: String) async {
        clearCache()
        await fetchAdvertisementSettings()
        await fetchAdvertisements(for: page)
    }
    
    // MARK: - Open Advertisement URL
    func openAdvertisementURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Track Advertisement (Impression/Click)
    func trackAdvertisement(advertisementId: String, pageKey: String, sectionKey: String, type: String, description: String = "") async {
        do {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
            let request = AdvertisementTrackingRequest(
                advertisementId: advertisementId,
                description: description,
                deviceId: deviceId,
                device: "ios",
                pageKey: pageKey,
                sectionKey: sectionKey,
                type: type
            )
            
            // Construct the full URL using analyticsUrl
            let url = URL(string: APIConfig.analyticsUrl + APIConfig.Path.advertisementAnalytics)!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let _: AdvertisementTrackingResponse = try await networkManager.fetch(Endpoint(path: ""), urlRequest: urlRequest)
            print("✅ Successfully tracked advertisement \(type) for ID: \(advertisementId)")
        } catch {
            print("❌ Failed to track advertisement \(type): \(error)")
        }
    }
}
