import SwiftUI

struct ReviewFilterSheet: View {
    @Binding var filter: ReviewFilter
    let reviewStore: ReviewStore
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempFilter: ReviewFilter
    @State private var showCategoryTypeDropdown = false
    @State private var showCategoryDropdown = false
    @State private var showSubcategoryDropdown = false
    @State private var showBrandDropdown = false
    
    init(filter: Binding<ReviewFilter>, reviewStore: ReviewStore, onApply: @escaping () -> Void) {
        _filter = filter
        self.reviewStore = reviewStore
        self.onApply = onApply
        _tempFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Category Type Filter
                Section(header: Text("Category Type")) {
                    Button(action: {
                        showCategoryTypeDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.categoryType ?? "All types")
                                .foregroundColor(tempFilter.categoryType == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showCategoryTypeDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showCategoryTypeDropdown {
                        ForEach(["All types", "Product", "Place", "People"], id: \.self) { type in
                            HStack {
                                Button(action: {
                                    if tempFilter.categoryType == type {
                                        tempFilter.categoryType = nil
                                    } else {
                                        tempFilter.categoryType = type
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.categoryType == type ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(tempFilter.categoryType == type ? .accentColor : .gray)
                                        Text(type)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                // Category Filter
                Section(header: Text("Categories")) {
                    Button(action: {
                        showCategoryDropdown.toggle()
                    }) {
                        HStack {
                            if let categoryId = tempFilter.category {
                                let categoryName = reviewStore.getCategoryName(for: categoryId)
                                Text(categoryName)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Category")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: showCategoryDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showCategoryDropdown {
                        ForEach(reviewStore.categories) { category in
                            HStack {
                                Button(action: {
                                    if tempFilter.category == category.id {
                                        tempFilter.category = nil
                                    } else {
                                        tempFilter.category = category.id
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.category == category.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(tempFilter.category == category.id ? .accentColor : .gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(category.name)
                                                .foregroundColor(.primary)
                                            Text(category.categoryType)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                // Subcategory Filter
                Section(header: Text("Subcategories")) {
                    Button(action: {
                        showSubcategoryDropdown.toggle()
                    }) {
                        HStack {
                            if let subcategoryId = tempFilter.subCategory {
                                let subcategoryName = reviewStore.getSubcategoryName(for: subcategoryId)
                                Text(subcategoryName)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Subcategory")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: showSubcategoryDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showSubcategoryDropdown {
                        ForEach(reviewStore.subcategories) { subcategory in
                            HStack {
                                Button(action: {
                                    if tempFilter.subCategory == subcategory.id {
                                        tempFilter.subCategory = nil
                                    } else {
                                        tempFilter.subCategory = subcategory.id
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.subCategory == subcategory.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(tempFilter.subCategory == subcategory.id ? .accentColor : .gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(subcategory.name)
                                                .foregroundColor(.primary)
                                            Text(subcategory.category.name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                // Brand Filter
                Section(header: Text("Brands")) {
                    Button(action: {
                        showBrandDropdown.toggle()
                    }) {
                        HStack {
                            if let brandId = tempFilter.brand {
                                let brandName = reviewStore.getBrandName(for: brandId)
                                Text(brandName)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Brand")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: showBrandDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showBrandDropdown {
                        ForEach(reviewStore.brands) { brand in
                            HStack {
                                Button(action: {
                                    if tempFilter.brand == brand.id {
                                        tempFilter.brand = nil
                                    } else {
                                        tempFilter.brand = brand.id
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.brand == brand.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(tempFilter.brand == brand.id ? .accentColor : .gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(brand.name)
                                                .foregroundColor(.primary)
                                            Text(brand.subCategory.name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
            }
            .navigationTitle("Filter Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        tempFilter.clearAll()
                        filter = tempFilter
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filter = tempFilter
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    ReviewFilterSheet(
        filter: .constant(ReviewFilter()),
        reviewStore: ReviewStore(),
        onApply: {}
    )
}
