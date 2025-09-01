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
                            if let categories = tempFilter.categories, !categories.isEmpty {
                                Text("\(categories.count) selected")
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Categories")
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
                                    if tempFilter.categories?.contains(category.id) == true {
                                        tempFilter.categories?.removeAll { $0 == category.id }
                                    } else {
                                        if tempFilter.categories == nil {
                                            tempFilter.categories = []
                                        }
                                        tempFilter.categories?.append(category.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.categories?.contains(category.id) == true ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.categories?.contains(category.id) == true ? .accentColor : .gray)
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
                            if let subcategories = tempFilter.subCategories, !subcategories.isEmpty {
                                Text("\(subcategories.count) selected")
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Subcategories")
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
                                    if tempFilter.subCategories?.contains(subcategory.id) == true {
                                        tempFilter.subCategories?.removeAll { $0 == subcategory.id }
                                    } else {
                                        if tempFilter.subCategories == nil {
                                            tempFilter.subCategories = []
                                        }
                                        tempFilter.subCategories?.append(subcategory.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.subCategories?.contains(subcategory.id) == true ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.subCategories?.contains(subcategory.id) == true ? .accentColor : .gray)
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
                            if let brands = tempFilter.brands, !brands.isEmpty {
                                Text("\(brands.count) selected")
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Brands")
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
                                    if tempFilter.brands?.contains(brand.id) == true {
                                        tempFilter.brands?.removeAll { $0 == brand.id }
                                    } else {
                                        if tempFilter.brands == nil {
                                            tempFilter.brands = []
                                        }
                                        tempFilter.brands?.append(brand.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.brands?.contains(brand.id) == true ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.brands?.contains(brand.id) == true ? .accentColor : .gray)
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
