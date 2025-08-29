import PhotosUI
import SwiftUI

// MARK: - Form Section Enum
enum DFormSection: String, CaseIterable {
    case drainageDetails = "Details"
    case optionalDetails = "Additional"
    case Images = "Images"
   
    
}

struct AddDrainageView: View {
    @EnvironmentObject var store: DrainageStore
    @Environment(\.presentationMode) var presentationMode

    @State private var patientId = ""
    @State private var patientName = ""
    @State private var recordedAt = Date()
    @State private var showPatientSelection = false
    @State private var amount = ""
    @State private var SalineFlushamount = ""

    @State private var amountUnit = "ml"
    @State private var location = ""
    @State private var color = DrainageEntry.colorOptions[0]
    @State private var colorOther = ""
    @State private var consistency: Set<String> = []
    @State private var consistencyOther = ""
    @State private var odor = DrainageEntry.odorOptions[0]
    @State private var odorOther = ""
    @State private var drainageType = DrainageEntry.drainageTypeOptions[0]
    @State private var drainageTypeOther = ""
    @State private var fluidType = DrainageEntry.fluidTypes[0]
    @State private var fluidTypeOther = ""
    @State private var odorPresent = false
    @State private var SalineFlush = false
    @State private var painLevel: Double = 0
    @State private var temperature = ""
    @State private var temperatureUnit = "°F"
    @State private var doctorNotified = false
    @State private var comments = ""
    @State private var beforePhotoItems: [PhotosPickerItem] = []
    @State private var afterPhotoItems: [PhotosPickerItem] = []
    @State private var fluidCupPhotoItems: [PhotosPickerItem] = []
    @State private var beforeImages: [(image: UIImage?, url: String?)] = []
    @State private var afterImages: [(image: UIImage?, url: String?)] = []
    @State private var fluidCupImages: [(image: UIImage?, url: String?)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let entry: DrainageEntry?
    private let incident: Incident?

    @State private var isDrainageDetailsExpanded = true
    @State private var isOptionalDetailsExpanded = true
    
    // Segmented control for form sections
    @State private var selectedSection: DFormSection = .drainageDetails
    
    // Camera states
    @State private var isBeforeCameraPresented = false
    @State private var isAfterCameraPresented = false
    @State private var isFluidCupCameraPresented = false

    // Field configuration states
    @State private var disabledFields: Set<String> = []
    @State private var hiddenFields: Set<String> = []
    @State private var requiredFields: Set<String> = []

    init(entry: DrainageEntry? = nil) {
        self.entry = entry
        incident = nil

        if let entry = entry {
            _patientId = State(initialValue: entry.patientId ?? "")
            _patientName = State(initialValue: entry.patientName ?? "")
            _recordedAt = State(initialValue: entry.recordedAt)
            _amount = State(initialValue: String(Int(entry.amount)))
            _amountUnit = State(initialValue: entry.amountUnit)
            _SalineFlush = State(initialValue: entry.fluidSalineFlushAmount != nil)
            _SalineFlushamount = State(initialValue: entry.fluidSalineFlushAmount != nil ? String(Int(entry.fluidSalineFlushAmount!)) : "")
            _location = State(initialValue: entry.location)
            let colorValue = entry.color.isEmpty ? DrainageEntry.colorOptions[0] : getDropdownValue(entry.color, options: DrainageEntry.colorOptions)
            _color = State(initialValue: colorValue)
            _colorOther = State(initialValue: getDropdownOtherValue(entry.color, options: DrainageEntry.colorOptions) ?? "")
            _consistency = State(initialValue: Set(entry.consistency))
            _consistencyOther = State(initialValue: "")
            let odorValue = entry.odor.isEmpty ? DrainageEntry.odorOptions[0] : getDropdownValue(entry.odor, options: DrainageEntry.odorOptions)
            _odor = State(initialValue: odorValue)
            _odorOther = State(initialValue: getDropdownOtherValue(entry.odor, options: DrainageEntry.odorOptions) ?? "")
            let drainageTypeValue = entry.drainageType.isEmpty ? DrainageEntry.drainageTypeOptions[0] : getDropdownValue(entry.drainageType, options: DrainageEntry.drainageTypeOptions)
            _drainageType = State(initialValue: drainageTypeValue)
            _drainageTypeOther = State(initialValue: getDropdownOtherValue(entry.drainageType, options: DrainageEntry.drainageTypeOptions) ?? "")
            _fluidType = State(initialValue: entry.fluidType)
            // Check if fluidType is not in predefined options and set up Other
            if !DrainageEntry.fluidTypes.contains(entry.fluidType) {
                _fluidType = State(initialValue: "Other")
                _fluidTypeOther = State(initialValue: entry.fluidType)
            }
            _odorPresent = State(initialValue: entry.odorPresent ?? false)
            _painLevel = State(initialValue: Double(entry.painLevel ?? 0))
            _temperature = State(initialValue: String(entry.temperature ?? 0))
            _doctorNotified = State(initialValue: entry.doctorNotified ?? false)
            _comments = State(initialValue: entry.comments ?? "")

            // Initialize image arrays with signed URLs
            if let beforeUrls = entry.beforeImageSign {
                _beforeImages = State(initialValue: beforeUrls.map { (image: nil as UIImage?, url: $0) })
            }
            if let afterUrls = entry.afterImageSign {
                _afterImages = State(initialValue: afterUrls.map { (image: nil as UIImage?, url: $0) })
            }
            if let fluidCupUrls = entry.fluidCupImageSign {
                _fluidCupImages = State(initialValue: fluidCupUrls.map { (image: nil as UIImage?, url: $0) })
            }
            _selectedSection = State(initialValue: .drainageDetails)
        }
    }

    init(incident: Incident) {
        entry = nil
        self.incident = incident

        // Calculate initial values from incident and field configs
        var initialAmount = ""
        var initialAmountUnit = "ml"
        var initialLocation = incident.location
        var initialColor = DrainageEntry.colorOptions[0]
        var initialColorOther = ""
        var initialConsistency: Set<String> = []
        var initialConsistencyOther = ""
        var initialOdor = DrainageEntry.odorOptions[0]
        var initialOdorOther = ""
        var initialDrainageType = incident.drainageType
        var initialDrainageTypeOther = ""
        var initialFluidType = DrainageEntry.fluidTypes[0]
        var initialFluidTypeOther = ""
        var initialOdorPresent = false
        var initialSalineFlush = false
        var initialSalineFlushAmount = ""
        var initialPainLevel: Double = 0
        var initialTemperature = ""
        var initialTemperatureUnit = "°F"
        var initialDoctorNotified = false
        var initialComments = ""

        // Initialize field configuration states
        var initialDisabledFields: Set<String> = []
        var initialHiddenFields: Set<String> = []
        var initialRequiredFields: Set<String> = []
        
        // Apply field configurations from incident
        if let fieldConfigs = incident.fieldConfig {
            for fieldConfig in fieldConfigs {
                // Track disabled, hidden, and required fields
                if !fieldConfig.isDefault {
                    initialDisabledFields.insert(fieldConfig.fieldKey)
                }
                if fieldConfig.isHidden {
                    initialHiddenFields.insert(fieldConfig.fieldKey)
                }
                if fieldConfig.isRequired {
                    initialRequiredFields.insert(fieldConfig.fieldKey)
                }

                switch fieldConfig.fieldKey {
                case "amount":
                    if case let .double(value) = fieldConfig.value {
                        initialAmount = String(Int(value))
                    } else if case let .int(value) = fieldConfig.value {
                        initialAmount = String(value)
                    }
                case "amountUnit":
                    if case let .string(value) = fieldConfig.value {
                        initialAmountUnit = value
                    }
                case "location":
                    if case let .string(value) = fieldConfig.value {
                        initialLocation = value
                    }
                case "fluidType":
                    if case let .string(value) = fieldConfig.value {
                        initialFluidType = getDropdownValue(value, options: DrainageEntry.fluidTypes)
                        if initialFluidType == "Other" {
                            initialFluidTypeOther = getDropdownOtherValue(value, options: DrainageEntry.fluidTypes) ?? ""
                        }
                    }
                case "color":
                    if case let .string(value) = fieldConfig.value {
                        initialColor = getDropdownValue(value, options: DrainageEntry.colorOptions)
                        if initialColor == "Other" {
                            initialColorOther = getDropdownOtherValue(value, options: DrainageEntry.colorOptions) ?? ""
                        }
                    }
                case "consistency":
                    if case let .stringArray(values) = fieldConfig.value {
                        initialConsistency = Set(values)
                        // Check if there are custom values not in predefined options
                        let predefinedOptions = Set(DrainageEntry.consistencyOptions)
                        let customValues = values.filter { !predefinedOptions.contains($0) }
                        if !customValues.isEmpty {
                            initialConsistency.insert("Other")
                            initialConsistencyOther = customValues.joined(separator: ", ")
                        }
                    }
                case "odor":
                    if case let .string(value) = fieldConfig.value {
                        initialOdor = getDropdownValue(value, options: DrainageEntry.odorOptions)
                        if initialOdor == "Other" {
                            initialOdorOther = getDropdownOtherValue(value, options: DrainageEntry.odorOptions) ?? ""
                        }
                    }
                case "drainageType":
                    if case let .string(value) = fieldConfig.value {
                        initialDrainageType = getDropdownValue(value, options: DrainageEntry.drainageTypeOptions)
                        if initialDrainageType == "Other" {
                            initialDrainageTypeOther = getDropdownOtherValue(value, options: DrainageEntry.drainageTypeOptions) ?? ""
                        }
                    }
                case "isFluidSalineFlush":
                    if case let .bool(value) = fieldConfig.value {
                        initialSalineFlush = value
                    }
                case "fluidSalineFlushAmount":
                    if case let .double(value) = fieldConfig.value {
                        initialSalineFlushAmount = String(Int(value))
                    } else if case let .int(value) = fieldConfig.value {
                        initialSalineFlushAmount = String(value)
                    }
                case "fluidSalineFlushAmountUnit":
                    if case let .string(value) = fieldConfig.value {
                        initialAmountUnit = value
                    }
                case "comments":
                    if case let .string(value) = fieldConfig.value {
                        initialComments = value
                    }
                case "odorPresent":
                    if case let .bool(value) = fieldConfig.value {
                        initialOdorPresent = value
                    }
                case "painLevel":
                    if case let .int(value) = fieldConfig.value {
                        initialPainLevel = Double(value)
                    }
                case "temperature":
                    if case let .double(value) = fieldConfig.value {
                        initialTemperature = String(value)
                    } else if case let .int(value) = fieldConfig.value {
                        initialTemperature = String(value)
                    }
                case "doctorNotified":
                    if case let .bool(value) = fieldConfig.value {
                        initialDoctorNotified = value
                    }
                default:
                    break
                }
            }
        }

        // Initialize State variables with calculated values
        _patientId = State(initialValue: incident.patientId)
        _patientName = State(initialValue: incident.patientName)
        _recordedAt = State(initialValue: Date())
        _amount = State(initialValue: initialAmount)
        _amountUnit = State(initialValue: initialAmountUnit)
        _SalineFlush = State(initialValue: initialSalineFlush)
        _SalineFlushamount = State(initialValue: initialSalineFlushAmount)
        _location = State(initialValue: initialLocation)
        _color = State(initialValue: initialColor)
        _colorOther = State(initialValue: initialColorOther)
        _consistency = State(initialValue: initialConsistency)
        _consistencyOther = State(initialValue: initialConsistencyOther)
        _odor = State(initialValue: initialOdor)
        _odorOther = State(initialValue: initialOdorOther)
        _drainageType = State(initialValue: initialDrainageType)
        _drainageTypeOther = State(initialValue: initialDrainageTypeOther)
        _fluidType = State(initialValue: initialFluidType)
        _fluidTypeOther = State(initialValue: initialFluidTypeOther)
        _odorPresent = State(initialValue: initialOdorPresent)
        _painLevel = State(initialValue: initialPainLevel)
        _temperature = State(initialValue: initialTemperature)
        _temperatureUnit = State(initialValue: initialTemperatureUnit)
        _doctorNotified = State(initialValue: initialDoctorNotified)
        _comments = State(initialValue: initialComments)
        _beforeImages = State(initialValue: [])
        _afterImages = State(initialValue: [])
        _fluidCupImages = State(initialValue: [])
        _beforePhotoItems = State(initialValue: [])
        _afterPhotoItems = State(initialValue: [])
        _fluidCupPhotoItems = State(initialValue: [])
        _isLoading = State(initialValue: false)
        _errorMessage = State(initialValue: nil)
        _showPatientSelection = State(initialValue: false)
        _isDrainageDetailsExpanded = State(initialValue: true)
        _isOptionalDetailsExpanded = State(initialValue: false)
        _disabledFields = State(initialValue: initialDisabledFields)
        _hiddenFields = State(initialValue: initialHiddenFields)
        _requiredFields = State(initialValue: initialRequiredFields)
        _selectedSection = State(initialValue: .drainageDetails)
    }

    // Temperature conversion computed properties
    private var temperatureInCelsius: Double? {
        guard let temp = Double(temperature) else { return nil }
        return temperatureUnit == "°F" ? (temp - 32) * 5 / 9 : temp
    }

    private var temperatureInFahrenheit: Double? {
        guard let temp = Double(temperature) else { return nil }
        return temperatureUnit == "°C" ? (temp * 9 / 5) + 32 : temp
    }

    private func convertTemperature() {
        guard let temp = Double(temperature) else { return }
        if temperatureUnit == "°C" {
            temperature = String(format: "%.1f", (temp * 9 / 5) + 32)
            temperatureUnit = "°F"
        } else {
            temperature = String(format: "%.1f", (temp - 32) * 5 / 9)
            temperatureUnit = "°C"
        }
    }

    private func getDropdownValue(_ value: String, options: [String]) -> String {
        if options.contains(value) {
            return value
        } else {
            return "Other"
        }
    }

    private func getDropdownOtherValue(_ value: String, options: [String]) -> String? {
        if options.contains(value) {
            return nil
        } else {
            return value
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 12) {
                    Picker("Form Section", selection: $selectedSection) {
                        ForEach(DFormSection.allCases, id: \.self) { section in
                            HStack {
                                Text(section.rawValue)
                            }
                            .tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)
                    
                    // Progress indicator
                    HStack {
                        ForEach(DFormSection.allCases, id: \.self) { section in
                            Circle()
                                .fill(selectedSection == section ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
                Form {
                    // Incident Header Section (only show when opened from incident)
                    if let incident = incident, selectedSection == .drainageDetails {
                        Section {
                            HStack {
                                Text("Incident Details")
                                    .font(.headline)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(incident.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if let incidentId = incident.incidentId {
                                        Text(incidentId)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.dynamicAccent)
                                            .clipShape(Capsule())
                                    }
                                }
                                HStack {
                                    Text("location: \(incident.location)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("DrainageType: \(incident.drainageType)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    if TokenManager.shared.loadCurrentUser()?.role != "Patient" && selectedSection == .drainageDetails {
                        Section(header: Text("Patient")) {
                            HStack {
                                VStack(alignment: .leading) {
                                    if patientId.isEmpty {
                                        Text("Select Patient")
                                            .foregroundColor(.gray)
                                    } else {
                                        Text(patientName)
                                            .foregroundColor(.primary)
                                        Text(patientId)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showPatientSelection = true
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if incident == nil {
                                    showPatientSelection = true
                                }
                            }
                        }
                    }
                    
                    if selectedSection == .drainageDetails {
                        Section(header: Text("Drainage Details")) {
                            // Header row - always visible
                            HStack {
                                VStack(alignment: .leading) {
                                    if !isDrainageDetailsExpanded {
                                        if !amount.isEmpty && !location.isEmpty {
                                            Text("\(amount) \(amountUnit) • \(location)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Tap to add drainage details")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDrainageDetailsExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isDrainageDetailsExpanded ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDrainageDetailsExpanded.toggle()
                                }
                            }
                            
                            // Expandable content - your original drainage details UI
                            if isDrainageDetailsExpanded {
                                DatePicker("Date & Time", selection: $recordedAt)
                                
                                HStack {
                                    Text("Total Fluid Amount")
                                        .font(.system(size: 16))
                                    
                                    TextField("0", text: $amount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(disabledFields.contains("amount"))
                                    
                                    Picker("Unit", selection: $amountUnit) {
                                        Text("ml").tag("ml")
                                        //   Text("cc").tag("cc")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 120)
                                    .disabled(disabledFields.contains("amountUnit"))
                                }
                                .opacity(hiddenFields.contains("amount") ? 0 : 1)
                                
                                TextField("Location", text: $location)
                                    .disabled(incident != nil) // disabledFields.contains("location"))
                                    .opacity(hiddenFields.contains("location") ? 0 : 1)
                                
                                Picker("Fluid Type", selection: $fluidType) {
                                    ForEach(DrainageEntry.fluidTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .disabled(disabledFields.contains("fluidType"))
                                .opacity(hiddenFields.contains("fluidType") ? 0 : 1)
                                
                                if fluidType == "Other" && !hiddenFields.contains("fluidType") {
                                    TextField("Specify Fluid Type", text: $fluidTypeOther)
                                        .disabled(disabledFields.contains("fluidType"))
                                }
                                
                                Picker("Color", selection: $color) {
                                    ForEach(DrainageEntry.colorOptions, id: \.self) { colorOption in
                                        Text(colorOption).tag(colorOption)
                                    }
                                }
                                .disabled(disabledFields.contains("color"))
                                .opacity(hiddenFields.contains("color") ? 0 : 1)
                                
                                if color == "Other" && !hiddenFields.contains("color") {
                                    TextField("Specify Color", text: $colorOther)
                                        .disabled(disabledFields.contains("fluidType"))
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Consistency")
                                        .font(.system(size: 16))
                                    
                                    ForEach(DrainageEntry.consistencyOptions, id: \.self) { option in
                                        HStack {
                                            Button(action: {
                                                if consistency.contains(option) {
                                                    consistency.remove(option)
                                                } else {
                                                    consistency.insert(option)
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: consistency.contains(option) ? "checkmark.square.fill" : "square")
                                                        .foregroundColor(consistency.contains(option) ? .accentColor : .gray)
                                                    Text(option)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .disabled(disabledFields.contains("consistency"))
                                            Spacer()
                                        }
                                    }
                                }
                                .opacity(hiddenFields.contains("consistency") ? 0 : 1)
                                
                                if consistency.contains("Other") && !hiddenFields.contains("consistency") {
                                    TextField("Specify Consistency", text: $consistencyOther)
                                        .disabled(disabledFields.contains("consistency"))
                                }
                                
                                
                                
                                if odor == "Other" && !hiddenFields.contains("odor") {
                                    TextField("Specify Odor", text: $odorOther)
                                        .disabled(disabledFields.contains("odorOther"))
                                }
                                
                                Picker("Type of Drainage", selection: $drainageType) {
                                    ForEach(DrainageEntry.drainageTypeOptions, id: \.self) { drainageTypeOption in
                                        Text(drainageTypeOption).tag(drainageTypeOption)
                                    }
                                }
                                .disabled(incident != nil) // disabledFields.contains("drainageType"))
                                .opacity(hiddenFields.contains("drainageType") ? 0 : 1)
                                
                                if drainageType == "Other" && !hiddenFields.contains("drainageType") {
                                    TextField("Specify Type of Drainage", text: $drainageTypeOther)
                                        .disabled(disabledFields.contains("drainageType"))
                                }
                            }
                        }
                    }
                    
                    if selectedSection == .optionalDetails {
                        Section(header: Text("Drainage Details (Optional)")) {
                            // Header row - always visible
                            HStack {
                                VStack(alignment: .leading) {
                                    if !isOptionalDetailsExpanded {
                                        // You can add a summary here if needed (e.g. Odor: Yes, Pain: 3/10)
                                        if odorPresent || Int(painLevel) > 0 || !temperature.isEmpty {
                                            Text("Tap to view optional details")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("No optional details entered")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isOptionalDetailsExpanded.toggle()
                                    }
                                }) {
                                    Image(systemName: isOptionalDetailsExpanded ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isOptionalDetailsExpanded.toggle()
                                }
                            }
                            
                            // Expandable content
                            if isOptionalDetailsExpanded {
                                Picker("Odor", selection: $odor) {
                                    ForEach(DrainageEntry.odorOptions, id: \.self) { odorOption in
                                        Text(odorOption).tag(odorOption)
                                    }
                                }
                                .disabled(disabledFields.contains("odor"))
                                .opacity(hiddenFields.contains("odor") ? 0 : 1)
                                
                                if odor == "Other" && !hiddenFields.contains("odor") {
                                    TextField("Specify Odor", text: $odorOther)
                                        .disabled(disabledFields.contains("odorOther"))
                                }
                                
                                Toggle("Does the Fluid collection include a Saline Flush?", isOn: $SalineFlush)
                                if SalineFlush {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("Total Fluid Amount")
                                                .font(.system(size: 16))
                                            
                                            TextField("0", text: $SalineFlushamount)
                                                .keyboardType(.numberPad)
                                                .multilineTextAlignment(.trailing)
                                            
                                            Picker("Unit", selection: $amountUnit) {
                                                Text("ml").tag("ml")
                                                //   Text("cc").tag("cc")
                                            }
                                            .pickerStyle(.menu)
                                            .frame(width: 120)
                                        }
                                    }
                                }
                                
                                //  Toggle("Odor Present", isOn: $odorPresent)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Pain Level")
                                        Spacer()
                                        Text("\(Int(painLevel))/10")
                                    }
                                    Slider(value: $painLevel, in: 0 ... 10, step: 1)
                                }
                                
                                HStack {
                                    Text("Temperature (F)")
                                    TextField("98.0", text: $temperature)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.dynamicAccent)
                                }
                                
                                //   Toggle("Doctor Notified", isOn: $doctorNotified)
                                
                                TextField("Additional Comments", text: $comments, axis: .vertical)
                                    .lineLimit(3 ... 6)
                            }
                        }
                    }
                    
                    if selectedSection == .Images {
                        Section(header: Text("Before Drainage")) {
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $beforePhotoItems,
                                             matching: .images,
                                             photoLibrary: .shared()) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text("Gallery")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                
                                Button {
                                    isBeforeCameraPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Camera")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                                         .onChange(of: beforePhotoItems) { _, newItems in
                                             Task {
                                                 let existingUrls = beforeImages.compactMap { $0.url }
                                                 beforeImages = existingUrls.map { (image: nil, url: $0) }
                                                 for item in newItems {
                                                     if let data = try? await item.loadTransferable(type: Data.self),
                                                        let image = UIImage(data: data) {
                                                         beforeImages.append((image: image, url: nil))
                                                     }
                                                 }
                                             }
                                         }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(beforeImages.indices, id: \.self) { index in
                                        if let image = beforeImages[index].image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 200)
                                                .cornerRadius(8)
                                                .overlay(alignment: .topTrailing) {
                                                    Button(action: {
                                                        beforeImages.remove(at: index)
                                                        if index < beforePhotoItems.count {
                                                            beforePhotoItems.remove(at: index)
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .padding(4)
                                                }
                                        } else if let url = beforeImages[index].url {
                                            AsyncImage(url: URL(string: url)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 200, height: 200)
                                                case let .success(image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 200, height: 200)
                                                        .cornerRadius(8)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .font(.largeTitle)
                                                        .foregroundColor(.gray)
                                                        .frame(width: 200, height: 200)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: {
                                                    beforeImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white.clipShape(Circle()))
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    if selectedSection == .Images {
                        Section(header: Text("After Drainage")) {
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $afterPhotoItems,
                                             matching: .images,
                                             photoLibrary: .shared()) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text("Gallery")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                
                                Button {
                                    isAfterCameraPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Camera")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                                         .onChange(of: afterPhotoItems) { _, newItems in
                                             Task {
                                                 let existingUrls = afterImages.compactMap { $0.url }
                                                 afterImages = existingUrls.map { (image: nil, url: $0) }
                                                 for item in newItems {
                                                     if let data = try? await item.loadTransferable(type: Data.self),
                                                        let image = UIImage(data: data) {
                                                         afterImages.append((image: image, url: nil))
                                                     }
                                                 }
                                             }
                                         }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(afterImages.indices, id: \.self) { index in
                                        if let image = afterImages[index].image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 200)
                                                .cornerRadius(8)
                                                .overlay(alignment: .topTrailing) {
                                                    Button(action: {
                                                        afterImages.remove(at: index)
                                                        if index < afterPhotoItems.count {
                                                            afterPhotoItems.remove(at: index)
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .padding(4)
                                                }
                                        } else if let url = afterImages[index].url {
                                            AsyncImage(url: URL(string: url)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 200, height: 200)
                                                case let .success(image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 200, height: 200)
                                                        .cornerRadius(8)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .font(.largeTitle)
                                                        .foregroundColor(.gray)
                                                        .frame(width: 200, height: 200)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: {
                                                    afterImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white.clipShape(Circle()))
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    if selectedSection == .Images {
                        Section(header: Text("Fluid Collection Cup")) {
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $fluidCupPhotoItems,
                                             matching: .images,
                                             photoLibrary: .shared()) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text("Gallery")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                
                                Button {
                                    isFluidCupCameraPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Camera")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                                         .onChange(of: fluidCupPhotoItems) { _, newItems in
                                             Task {
                                                 let existingUrls = fluidCupImages.compactMap { $0.url }
                                                 fluidCupImages = existingUrls.map { (image: nil, url: $0) }
                                                 for item in newItems {
                                                     if let data = try? await item.loadTransferable(type: Data.self),
                                                        let image = UIImage(data: data) {
                                                         fluidCupImages.append((image: image, url: nil))
                                                     }
                                                 }
                                             }
                                         }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(fluidCupImages.indices, id: \.self) { index in
                                        if let image = fluidCupImages[index].image {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 200)
                                                .cornerRadius(8)
                                                .overlay(alignment: .topTrailing) {
                                                    Button(action: {
                                                        fluidCupImages.remove(at: index)
                                                        if index < fluidCupPhotoItems.count {
                                                            fluidCupPhotoItems.remove(at: index)
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .padding(4)
                                                }
                                        } else if let url = fluidCupImages[index].url {
                                            AsyncImage(url: URL(string: url)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 200, height: 200)
                                                case let .success(image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 200, height: 200)
                                                        .cornerRadius(8)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .font(.largeTitle)
                                                        .foregroundColor(.gray)
                                                        .frame(width: 200, height: 200)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                Button(action: {
                                                    fluidCupImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white.clipShape(Circle()))
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            NavigationManager.shared.dismiss()
                        }
                        .foregroundColor(.gray)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(saveButtonTitle) {
                            Task {
                                await saveEntry()
                            }
                        }
                        .disabled(!isFormValid || isLoading)
                        .foregroundColor(isFormValid && !isLoading ? .accent : .gray)
                    }
                }
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.1))
                        }
                    }
                )
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                    }
                }
                .sheet(isPresented: $showPatientSelection) {
                    PatientSelectionView(
                        isPresented: $showPatientSelection,
                        selectedPatientId: $patientId,
                        selectedPatientName: $patientName
                    )
                }
                .sheet(isPresented: $isBeforeCameraPresented) {
                    ImagePicker(sourceType: .camera) { image in
                        if let image = image {
                            beforeImages.append((image: image, url: nil))
                        }
                    }
                }
                .sheet(isPresented: $isAfterCameraPresented) {
                    ImagePicker(sourceType: .camera) { image in
                        if let image = image {
                            afterImages.append((image: image, url: nil))
                        }
                    }
                }
                .sheet(isPresented: $isFluidCupCameraPresented) {
                    ImagePicker(sourceType: .camera) { image in
                        if let image = image {
                            fluidCupImages.append((image: image, url: nil))
                        }
                    }
                }
            }
            .interactiveDismissDisabled()
        }
    }

    private var isFormValid: Bool {
        // Check required fields based on FieldConfig
        let requiredFieldsValid = requiredFields.allSatisfy { fieldKey in
            switch fieldKey {
            case "amount":
                return !amount.isEmpty && Double(amount) != nil
            case "location":
                return !location.isEmpty
            case "color":
                return !color.isEmpty && (color != "Other" || !colorOther.isEmpty)
            case "drainageType":
                return !drainageType.isEmpty && (drainageType != "Other" || !drainageTypeOther.isEmpty)
            case "consistency":
                return !consistency.isEmpty && (!consistency.contains("Other") || !consistencyOther.isEmpty)
            case "odor":
                return !odor.isEmpty && (odor != "Other" || !odorOther.isEmpty)
            case "fluidType":
                return !fluidType.isEmpty
            case "temperature":
                return !temperature.isEmpty && Double(temperature) != nil
            case "painLevel":
                return painLevel > 0
            case "comments":
                return !comments.isEmpty
            case "beforeImage":
                return !beforeImages.isEmpty
            case "afterImage":
                return !afterImages.isEmpty
            case "fluidCupImage":
                return !fluidCupImages.isEmpty
            default:
                return true // For unknown fields, assume valid
            }
        }
        
        // Check current validation logic for non-FieldConfig fields
        let currentValidation = 
            (requiredFields.contains("beforeImage") || !beforeImages.isEmpty) &&
            (requiredFields.contains("afterImage") || !afterImages.isEmpty) &&
            (requiredFields.contains("fluidCupImage") || !fluidCupImages.isEmpty) &&
            // Only validate amount if not in required fields (to avoid double validation)
            (requiredFields.contains("amount") || !amount.isEmpty) &&
            (requiredFields.contains("location") || !location.isEmpty) &&
            (requiredFields.contains("color") || !color.isEmpty) &&
            (requiredFields.contains("drainageType") || !drainageType.isEmpty) &&
            (requiredFields.contains("consistency") || !consistency.isEmpty) &&
            // Validate "Other" fields only if the main field is not required or is valid
            (color != "Other" || !colorOther.isEmpty) &&
            (!consistency.contains("Other") || !consistencyOther.isEmpty) &&
            (odor != "Other" || !odorOther.isEmpty) &&
            (drainageType != "Other" || !drainageTypeOther.isEmpty) &&
            (requiredFields.contains("amount") || Double(amount) != nil) &&
            (temperature.isEmpty || Double(temperature) != nil)
        
        return requiredFieldsValid && currentValidation
    }

    private var navigationTitle: String {
        if incident != nil {
            return "Create Record"
        } else if entry != nil {
            return "Edit Entry"
        } else {
            return "New Drainage Entry"
        }
    }

    private var saveButtonTitle: String {
        if incident != nil {
            return "Save Record"
        } else {
            return entry != nil ? "Update" : "Save"
        }
    }

    private func saveEntry() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Upload images first
            var beforeImageUrls: [String] = []
            var afterImageUrls: [String] = []
            var fluidCupImageUrls: [String] = []

            // Process before images
            for imageData in beforeImages {
                if let url = imageData.url {
                    // Remove signature parameters from URL
                    if let baseUrl = url.split(separator: "?").first {
                        beforeImageUrls.append(String(baseUrl))
                    } else {
                        beforeImageUrls.append(url)
                    }
                } else if let image = imageData.image {
                    if let url = try await store.uploadEventImage(image) {
                        beforeImageUrls.append(url)
                    }
                }
            }

            // Process after images
            for imageData in afterImages {
                if let url = imageData.url {
                    // Remove signature parameters from URL
                    if let baseUrl = url.split(separator: "?").first {
                        afterImageUrls.append(String(baseUrl))
                    } else {
                        afterImageUrls.append(url)
                    }
                } else if let image = imageData.image {
                    if let url = try await store.uploadEventImage(image) {
                        afterImageUrls.append(url)
                    }
                }
            }

            // Process fluid cup images
            for imageData in fluidCupImages {
                if let url = imageData.url {
                    // Remove signature parameters from URL
                    if let baseUrl = url.split(separator: "?").first {
                        fluidCupImageUrls.append(String(baseUrl))
                    } else {
                        fluidCupImageUrls.append(url)
                    }
                } else if let image = imageData.image {
                    if let url = try await store.uploadEventImage(image) {
                        fluidCupImageUrls.append(url)
                    }
                }
            }

            // Convert temperature to Celsius for API
            //  let temp = temperature.isEmpty ? 0.0 : (temperatureInCelsius ?? 0.0)
            let temp = Double(temperature) ?? 0.0

            let newEntry = DrainageEntry(
                id: entry?.id ?? "",
                userId: entry?.userId ?? "",
                patientId: TokenManager.shared.loadCurrentUser()?.role == "Patient" ? TokenManager.shared.loadCurrentUser()?.userSlug ?? "" : patientId.trimmingCharacters(in: .whitespacesAndNewlines),
                patientName: TokenManager.shared.loadCurrentUser()?.role == "Patient" ? TokenManager.shared.getUserName() ?? "" : patientName.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: Double(amount) ?? 0,
                amountUnit: amountUnit,
                location: location,
                fluidType: fluidType == "Other" ? fluidTypeOther : fluidType,
                color: color == "Other" ? colorOther : color,
                colorOther: color == "Other" ? colorOther : nil,
                consistency: consistency.contains("Other") ? Array(consistency.filter { $0 != "Other" }) + [consistencyOther] : Array(consistency),
                odor: odor == "Other" ? odorOther : odor,
                drainageType: drainageType == "Other" ? drainageTypeOther : drainageType,
                isFluidSalineFlush: SalineFlush,
                fluidSalineFlushAmount: SalineFlush && !SalineFlushamount.isEmpty ? Double(SalineFlushamount) : nil,
                fluidSalineFlushAmountUnit: SalineFlush ? amountUnit : nil,
                comments: comments,
                odorPresent: odorPresent,
                painLevel: Int(painLevel),
                temperature: temp,
                doctorNotified: doctorNotified,
                recordedAt: recordedAt,
                createdAt: entry?.createdAt ?? Date(),
                updatedAt: Date(),
                beforeImage: beforeImageUrls,
                afterImage: afterImageUrls,
                fluidCupImage: fluidCupImageUrls,
                access: entry?.access ?? [],
                accessData: entry?.accessData ?? [],
                drainageId: entry?.drainageId,
                incidentId: incident?.id
            )

            if let existingEntry = entry {
                await store.updateEntry(newEntry)
                try? await Task.sleep(nanoseconds: 1 * 1000000000) // Add a small delay
                NotificationCenter.default.post(name: .updateDrainageRecord, object: nil)
            } else {
                await store.addEntry(newEntry)
            }

            NavigationManager.shared.dismiss()
            // try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // Add a small delay
            NotificationCenter.default.post(name: .RefreshDrainageList, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationView {
        AddDrainageView()
            .environmentObject(DrainageStore())
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            parent.completion(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
