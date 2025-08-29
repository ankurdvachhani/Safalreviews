import SwiftUI

struct DatePickerField: View {
    let title: String
    @Binding var selectedDate: Date
    let error: String?
    
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
                Text(dateFormatter.string(from: selectedDate))
                    .foregroundColor(.primary)
                
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
                showDatePicker()
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private func showDatePicker() {
        let alert = UIAlertController(title: "Select Date of Birth", message: nil, preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = maxDate
        datePicker.minimumDate = minDate
        datePicker.date = selectedDate
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            selectedDate = datePicker.date
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}
