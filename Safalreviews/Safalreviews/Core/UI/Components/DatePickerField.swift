import SwiftUI

struct DatePickerField: View {
    let title: String
    @Binding var selectedDate: Date
    let error: String?
    @State private var showDatePicker = false
    @State private var hasSelectedDate = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private var maxDate: Date {
        calendar.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }
    
    private var minDate: Date {
        calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text(hasSelectedDate ? dateFormatter.string(from: selectedDate) : "Select Date of Birth")
                    .foregroundColor(hasSelectedDate ? .primary : .gray)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        error == nil ? Color.gray.opacity(0.2) : Color.red,
                        lineWidth: 1
                    )
            )
            .onTapGesture {
                showDatePicker = true
            }
            
            if showDatePicker {
                DatePicker(
                    "Select Date of Birth",
                    selection: $selectedDate,
                    in: minDate...maxDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .onChange(of: selectedDate) { _ in
                    hasSelectedDate = true
                    showDatePicker = false
                }
                .padding(.top, 8)
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}
