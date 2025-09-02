import SwiftUI

struct LatestReviewsView: View {
    @StateObject private var viewModel = LatestReviewsViewModel()
    @State private var searchText = ""
    @State private var showingSearchBar = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search bar
                headerView
                
                // Category filter tabs
                categoryFilterView
                
                // Main content
                mainContentView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("What's on your mind?", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            viewModel.searchPosts(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchPosts(query: "")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                Button(action: {
                    // TODO: Add new post action
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.dynamicAccent)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
        }
    }
    
    // MARK: - Category Filter View
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CategoryType.allCases) { categoryType in
                    CategoryFilterButton(
                        title: categoryType.displayName,
                        isSelected: viewModel.selectedCategoryType == categoryType
                    ) {
                        Task {
                            await viewModel.updateCategoryType(categoryType)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                loadingView
            } else if viewModel.posts.isEmpty {
                emptyStateView
            } else {
                postsListView
            }
        }
    }
    
    // MARK: - Posts List View
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(post: post, viewModel: viewModel)
                        .onAppear {
                            if index == viewModel.posts.count - 1 {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentItem: post)
                                }
                            }
                        }
                }
                
                if viewModel.isLoading && !viewModel.posts.isEmpty {
                    loadingIndicator
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.refreshPosts()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading posts...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Posts Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("No posts available for the selected category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    await viewModel.refreshPosts()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.dynamicAccent)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.dynamicAccent : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    let viewModel: LatestReviewsViewModel
    @State private var isDescriptionExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with rating, price, and tag
            headerSection
            
            // Title
            Text(post.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Product metadata
            productMetadataSection
            
            // Description
            descriptionSection
            
            // Author and date
            authorSection
            
            // Images/Videos
            mediaSection
            
            // Interaction buttons
            interactionSection
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
                            // Rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= post.rating ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(index <= post.rating ? .yellow : .gray)
                    }
                    Text("(\(post.rating)/5)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            
            Spacer()
            
            // Price
            if let price = post.price {
                Text(post.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // Safal/UnSafal tag
            HStack(spacing: 4) {
                Image(post.recommended.lowercased() == "safal" ? "suf" : "unsf")
                    .font(.system(size: 10))
//                Text(post.recommended.capitalized)
//                    .font(.caption2)
//                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
           
        }
    }
    
    // MARK: - Product Metadata Section
    private var productMetadataSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category type tag
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 10))
                Text(post.categoryType.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Product details - First line
            HStack(spacing: 4) {
                Text(post.categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(post.subcategoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Product details - Second line
            HStack(spacing: 4) {
                Text(post.brandName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(post.productName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(isDescriptionExpanded ? nil : 3)
                .multilineTextAlignment(.leading)
            
            if post.description.count > 150 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isDescriptionExpanded.toggle()
                    }
                }) {
                    Text(isDescriptionExpanded ? "See less" : "See more")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.dynamicAccent)
                }
            }
        }
    }
    
    // MARK: - Author Section
    private var authorSection: some View {
        HStack(spacing: 8) {
            // Profile picture
            AsyncImage(url: URL(string: post.user.profilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            // Name and date
            VStack(alignment: .leading, spacing: 2) {
                Text(post.user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(post.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        Group {
            if post.hasImages || post.hasVideos {
                TabView {
                    ForEach(post.imgs, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .frame(height: 200)
                        .clipped()
                    }
                    
                    ForEach(post.videos, id: \.self) { videoUrl in
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                    Text("Video")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
                .frame(height: 200)
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
        }
    }
    
    // MARK: - Interaction Section
    private var interactionSection: some View {
        VStack(spacing: 8) {
            // Engagement metrics (like the image shows)
            HStack {
                Text("👍 \(post.likesCount) Likes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(post.reviews.count) comments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .background(Color(.systemGray4))
            
            // Interaction buttons (simple style like the image)
            HStack {
                // Like Button
                Button(action: {
                    Task {
                        await viewModel.likePost(post)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 16))
                        Text("Like")
                            .font(.subheadline)
                    }
                    .foregroundColor(post.isLiked ? .blue : .secondary)
                }
                
                Spacer()
                
                // Dislike Button
                Button(action: {
                    Task {
                        await viewModel.dislikePost(post)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 16))
                        Text("Dislike")
                            .font(.subheadline)
                    }
                    .foregroundColor(post.isDisliked ? .red : .secondary)
                }
                
                Spacer()
                
                // Comment Button
                Button(action: {
                    viewModel.commentOnPost(post)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                        Text("Comment")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .background(Color(.systemGray4))
        }
        .padding(.top, 8)
    }
}

#Preview {
    LatestReviewsView()
}
