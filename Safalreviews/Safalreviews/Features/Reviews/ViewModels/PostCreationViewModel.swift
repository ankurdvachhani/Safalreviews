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
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "categoryType", value: state.categoryType)
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
          //  errorMessage = "Failed to fetch subcategories"
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
          //  errorMessage = "Failed to fetch brands"
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
          //  errorMessage = "Failed to fetch products"
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
        print("🎥 Adding video to viewModel: \(videoURL)")
        guard state.selectedVideos.count < 5 else {
            errorMessage = "Maximum 5 videos allowed"
            return
        }
        state.selectedVideos.append(videoURL)
        print("🎥 Video added successfully. Total videos: \(state.selectedVideos.count)")
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
            var categoryType = ""
            if state.categoryType.lowercased().contains("people"){
                categoryType = "person"
            }else{
                categoryType = state.categoryType.lowercased()
            }
            //people
            let request = CreatePostRequest(
                title: state.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: state.description.trimmingCharacters(in: .whitespacesAndNewlines),
                imgs: uploadedImageURLs,
                videos: uploadedVideoURLs,
                categoryType: categoryType,
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
    
    // MARK: - Post Editing
    
    func populateForEditing(post: Post) async {
        // Clear existing data
        clearForm()
        
        // Populate with post data
        state.title = post.title
        state.description = post.description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        state.categoryType = post.categoryType.capitalized
        state.recommended = post.recommended
        state.rating = post.rating
        state.price = post.price?.description ?? ""
        
        // Set category selections if available
        if let category = post.category {
            // Create a Category with required fields
            let categoryData = """
            {
                "_id": "\(category.id)",
                "name": "\(category.name)",
                "slug": "\(category.slug)",
                "isActive": true,
                "categoryType": "\(post.categoryType.lowercased())",
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2024-01-01T00:00:00.000Z"
            }
            """.data(using: .utf8)!
            
            if let decodedCategory = try? JSONDecoder().decode(Category.self, from: categoryData) {
                state.selectedCategory = decodedCategory
            }
        }
        
        if let subcategory = post.subcategory {
            // Create a Subcategory with required fields
            let subcategoryData = """
            {
                "_id": "\(subcategory.id)",
                "name": "\(subcategory.name)",
                "slug": "\(subcategory.slug)",
                "category": {
                    "_id": "\(post.category?.id ?? "")",
                    "name": "\(post.category?.name ?? "")",
                    "slug": "\(post.category?.slug ?? "")"
                },
                "isActive": true,
                "categoryType": "\(post.categoryType.lowercased())",
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2024-01-01T00:00:00.000Z"
            }
            """.data(using: .utf8)!
            
            if let decodedSubcategory = try? JSONDecoder().decode(Subcategory.self, from: subcategoryData) {
                state.selectedSubcategory = decodedSubcategory
            }
        }
        
        if let brand = post.brand {
            // Create a Brand with required fields
            let brandData = """
            {
                "_id": "\(brand.id)",
                "name": "\(brand.name)",
                "slug": "\(brand.slug)",
                "subCategory": {
                    "_id": "\(post.subcategory?.id ?? "")",
                    "name": "\(post.subcategory?.name ?? "")",
                    "slug": "\(post.subcategory?.slug ?? "")",
                    "category": {
                        "_id": "\(post.category?.id ?? "")",
                        "name": "\(post.category?.name ?? "")",
                        "slug": "\(post.category?.slug ?? "")"
                    }
                },
                "isActive": true,
                "categoryType": "\(post.categoryType.lowercased())",
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2024-01-01T00:00:00.000Z"
            }
            """.data(using: .utf8)!
            
            if let decodedBrand = try? JSONDecoder().decode(Brand.self, from: brandData) {
                state.selectedBrand = decodedBrand
            }
        }
        
        if let product = post.product {
            // Create a ProductListItem with required fields
            let productData = """
            {
                "_id": "\(product.id)",
                "name": "\(product.name)",
                "description": "",
                "media": [],
                "category": "\(post.category?.id ?? "")",
                "subCategory": "\(post.subcategory?.id ?? "")",
                "specifications": {},
                "isActive": true,
                "slug": "\(product.slug)",
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2024-01-01T00:00:00.000Z",
                "categoryType": "\(post.categoryType.lowercased())",
                "brand": {
                    "_id": "\(post.brand?.id ?? "")",
                    "name": "\(post.brand?.name ?? "")",
                    "slug": "\(post.brand?.slug ?? "")",
                    "subCategory": {
                        "_id": "\(post.subcategory?.id ?? "")",
                        "name": "\(post.subcategory?.name ?? "")",
                        "slug": "\(post.subcategory?.slug ?? "")",
                        "category": {
                            "_id": "\(post.category?.id ?? "")",
                            "name": "\(post.category?.name ?? "")",
                            "slug": "\(post.category?.slug ?? "")"
                        }
                    }
                },
                "averageRating": 0.0,
                "totalRatings": 0,
                "ratings": [],
                "mediaSignedUrls": []
            }
            """.data(using: .utf8)!
            
            if let decodedProduct = try? JSONDecoder().decode(ProductListItem.self, from: productData) {
                state.selectedProduct = decodedProduct
            }
        }
        
        // Check if using custom categories
        if let customCategory = post.customCategory, !customCategory.isEmpty {
            state.isUsingCustomCategory = true
            state.customCategory = customCategory
            state.customSubCategory = post.customSubCategory ?? ""
            state.customBrand = post.customBrand ?? ""
            state.customProduct = post.customProduct ?? ""
        }
        
        // Load existing media (images and videos)
        await loadExistingMedia(from: post)
    }
    
    // MARK: - Media Loading for Editing
    
    private func loadExistingMedia(from post: Post) async {
        // Clear existing media first
        state.selectedImages = []
        state.selectedVideos = []
        
        // Load images
        for imageURL in post.imgs {
            if let image = await downloadImage(from: imageURL) {
                await MainActor.run {
                    state.selectedImages.append(image)
                }
            }
        }
        
        // Load videos
        for videoURLString in post.videos {
            if let videoURL = URL(string: videoURLString) {
                await MainActor.run {
                    state.selectedVideos.append(videoURL)
                }
            }
        }
    }
    
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error downloading image from \(urlString): \(error)")
            return nil
        }
    }
    
    func populateForProductReview(product: ProductReview) async {
        // Clear existing data
        clearForm()
        
        // Set category type from product
        state.categoryType = product.categoryType.capitalized
        
        print("🔍 Populating for product review:")
        print("   Product: \(product.name)")
        print("   Category ID: \(product.category ?? "nil")")
        print("   SubCategory ID: \(product.subCategory ?? "nil")")
        print("   Brand: \(product.brand.name)")
        print("   Brand ID: \(product.brand.id)")
        
        // Set a default title based on product name
        state.title = "Review: \(product.name)"
        
        // Set default rating to 5 (user can change)
        state.rating = 5
        
        // Set default recommendation to "safal" (user can change)
        state.recommended = "safal"
        
        // Step 1: Fetch categories if not already loaded
        if categories.isEmpty {
            print("📡 Fetching categories...")
            await fetchCategories()
        }
        print("   Available categories: \(categories.map { "\($0.name) (\($0.id))" })")
        
        // Step 2: Find and select category by ID
        if let categoryId = product.category,
           let matchingCategory = categories.first(where: { $0.id == categoryId }) {
            state.selectedCategory = matchingCategory
            print("✅ Found matching category: \(matchingCategory.name) (\(matchingCategory.id))")
            
            // Step 3: Fetch subcategories for this category
            print("📡 Fetching subcategories for category: \(matchingCategory.id)")
            await fetchSubcategories()
            print("   Available subcategories: \(subcategories.map { "\($0.name) (\($0.id))" })")
            
            // Step 4: Find and select subcategory by ID
            if let subCategoryId = product.subCategory,
               let matchingSubcategory = subcategories.first(where: { $0.id == subCategoryId }) {
                state.selectedSubcategory = matchingSubcategory
                print("✅ Found matching subcategory: \(matchingSubcategory.name) (\(matchingSubcategory.id))")
                
                // Step 5: Fetch brands for this subcategory
                print("📡 Fetching brands for subcategory: \(matchingSubcategory.id)")
                await fetchBrands()
                print("   Available brands: \(brands.map { "\($0.name) (\($0.id))" })")
                
                // Step 6: Find and select brand by ID
                if let matchingBrand = brands.first(where: { $0.id == product.brand.id }) {
                    state.selectedBrand = matchingBrand
                    print("✅ Found matching brand: \(matchingBrand.name) (\(matchingBrand.id))")
                    
                    // Step 7: Fetch products for this brand
                    print("📡 Fetching products for brand: \(matchingBrand.id)")
                    await fetchProducts()
                    print("   Available products: \(products.map { "\($0.name) (\($0.id))" })")
                    
                    // Step 8: Find and select product by ID
                    if let matchingProduct = products.first(where: { $0.id == product.id }) {
                        state.selectedProduct = matchingProduct
                        print("✅ Found matching product: \(matchingProduct.name) (\(matchingProduct.id))")
                    } else {
                        print("⚠️ No matching product found for ID: \(product.id)")
                    }
                } else {
                    print("⚠️ No matching brand found for ID: \(product.brand.id)")
                }
            } else {
                print("⚠️ No matching subcategory found for ID: \(product.subCategory ?? "nil")")
            }
        } else {
            print("⚠️ No matching category found for ID: \(product.category ?? "nil")")
        }
        
        // If no matching categories found, use custom category approach
        if state.selectedCategory == nil {
            print("🔄 Using custom category approach")
            state.isUsingCustomCategory = true
            
            // Extract names from the nested brand structure
            let categoryName = product.brand.subCategory.category.name
            let subCategoryName = product.brand.subCategory.name
            let brandName = product.brand.name
            
            state.customCategory = categoryName
            state.customSubCategory = subCategoryName
            state.customBrand = brandName
            state.customProduct = product.name
            
            print("📝 Custom category values:")
            print("   Category: \(categoryName)")
            print("   SubCategory: \(subCategoryName)")
            print("   Brand: \(brandName)")
            print("   Product: \(product.name)")
        }
        
        print("🎯 Final state:")
        print("   Selected Category: \(state.selectedCategory?.name ?? "nil")")
        print("   Selected Subcategory: \(state.selectedSubcategory?.name ?? "nil")")
        print("   Selected Brand: \(state.selectedBrand?.name ?? "nil")")
        print("   Selected Product: \(state.selectedProduct?.name ?? "nil")")
        print("   Using Custom Category: \(state.isUsingCustomCategory)")
    }
    
    func editPost(postId: String) async {
        guard state.isValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isCreatingPost = true
        errorMessage = nil
        
        do {
            // Upload new images first
            var uploadedImageURLs: [String] = []
            for image in state.selectedImages {
                if let imageURL = try await uploadImage(image) {
                    uploadedImageURLs.append(imageURL)
                }
            }
            
            // Upload new videos
            var uploadedVideoURLs: [String] = []
            for videoURL in state.selectedVideos {
                if let videoURLString = try await uploadVideo(videoURL) {
                    uploadedVideoURLs.append(videoURLString)
                }
            }
            
            var categoryType = ""
            if state.categoryType.lowercased().contains("people"){
                categoryType = "person"
            }else{
                categoryType = state.categoryType.lowercased()
            }
            
            // Create edit post request
            let request = EditPostRequest(
                title: state.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: state.description.trimmingCharacters(in: .whitespacesAndNewlines),
                categoryType: categoryType,
                category: state.isUsingCustomCategory ? nil : state.selectedCategory?.id,
                subcategory: state.isUsingCustomCategory ? nil : state.selectedSubcategory?.id,
                brand: state.isUsingCustomCategory ? nil : state.selectedBrand?.id,
                product: state.isUsingCustomCategory ? nil : state.selectedProduct?.id,
                customCategory: state.isUsingCustomCategory ? state.customCategory : "",
                customSubCategory: state.isUsingCustomCategory ? state.customSubCategory : "",
                customBrand: state.isUsingCustomCategory ? state.customBrand : "",
                customProduct: state.isUsingCustomCategory ? state.customProduct : "",
                recommended: state.recommended,
                rating: state.rating,
                imgs: uploadedImageURLs,
                videos: uploadedVideoURLs
            )
            
            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + "/api/post/\(postId)") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
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
                let response = try JSONDecoder().decode(EditPostResponse.self, from: data)
                
                if response.success {
                    successMessage = response.message ?? "Post updated successfully!"
                    
                    // Call the callback to notify parent view
                    onPostCreated?()
                } else {
                    errorMessage = "Failed to update post"
                }
            } else {
                throw NetworkError.apiError("Failed to update post: \(httpResponse.statusCode)")
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

    
    
    private func uploadImage(_ image: UIImage) async throws -> String? {
        // Usage:
        let smallImage = resizedImage(image)
        guard let imageData = smallImage.jpegData(compressionQuality: 0.2) else {
            throw NetworkError.invalidData
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "post_image_\(timestamp).jpg"
        
        print("📤 Uploading post image: \(uniqueFileName)")
        
        let uploadRequest = PostImageUploadRequest(
            fileName: uniqueFileName,
            folder: "reviews/posts/images"
        )
        
        return try await uploadMedia(uploadRequest: uploadRequest, filedata: imageData, contentType: "image/jpeg")
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
        return try await uploadMedia(uploadRequest: uploadRequest, filedata: videoData, contentType: contentType)
    }
    
    private func uploadMedia<T: Codable>(uploadRequest: T, filedata: Data, contentType: String) async throws -> String? {
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
            
            print("Got signed URL for upload: \(uploadUrlResponse.data.uploadUrl)")
            
            // Upload file using NetworkManager
            try await networkManager.uploadFile(
                url: uploadUrlResponse.data.uploadUrl,
                data: filedata,
                contentType: contentType
            )
            
            print("✅ Media uploaded successfully")
            return uploadUrlResponse.data.fileUrl
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
        let hasImages = !state.selectedImages.isEmpty
        let hasVideos = !state.selectedVideos.isEmpty
        print("🎥 hasSelectedMedia check - Images: \(hasImages), Videos: \(hasVideos), Total: \(hasImages || hasVideos)")
        return hasImages || hasVideos
    }
}
