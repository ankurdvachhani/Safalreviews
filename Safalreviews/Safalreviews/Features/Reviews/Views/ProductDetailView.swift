import SwiftUI

struct ProductDetailView: View {
    let product: ProductReview
    @StateObject private var viewModel = ProductDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingWriteReview = false
    
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
        .task {
            await viewModel.loadProductDetail(productId: product.id)
        }
    }
    
    // MARK: - Product Image and Details Section
    private func productImageAndDetailsSection(_ productDetail: ProductDetail) -> some View {
        VStack(spacing: 20) {
            // Product Image (Left) and Details (Right)
            HStack(alignment: .top, spacing: 20) {
                // Product Image
                productImageView(productDetail)
                
                // Product Details
                productDetailsView(productDetail)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Rating Breakdown
            ratingBreakdownView(productDetail)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Product Image View
    private func productImageView(_ productDetail: ProductDetail) -> some View {
        ZStack(alignment: .topTrailing) {
            if let imageUrl = productDetail.displayImage {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 200, height: 200)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Image carousel indicators
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
            .offset(x: -8, y: 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Product Details View
    private func productDetailsView(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Tag
            Text("Product")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            
            // Title
            Text(productDetail.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Subtitle
            Text(productDetail.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Overall Rating
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(productDetail.averageRating) ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(index < Int(productDetail.averageRating) ? .yellow : .gray)
                    }
                }
                
                Text("(\(productDetail.totalRatings) reviews)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Product Attributes
            VStack(alignment: .leading, spacing: 4) {
                Text("Category: \(productDetail.category)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Subcategory: \(productDetail.subcategory)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Brand: \(productDetail.brand)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Write Review Button
            Button {
                showingWriteReview = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                    Text("Write Review")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.dynamicAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Rating Breakdown View
    private func ratingBreakdownView(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    HStack(spacing: 12) {
                        Text("\(rating)★")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .clipShape(Capsule())
                                
                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(
                                        width: geometry.size.width * CGFloat(productDetail.ratingBreakdown[rating] ?? 0) / CGFloat(max(productDetail.totalRatings, 1)),
                                        height: 8
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(productDetail.ratingBreakdown[rating] ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Customer Reviews Section
    private func customerReviewsSection(_ productDetail: ProductDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Customer Reviews (\(productDetail.totalRatings))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Reviews List
            LazyVStack(spacing: 16) {
                ForEach(productDetail.reviews) { review in
                    ReviewCardView(review: review)
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
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
            
            // End of reviews indicator
            if !viewModel.isLoading && productDetail.reviews.count > 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                        Text("You've seen all reviews!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
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
}

// MARK: - Review Card View
struct ReviewCardView: View {
    let review: ReviewPost
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rating
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < review.rating ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(index < review.rating ? .yellow : .gray)
                }
            }
            
            // Title
            Text(review.title)
                .font(.headline)
                .fontWeight(.semibold)
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
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            // Reviewer Info
            HStack {
                Text(review.userDisplayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(review.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Engagement
            HStack(spacing: 16) {
                Button {
                    // Handle like
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(review.likesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Button {
                    showingComments.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("\(review.reviews.count) comments")
                            .font(.caption)
                        Image(systemName: showingComments ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Safal Tag
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                    Text("Safal")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
