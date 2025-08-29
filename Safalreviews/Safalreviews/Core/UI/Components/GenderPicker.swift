import SwiftUI

struct GenderPicker: View {
    @Binding var selectedGender: String
    let error: String?
    
    private let genders = [
        ("Male", "male"),
        ("Female", "female"),
        ("Other", "other")
    ]
    
    private var selectedGenderName: String {
        genders.first { $0.1 == selectedGender }?.0 ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                ForEach(genders, id: \.1) { gender in
                    Button {
                        selectedGender = gender.1
                    } label: {
                        HStack {
                            Text(gender.0)
                            if selectedGender == gender.1 {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedGender.isEmpty ? "Select Gender" : selectedGenderName)
                        .foregroundColor(selectedGender.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error == nil ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
                )
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}
