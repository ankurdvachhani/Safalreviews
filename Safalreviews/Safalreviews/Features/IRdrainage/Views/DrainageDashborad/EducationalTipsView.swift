import SwiftUI

struct EducationalTipsView: View {
    let tips: [EducationalTip]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(tips) { tip in
                        EducationalTipDetailCard(tip: tip)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Health Tips")
            .navigationBarTitleDisplayMode(.large)
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

struct EducationalTipDetailCard: View {
    let tip: EducationalTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(tip.category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: tip.icon)
                            .foregroundColor(tip.category.color)
                            .font(.title2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(tip.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(tip.category.color)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            Text(tip.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
struct EducationalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        EducationalTipsView(tips: [
            EducationalTip(
                title: "Proper Wound Care",
                description: "Keep the drainage site clean and dry. Change dressings as instructed by your healthcare provider. This is a longer description to show how the card handles multiple lines of text.",
                category: .aftercare,
                icon: "bandage.fill"
            ),
            EducationalTip(
                title: "Monitor for Infection",
                description: "Watch for signs of infection: increased redness, swelling, or foul odor.",
                category: .hygiene,
                icon: "eye.fill"
            )
        ])
    }
}
