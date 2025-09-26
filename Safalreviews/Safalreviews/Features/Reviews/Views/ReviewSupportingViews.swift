import SwiftUI

// MARK: - Review No Search Results View
struct ReviewNoSearchResultsView: View {
    let searchText: String
    let onClearSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(Color.dynamicAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("No products found for '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                Text("Try different keywords or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    onClearSearch()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear Search")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.dynamicAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.dynamicAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Review No Filter Results View
struct ReviewNoFilterResultsView: View {
    let currentFilter: ReviewFilter
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent)
            
            Text("No Matching Products")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No products match your current filter criteria")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Show active filters summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Filters:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let categoryType = currentFilter.categoryType {
                        Text("• Category Type: \(categoryType)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let categories = currentFilter.categories, !categories.isEmpty {
                        Text("• Categories: \(categories.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let subCategories = currentFilter.subCategories, !subCategories.isEmpty {
                        Text("• Subcategories: \(subCategories.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let brands = currentFilter.brands, !brands.isEmpty {
                        Text("• Brands: \(brands.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(spacing: 12) {
                Text("Try adjusting your filters or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    onClearFilters()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear All Filters")
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

// MARK: - Shimmer Effect Extension
extension View {
    func homeshimmerEffect() -> some View {
        ShimmerEffectView(content: self)
    }
}

struct ShimmerEffectView<Content: View>: View {
    let content: Content
    @State private var isAnimating = false

    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            )
            .clipped()
    }
}

struct homeShimmerEffectView<Content: View>: View {
    let content: Content
    @State private var isAnimating = false
    
    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.6), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            )
            .clipped()
    }
}

#Preview {
    VStack(spacing: 20) {
        ReviewNoSearchResultsView(
            searchText: "test",
            onClearSearch: {}
        )
        
        ReviewNoFilterResultsView(
            currentFilter: ReviewFilter(),
            onClearFilters: {}
        )
    }
}
