import SwiftUI

struct ReviewSortSheet: View {
    @Binding var selectedSortOption: ReviewSortOption
    @Binding var isPresented: Bool
    let onSortChanged: (ReviewSortOption) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            Text("Sort & Order")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 12)
                .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(ReviewSortOption.allCases) { option in
                        Button(action: {
                            selectedSortOption = option
                            onSortChanged(option)
                            isPresented = false
                        }) {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundColor(.dynamicAccent)
                                    .padding(.vertical, 14)
                                Spacer()
                                if option == selectedSortOption {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.dynamicAccent)
                                }
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                    }
                }
            }
            
            HStack(spacing: 12) {
                // Reset button
                Button(action: {
                    selectedSortOption = .dateDesc
                    onSortChanged(.dateDesc)
                    isPresented = false
                }) {
                    Text("Reset")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.red)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
                
                // Cancel button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(Color.dynamicAccent)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dynamicAccent, lineWidth: 2)
                        )
                }
            }
            .padding()
        }
        .background(Color.dynamicBackground)
        .cornerRadius(20)
    }
}

#Preview {
    ReviewSortSheet(
        selectedSortOption: .constant(.dateDesc),
        isPresented: .constant(true),
        onSortChanged: { _ in }
    )
}
