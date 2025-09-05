import SwiftUI

struct ProductDetailView: View {
    let product: ProductReview
    @StateObject private var viewModel = ProductDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingWriteReview = false
    @State private var currentImageIndex = 0
    @State private var timer: Timer?
    @State private var showingCommentSheet = false
    @State private var selectedReviewForComments: ReviewPost?
    
    var body: some View {
            ZStack {
                if viewModel.isLoading && viewModel.productDetail == nil {
                    ProductDetailShimmerView()
                } else if let productDetail = viewModel.productDetail {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Product Image and Details Section
                            productImageAndDetailsSection(productDetail)
                            
                            // Customer Reviews Section
                            customerReviewsSection(productDetail)
                        }
                    }
                    .refreshable {
                        await viewModel.refreshData(productId: product.id)
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toast(message: $viewModel.errorMessage, type: .error)
            .toast(message: $viewModel.successMessage, type: .success)
            .sheet(isPresented: $showingWriteReview) {
                WriteReviewView(product: product)
            }
            .sheet(isPresented: $showingCommentSheet) {
                if let review = selectedReviewForComments {
                    ReviewCommentSheet(
                        review: review,
                        onCommentAdded: {
                            // Update the comment count for the selected review
                            if let index = viewModel.reviews.firstIndex(where: { $0.id == review.id }) {
                                // Add a mock comment to show the update
                                // In a real app, you'd reload the review data
                                print("Comment added to review: \(review.id)")
                            }
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        .task {
            await viewModel.loadProductDetail(productId: product.id)
            
            // If no product detail was loaded (no reviews found), create one from the original product data
            if viewModel.productDetail == nil {
                viewModel.createProductDetailFromProduct(product)
            }
        }
        .onAppear {
            startImageCarousel()
        }
        .onDisappear {
            stopImageCarousel()
        }
    }
    
    // MARK: - Product Image and Details Section
    private func productImageAndDetailsSection(_ productDetail: ProductDetail) -> some View {
        VStack(spacing: 0) {
            // Product Image (Full Width)
            productImageView(productDetail)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // Product Details (Below Image)
            productDetailsView(productDetail)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            
            // Rating Breakdown
            ratingBreakdownView(productDetail)
                .padding(.horizontal, 20)
                .padding(.top, 24)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Product Image View
    private func productImageView(_ productDetail: ProductDetail) -> some View {
        ZStack(alignment: .topTrailing) {
            // Get all available images
            let allImages = product.mediaSignedUrls.isEmpty ? 
                (product.media.isEmpty ? [productDetail.displayImage].compactMap { $0 } : product.media) : 
                product.mediaSignedUrls
            
            if allImages.count > 1 {
                // Multiple images - show carousel
                TabView(selection: $currentImageIndex) {
                    ForEach(0..<allImages.count, id: \.self) { index in
                        AsyncImage(url: URL(string: allImages[index])) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                )
                        }
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
            } else if let imageUrl = allImages.first {
                // Single image
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        )
                }
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                .clipped()
            } else {
                // No image
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Image carousel indicators (only show if multiple images)
            if allImages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<allImages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                .offset(x: -8, y: 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Product Details View
    private func productDetailsView(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Product Tag
            HStack {
                Text("Product")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                Spacer()
            }
            
            // Title
            Text(productDetail.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Subtitle
            Text(productDetail.description)
                .font(.title3)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Overall Rating
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(productDetail.averageRating) ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundColor(index < Int(productDetail.averageRating) ? .yellow : .gray)
                    }
                }
                
                Text("(\(productDetail.totalRatings) reviews)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Product Attributes
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Category:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(productDetail.category)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("Subcategory:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(productDetail.subcategory)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("Brand:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(productDetail.brand)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            
            // Write Review Button
            Button {
                showingWriteReview = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Write Review")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dynamicAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.dynamicAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Rating Breakdown View
    private func ratingBreakdownView(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rating Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    HStack(spacing: 20) {
                        Text("\(rating)★")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .frame(height: 12)
                                    .clipShape(Capsule())
                                
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(
                                        width: geometry.size.width * CGFloat(productDetail.ratingBreakdown[rating] ?? 0) / CGFloat(max(productDetail.totalRatings, 1)),
                                        height: 12
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 12)
                        
                        Text("\(productDetail.ratingBreakdown[rating] ?? 0)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Customer Reviews Section
    private func customerReviewsSection(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Header
            HStack {
                Text("Customer Reviews (\(productDetail.totalRatings))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Reviews List or No Reviews State
            if productDetail.reviews.isEmpty {
                noReviewsState
            } else {
                LazyVStack(spacing: 24) {
                    ForEach(productDetail.reviews) { review in
                        ReviewCardView(
                            review: review, 
                            viewModel: viewModel,
                            onCommentTap: { selectedReview in
                                selectedReviewForComments = selectedReview
                                showingCommentSheet = true
                            }
                        )
                        .task {
                            if review.id == productDetail.reviews.last?.id {
                                await viewModel.loadMoreReviews(productId: product.id)
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more reviews...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, 20)
                
                // End of reviews indicator
                if !viewModel.isLoading && productDetail.reviews.count > 0 {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("You've seen all reviews!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 32)
                }
            }
        }
    }
    
    // MARK: - No Reviews State
    private var noReviewsState: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Reviews Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Be the first to review this product and help others make informed decisions!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                showingWriteReview = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Write First Review")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dynamicAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.dynamicAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.square.on.square")
                .font(.system(size: 80))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Product Details Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Unable to load product details and reviews")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Image Carousel Methods
    private func startImageCarousel() {
        let allImages = product.mediaSignedUrls.isEmpty ? 
            (product.media.isEmpty ? [] : product.media) : 
            product.mediaSignedUrls
        
        guard allImages.count > 1 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentImageIndex = (currentImageIndex + 1) % allImages.count
            }
        }
    }
    
    private func stopImageCarousel() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Review Card View
struct ReviewCardView: View {
    let review: ReviewPost
    let viewModel: ProductDetailViewModel
    let onCommentTap: (ReviewPost) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rating
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Image(systemName: index < review.rating ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(index < review.rating ? .yellow : .gray)
                }
            }
            
            // Title
            Text(review.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Description
            Text(review.cleanDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            // Review Image (if any)
            if let imageUrl = review.displayImage {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            // Reviewer Info
            HStack {
                Text(review.userDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(review.formattedCreatedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Engagement metrics
            HStack {
                Text("👍 \(review.likesCount) Likes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(review.reviews?.count ?? 0) comments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .background(Color(.systemGray4))
            
            // Interaction buttons
            HStack {
                // Like Button
                Button(action: {
                    Task {
                        await viewModel.likeReview(review)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: review.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 16))
                        Text("Like")
                            .font(.subheadline)
                    }
                    .foregroundColor(review.isLiked ? .blue : .secondary)
                }
                
                Spacer()
                
                // Dislike Button
                Button(action: {
                    Task {
                        await viewModel.dislikeReview(review)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: review.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 16))
                        Text("Dislike")
                            .font(.subheadline)
                    }
                    .foregroundColor(review.isDisliked ? .red : .secondary)
                }
                
                Spacer()
                
                // Comment Button
                Button(action: {
                    onCommentTap(review)
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
            
            // Safal Tag
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                    Text("Safal")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green)
                .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Product Detail Shimmer View
struct ProductDetailShimmerView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product Image and Details Shimmer
                HStack(alignment: .top, spacing: 20) {
                    // Image shimmer
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 200)
                        .homeshimmerEffect()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Details shimmer
                    VStack(alignment: .leading, spacing: 12) {
                        ProductDetailShimmerBox(width: 60, height: 20)
                        ProductDetailShimmerBox(width: 150, height: 24)
                        ProductDetailShimmerBox(width: 120, height: 16)
                        ProductDetailShimmerBox(width: 100, height: 16)
                        ProductDetailShimmerBox(width: 80, height: 16)
                        ProductDetailShimmerBox(width: 120, height: 40)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Rating breakdown shimmer
                VStack(alignment: .leading, spacing: 12) {
                    ProductDetailShimmerBox(width: 120, height: 20)
                    VStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { _ in
                            ProductDetailShimmerBox(width: .infinity, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Reviews shimmer
                VStack(alignment: .leading, spacing: 16) {
                    ProductDetailShimmerBox(width: 150, height: 20)
                    .padding(.horizontal, 20)
                    
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 12) {
                            ProductDetailShimmerBox(width: 80, height: 14)
                            ProductDetailShimmerBox(width: 200, height: 18)
                            ProductDetailShimmerBox(width: .infinity, height: 16)
                            ProductDetailShimmerBox(width: 120, height: 14)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .disabled(true)
    }
}

struct ProductDetailShimmerBox: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 4)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .homeshimmerEffect()
    }
}

// MARK: - Write Review View (Placeholder)
struct WriteReviewView: View {
    let product: ProductReview
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Write Review for \(product.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("This is a placeholder for the write review functionality")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Review Comment Sheet
struct ReviewCommentSheet: View {
    let review: ReviewPost
    let onCommentAdded: () -> Void
    @StateObject private var commentViewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Review header
                VStack(alignment: .leading, spacing: 12) {
                    Text(review.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(review.cleanDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                
                // Comments list
                if commentViewModel.isLoading && commentViewModel.comments.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading comments...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if commentViewModel.comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No comments yet")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Be the first to comment on this review!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(commentViewModel.comments) { comment in
                                CommentCardView(comment: comment, viewModel: commentViewModel)
                            }
                            
                            if commentViewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading more comments...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                }
                
                // Add comment section
                AddCommentView(
                    postId: review.id,
                    onCommentAdded: {
                        onCommentAdded()
                    }
                )
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .toast(message: $commentViewModel.errorMessage, type: .error)
            .toast(message: $commentViewModel.successMessage, type: .success)
        }
        .task {
            // Load comments when view appears
        }
    }
}

// MARK: - Comment Card View
struct CommentCardView: View {
    let comment: PostComment
    let viewModel: CommentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: comment.user.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(comment.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Comment text
            Text(comment.comment)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Comment images
            if !comment.imgs.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(comment.imgs, id: \.self) { imageUrl in
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
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // Like/Dislike buttons
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.likeComment(comment)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(comment.likesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(comment.isLiked ? .blue : .secondary)
                }
                
                Button(action: {
                    Task {
                        await viewModel.dislikeComment(comment)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14))
                        Text("\(comment.dislikesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(comment.isDisliked ? .red : .secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Add Comment View
struct AddCommentView: View {
    let postId: String
    let onCommentAdded: () -> Void
    @StateObject private var commentViewModel = CommentViewModel()
    @State private var commentText = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Image preview
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .font(.system(size: 16))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    Task {
                        await addComment()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(commentText.isEmpty ? .secondary : Color.dynamicAccent)
                }
                .disabled(commentText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingImagePicker) {
            ProductDetailImagePicker(selectedImages: $selectedImages)
        }
        .toast(message: $commentViewModel.errorMessage, type: .error)
        .toast(message: $commentViewModel.successMessage, type: .success)
    }
    
    private func addComment() async {
        await commentViewModel.addComment(to: postId)
        
        if commentViewModel.successMessage != nil {
            commentText = ""
            selectedImages = []
            onCommentAdded()
        }
    }
}

// MARK: - Product Detail Image Picker
struct ProductDetailImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProductDetailImagePicker
        
        init(_ parent: ProductDetailImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(product: ProductReview(
            id: "1",
            name: "Ben 10",
            description: "This is ben tenison",
            media: [],
            category: "Animation",
            subCategory: "Character",
            specifications: [:],
            isActive: true,
            slug: "ben-10",
            createdAt: "2025-09-04T13:28:31.511Z",
            updatedAt: "2025-09-04T13:28:31.511Z",
            categoryType: "product",
            brand: BrandInfo(
                id: "1",
                name: "Cartoon",
                slug: "cartoon",
                subCategory: SubCategoryInfo(
                    id: "1",
                    name: "Character",
                    slug: "character",
                    category: CategoryInfo(
                        id: "1",
                        name: "Animation",
                        slug: "animation"
                    )
                )
            ),
            averageRating: 3.5,
            totalRatings: 2,
            ratings: [1, 1],
            mediaSignedUrls: []
        ))
    }
}
