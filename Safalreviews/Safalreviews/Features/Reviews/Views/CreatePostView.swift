import SwiftUI
import PhotosUI
import AVKit

struct CreatePostView: View {
    @StateObject private var viewModel = PostCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    var onPostCreated: (() -> Void)?
    
    // Edit mode properties
    var postToEdit: Post? = nil
    var isEditMode: Bool { postToEdit != nil }
    
    // Product review properties
    var productToReview: ProductReview? = nil
    var isProductReviewMode: Bool { productToReview != nil }
    
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var selectedImageItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    
    // Camera states
    @State private var showImageCamera = false
    @State private var showVideoCamera = false
    @State private var showMediaActionSheet = false
    @State private var showVideoActionSheet = false
    
    // Validation states
    @State private var titleError: String?
    @State private var descriptionError: String?
    @State private var categoryError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 32) {
//                        // User Info Section
//                        userInfoSection
                        
                        // Category Selection Section
                        categorySelectionSection
                        
                        // Title Section
                        titleSection
                        
                        // Description Section
                        descriptionSection
                        
                        // Media Section
                        mediaSection
                        
                        // Recommendation Section
                        recommendationSection
                        
                        // Rating Section
                        ratingSection
                        
                        // Price Section
                        priceSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                // Action Buttons
                actionButtonsView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $viewModel.showCustomCategoryModal) {
            AddCustomCategoryView(
                isPresented: $viewModel.showCustomCategoryModal,
                viewModel: viewModel
            )
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedImageItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedVideoItems,
            maxSelectionCount: 5,
            matching: .videos,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showImageCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.addImage(image)
            }
        }
        .sheet(isPresented: $showVideoCamera) {
            VideoPicker(sourceType: .camera) { videoURL in
                viewModel.addVideo(videoURL)
            }
        }
        .confirmationDialog("Add Photos", isPresented: $showMediaActionSheet, titleVisibility: .visible) {
            Button("Camera") {
                print("📸 Camera selected for photos")
                showImageCamera = true
            }
            Button("Photo Library") {
                print("📸 Photo Library selected")
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) { 
                print("📸 Photo selection cancelled")
            }
        } message: {
            Text("Choose how you want to add photos")
        }
        .confirmationDialog("Add Videos", isPresented: $showVideoActionSheet, titleVisibility: .visible) {
            Button("Camera") {
                print("🎥 Camera selected for videos")
                showVideoCamera = true
            }
            Button("Video Library") {
                print("🎥 Video Library selected")
                showVideoPicker = true
            }
            Button("Cancel", role: .cancel) { 
                print("🎥 Video selection cancelled")
            }
        } message: {
            Text("Choose how you want to add videos")
        }
        .onChange(of: selectedImageItems) { items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.addImage(image)
                    }
                }
                selectedImageItems = []
            }
        }
        .onChange(of: selectedVideoItems) { items in
            print("🎥 Video items changed: \(items.count) items")
            Task {
                for item in items {
                    print("🎥 Processing video item...")
                    // Try different approaches to load the video
                    if let url = try? await item.loadTransferable(type: URL.self) {
                        print("🎥 Video URL loaded: \(url)")
                        viewModel.addVideo(url)
                    } else if let data = try? await item.loadTransferable(type: Data.self) {
                        print("🎥 Video data loaded, creating temporary URL")
                        // Create a temporary file URL
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_video_\(UUID().uuidString).mp4")
                        try? data.write(to: tempURL)
                        viewModel.addVideo(tempURL)
                    } else {
                        print("🎥 Failed to load video URL or data")
                    }
                }
                selectedVideoItems = []
            }
        }
        .toast(message: $viewModel.errorMessage, type: .error)
        .toast(message: $viewModel.successMessage, type: .success)
        .onAppear {
            viewModel.onPostCreated = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                    onPostCreated?()
                }
            }
            
            // Populate form if in edit mode
            if isEditMode, let post = postToEdit {
                viewModel.populateForEditing(post: post)
            }
            
            // Auto-populate category if in product review mode
            if isProductReviewMode, let product = productToReview {
                Task {
                    await viewModel.populateForProductReview(product: product)
                }
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private func validateTitle() {
        let trimmedTitle = viewModel.state.title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            titleError = "Title is required"
        } else if trimmedTitle.count < 5 {
            titleError = "Title must be at least 5 characters"
        } else if trimmedTitle.count > 100 {
            titleError = "Title must be less than 100 characters"
        } else {
            titleError = nil
        }
    }
    
    private func validateDescription() {
        let trimmedDescription = viewModel.state.description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedDescription.isEmpty {
            descriptionError = "Description is required"
        } else if trimmedDescription.count < 10 {
            descriptionError = "Description must be at least 10 characters"
        } else if trimmedDescription.count > 2000 {
            descriptionError = "Description must be less than 2000 characters"
        } else {
            descriptionError = nil
        }
    }
    
    private func validateCategory() {
        if !viewModel.state.isUsingCustomCategory && viewModel.state.selectedCategory == nil {
            categoryError = "Please select a category"
        } else if viewModel.state.isUsingCustomCategory && viewModel.state.customCategory.isEmpty {
            categoryError = "Please enter a custom category"
        } else {
            categoryError = nil
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            Text(isEditMode ? "Edit Post" : (isProductReviewMode ? "Write Review" : "Create Post"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: "https://via.placeholder.com/40")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.dynamicAccent.opacity(0.2))
                    .overlay(
                        Text("AA")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.dynamicAccent)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            Text("Andy02")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Category Selection Section
    
    private var categorySelectionSection: some View {
        VStack(spacing: 20) {
            // Category Type Dropdown
            categoryTypeDropdown
            
            if !viewModel.state.isUsingCustomCategory {
                // Dynamic Category Dropdowns
                categoryDropdowns
            } else {
                // Custom Category Display
                customCategoryDisplay
            }
            
            // Add Custom Button
            addCustomButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var categoryTypeDropdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("*")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            Menu {
                Button(action: {
                    Task {
                        await viewModel.updateCategoryType("Product")
                    }
                }) {
                    HStack {
                        Image(systemName: "cube.box.fill")
                        Text("Product")
                        if viewModel.state.categoryType == "Product" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.updateCategoryType("Person")
                    }
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Person")
                        if viewModel.state.categoryType == "Person" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.updateCategoryType("Place")
                    }
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Place")
                        if viewModel.state.categoryType == "Place" {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: categoryTypeIcon)
                        .foregroundColor(.dynamicAccent)
                        .font(.system(size: 18))
                    
                    Text(viewModel.state.categoryType.capitalized)
                        .foregroundColor(.primary)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .rotationEffect(.degrees(0))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.state.categoryType)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dynamicAccent, lineWidth: 1.5)
                        )
                )
            }
        }
    }
    
    private var categoryTypeIcon: String {
        switch viewModel.state.categoryType {
        case "Product":
            return "cube.box.fill"
        case "Person":
            return "person.fill"
        case "Place":
            return "location.fill"
        default:
            return "tag.fill"
        }
    }
    
    private var categoryDropdowns: some View {
        VStack(spacing: 12) {
            // Category Dropdown
            CategoryDropdown(
                title: "Category",
                items: viewModel.categories,
                selectedItem: viewModel.state.selectedCategory,
                onSelect: { category in
                    viewModel.selectCategory(category)
                }
            )
            
            // Subcategory Dropdown
            if viewModel.state.selectedCategory != nil {
                CategoryDropdown(
                    title: "Subcategory",
                    items: viewModel.subcategories,
                    selectedItem: viewModel.state.selectedSubcategory,
                    onSelect: { subcategory in
                        viewModel.selectSubcategory(subcategory)
                    }
                )
            }
            
            // Brand Dropdown
            if viewModel.state.selectedSubcategory != nil {
                CategoryDropdown(
                    title: "Brand",
                    items: viewModel.brands,
                    selectedItem: viewModel.state.selectedBrand,
                    onSelect: { brand in
                        viewModel.selectBrand(brand)
                    }
                )
            }
            
            // Product Dropdown
            if viewModel.state.selectedBrand != nil {
                ProductDropdown(
                    title: "Product",
                    items: viewModel.products,
                    selectedItem: viewModel.state.selectedProduct,
                    onSelect: { product in
                        viewModel.selectProduct(product)
                    }
                )
            }
        }
    }
    
    private var customCategoryDisplay: some View {
        VStack(spacing: 12) {
            CustomCategoryRow(title: "Category", value: viewModel.state.customCategory)
            CustomCategoryRow(title: "Subcategory", value: viewModel.state.customSubCategory)
            CustomCategoryRow(title: "Brand", value: viewModel.state.customBrand)
            CustomCategoryRow(title: "Product", value: viewModel.state.customProduct)
        }
    }
    
    private var addCustomButton: some View {
        Button(action: {
            viewModel.showCustomCategoryModal = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.dynamicAccent)
                    .font(.system(size: 18))
                Text("Add Custom Category")
                    .fontWeight(.semibold)
                    .foregroundColor(.dynamicAccent)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dynamicAccent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dynamicAccent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Post Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("*")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter a compelling title for your post", text: $viewModel.state.title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        titleError != nil ? Color.red : 
                                        viewModel.state.title.isEmpty ? Color(.systemGray4) : Color.dynamicAccent,
                                        lineWidth: titleError != nil ? 2 : 1
                                    )
                            )
                    )
                    .font(.body)
                    .onChange(of: viewModel.state.title) { _ in
                        validateTitle()
                    }
                
                if let error = titleError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("*")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.state.description)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            descriptionError != nil ? Color.red : 
                                            viewModel.state.description.isEmpty ? Color(.systemGray4) : Color.dynamicAccent,
                                            lineWidth: descriptionError != nil ? 2 : 1
                                        )
                                )
                        )
                        .frame(minHeight: 120)
                        .onChange(of: viewModel.state.description) { _ in
                            validateDescription()
                        }
                    
                    if viewModel.state.description.isEmpty {
                        Text("Share your thoughts and experiences...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                
                if let error = descriptionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(viewModel.state.description.count)/2000")
                        .font(.caption)
                        .foregroundColor(viewModel.state.description.count > 1800 ? .red : .secondary)
                }
            }
        }
    }
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Media (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Media Buttons
            HStack(spacing: 16) {
                Button(action: {
                    print("📸 Photo button tapped - showing action sheet")
                    showMediaActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                        Text("Add Photos")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }
                
                Button(action: {
                    print("🎥 Video button tapped - showing action sheet")
                    showVideoActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                        Text("Add Videos")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
                }
            }
            
            // Selected Media Preview
            if viewModel.hasSelectedMedia {
                selectedMediaPreview
            }
        }
    }
    
    private var selectedMediaPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Selected Media")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.state.selectedImages.count + viewModel.state.selectedVideos.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Images
                    ForEach(Array(viewModel.state.selectedImages.enumerated()), id: \.offset) { index, image in
                        MediaPreviewItem(
                            image: image,
                            videoURL: nil,
                            type: .image,
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.removeImage(at: index)
                                }
                            }
                        )
                    }
                    
                    // Videos
                    ForEach(Array(viewModel.state.selectedVideos.enumerated()), id: \.offset) { index, videoURL in
                        MediaPreviewItem(
                            image: nil,
                            videoURL: videoURL,
                            type: .video,
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.removeVideo(at: index)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Recommendation Section
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommendation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("*")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                ForEach(RecommendationType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.state.recommended = type.rawValue
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(type.iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                            
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.state.recommended == type.rawValue ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    viewModel.state.recommended == type.rawValue ?
                                    type.color : Color(.systemBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            viewModel.state.recommended == type.rawValue ?
                                            type.color : Color(.systemGray4),
                                            lineWidth: viewModel.state.recommended == type.rawValue ? 2 : 1
                                        )
                                )
                        )
                        .scaleEffect(viewModel.state.recommended == type.rawValue ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.state.recommended)
                    }
                }
            }
        }
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rating")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("*")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(viewModel.state.rating)/5")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dynamicAccent)
            }
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.state.rating = index
                        }
                    }) {
                        Image(systemName: index <= viewModel.state.rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(index <= viewModel.state.rating ? .yellow : .gray)
                            .scaleEffect(index <= viewModel.state.rating ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.state.rating)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Price (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Text("$")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.dynamicAccent)
                    .padding(.leading, 4)
                
                TextField("0.00", text: $viewModel.state.price)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                viewModel.state.price.isEmpty ? Color(.systemGray4) : Color.dynamicAccent,
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Create/Update Post Button
            Button(action: {
                Task {
                    if isEditMode, let post = postToEdit {
                        await viewModel.editPost(postId: post.id)
                    } else {
                        await viewModel.createPost()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isCreatingPost {
                        ProgressView()
                            .scaleEffect(0.9)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    
                    Text(viewModel.isCreatingPost ? 
                         (isEditMode ? "Updating Post..." : (isProductReviewMode ? "Publishing Review..." : "Creating Post...")) : 
                         (isEditMode ? "Update Post" : (isProductReviewMode ? "Publish Review" : "Create Post")))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.canCreatePost ? Color.dynamicAccent : Color(.systemGray4))
                        .shadow(
                            color: viewModel.canCreatePost ? Color.dynamicAccent.opacity(0.3) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(viewModel.canCreatePost ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: viewModel.canCreatePost)
            }
            .disabled(!viewModel.canCreatePost)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Supporting Views

struct CategoryDropdown<T: Identifiable & Codable & Hashable>: View {
    let title: String
    let items: [T]
    let selectedItem: T?
    let onSelect: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if title == "Category" {
                    Text("*")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            Menu {
                ForEach(items, id: \.id) { item in
                    Button(action: {
                        onSelect(item)
                    }) {
                        HStack {
                            Text(itemName(item))
                                .font(.body)
                            if selectedItem?.id == item.id {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.dynamicAccent)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: dropdownIcon)
                        .foregroundColor(.dynamicAccent)
                        .font(.system(size: 16))
                    
                    Text(selectedItem != nil ? itemName(selectedItem!) : "Select \(title)")
                        .foregroundColor(selectedItem != nil ? .primary : .secondary)
                        .font(.body)
                        .fontWeight(selectedItem != nil ? .medium : .regular)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .rotationEffect(.degrees(0))
                        .animation(.easeInOut(duration: 0.2), value: selectedItem?.id)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedItem != nil ? Color.dynamicAccent : Color(.systemGray4),
                                    lineWidth: selectedItem != nil ? 1.5 : 1
                                )
                        )
                )
            }
        }
    }
    
    private var dropdownIcon: String {
        switch title {
        case "Category":
            return "folder.fill"
        case "Subcategory":
            return "folder.badge.plus"
        case "Brand":
            return "tag.fill"
        default:
            return "list.bullet"
        }
    }
    
    private func itemName(_ item: T) -> String {
        if let category = item as? Category {
            return category.name
        } else if let subcategory = item as? Subcategory {
            return subcategory.name
        } else if let brand = item as? Brand {
            return brand.name
        }
        return "Unknown"
    }
}

struct ProductDropdown: View {
    let title: String
    let items: [ProductListItem]
    let selectedItem: ProductListItem?
    let onSelect: (ProductListItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Menu {
                ForEach(items, id: \.id) { item in
                    Button(action: {
                        onSelect(item)
                    }) {
                        HStack {
                            Text(item.name)
                                .font(.body)
                            if selectedItem?.id == item.id {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.dynamicAccent)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "cube.fill")
                        .foregroundColor(.dynamicAccent)
                        .font(.system(size: 16))
                    
                    Text(selectedItem?.name ?? "Select \(title)")
                        .foregroundColor(selectedItem != nil ? .primary : .secondary)
                        .font(.body)
                        .fontWeight(selectedItem != nil ? .medium : .regular)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .rotationEffect(.degrees(0))
                        .animation(.easeInOut(duration: 0.2), value: selectedItem?.id)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedItem != nil ? Color.dynamicAccent : Color(.systemGray4),
                                    lineWidth: selectedItem != nil ? 1.5 : 1
                                )
                        )
                )
            }
        }
    }
}

struct CustomCategoryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dynamicAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
}

struct MediaPreviewItem: View {
    let image: UIImage?
    let videoURL: URL?
    let type: MediaType
    let onRemove: () -> Void
    
    @State private var videoThumbnail: UIImage?
    
    enum MediaType {
        case image, video
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if type == .image, let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if type == .video, let videoURL = videoURL {
                    if let thumbnail = videoThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                // Play button overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.black.opacity(0.6))
                                                    .frame(width: 32, height: 32)
                                            )
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            )
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Video")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 24, height: 24)
                    )
            }
            .offset(x: 8, y: -8)
        }
        .onAppear {
            if type == .video, let videoURL = videoURL, videoThumbnail == nil {
                generateVideoThumbnail(from: videoURL)
            }
        }
    }
    
    private func generateVideoThumbnail(from url: URL) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 200, height: 200)
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        Task {
            do {
                let cgImage = try await imageGenerator.image(at: time).image
                await MainActor.run {
                    self.videoThumbnail = UIImage(cgImage: cgImage)
                }
            } catch {
                print("Error generating video thumbnail: \(error)")
            }
        }
    }
}

// MARK: - Camera Components

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onVideoPicked: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 300 // 5 minutes max
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoPicked(videoURL)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CreatePostView()
}
