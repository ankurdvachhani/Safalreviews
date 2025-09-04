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
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Image carousel indicators
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(6)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            .offset(x: -8, y: 8)
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
            
            // Reviews List
            LazyVStack(spacing: 24) {
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
            
            // Engagement
            HStack(spacing: 20) {
                Button {
                    // Handle like
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup")
                            .font(.system(size: 16))
                        Text("\(review.likesCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                }
                
                Button {
                    showingComments.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                        Text("0 comments")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: showingComments ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
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
