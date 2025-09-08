import SwiftUI

struct AddCustomCategoryView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: PostCreationViewModel
    
    @State private var categoryType: String = "product"
    @State private var customCategory: String = ""
    @State private var customSubCategory: String = ""
    @State private var customBrand: String = ""
    @State private var customProduct: String = ""
    
    let categoryTypes = ["product", "person"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Category Type Dropdown
                        categoryTypeSection
                        
                        // Custom Fields
                        customFieldsSection
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
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Add Custom Product")
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
    
    // MARK: - Category Type Section
    
    private var categoryTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Type")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Menu {
                ForEach(categoryTypes, id: \.self) { type in
                    Button(action: {
                        categoryType = type
                    }) {
                        HStack {
                            Text(type.capitalized)
                            if categoryType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 16))
                    
                    Text(categoryType.capitalized)
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
    
    // MARK: - Custom Fields Section
    
    private var customFieldsSection: some View {
        VStack(spacing: 20) {
            // Category Field
            CustomTextField(
                title: "Category",
                placeholder: "e.g., Electronics, Clothing, Food",
                text: $customCategory,
                showSecureText: .constant(false)
            )
            
            // Subcategory Field
            CustomTextField(
                title: "Subcategory",
                placeholder: "e.g., Smartphones, Men's Wear, Snacks",
                text: $customSubCategory,
                showSecureText: .constant(false)
            )
            
            // Brand Field
            CustomTextField(
                title: "Brand",
                placeholder: "e.g., Apple, Nike, Coca-Cola",
                text: $customBrand,
                showSecureText: .constant(false)
            )
            
            // Product Field
            CustomTextField(
                title: "Product",
                placeholder: "e.g., iPhone 15, Air Jordan 1, Coca-Cola Classic",
                text: $customProduct,
                showSecureText: .constant(false)
            )
        }
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Cancel Button
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Save Button
            Button(action: {
                saveCustomCategory()
            }) {
                Text("Save")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color.dynamicAccent : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Methods
    
    private var canSave: Bool {
        return !customCategory.isEmpty && !customSubCategory.isEmpty && !customBrand.isEmpty && !customProduct.isEmpty
    }
    
    private func setupInitialValues() {
        categoryType = viewModel.state.categoryType
        customCategory = viewModel.state.customCategory
        customSubCategory = viewModel.state.customSubCategory
        customBrand = viewModel.state.customBrand
        customProduct = viewModel.state.customProduct
    }
    
    private func saveCustomCategory() {
        viewModel.state.categoryType = categoryType
        viewModel.state.customCategory = customCategory
        viewModel.state.customSubCategory = customSubCategory
        viewModel.state.customBrand = customBrand
        viewModel.state.customProduct = customProduct
        viewModel.state.isUsingCustomCategory = true
        
        // Clear selected items
        viewModel.state.selectedCategory = nil
        viewModel.state.selectedSubcategory = nil
        viewModel.state.selectedBrand = nil
        viewModel.state.selectedProduct = nil
        
        isPresented = false
    }
}


#Preview {
    AddCustomCategoryView(
        isPresented: .constant(true),
        viewModel: PostCreationViewModel()
    )
}
