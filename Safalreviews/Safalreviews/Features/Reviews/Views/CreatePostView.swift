import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = PostCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    var onPostCreated: (() -> Void)?
    
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var selectedImageItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
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
            matching: .videos
        )
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
            Task {
                for item in items {
                    if let url = try? await item.loadTransferable(type: URL.self) {
                        viewModel.addVideo(url)
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
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Create Post")
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
        .background(Color(.systemBackground))
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
        VStack(spacing: 16) {
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
    }
    
    private var categoryTypeDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category Type")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Menu {
                Button("Product") {
                    Task {
                        await viewModel.updateCategoryType("Product")
                    }
                }
                Button("Person") {
                    Task {
                        await viewModel.updateCategoryType("Person")
                    }
                }
                Button("Place") {
                    Task {
                        await viewModel.updateCategoryType("Place")
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 16))
                    
                    Text(viewModel.state.categoryType.capitalized)
                        .foregroundColor(.primary)
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.dynamicAccent)
                Text("Add Custom")
                    .fontWeight(.medium)
                    .foregroundColor(.dynamicAccent)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.dynamicAccent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a title for your post...*")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField("Enter post title", text: $viewModel.state.title)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.body)
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's on your mind? *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.state.description)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 120)
                
                if viewModel.state.description.isEmpty {
                    Text("Share your thoughts...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.state.description.count)/2000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Media Buttons
            HStack(spacing: 16) {
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.green)
                        Text("Photo")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    showVideoPicker = true
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundColor(.red)
                        Text("Video")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Selected Media Preview
            if viewModel.hasSelectedMedia {
                selectedMediaPreview
            }
        }
    }
    
    private var selectedMediaPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Media")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Images
                    ForEach(Array(viewModel.state.selectedImages.enumerated()), id: \.offset) { index, image in
                        MediaPreviewItem(
                            image: image,
                            videoURL: nil,
                            type: .image,
                            onRemove: {
                                viewModel.removeImage(at: index)
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
                                viewModel.removeVideo(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Recommendation Section
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 24) {
                ForEach(RecommendationType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.state.recommended = type.rawValue
                    }) {
                        VStack(spacing: 8) {
                            Image(type.iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            
                            Text(type.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            viewModel.state.recommended == type.rawValue ?
                            type.color.opacity(0.2) : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: {
                        viewModel.state.rating = index
                    }) {
                        Image(systemName: index <= viewModel.state.rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(index <= viewModel.state.rating ? .yellow : .gray)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add price (in $)...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                Text("$")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $viewModel.state.price)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Create Post Button
            Button(action: {
                Task {
                    await viewModel.createPost()
                }
            }) {
                HStack {
                    if viewModel.isCreatingPost {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                    }
                    
                    Text(viewModel.isCreatingPost ? "Creating..." : "Create Post")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canCreatePost ? Color.dynamicAccent : Color(.systemGray4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canCreatePost)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views

struct CategoryDropdown<T: Identifiable & Codable & Hashable>: View {
    let title: String
    let items: [T]
    let selectedItem: T?
    let onSelect: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Menu {
                ForEach(items, id: \.id) { item in
                    Button(action: {
                        onSelect(item)
                    }) {
                        HStack {
                            Text(itemName(item))
                            if selectedItem?.id == item.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedItem != nil ? itemName(selectedItem!) : "Select \(title)")
                        .foregroundColor(selectedItem != nil ? .primary : .secondary)
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Menu {
                ForEach(items, id: \.id) { item in
                    Button(action: {
                        onSelect(item)
                    }) {
                        HStack {
                            Text(item.name)
                            if selectedItem?.id == item.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedItem?.name ?? "Select \(title)")
                        .foregroundColor(selectedItem != nil ? .primary : .secondary)
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MediaPreviewItem: View {
    let image: UIImage?
    let videoURL: URL?
    let type: MediaType
    let onRemove: () -> Void
    
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
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                Text("Video")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

#Preview {
    CreatePostView()
}
