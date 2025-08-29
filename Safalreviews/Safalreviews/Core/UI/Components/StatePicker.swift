import SwiftUI

struct StatePicker: View {
    @Binding var selectedState: String
    let country: String
    let error: String?
    
    private var states: [(name: String, code: String)] {
        switch country {
        case "USA":
            return [
                ("Alabama", "AL"), ("Alaska", "AK"), ("Arizona", "AZ"), ("Arkansas", "AR"),
                ("California", "CA"), ("Colorado", "CO"), ("Connecticut", "CT"), ("Delaware", "DE"),
                ("Florida", "FL"), ("Georgia", "GA"), ("Hawaii", "HI"), ("Idaho", "ID"),
                ("Illinois", "IL"), ("Indiana", "IN"), ("Iowa", "IA"), ("Kansas", "KS"),
                ("Kentucky", "KY"), ("Louisiana", "LA"), ("Maine", "ME"), ("Maryland", "MD"),
                ("Massachusetts", "MA"), ("Michigan", "MI"), ("Minnesota", "MN"), ("Mississippi", "MS"),
                ("Missouri", "MO"), ("Montana", "MT"), ("Nebraska", "NE"), ("Nevada", "NV"),
                ("New Hampshire", "NH"), ("New Jersey", "NJ"), ("New Mexico", "NM"), ("New York", "NY"),
                ("North Carolina", "NC"), ("North Dakota", "ND"), ("Ohio", "OH"), ("Oklahoma", "OK"),
                ("Oregon", "OR"), ("Pennsylvania", "PA"), ("Rhode Island", "RI"), ("South Carolina", "SC"),
                ("South Dakota", "SD"), ("Tennessee", "TN"), ("Texas", "TX"), ("Utah", "UT"),
                ("Vermont", "VT"), ("Virginia", "VA"), ("Washington", "WA"), ("West Virginia", "WV"),
                ("Wisconsin", "WI"), ("Wyoming", "WY")
            ]
        case "IND":
            return [
                ("Andhra Pradesh", "AP"), ("Arunachal Pradesh", "AR"), ("Assam", "AS"), ("Bihar", "BR"),
                ("Chhattisgarh", "CG"), ("Goa", "GA"), ("Gujarat", "GJ"), ("Haryana", "HR"),
                ("Himachal Pradesh", "HP"), ("Jharkhand", "JH"), ("Karnataka", "KA"), ("Kerala", "KL"),
                ("Madhya Pradesh", "MP"), ("Maharashtra", "MH"), ("Manipur", "MN"), ("Meghalaya", "ML"),
                ("Mizoram", "MZ"), ("Nagaland", "NL"), ("Odisha", "OR"), ("Punjab", "PB"),
                ("Rajasthan", "RJ"), ("Sikkim", "SK"), ("Tamil Nadu", "TN"), ("Telangana", "TS"),
                ("Tripura", "TR"), ("Uttar Pradesh", "UP"), ("Uttarakhand", "UK"), ("West Bengal", "WB"),
                ("Andaman and Nicobar Islands", "AN"), ("Chandigarh", "CH"), ("Dadra and Nagar Haveli and Daman and Diu", "DN"),
                ("Delhi", "DL"), ("Jammu and Kashmir", "JK"), ("Ladakh", "LA"), ("Lakshadweep", "LD"),
                ("Puducherry", "PY")
            ]
        default:
            return []
        }
    }
    
    private var selectedStateName: String {
        states.first { $0.code == selectedState }?.name ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                ForEach(states, id: \.code) { state in
                    Button {
                        selectedState = state.code
                    } label: {
                        HStack {
                            Text(state.name)
                            if selectedState == state.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedState.isEmpty ? "Select State" : selectedStateName)
                        .foregroundColor(selectedState.isEmpty ? .gray : .primary)
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
            .disabled(country.isEmpty || states.isEmpty)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}
