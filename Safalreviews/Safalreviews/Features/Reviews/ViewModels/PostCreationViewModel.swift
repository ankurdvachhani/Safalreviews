import Foundation
import SwiftUI
import PhotosUI

@MainActor
class PostCreationViewModel: ObservableObject {
    @Published var state = PostCreationState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isCreatingPost = false
    var onPostCreated: (() -> Void)?
    
    // Filter data
    @Published var categories: [Category] = []
    @Published var subcategories: [Subcategory] = []
    @Published var brands: [Brand] = []
    @Published var products: [ProductListItem] = []
    
    // UI state
    @Published var showCategoryTypeDropdown = false
    @Published var showCategoryDropdown = false
    @Published var showSubcategoryDropdown = false
    @Published var showBrandDropdown = false
    @Published var showProductDropdown = false
    @Published var showCustomCategoryModal = false
    @Published var showImagePicker = false
    @Published var showVideoPicker = false
    @Published var showDocumentPicker = false
    
    private let networkManager = NetworkManager()
    private let reviewStore = ReviewStore()
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        await fetchCategories()
        await fetchSubcategories()
        await fetchBrands()
    }
    
    func fetchCategories() async {
        do {
            let queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100")
            ]
            
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
            errorMessage = "Failed to fetch categories"
        }
    }
    
    func fetchSubcategories() async {
        do {
            let queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "category", value: state.selectedCategory?.id)
            ]
            
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
            errorMessage = "Failed to fetch subcategories"
        }
    }
    
    func fetchBrands() async {
        do {
            let queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "categoryType", value: state.categoryType),
                URLQueryItem(name: "subCategory", value: state.selectedSubcategory?.id ?? "")
            ]
            
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
            errorMessage = "Failed to fetch brands"
        }
    }
    
    func fetchProducts() async {
        guard let category = state.selectedCategory,
              let subcategory = state.selectedSubcategory,
              let brand = state.selectedBrand else {
            products = []
            return
        }
        
        do {
            let queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "category", value: category.id),
                URLQueryItem(name: "subCategory", value: subcategory.id),
                URLQueryItem(name: "brand", value: brand.id)
            ]
            
            let endpoint = Endpoint(
                path: APIConfig.Path.getProducts,
                method: .get,
                queryItems: queryItems
            )
            
            let response: ProductListResponse = try await networkManager.fetch(endpoint)
            products = response.data
            print("✅ Successfully fetched \(products.count) products")
            
        } catch {
            print("❌ Error fetching products: \(error)")
            errorMessage = "Failed to fetch products"
        }
    }
    
    // MARK: - Category Type Management
    
    func updateCategoryType(_ type: String) async {
        state.categoryType = type
        state.selectedCategory = nil
        state.selectedSubcategory = nil
        state.selectedBrand = nil
        state.selectedProduct = nil
        state.isUsingCustomCategory = false
        
        await fetchCategories()
        await fetchSubcategories()
        await fetchBrands()
    }
    
    // MARK: - Selection Management
    
    func selectCategory(_ category: Category) {
        state.selectedCategory = category
        state.selectedSubcategory = nil
        state.selectedBrand = nil
        state.selectedProduct = nil
        
        Task {
            await fetchSubcategories()
        }
    }
    
    func selectSubcategory(_ subcategory: Subcategory) {
        state.selectedSubcategory = subcategory
        state.selectedBrand = nil
        state.selectedProduct = nil
        
        Task {
            await fetchBrands()
        }
    }
    
    func selectBrand(_ brand: Brand) {
        state.selectedBrand = brand
        state.selectedProduct = nil
        
        Task {
            await fetchProducts()
        }
    }
    
    func selectProduct(_ product: ProductListItem) {
        state.selectedProduct = product
    }
    
    // MARK: - Media Management
    
    func addImage(_ image: UIImage) {
        guard state.selectedImages.count < 10 else {
            errorMessage = "Maximum 10 images allowed"
            return
        }
        state.selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index < state.selectedImages.count else { return }
        state.selectedImages.remove(at: index)
    }
    
    func addVideo(_ videoURL: URL) {
        guard state.selectedVideos.count < 5 else {
            errorMessage = "Maximum 5 videos allowed"
            return
        }
        state.selectedVideos.append(videoURL)
    }
    
    func removeVideo(at index: Int) {
        guard index < state.selectedVideos.count else { return }
        state.selectedVideos.remove(at: index)
    }
    
    // MARK: - Post Creation
    
    func createPost() async {
        guard state.isValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isCreatingPost = true
        errorMessage = nil
        
        do {
            // Upload images first
            var uploadedImageURLs: [String] = []
            for image in state.selectedImages {
                if let imageURL = try await uploadImage(image) {
                    uploadedImageURLs.append(imageURL)
                }
            }
            
            // Upload videos
            var uploadedVideoURLs: [String] = []
            for videoURL in state.selectedVideos {
                if let videoURLString = try await uploadVideo(videoURL) {
                    uploadedVideoURLs.append(videoURLString)
                }
            }
            
            // Create post request
            let request = CreatePostRequest(
                title: state.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: state.description.trimmingCharacters(in: .whitespacesAndNewlines),
                imgs: uploadedImageURLs,
                videos: uploadedVideoURLs,
                categoryType: state.categoryType.lowercased(),
                category: state.isUsingCustomCategory ? nil : state.selectedCategory?.id,
                subcategory: state.isUsingCustomCategory ? nil : state.selectedSubcategory?.id,
                brand: state.isUsingCustomCategory ? nil : state.selectedBrand?.id,
                product: state.isUsingCustomCategory ? nil : state.selectedProduct?.id,
                customCategory: state.isUsingCustomCategory ? state.customCategory : nil,
                customSubCategory: state.isUsingCustomCategory ? state.customSubCategory : nil,
                customBrand: state.isUsingCustomCategory ? state.customBrand : nil,
                customProduct: state.isUsingCustomCategory ? state.customProduct : nil,
                recommended: state.recommended,
                rating: state.rating,
                price: state.formattedPrice
            )
            
            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + APIConfig.Path.createPost) else {
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
                let response = try JSONDecoder().decode(CreatePostResponse.self, from: data)
                
                if response.success {
                    successMessage = response.message
                    clearForm()
                    
                    // Call the callback to notify parent view
                    onPostCreated?()
                } else {
                    errorMessage = "Failed to create post"
                }
            } else {
                throw NetworkError.apiError("Failed to create post: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred"
        }
        
        isCreatingPost = false
    }
    
    // MARK: - Media Upload
    
    private func uploadImage(_ image: UIImage) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NetworkError.invalidData
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "post_image_\(timestamp).jpg"
        
        print("📤 Uploading post image: \(uniqueFileName)")
        
        let uploadRequest = PostImageUploadRequest(
            fileName: uniqueFileName,
            folder: "reviews/posts/images"
        )
        
        return try await uploadMedia(uploadRequest: uploadRequest, data: imageData, contentType: "image/jpeg")
    }
    
    private func uploadVideo(_ videoURL: URL) async throws -> String? {
        let videoData = try Data(contentsOf: videoURL)
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileExtension = videoURL.pathExtension
        let uniqueFileName = "post_video_\(timestamp).\(fileExtension)"
        
        print("📤 Uploading post video: \(uniqueFileName)")
        
        let uploadRequest = PostVideoUploadRequest(
            fileName: uniqueFileName,
            folder: "reviews/posts/videos"
        )
        
        let contentType = fileExtension.lowercased() == "mp4" ? "video/mp4" : "video/\(fileExtension)"
        return try await uploadMedia(uploadRequest: uploadRequest, data: videoData, contentType: contentType)
    }
    
    private func uploadMedia<T: Codable>(uploadRequest: T, data: Data, contentType: String) async throws -> String? {
        // Create the URL request for upload URL
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Path.getUploadUrls) else {
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
            let uploadUrlResponse = try JSONDecoder().decode(PostImageUploadResponse.self, from: data)
            
            if uploadUrlResponse.status == "success" {
                print("Got signed URL for upload: \(uploadUrlResponse.data.uploadUrl)")
                
                // Upload file using NetworkManager
                try await networkManager.uploadFile(
                    url: uploadUrlResponse.data.uploadUrl,
                    data: data,
                    contentType: contentType
                )
                
                print("✅ Media uploaded successfully")
                return uploadUrlResponse.data.fileUrl
            } else {
                throw NetworkError.apiError("Upload URL request failed")
            }
        } else {
            throw NetworkError.apiError("Failed to get upload URL: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Helper Methods
    
    func clearForm() {
        state = PostCreationState()
        state.categoryType = "product"
        Task {
            await loadInitialData()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        successMessage = nil
    }
    
    // MARK: - Validation
    
    var canCreatePost: Bool {
        return state.isValid && !isCreatingPost
    }
    
    var hasSelectedMedia: Bool {
        return !state.selectedImages.isEmpty || !state.selectedVideos.isEmpty
    }
}
