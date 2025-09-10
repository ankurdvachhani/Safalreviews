import SwiftUI

struct LatestReviewsView: View {
    @StateObject private var viewModel = LatestReviewsViewModel()
    @State private var searchText = ""
    @State private var showingSearchBar = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isHeaderVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var selectedMediaIndex = 0
    @State private var selectedMediaURLs: [String] = []
    @State private var showingFullScreenMedia: MediaPresentationData?
    @State private var selectedPostForComments: Post?
    @State private var showingCreatePost = false
    @State private var showingDeleteAlert = false
    @State private var postToDelete: Post?
    @State private var postToEdit: Post?
    
    // Configuration properties
    var isMyPosts: Bool = false
    var userId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search bar
                if isHeaderVisible {
                    headerView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Category filter tabs
                if isHeaderVisible {
                    categoryFilterView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main content
                mainContentView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .animation(.easeInOut(duration: 0.3), value: isHeaderVisible)
        }
        .toast(message: $viewModel.errorMessage, type: .error)
        .toast(message: $viewModel.successMessage, type: .success)
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(item: $showingFullScreenMedia) { mediaData in
            FullScreenMediaView(
                mediaURLs: mediaData.mediaURLs,
                initialIndex: mediaData.initialIndex,
                isPresented: $showingFullScreenMedia
            )
        }
        .sheet(item: $selectedPostForComments) { post in
            CommentSheet(
                post: post,
                onCommentAdded: {
                    // Update the comment count for the selected post
                    if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                        viewModel.posts[index].reviews.append(Review.mockReview)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(onPostCreated: {
                // Refresh the posts when a new post is created
                Task {
                    await viewModel.refreshPosts()
                }
            })
        }
        .sheet(item: $postToEdit) { post in
            CreatePostView(
                onPostCreated: {
                    Task {
                        await viewModel.refreshPosts()
                    }
                },
                postToEdit: post
            )
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    Task {
                        await viewModel.deletePost(post)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .onAppear {
            // Configure view model based on parameters
            if isMyPosts, let userId = userId {
                viewModel.configureForMyPosts(userId: userId)
            } else {
                viewModel.configureForAllPosts()
            }
        }
    }
    
    // MARK: - Scroll Handling
    private func handleScrollOffset(_ offset: CGFloat) {
        let scrollDelta = offset - lastScrollOffset
        lastScrollOffset = offset
        
        let threshold: CGFloat = 15
        
        if scrollDelta < -threshold && isHeaderVisible {
            // Scrolling down → hide header
            withAnimation(.easeInOut(duration: 0.3)) {
               // isHeaderVisible = false
            }
        } else if scrollDelta > threshold && !isHeaderVisible {
            // Scrolling up → show header
            withAnimation(.easeInOut(duration: 0.3)) {
             //  isHeaderVisible = true
            }
        }
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
                    
                    TextField(isMyPosts ? "Search my posts..." : "What's on your mind?", text: $searchText)
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
                    showingCreatePost = true
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
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(
                        post: post, 
                        viewModel: viewModel,
                        isMyPosts: isMyPosts,
                        onMediaTap: { mediaURLs, selectedIndex in
                            showingFullScreenMedia = MediaPresentationData(
                                mediaURLs: mediaURLs,
                                initialIndex: selectedIndex
                            )
                        },
                        onCommentTap: { post in
                            selectedPostForComments = post
                        },
                        onEditTap: { post in
                            postToEdit = post
                        },
                        onDeleteTap: { post in
                            postToDelete = post
                            showingDeleteAlert = true
                        }
                    )
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
            .background(
                GeometryReader { geometry in
                    let offset = geometry.frame(in: .global).minY
                    Color.clear
                        .onAppear {
                            scrollOffset = offset
                        }
                        .onChange(of: offset) { newOffset in
                            scrollOffset = newOffset
                            handleScrollOffset(newOffset)
                        }
                }
            )
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
            Image(systemName: isMyPosts ? "person.circle" : "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(isMyPosts ? "No Posts Yet" : "No Posts Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(isMyPosts ? "You haven't created any posts yet. Start sharing your reviews!" : "No posts available for the selected category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isMyPosts {
                Button {
                    showingCreatePost = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Your First Post")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.dynamicAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            } else {
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
    let isMyPosts: Bool
    let onMediaTap: ([String], Int) -> Void
    let onCommentTap: (Post) -> Void
    let onEditTap: (Post) -> Void
    let onDeleteTap: (Post) -> Void
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
            
            // Edit/Delete buttons for My Posts
            if isMyPosts {
                myPostsActionSection
            }
            
            // Images/Videos
            mediaSection
            
            // Interaction buttons
            interactionSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
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
    
    // MARK: - My Posts Action Section
    private var myPostsActionSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                onEditTap(post)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Button(action: {
                onDeleteTap(post)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("Delete")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        Group {
            if post.hasImages || post.hasVideos {
                TabView {
                    ForEach(Array(post.imgs.enumerated()), id: \.element) { index, imageUrl in
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
                        .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
                        .clipped()
                        .onTapGesture {
                            let allMedia = post.imgs + post.videos
                            onMediaTap(allMedia, index)
                        }
                    }
                    
                    ForEach(Array(post.videos.enumerated()), id: \.element) { index, videoUrl in
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
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
                            .onTapGesture {
                                let allMedia = post.imgs + post.videos
                                let videoIndex = post.imgs.count + index
                                onMediaTap(allMedia, videoIndex)
                            }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .padding(.horizontal, -16) // Extend to full width
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
                    onCommentTap(post)
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

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Full Screen Media View
struct FullScreenMediaView: View {
    let mediaURLs: [String]
    let initialIndex: Int
    @Binding var isPresented: MediaPresentationData?
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(mediaURLs: [String], initialIndex: Int, isPresented: Binding<MediaPresentationData?>) {
        self.mediaURLs = mediaURLs
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button and counter
                HStack {
                    Button(action: {
                        isPresented = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) of \(mediaURLs.count)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding()
                
                // Media content - centered
                Spacer()
                
                TabView(selection: $currentIndex) {
                    ForEach(Array(mediaURLs.enumerated()), id: \.element) { index, url in
                        ZoomableImageView(imageURL: url)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentIndex) { _ in
                    // Reset zoom when changing images
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
                
                Spacer()
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    if scale <= 1 {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if scale > 1 {
                                scale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
                    .scaleEffect(1.5)
                    .foregroundColor(.white)
            }
        }
        .background(Color.black)
    }
}
